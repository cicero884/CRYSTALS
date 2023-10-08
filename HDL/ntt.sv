/***************
duel pipelined ntt
***************/
import ntt_pkg::*;
module ntt(
	input clk,input rst,
	input in_en,input [DATA_WIDTH-1:0]in[2],
	output logic out_en,output logic [DATA_WIDTH-1:0]out[2],

	output logic[NTT_STAGE_CNT-2:0] rom_addr[NTT_STAGE_CNT],
	input [DATA_WIDTH-1:0] rom_data[NTT_STAGE_CNT],
	output fifo_en[NTT_STAGE_CNT],
	input [`MAX_FIFO_ADDR_BITS-1:0] fifom_addr,
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr[NTT_STAGE_CNT]
);
logic [DATA_WIDTH-1:0] data[NTT_STAGE_CNT+1][2];
logic en[NTT_STAGE_CNT+1], gclk[NTT_STAGE_CNT];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[NTT_STAGE_CNT];
assign out_en = en[NTT_STAGE_CNT];
// TODO clock gating

// stage 0
assign fifo_en[0] = en[0]|en[1];
assign gclk[0] = clk;// & (en[0]|en[1]);
ntt_s0 staged_ntt_0 (
	.clk(gclk[0]),
	.in_en(en[0]), .in(data[0]),
	.out_en(en[1]), .out(data[1]),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
	.fifo1_addr(fifom_addr),
.*);

genvar i;
generate
for (i=1; i < NTT_STAGE_CNT; i++) begin
	assign fifo_en[i] = en[i]|en[i+1];
	assign gclk[i] = clk;// & (en[i]|en[i+1]);
	localparam SWITCH_INDEX = (NTT_STAGE_CNT-i-1);
	if (1<<(SWITCH_INDEX) > MUL_STAGE_CNT) begin
		ntt_sl #(.SWITCH_INDEX(SWITCH_INDEX)) staged_ntt_l (
			.clk(gclk[i]),
			.in_en(en[i]), .in(data[i]),
			.out_en(en[i+1]), .out(data[i+1]),
			.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
			.fifo1_addr(fifom_addr), .fifo2_addr(fifo2_addr[i]),
		.*);
	end
	else begin
		ntt_ss #(.SWITCH_INDEX(SWITCH_INDEX)) staged_ntt_s (
			.clk(gclk[i]),
			.in_en(en[i]), .in(data[i]),
			.out_en(en[i+1]), .out(data[i+1]),
			.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
			.fifo2_addr(fifo2_addr[i]),
		.*);
	end
end
endgenerate
endmodule

// stage 0
module ntt_s0(
	input clk,input rst,
	input in_en,input [DATA_WIDTH-1:0] in[2],
	output logic [NTT_STAGE_CNT-2:0] rom_addr,input [DATA_WIDTH-1:0] rom_data,
	output logic out_en,output [DATA_WIDTH-1:0] out[2],
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo1_addr
);
logic [DATA_WIDTH-1:0] fifo1_out, mul_result;
dp_ram #(.WIDTH(DATA_WIDTH), .DEPTH(MUL_STAGE_CNT-1)) s0_fifo(
	.addr(fifo1_addr),
	.in(in[0]), .out(fifo1_out), 
.*);

assign rom_addr = '0;
mo_mul s0_mul(
	.a(rom_data), .b(in[1]),
	.result(mul_result),
.*);

logic [DATA_WIDTH-1:0] add_sub_in[2];
assign add_sub_in = '{fifo1_out,mul_result};
add_sub #(.isNTT(1)) as_0(
	.in(add_sub_in),
	.out(out),
.*);

// counter for out_en
localparam out_max_cnt = MUL_STAGE_CNT+ADD_SUB_STAGE_CNT-1;
logic [$clog2(out_max_cnt+1)-1:0] out_cnt;
always_ff @(posedge clk,posedge rst) begin
	if(rst) begin
		out_en <= '0;
		out_cnt <= '0;
	end
	else begin
		if(in_en ^ out_en) begin
			if(out_cnt < out_max_cnt) out_cnt <= out_cnt + 1;
			else out_en <= in_en;
		end
		else out_cnt <= '0;
	end
end
endmodule: ntt_s0

`define NTT_SWITCH_CNT_BITS SWITCH_INDEX-1:0
`define NTT_ROM_BITS NTT_STAGE_CNT-2:SWITCH_INDEX
// helf reorder size
`define HRS (1<<(SWITCH_INDEX))

// stage L
// helf reorder size larger than mul cycle 
module ntt_sl #(parameter SWITCH_INDEX)(
	input clk,input rst,
	input in_en,input [DATA_WIDTH-1:0] in[2],
	output logic out_en,output [DATA_WIDTH-1:0] out[2],
	output logic [NTT_STAGE_CNT-2:0] rom_addr,input [DATA_WIDTH-1:0] rom_data,
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo1_addr, input [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr
);
logic [NTT_STAGE_CNT-2:0] ctl_cnt;
// counter for control switch & rom
always_ff @(posedge clk) begin
	if (in_en|out_en) ctl_cnt <= ctl_cnt-1;
	else ctl_cnt <= '1;
end
assign rom_addr = ctl_cnt[`NTT_ROM_BITS];
logic [DATA_WIDTH-1:0] switch_data[2], fifo1_out, mul_result;
logic switch_bit;
assign switch_bit = ctl_cnt[SWITCH_INDEX];
always_ff @(posedge clk) begin
	if(ctl_cnt[SWITCH_INDEX]) switch_data <= '{fifo1_out, in[1]};
	else switch_data <= '{in[1], fifo1_out};
end
// fifo2
logic [DATA_WIDTH-1:0] fifo2_out[2];
localparam fifo2_size = `HRS-MUL_STAGE_CNT-1;
dp_ram #(.WIDTH(DATA_WIDTH*2), .DEPTH(fifo2_size)) fifo2(
	.addr(fifo2_addr),
	.in({in[0], mul_result}), .out({fifo2_out[0], fifo2_out[1]}), 
.*);
// fifo1
dp_ram #(.WIDTH(DATA_WIDTH), .DEPTH(MUL_STAGE_CNT-1)) fifo1(
	.addr(fifo1_addr),
	.in(fifo2_out[0]), .out(fifo1_out), 
.*);
// mul with zeta
mo_mul si_mul(
	.a(rom_data), .b(switch_data[1]),
	.result(mul_result),
.*);

// add_sub
logic [DATA_WIDTH-1:0] add_sub_in[2];
assign add_sub_in = '{switch_data[0], fifo2_out[1]};
add_sub #(.isNTT(1)) as_l(
	.in(add_sub_in),
	.out(out),
.*);

