/************
zeta_rom
*************/
`include "rom.svh"

module duel_rom #(parameter STAGE)(
	input clk,
	input [`NTT_STAGE_CNT-2:0] addr[2],
	output logic [`DATA_WIDTH-1:0] data[2]
);
logic [`DATA_WIDTH-1:0] rom[(1<<STAGE)];


//string fname;

initial begin
    //$sformat(fname ,"rom_%0d.rom", STAGE);
	//$readmemh($sformatf("rom_%0d.rom", STAGE), rom);

	// I know this is dumb, but I cant find better way for vivodo 2018
	// if you are not using vivodo, you should use memory generator
	localparam bit [7:0] asscii_index = "0" + STAGE;
	//localparam path = get_path_from_file(`__FILE__);
	localparam fname = {`ROM_PATH,"/rom_",asscii_index,".dat"};
	if(STAGE > 9) begin
		$display("ERROR! the STAGE is over one digit, consider fix it in zeta_rom");
		$finish;
	end
	$readmemh(fname, rom, 0, (1<<STAGE)-1);
end

always_ff @(posedge clk) begin
	data[0] <= rom[addr[0][STAGE-1:0]];
	data[1] <= rom[addr[1][STAGE-1:0]];
end

endmodule


module zeta_rom(
	input clk,
	input [`NTT_STAGE_CNT-2:0] rom_addr[2][`NTT_STAGE_CNT],
	output logic [`DATA_WIDTH-1:0]rom_data[2][`NTT_STAGE_CNT]
);


// rom_0 (only one number inside)
logic [`DATA_WIDTH-1:0] rom_0[0:1];
initial begin
	localparam fname = {`ROM_PATH,"/rom_0.dat"};
	$readmemh({`ROM_PATH,"/rom_0.dat"}, rom_0);
end

always_ff @(posedge clk) begin
    rom_data[0][0] <= rom_0[0];
    rom_data[1][0] <= rom_0[0];
end
//assign rom_data[0][0] = rom_0[0];
//assign rom_data[1][0] = rom_0[0];


genvar i;
generate
for (i=1; i < `NTT_STAGE_CNT; i++) begin
	logic [`NTT_STAGE_CNT-2:0] tmp_rom_addr[2];
	logic [`DATA_WIDTH-1:0]tmp_rom_data[2];
	assign tmp_rom_addr = '{rom_addr[0][i],rom_addr[1][i]};
	assign rom_data[0][i] = tmp_rom_data[0];
	assign rom_data[1][i] = tmp_rom_data[0];
	duel_rom #(i) zeta_splited(
		.addr(tmp_rom_addr),
		.data(tmp_rom_data),
	.*);
end
endgenerate
endmodule
