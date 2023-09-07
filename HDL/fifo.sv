/***********
fifo
use mem
***********/
module fifo #(parameter WIDTH, parameter SIZE)(
	input clk,input rst,
	input [WIDTH-1:0] in,
	output [WIDTH-1:0] out
);
/*
if(WIDTH < 256) begin 
	DW_fifo_s1_sf #(WIDTH,  SIZE,  1,  1,  0,  3)
	U1 (.clk(inst_clk),   .rst_n(!rst),   .push_req_n(inst_push_req_n),
		.pop_req_n(inst_pop_req_n),   .diag_n(inst_diag_n),
		.data_in(inst_data_in),   .empty(empty_inst),
		.almost_empty(almost_empty_inst),   .half_full(half_full_inst),
		.almost_full(almost_full_inst),   .full(full_inst),
	.error(error_inst),   .data_out(data_out_inst) );
end
else begin
*/
logic [$clog2(SIZE-1)-1:0] addr;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		addr <= '0;
	end
	else begin
		if (addr < SIZE-2) addr <= addr+1;
		else addr <= '0;
	end
end
sio_ram #(.WIDTH(WIDTH), .SIZE(SIZE-1)) ram(.*);
//end
endmodule

// will delay one more clock if it's BRAM in fifo
module sio_ram #(parameter WIDTH, parameter SIZE, parameter BRAM=1)(
	input clk,
	input [$clog2(SIZE)-1:0] addr,
	input [WIDTH-1:0] in,
	output logic[WIDTH-1:0] out
);
logic [WIDTH-1:0] ram[SIZE];
generate
if(BRAM == 1) begin
	always_ff @(posedge clk) begin
		ram[addr] <= in;
		out <= ram[addr];
	end
end
else begin
	always_ff @(posedge clk) begin
		ram[addr] <= in;
	end
	assign out = ram[addr];
end
endgenerate
endmodule
