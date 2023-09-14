/***************
duel pipelined ntt
***************/

module ntt(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic [`DATA_WIDTH-1:0]out[2],

	output logic[`NTT_STAGE_CNT-2:0] rom_addr[`NTT_STAGE_CNT],
	input [`DATA_WIDTH-1:0] rom_data[`NTT_STAGE_CNT],
	fifo_ctrl_io fifo_ctrl_if
);
logic [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT][2];
logic en[`NTT_STAGE_CNT], gclk[`NTT_STAGE_CNT];
assign data[0] = in;
assign out = data[`NTT_STAGE_CNT-1];
assign out_en = en[`NTT_STAGE_CNT-1];
// TODO clock gating

// stage 0
ntt_s0 staged_ntt_0 (
	.clk(clk),
	.out_en(en[0]), .out(data[0]),
	.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
	.fifo1_addr(fifo_ctrl_if.fifom_addr),
.*);

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT-1; i++) begin
	assign gclk[i] = clk;// & (en[i]|en[i+1]);
	localparam SWITCH_INDEX = (`NTT_STAGE_CNT-i-2)
	if (1<<(SWITCH_INDEX) > `MUL_STAGE_CNT) begin
		ntt_sl #(.SWITCH_INDEX(SWITCH_INDEX)) staged_ntt_l (
			.clk(gclk[i]),
			.in_en(en[i]), .in(data[i]),
			.out_en(en[i+1]), .out(data[i+1]),
			.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
			.fifo1_addr(fifo_ctrl_if.fifom_addr), .fifo2_addr(fifo_ctrl_if.fifo2_addr),
		.*);
	end
	else begin
		ntt_ss #(.SWITCH_INDEX(SWITCH_INDEX)) staged_ntt_s (
			.clk(gclk[i]),
			.in_en(en[i]), .in(data[i]),
			.out_en(en[i+1]), .out(data[i+1]),
			.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
			.fifo2_addr(fifo_ctrl_if.fifo2_addr),
		.*);
	end
	//ntt_stage #(.STAGE(i)) staged_ntt (
	//	.clk(gclk[i]),
	//	.in_en(en[i]), .in(data[i]),
	//	.out_en(en[i+1]), .out(data[i+1]),
	//	.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
	//.*);
end
endgenerate
endmodule

// stage 0
module ntt_s0(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	output logic out_en,output [`DATA_WIDTH-1:0] out[2],
	input [$clog2(`MUL_STAGE_CNT-1)-1:0] fifo1_addr
);
logic [`DATA_WIDTH-1:0] fifo1_out, mul_result;
dp_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-1)) s0_fifo(
	.addr(fifo1_addr),
	.in(in[0]), .out(fifo1_out), 
.*);

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
endmodule: ntt_s0

`define NTT_SWITCH_CNT_BITS SWITCH_INDEX-1:0
`define NTT_ROM_BITS `NTT_STAGE_CNT-2:SWITCH_INDEX
// helf reorder size
`define HRS (1<<(SWITCH_INDEX))

// helf reorder size larger than mul cycle 
module ntt_sl #(parameter SWITCH_INDEX)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [$clog2(`MUL_STAGE_CNT-1)-1:0] fifo1_addr, input [SWITCH_INDEX-1:0] fifo2_addr;
);
logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
// counter for control switch & rom
always_ff @(posedge clk) begin
	if (in_en|out_en) ctl_cnt <= ctl_cnt-1;
	else ctl_cnt <= '1;
end
assign rom_addr = ctl_cnt[`NTT_ROM_BITS];
logic [`DATA_WIDTH-1:0] switch_data[2];
always_ff @(posedge clk) begin
	if(ctl_cnt[SWITCH_INDEX]) switch_data <= '{fifo1_out, in[1]};
	else switch_data <= '{in[1], fifo1_out};
end
// fifo2
logic [`DATA_WIDTH-1:0] fifo2_out[2];
dp_ram #(.WIDTH(`DATA_WIDTH), .SIZE(HRS-`MUL_STAGE_CNT-1)) fifo2(
	.addr(fifo2_addr),
	.in({in[0], mul_result}), .out({fifo2_out[0], fifo2_out[1]}), 
.*);
// fifo1
dp_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-1)) fifo1(
	.addr(fifo1_addr),
	.in(fifo2_out[0]), .out(fifo1_out), 
.*);
// mul with zeta
mo_mul si_mul(
	.a(rom_data), .b(switch_data[1]),
	.result(mul_result),
.*);

// add_sub
add_sub #(.isNTT(1)) as_l(
	.in('{switch_data[0], fifo2_out[1]}),
	.out(out),
.*);

// out_en
logic out_en_delay[`ADD_SUB_STAGE_CNT+1];
assign out_en = out_en_delay[`ADD_SUB_STAGE_CNT-1];
always_ff @(posedge clk, posedge rst) begin
	if(rst) out_en_delay <= '{default: '0};
	else begin
		if(!ctl_cnt[SWITCH_INDEX]) begin
			out_en_delay[0] <= in_en;
		end
		for(int i=0; i<`ADD_SUB_STAGE_CNT; ++i) out_en_delay[i+1] <= out_en_delay[i];
	end
end
endmodule: ntt_sl


