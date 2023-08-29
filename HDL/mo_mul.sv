/************
modular multiplication
use modified MWR2MM
switch a and b in this design will change range of output
it's better to let a<Q

TODO: optmize every stage to FA & HA

input: a,b (RANGE:unsigned 0~Q)
output: result = a*b*2^^(WIDTH-1) %Q (RANGE: signed -Q~Q)
************/
`include "ntt.svh"

module mo_mul #(WIDTH)(
	input clk,
	input [WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic signed[WIDTH:0] result
);

logic [WIDTH-1:0] tmp_b[WIDTH+1],tmp_a[WIDTH+1];
logic signed [WIDTH:0] data[WIDTH+1];
logic signed [WIDTH+1:0] tmp_data[WIDTH];
assign data[0] = '0;
assign tmp_a[0] = a;
assign tmp_b[0] = b;
assign result = data[WIDTH];

always_comb begin
	for (int i=0; i < WIDTH; i++) begin
		/* // sigend bit of b need to be negetive
		if(i == WIDTH-1) begin
			tmp_data[i] = (tmp_b[i][i])? data[i] - tmp_a[i]: data[i];
		end
		else begin */
		//tmp_data[i] = $signed((tmp_b[i][i])? data[i] + tmp_a[i]: data[i]);
		tmp_data[i] = data[i];
		if(tmp_b[i][i])? tmp_data+=tmp_a[i];
		if(tmp_data[i][0]) tmp_data[i][WIDTH+1:`Q_M] -= `Q_K;
		//end
	end
end
always_ff @(posedge clk) begin
	for (int i=0; i < WIDTH; i++) begin
		data[i+1] <= tmp_data[i]>>1;
		tmp_a[i+1] <= tmp_a[i];
		tmp_b[i+1] <= tmp_b[i];
	end
end
endmodule
