/***************
duel pipelined intt
***************/

`include "add_sub.svh"

module intt(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic [`DATA_WIDTH-1:0]out[2],

	output logic[`NTT_STAGE_CNT-2:0] rom_addr[`NTT_STAGE_CNT],
	input [`DATA_WIDTH-1:0] rom_data[`NTT_STAGE_CNT],
	input [$clog2(`DATA_WIDTH)-1:0] fifo1_addr
);
logic signed [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT+1][2];
logic en[`NTT_STAGE_CNT+1], gclk[`NTT_STAGE_CNT];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[`NTT_STAGE_CNT];
assign out_en = en[`NTT_STAGE_CNT];

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT; i++) begin
	// TODO clock gating
	assign gclk[i] = clk;// & (en[i]|en[i+1]);
	intt_stage #(.STAGE(i)) staged_ntt (
		.clk(gclk[i]),
		.in_en(en[i]), .in(data[i]),
		.out_en(en[i+1]), .out(data[i+1]),
		.rom_addr(rom_addr[`NTT_STAGE_CNT-i-1]), .rom_data(rom_data[`NTT_STAGE_CNT-i-1]),
	.*);
end
endgenerate
endmodule

// stage
module intt_stage #(parameter STAGE = `NTT_STAGE_CNT-1)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [$clog2(`DATA_WIDTH)-1:0] fifo1_addr
);

// component output
logic [`DATA_WIDTH-1:0] add_sub_out[2];

generate
// first stage
// all data already ordered, so dont need reorder
if (STAGE == `NTT_STAGE_CNT-1) begin
	add_sub #(.isNTT(0)) as_0(
		.in(in),
		.out(add_sub_out),
	.*);

	// delay with mo_mul
	sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-1)) s0_fifo(
		.addr(fifo1_addr),
		.in(add_sub_out[0]), .out(out[0]), 
	.*);

	// mul with zeta
	assign rom_addr = '0;
	mo_mul s0_mul(
		.a(rom_data), .b(add_sub_out[1]),
		.result(out[1]),
	.*);
	// counter for out_en
	localparam out_max_cnt = `MUL_STAGE_CNT+`ADD_SUB_STAGE_CNT-1;
	logic [$clog2(out_max_cnt+1)-1:0] out_cnt;
	always_ff @(posedge clk,posedge rst) begin
		if(rst) begin
			out_en <= '0;
			out_cnt <= '0;
		end
		else begin
			if(in_en ^ out_en) begin
				if(out_cnt < out_max_cnt) out_cnt <= out_cnt + 1;
				else out_en <= !out_en;
			end
			else out_cnt <= '0;
		end
	end
end
// other stage except last stage
else begin
	logic [`DATA_WIDTH-1:0] add_sub_out[2],switch_data,fifo2_out;
	// add_sub
	add_sub #(.isNTT(0)) as_i(
		.in(in),
		.out(add_sub_out),
	.*);

	logic in_en_delay[`ADD_SUB_STAGE_CNT+1];
	assign in_en_delay[0] = in_en;
	always_ff @(posedge clk) begin
		for(int i=0; i < ADD_SUB_STAGE_CNT; i++) in_en_delay[i+1] <= in_en_delay[i];
	end
	// counter for control switch & rom
	logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
	`define SWITCH_CNT_BITS STAGE-1:0
	`define ROM_BITS `NTT_STAGE_CNT-2:STAGE
	always_ff @(posedge clk) begin
		if (in_en_delay[`ADD_SUB_STAGE_CNT]|out_en) ctl_cnt <= ctl_cnt-1;
		else ctl_cnt <= '1;
	end

	assign rom_addr = ctl_cnt[`ROM_BITS];
	logic switch_bit;
	assign switch_bit = ctl_cnt[STAGE];
	// mul with zeta
	mo_mul si_mul(
		.a(rom_data), .b(add_sub_out[1]),
		.result(mul_result),
	.*);

	// helf reorder size
	localparam HRS = 1<<(STAGE);
	// helf reorder size larger than mul cycle 
	if (HRS > `MUL_STAGE_CNT) begin
		// fifo2
		logic [`DATA_WIDTH-1:0] fifo1_out;
		fifo #(.WIDTH(`DATA_WIDTH*2), .SIZE(HRS-`MUL_STAGE_CNT)) fifo2(
			.in({mul_result,fifo1_out}), .out({fifo2_out, out[1]}), 
		.*);
		// switch
		always_ff @(posedge clk) begin
			if(ctl_cnt[STAGE]) {switch_data,out[1]} <= '{add_sub_out[0], fifo2_out};
			else {switch_data,out[1]} <= '{fifo2_out, add_sub_out[0]};
		end
		// fifo1
		sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-1)) fifo1(
			.addr(fifo1_addr),
			.in(switch_data), .out(fifo1_out), 
		.*);
		// counter for out_en
		localparam out_max_cnt = HRS+`ADD_SUB_STAGE_CNT;
		logic [$clog2(out_max_cnt+1)-1:0] out_cnt;
		always_ff @(posedge clk,posedge rst) begin
			if(rst) begin
				out_en <= '0;
				out_cnt <= '0;
			end
			else begin
				if(in_en ^ out_en) begin
					if(out_cnt < out_max_cnt) out_cnt <= out_cnt + 1;
					else out_en <= !out_en;
				end
				else out_cnt <= '0;
			end
		end
	end
	// helf reorder size smaller than mul cycle
	else begin
		// fifo2
		fifo #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-HRS)) fifo2(
			.in(add_sub_out[0]), .out(fifo2_out), 
		.*);
		// switch
		always_ff @(posedge clk) begin
			if(ctl_cnt[STAGE]) {switch_data,out[1]} <= '{add_sub_out[0], fifo2_out};
			else {switch_data,out[1]} <= '{fifo2_out, add_sub_out[0]};
		end
		// fifo1
		if(STAGE > 0) begin
			sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(HRS-1)) fifo1(
				.addr(ctl_cnt[`SWITCH_CNT_BITS]),
				.in(switch_data), .out(out[0]), 
			.*);
		end
		else begin
			always_ff @(posedge clk) fifo1_out <= in[0];
		end
		// counter for out_en
		localparam out_max_cnt = `MUL_STAGE_CNT+`ADD_SUB_STAGE_CNT;
		logic [$clog2(out_max_cnt+1)-1:0] out_cnt;
		always_ff @(posedge clk,posedge rst) begin
			if(rst) begin
				out_en <= '0;
				out_cnt <= '0;
			end
			else begin
				if(in_en ^ out_en) begin
					if(out_cnt < out_max_cnt) out_cnt <= out_cnt+1;
					else out_en <= !out_en;
				end
				else out_cnt <= '0;
			end
		end
	end
end

//TODO:more specific clock gating?
/*
`ifdef CLK_GATING
assign m_en  = (out_en&in_en)|((in_en^out_en)&(out_cnt>=0));
assign as_en = (out_en&in_en)|((in_en^out_en)&(out_cnt>=(out_max_cnt-`ADD_SUB_STAGE_CNT)));
`else
`endif
*/
endgenerate
endmodule