// out_en
logic out_en_delay[ADD_SUB_STAGE_CNT+1];
assign out_en = out_en_delay[ADD_SUB_STAGE_CNT];
always_ff @(posedge clk, posedge rst) begin
	if(rst) out_en_delay <= '{default: '0};
	else begin
		if(!ctl_cnt[SWITCH_INDEX]) begin
			out_en_delay[0] <= in_en;
		end
		for(int i=0; i<ADD_SUB_STAGE_CNT; ++i) out_en_delay[i+1] <= out_en_delay[i];
	end
end
endmodule: ntt_sl

// stage S
// helf reorder size larger than mul cycle 
module ntt_ss #(parameter SWITCH_INDEX)(
	input clk,input rst,
	input in_en,input [DATA_WIDTH-1:0] in[2],
	output logic out_en,output [DATA_WIDTH-1:0] out[2],
	output logic [NTT_STAGE_CNT-2:0] rom_addr,input [DATA_WIDTH-1:0] rom_data,
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr
);
logic [NTT_STAGE_CNT-2:0] ctl_cnt, ctl_delay;
logic [DATA_WIDTH-1:0] in1_delay;
//logic switch_delay;
// counter for control switch & rom
always_ff @(posedge clk) begin
	if (in_en|out_en) ctl_cnt <= ctl_cnt-1;
	else ctl_cnt <= '1;
	ctl_delay <= ctl_cnt;

	in1_delay <=in[1];
end
assign rom_addr = ctl_delay[`NTT_ROM_BITS];
logic [DATA_WIDTH-1:0] switch_data[2], fifo1_out, mul_result;
logic switch_bit;
assign switch_bit = ctl_cnt[SWITCH_INDEX];
always_ff @(posedge clk) begin
	if(ctl_delay[SWITCH_INDEX]) switch_data <= '{fifo1_out, in1_delay};
	else switch_data <= '{in1_delay, fifo1_out};
end
// mul with zeta
mo_mul si_mul(
	.a(rom_data), .b(switch_data[1]),
	.result(mul_result),
.*);

// fifo1
generate
if (SWITCH_INDEX == 0) begin
	logic [DATA_WIDTH-1:0] fifo1_tmp;
	always_ff @(posedge clk) begin
		fifo1_tmp <= in[0];
		fifo1_out <= fifo1_tmp;
	end
end
else begin
	dp_ram #(.WIDTH(DATA_WIDTH), .DEPTH(`HRS)) fifo1(
		.addr(`MAX_FIFO_ADDR_BITS'(ctl_cnt[`NTT_SWITCH_CNT_BITS])),
		.in(in[0]), .out(fifo1_out), 
	.*);
end
endgenerate

// fifo2
logic [DATA_WIDTH-1:0] fifo2_out;
localparam fifo2_size = MUL_STAGE_CNT-`HRS-1;
dp_ram #(.WIDTH(DATA_WIDTH), .DEPTH(fifo2_size)) fifo2(
	.addr(fifo2_addr),
	.in(switch_data[0]), .out(fifo2_out), 
.*);
// add_sub
logic [DATA_WIDTH-1:0] add_sub_in[2];
assign add_sub_in = '{fifo2_out, mul_result};
add_sub #(.isNTT(1)) as_s(
	.in(add_sub_in),
	.out(out),
.*);
// out_en
localparam out_max_cnt = MUL_STAGE_CNT+ADD_SUB_STAGE_CNT+1;
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

//TODO:more specific clock gating?
/*
`ifdef CLK_GATING
assign m_en  = (out_en&in_en)|((in_en^out_en)&(out_cnt>=0));
assign as_en = (out_en&in_en)|((in_en^out_en)&(out_cnt>=(out_max_cnt-ADD_SUB_STAGE_CNT)));
`else
`endif
*/
