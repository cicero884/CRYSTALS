/***********
fifo
use mem
***********/

module fifo #(parameter WIDTH, parameter SIZE)(
	input clk,input rst,
	input [WIDTH-1:0] in,
	output [WIDTH-1:0] out
);
logic [WIDTH-1:0] mem[SIZE];
logic [$clog2(SIZE)-1:0] cnt;
always_ff @(posedge clk,posedge rst) begin
	if(rst) begin
		cnt <= 0;
	end
	else begin
		if(cnt == SIZE-1) cnt <= 0;
		else cnt <= cnt+1;
	end
end
always_ff @(posedge clk) begin
	mem[cnt] <= in;
end
assign out = mem[cnt];
