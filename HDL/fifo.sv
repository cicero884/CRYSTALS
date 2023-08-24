/***********
fifo
use mem
***********/

module fifo #(parameter WIDTH, parameter SIZE)(
	input clk,input rst,
	input [WIDTH-1:0] in,
	output [WIDTH-1:0] out
);
generate
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
// use memory generator?
logic [WIDTH-1:0] mem[SIZE];
logic [$clog2(SIZE)-1:0] cnt;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		cnt <= 0;
	end
	else begin
		if (cnt == SIZE-1) cnt <= 0;
		else cnt <= cnt+1;
	end
end
always_ff @(posedge clk) begin
	mem[cnt] <= in;
end
assign out = mem[cnt];
//end
//endgenerate
endmodule