// helf reorder size larger than mul cycle 
module ntt_ss #(parameter SWITCH_INDEX)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [SWITCH_INDEX-1:0] fifo2_addr;
);
logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
logic [`DATA_WIDTH-1:0] in1_delay;
// counter for control switch & rom
always_ff @(posedge clk) begin
	if (in_en|out_en) ctl_cnt <= ctl_cnt-1;
	else ctl_cnt <= '1;

	in1_delay <=in[1];
end
assign rom_addr = ctl_cnt[`NTT_ROM_BITS];
logic [`DATA_WIDTH-1:0] switch_data[2];
always_comb begin
	if(ctl_cnt[SWITCH_INDEX]) switch_data = '{fifo1_out, in1_delay};
	else switch_data = '{in1_delay, fifo1_out};
end
// mul with zeta
mo_mul si_mul(
	.a(rom_data), .b(switch_data[1]),
	.result(mul_result),
.*);

// fifo1
dp_ram #(.WIDTH(`DATA_WIDTH), .SIZE(HRS)) fifo1(
	.addr(ctl_cnt[`NTT_SWITCH_CNT_BITS]),
	.in(in[0]), .out(fifo1_out), 
.*);

// fifo2
logic [`DATA_WIDTH-1:0] fifo2_out;
dp_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-HRS-1)) fifo2(
	.addr(fifo2_addr),
	.in(switch_data[0]), .out(fifo2_out), 
.*);
// add_sub
add_sub #(.isNTT(1)) as_s(
	.in('{fifo2_out, mul_result}),
	.out(out),
.*);
// out_en
localparam out_max_cnt = `MUL_STAGE_CNT+`ADD_SUB_STAGE_CNT;
always_ff @(posedge clk,posedge rst) begin
	if(rst) begin
		out_en <= '0;
	end
	else begin
		if(in_en ^ out_en) begin
			if(signed'(ctl_cnt) < -out_max_cnt) out_en <= in_en;
		end
	end
end
endmodule: ntt_ss

/*
module ntt_stage #(parameter STAGE = 0)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [$clog2(`MUL_STAGE_CNT-1)-1:0] fifo1_addr
);

// component output
logic [`DATA_WIDTH-1:0] fifo1_out, mul_result;

generate
// first stage
// all data already ordered, so dont need reorder
if (STAGE == 0) begin
	// delay with mo_mul
	sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-1)) s0_fifo(
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
	logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
`define SWITCH_INDEX (`NTT_STAGE_CNT-STAGE-1)
`define NTT_SWITCH_CNT_BITS `SWITCH_INDEX-1:0
`define NTT_ROM_BITS `NTT_STAGE_CNT-2:`SWITCH_INDEX
	// counter for control switch & rom
	always_ff @(posedge clk) begin
		if (in_en|out_en) ctl_cnt <= ctl_cnt-1;
		else ctl_cnt <= '1;
	end
	assign rom_addr = ctl_cnt[`NTT_ROM_BITS];
	logic [`DATA_WIDTH-1:0] switch_data[2];
	always_ff @(posedge clk) begin
		if(ctl_cnt[`SWITCH_INDEX]) switch_data <= '{fifo1_out, in[1]};
		else switch_data <= '{in[1], fifo1_out};
	end
	// mul with zeta
	mo_mul si_mul(
		.a(rom_data), .b(switch_data[1]),
		.result(mul_result),
	.*);

	// helf reorder size
	localparam HRS = 1<<(`SWITCH_INDEX);
	// helf reorder size larger than mul cycle 
	if (HRS > `MUL_STAGE_CNT) begin
		// fifo2
		logic [`DATA_WIDTH-1:0] fifo2_out[2];
		fifo #(.WIDTH(`DATA_WIDTH*2), .SIZE(HRS-`MUL_STAGE_CNT)) fifo2(
			.in({in[0], mul_result}), .out({fifo2_out[0], fifo2_out[1]}), 
		.*);
		// fifo1
		sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-1)) fifo1(
			.addr(fifo1_addr),
			.in(fifo2_out[0]), .out(fifo1_out), 
		.*);
		// add_sub
		add_sub #(.isNTT(1)) as_l(
			.in('{switch_data[0], fifo2_out[1]}),
			.out(out),
		.*);
		logic out_en_delay[`ADD_SUB_STAGE_CNT+1];
		assign out_en = out_en_delay[`ADD_SUB_STAGE_CNT];
		always_ff @(posedge clk,posedge rst) begin
			if(rst) begin
				out_en_delay <= '{default: '0};
			end
			else begin
				if(!ctl_cnt[`SWITCH_INDEX]) out_en_delay[0] <= in_en;
				for(int j=0; j < `ADD_SUB_STAGE_CNT; ++j) out_en_delay[j+1] <= out_en_delay[j];
			end
		end
	end
	// helf reorder size smaller than mul cycle
	else begin
		// fifo1
		if(`SWITCH_INDEX > 0) begin
			sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(HRS), .BRAM(0)) fifo1(
				.addr(ctl_cnt[`NTT_SWITCH_CNT_BITS]),
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
		// out_en
		localparam out_max_cnt = `MUL_STAGE_CNT+`ADD_SUB_STAGE_CNT;
		always_ff @(posedge clk,posedge rst) begin
			if(rst) begin
				out_en <= '0;
			end
			else begin
				if(in_en ^ out_en) begin
					if(signed'(ctl_cnt) < -out_max_cnt) out_en <= in_en;
				end
			end
		end
	end
end
endgenerate
endmodule
*/
//TODO:more specific clock gating?
/*
`ifdef CLK_GATING
assign m_en  = (out_en&in_en)|((in_en^out_en)&(out_cnt>=0));
assign as_en = (out_en&in_en)|((in_en^out_en)&(out_cnt>=(out_max_cnt-`ADD_SUB_STAGE_CNT)));
`else
`endif
*/
