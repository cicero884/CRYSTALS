/************
zeta_rom
*************/

`include "ntt.svh"

module duel_rom #(parameter STAGE)(
	input clk,
	input [STAGE-1:0] addr[2],
	output logic [`DATA_WIDTH-1:0] data[2]
);
logic [`DATA_WIDTH-1:0] rom[(1<<STAGE)];
string filename;
initial begin
	$sformat(filename, "rom_%0d.rom",STAGE);
	$readmemh(filename, rom);
end

always_ff @(posedge clk) begin
	data[0] <= rom[addr[0]];
	data[1] <= rom[addr[1]];
end

endmodule


module zeta_rom(
	input clk,
	input [`NTT_STAGE_CNT-2:0] rom_addr[2][`NTT_STAGE_CNT],
	output logic [`DATA_WIDTH-1:0]rom_data[2][`NTT_STAGE_CNT]
);

// rom_0 (only one number inside)
logic [`DATA_WIDTH-1:0] rom_0[1];
initial begin
	$readmemh("rom_0.rom",rom_0);
end
assign rom_data[0][0] = rom_0[0];
assign rom_data[1][0] = rom_0[0];

genvar i;
generate
for (i=1; i < `NTT_STAGE_CNT; i++) begin
	duel_rom #(i) zeta_splited(
		.addr('{rom_addr[0][i],rom_addr[1][i]}),
		.data('{rom_data[0][i],rom_data[1][i]}),
	.*);
end
endgenerate
endmodule
