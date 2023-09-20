/**********
top_ntt
example of usage this module
**********/
`include "ntt.svh"
`include "add_sub.svh"
`include "mo_mul.svh"
`include "fifo.svh"

module top_ntt(
	input clk, input rst,
	input ntt_in_en, input [`DATA_WIDTH-1:0] ntt_in1,input [`DATA_WIDTH-1:0] ntt_in2,
	output logic ntt_out_en, output logic [`DATA_WIDTH-1:0] ntt_out1,output logic [`DATA_WIDTH-1:0] ntt_out2,
	input intt_in_en, input [`DATA_WIDTH-1:0] intt_in1,input [`DATA_WIDTH-1:0] intt_in2,
	output logic intt_out_en, output logic [`DATA_WIDTH-1:0] intt_out1,output logic [`DATA_WIDTH-1:0] intt_out2,
	input pwm_in_en, input [`DATA_WIDTH-1:0] pwm_in11,input [`DATA_WIDTH-1:0] pwm_in12,input [`DATA_WIDTH-1:0] pwm_in21,input [`DATA_WIDTH-1:0] pwm_in22,
	output logic pwm_out_en, output logic [`DATA_WIDTH-1:0] pwm_out1, output logic [`DATA_WIDTH-1:0] pwm_out2
);

// all the zeta
logic [`NTT_STAGE_CNT-2:0] rom_addr[2][`NTT_STAGE_CNT];
logic [`DATA_WIDTH-1:0] rom_data[2][`NTT_STAGE_CNT];
zeta_rom zeta_rom(.*);

// fifo controls
localparam ntt_cnt = 1;
localparam intt_cnt = 1;

logic ntt_en [ntt_cnt][`NTT_STAGE_CNT], intt_en[ntt_cnt][`NTT_STAGE_CNT], fifo_en[`NTT_STAGE_CNT];
logic [`MAX_FIFO2_ADDR_BITS-1:0] fifo2_ntt_addr[`NTT_STAGE_CNT], fifo2_intt_addr[`NTT_STAGE_CNT], fifo2_addr[`NTT_STAGE_CNT];
logic [`MUL_STAGE_BITS-1:0] fifom_addr;
// FIXME: require casting to int for correct streaming operator
// I guess it's vcs bug
//ex: the behavier is different under there
//assign fifo2_ntt_addr = {<<$clog2(32){fifo2_addr}};
//assign fifo2_ntt_addr = {<<5{fifo2_addr}};
assign fifo2_ntt_addr = {<<(int'(`MAX_FIFO2_ADDR_BITS)){fifo2_addr}};
assign fifo2_intt_addr = fifo2_addr;
always_comb begin
	for (int i=0; i<`NTT_STAGE_CNT; i++) begin
		fifo_en[i] = '0;
		for (int j=0; j<ntt_cnt; j++) fifo_en[i]|=ntt_en[j][`NTT_STAGE_CNT-i-1];
		for (int j=0; j<intt_cnt; j++) fifo_en[i]|=intt_en[j][i];
	end
end
// fifo ctrls
// you only need one even if you have a lot of ntt or intt
// fifo_ctrl_io fifo_ctrl_if();
fifo_cts u_fifo_cts(.*);

logic [`DATA_WIDTH-1:0] ntt_in[2];
logic [`DATA_WIDTH-1:0] ntt_out[2];
logic [`DATA_WIDTH-1:0] intt_in[2];
logic [`DATA_WIDTH-1:0] intt_out[2];
logic [`DATA_WIDTH-1:0] pwm_in[2][2];
logic [`DATA_WIDTH-1:0] pwm_out[2];
logic ntt_in_en_delay,intt_in_en_delay,pwm_in_en_delay;
// give in negetive clk, so cache at posedge clk
always_ff @(posedge clk) begin
	ntt_in_en_delay <= ntt_in_en;
	intt_in_en_delay <= intt_in_en;
	pwm_in_en_delay <= pwm_in_en;
	ntt_in  <= '{ntt_in1,ntt_in2};
	intt_in <= '{intt_in1,intt_in2};
	pwm_in  <= '{'{pwm_in11,pwm_in12}, '{pwm_in21,pwm_in22}};
end

assign {ntt_out1,ntt_out2}   = {>>{ntt_out}};
assign {intt_out1,intt_out2} = {>>{intt_out}};
assign {pwm_out1,pwm_out2}   = {>>{pwm_out}};
ntt u_ntt(
	.in_en(ntt_in_en_delay), .in(ntt_in),
	.out_en(ntt_out_en), .out(ntt_out),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
	.fifo_en(ntt_en[0]),
	.fifo2_addr(fifo2_ntt_addr),
.*);

//intt u_intt(
//	.in_en(intt_in_en), .in(intt_in),
//	.out_en(intt_out_en), .out(intt_out),
//	.rom_addr(rom_addr[1]), .rom_data(rom_data[1]),
//	.fifo_en(intt_en[0]),
//	.fifo2_addr(fifo2_intt_addr),
//.*);

// for pwm
endmodule
