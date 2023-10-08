/***********
add and substract with modular

ntt(signed):
	input: (0 ~ (2^^n)-1, 0 ~ Q)
	add_sub: (0 ~ Q+(2^^n-1), -Q ~ (2^^n-1))
	after mod: 0 ~ (2^^n-1)
intt(unsigned):
	input: (0 ~ Q, 0 ~ Q)
	add_sub(with /2): (-Q/2 ~ Q, -Q ~ Q/2)
	after mod: 0~Q

input: in[0],in[1]
output: 
	ntt:
		out[0] = (in[0]+in[1]) %Q
		out[1] = (in[0]-in[1]) %Q
	intt:
		out[0] = (in[0]+in[1])/2 %Q
		out[1] = (in[0]-in[1])/2 %Q
***********/
import ntt_pkg::*;
module add_sub #(parameter isNTT)(
	input clk,
	input [DATA_WIDTH-1:0]in[2],
	output logic [DATA_WIDTH-1:0]out[2]
);
generate
if(isNTT) begin
	logic [DATA_WIDTH:0] add;
	logic signed [DATA_WIDTH:0] sub;
	always_ff @(posedge clk) begin
		add <= in[0]+in[1];
		sub <= in[0]-in[1];

		// reduce width
		out[0] <= (add[DATA_WIDTH])? add-Q :add;
		out[1] <= (sub[DATA_WIDTH])? sub+Q :sub;
	end
end
else begin
	logic signed[DATA_WIDTH+1:0]tmp_data[2];
	logic signed[DATA_WIDTH:0]tmp_result[2];
	always_comb begin
		tmp_data[0] = in[1]+in[0];
		tmp_data[1] = in[1]-in[0];
		// if it's odd number, substract Q for later divide 2
		for(int i=0; i < 2; i++) begin
			if(tmp_data[i][0]) tmp_data[i][DATA_WIDTH+1:Q_M] -= Q_K;
		end
	end
	always_ff @(posedge clk) begin
		for(int i=0; i < 2; i++) begin
			// divide by 2
			tmp_result[i] <= tmp_data[i][DATA_WIDTH+1:1];
			// reduce to 0~Q
			out[i] <= (tmp_result[i][DATA_WIDTH])? tmp_result[i]+Q : tmp_result[i];
		end
	end
end
endgenerate
endmodule
