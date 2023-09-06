/**********
top_ntt
example of usage this module
**********/
`include "ntt.svh"
`include "mo_mul.svh"

module top_ntt(
	input clk, input rst,
	input ntt_in_en, input [`DATA_WIDTH-1:0] ntt_in[2],
	output logic ntt_out_en, output logic [`DATA_WIDTH-1:0] ntt_out[2],
	input intt_in_en, input [`DATA_WIDTH-1:0] intt_in[2],
	output logic intt_out_en, output logic [`DATA_WIDTH-1:0] intt_out[2],
	input pwm_in_en, input [`DATA_WIDTH-1:0] pwm_in[2][2],
	output logic pwm_out_en, output logic [`DATA_WIDTH-1:0] pwm_out[2]
);

// all the zeta rom
logic [`NTT_STAGE_CNT-2:0] rom_addr[2][`NTT_STAGE_CNT];
logic [`DATA_WIDTH-1:0] rom_data[2][`NTT_STAGE_CNT];
zeta_rom zeta_rom(.*);

// counter for fifo which require delay `MUL_STAGE_CNT
// use same controller for all fifo in that size
logic [$clog2(`MUL_STAGE_CNT)-1:0] fifo1_addr;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		fifo1_addr <= '0;
	end
	else begin
		if (fifo1_addr < `MUL_STAGE_CNT-1) fifo1_addr <= fifo1_addr+1;
		else fifo1_addr <= '0;
	end
end

ntt u_ntt(
	.in_en(ntt_in_en), .in(ntt_in),
	.out_en(ntt_out_en), .out(ntt_out),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
.*);

intt u_intt(
	.in_en(intt_in_en), .in(intt_in),
	.out_en(intt_out_en), .out(intt_out),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
.*);

// for pwm
endmodule
