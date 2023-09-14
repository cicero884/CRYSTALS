/**********
top_ntt
example of usage this module
**********/

module top_ntt(
	input clk, input rst,
	input ntt_in_en, input [`DATA_WIDTH-1:0] ntt_in[2],
	output logic ntt_out_en, output logic [`DATA_WIDTH-1:0] ntt_out[2],
	input intt_in_en, input [`DATA_WIDTH-1:0] intt_in[2],
	output logic intt_out_en, output logic [`DATA_WIDTH-1:0] intt_out[2],
	input pwm_in_en, input [`DATA_WIDTH-1:0] pwm_in[2][2],
	output logic pwm_out_en, output logic [`DATA_WIDTH-1:0] pwm_out[2]
);

// all the zeta
logic [`NTT_STAGE_CNT-2:0] rom_addr[2][`NTT_STAGE_CNT];
logic [`DATA_WIDTH-1:0] rom_data[2][`NTT_STAGE_CNT];
zeta_rom zeta_rom(.*);

// fifo ctrls
// you only need one even if you have a lot of ntt or intt
fifo_ctrl_io fifo_ctrl_if;
fifo_ctls u_fifo_cts(
	.fifo_ctrl_if(fifo_ctrl_if.controller.counter),
.*);

ntt u_ntt(
	.in_en(ntt_in_en), .in(ntt_in),
	.out_en(ntt_out_en), .out(ntt_out),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
	.fifo_ctrl_if(fifo_ctrl_if.ntts[0].client)
.*);

intt u_intt(
	.in_en(intt_in_en), .in(intt_in),
	.out_en(intt_out_en), .out(intt_out),
	.rom_addr(rom_addr[1]), .rom_data(rom_data[1]),
	.fifo_ctrl_if(fifo_ctrl_if.intts[0].client)
.*);

// for pwm
endmodule
