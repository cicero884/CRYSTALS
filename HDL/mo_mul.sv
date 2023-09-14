/************
modular multiplication
use modified MWR2MM
switch a and b in this design will change range of output
it's better to let a<Q

TODO: optmize every stage to FA & HA

input: a,b (RANGE:unsigned 0~Q)
output: result = a*b*2^^(WIDTH) %Q (RANGE: 0~Q or 0~2^^(WIDTH)-1, depend on a)
************/

module mo_mul #(parameter WIDTH=`DATA_WIDTH)(
	input clk,
	input [WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic [WIDTH-1:0] result
);

logic [WIDTH-1:0] tmp_b[WIDTH+1],tmp_a[WIDTH+1];
logic signed [WIDTH:0] data[WIDTH+1];
logic signed [WIDTH+1:0] tmp_data[WIDTH];
assign data[0] = '0;

assign tmp_a[0] = a;
assign tmp_b[0] = b;
always_comb begin
	for (int i=0; i < WIDTH; i++) begin
		tmp_data[i] = data[i];
		if(tmp_b[i][i]) tmp_data[i] += tmp_a[i];
		if(tmp_b[i][i]==='x) tmp_data[i] = 'x;
		if(tmp_data[i][0]) tmp_data[i][WIDTH+1:`Q_M] -= `Q_K;
	end
end
always_ff @(posedge clk) begin
	for (int i=0; i < WIDTH; i++) begin
		data[i+1] <= tmp_data[i]>>1;
		tmp_a[i+1] <= tmp_a[i];
		tmp_b[i+1] <= tmp_b[i];
	end
	result <= (data[WIDTH][WIDTH])? WIDTH'(data[WIDTH]+`Q) : WIDTH'(data[WIDTH]);
end
endmodule
