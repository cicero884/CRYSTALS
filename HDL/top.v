/**********
top
example of usage this module
**********/
module top(
	input clk, input rst,
	input ntt_in_en, input [`DATA_WIDTH-1:0] ntt_in[2],
	output logic ntt_out_en, output logic [`DATA_WIDTH-1:0] ntt_out[2],
	input intt_in_en, input [`DATA_WIDTH-1:0] intt_in[2],
	output logic intt_out_en, output logic [`DATA_WIDTH-1:0] intt_out[2],
	input pwm_in_en, input [`DATA_WIDTH-1:0] pwm_in[2][2],
	output logic pwm_out_en, output logic [`DATA_WIDTH-1:0] pwm_out[2]
);

logic [`NTT_STAGE_CNT-2:0]rom_addr[2][`NTT_STAGE_CNT-1];
logic [`DATA_SIZE-1:0]rom_data[2][`NTT_STAGE_CNT];
zeta_rom u_zeta_rom(.*);

ntt u_ntt(
	.in_en(ntt_in_en), .in(ntt_in),
	.out_en(ntt_out_en), .out(ntt_out),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
.*);

endmodule
