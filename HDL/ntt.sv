/***************
duel pipelined ntt
***************/
`include "ntt.svh"
`include "add_sub.svh"

module ntt(
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
	ntt_stage #(.STAGE(i)) staged_ntt (
		.clk(gclk[i]),
		.in_en(en[i]), .in(data[i]),
		.out_en(en[i+1]), .out(data[i+1]),
		.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
	.*);
end
endgenerate
endmodule

// stage
module ntt_stage #(parameter STAGE = 0)(
	input clk,input rst,
	input in_en,input signed [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output signed [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [$clog2(`DATA_WIDTH)-1:0] fifo1_addr
);

// component output
logic [`DATA_WIDTH-1:0] fifo1_out, mul_result;

generate
// first stage
// all data already ordered, so dont need reorder
if (STAGE == 0) begin
	// delay with mo_mul
	sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT)) s0_fifo(
		.addr(fifo1_addr),
		.in(in[0]), .out(fifo1_out), 
	.*);

	// mul with zeta
	assign rom_addr = '0;
	mo_mul s0_mul(
		.a(rom_data), .b(in[1]),
		.result(mul_result),
	.*);
	add_sub #(.isNTT(1)) as_0(
		.in('{fifo1_out,mul_result}),
		.out(out),
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
// other stage except 0
else begin
	// counter for control switch & rom
	logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
	`define SWITCH_BITS `NTT_STAGE_CNT-STAGE-2:0
	`define ROM_BITS `NTT_STAGE_CNT-2:`NTT_STAGE_CNT-STAGE-1
	always_ff @(posedge clk) begin
		if (in_en|out_en) ctl_cnt <= ctl_cnt-1;
		else ctl_cnt <= '1;
	end

	assign rom_addr = ctl_cnt[`ROM_BITS];
	logic [`DATA_WIDTH-1:0] switch_data[2];
	logic switch_bit;
	assign switch_bit = ctl_cnt[`NTT_STAGE_CNT-STAGE-1];
	always_ff @(posedge clk) begin
		if(ctl_cnt[`NTT_STAGE_CNT-STAGE-1]) switch_data <= '{fifo1_out, in[1]};
		else switch_data <= '{in[1], fifo1_out};
	end
	// mul with zeta
	mo_mul si_mul(
		.a(rom_data), .b(switch_data[1]),
		.result(mul_result),
	.*);

	// helf reorder size
	localparam HRS = 1<<(`NTT_STAGE_CNT-STAGE-1);
	// helf reorder size larger than mul cycle 
	if (HRS > `MUL_STAGE_CNT) begin
		// fifo2
		logic [`DATA_WIDTH-1:0] fifo2_out[2];
		fifo #(.WIDTH(`DATA_WIDTH*2), .SIZE(HRS-`MUL_STAGE_CNT)) fifo2(
			.in({in[0], mul_result}), .out({fifo2_out[0], fifo2_out[1]}), 
		.*);
		// fifo1
		sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT)) fifo1(
			.addr(fifo1_addr),
			.in(fifo2_out[0]), .out(fifo1_out), 
		.*);
		// add_sub
		add_sub #(.isNTT(1)) as_l(
			.in('{switch_data[0], fifo2_out[1]}),
			.out(out),
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
		// fifo1
		if(`NTT_STAGE_CNT-STAGE > 1) begin
			sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(HRS)) fifo1(
				.addr(ctl_cnt[`SWITCH_BITS]),
				.in(in[0]), .out(fifo1_out), 
			.*);
		end
		else begin
			always_ff @(posedge clk) fifo1_out <= in[0];
		end
		// fifo2
		logic [`DATA_WIDTH-1:0] fifo2_out;
		fifo #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-HRS)) fifo2(
			.in(switch_data[0]), .out(fifo2_out), 
		.*);
		// add_sub
		add_sub #(.isNTT(1)) as_s(
			.in('{fifo2_out, mul_result}),
			.out(out),
		.*);
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
