/***********
add and substract with modular

input: in[0],in[1]
output: 
	out[0] = (in[0]+in[1]) %Q
	out[1] = (in[0]-in[1]) %Q
***********/

module add_sub (
	input clk,
	input signed [`DATA_WIDTH-1:0]in[2],
	output logic signed [`DATA_WIDTH-1:0]out[2]
);
logic signed [`DATA_WIDTH:0] add, sub;
always_ff @(posedge clk) begin
	add <= in[0]+in[1];
	sub <= in[0]-in[1];

	if(add[`DATA_WIDTH]^add[`DATA_WIDTH-1]) out[0] <= (add[`DATA_WIDTH])? add+`Q : add-`Q;
	else out[0] <= add;
	if(sub[`DATA_WIDTH]^sub[`DATA_WIDTH-1]) out[1] <= (sub[`DATA_WIDTH])? sub+`Q : sub-`Q;
	else out[1] <= sub;
end
endmodule
