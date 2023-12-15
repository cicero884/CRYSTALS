/************
tf_rom
*************/
import ntt_pkg::*;
module duel_rom #(parameter STAGE)(
	input clk,
	input [NTT_STAGE_CNT-2:0] addr[2],
	output logic [DATA_WIDTH-1:0] data[2]
);
logic [DATA_WIDTH-1:0] rom[(1<<STAGE)];

`ifdef FAKE_ROM // temperary test for asic without memory generator
`include "fake_rom.svh"
always_ff @(posedge clk) begin
	data[0] <= tf_rom_array[(1<<STAGE)+addr[0][STAGE-1:0]];
	data[1] <= tf_rom_array[(1<<STAGE)+addr[1][STAGE-1:0]];
end
`else // work in ISE, for asic you should use memory generator
initial begin
	localparam bit [7:0] asscii_index = "0" + STAGE;
	localparam fname = {ROM_PATH,"/rom_",asscii_index,".dat"};
	if (STAGE > 9) begin
		$display("Error! the STAGE is over one digit, consider fix it in tf_rom");
		$finish;
	end
	$readmemh(fname, rom, 0, (1<<STAGE)-1);
end

always_ff @(posedge clk) begin
	data[0] <= rom[addr[0][STAGE-1:0]];
	data[1] <= rom[addr[1][STAGE-1:0]];
end
`endif
endmodule


module tf_rom(
	input clk,
	input [NTT_STAGE_CNT-2:0] rom_addr[2][NTT_STAGE_CNT],
	output logic [DATA_WIDTH-1:0]rom_data[2][NTT_STAGE_CNT]
);


// rom_0 (only one number inside)
/*
always_ff @(posedge clk) begin
    rom_data[0][0] <= ROM0_DATA;
    rom_data[1][0] <= ROM0_DATA;
end
*/
assign rom_data[0][0] = ROM0_DATA;
assign rom_data[1][0] = ROM0_DATA;


genvar i;
generate
for (i=1; i < NTT_STAGE_CNT; i++) begin
	logic [NTT_STAGE_CNT-2:0] tmp_rom_addr[2];
	logic [DATA_WIDTH-1:0]tmp_rom_data[2];
	assign tmp_rom_addr = '{rom_addr[0][i],rom_addr[1][i]};
	assign rom_data[0][i] = tmp_rom_data[0];
	assign rom_data[1][i] = tmp_rom_data[0];
	duel_rom #(i) tf_splited(
		.addr(tmp_rom_addr),
		.data(tmp_rom_data),
	.*);
end
endgenerate
endmodule
