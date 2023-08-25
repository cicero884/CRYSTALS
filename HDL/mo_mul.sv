/************
modular multiplication
use modified MWR2MM

input: a,b (RANGE:unsigned 0~Q)
output: result = a*b*2^(MUL_STAGE_CNT-1) %Q (RANGE: signed -Q~Q)
************/
`include "mo_mul.svh"

// Q = Q_K*(2^Q_M)+1
// 3329 = 13*(2^8)+1
`define Q_M 8
`define Q_K 13
module mo_mul (
	input clk,
	input [`MUL_STAGE_CNT-1:0] a, input [`MUL_STAGE_CNT-1:0] b,
	output logic signed[`MUL_STAGE_CNT:0] result
);

logic [`MUL_STAGE_CNT-1:0] tmp_b[`MUL_STAGE_CNT+1],tmp_a[`MUL_STAGE_CNT+1];
logic signed [`MUL_STAGE_CNT:0] data[`MUL_STAGE_CNT+1];
logic signed [`MUL_STAGE_CNT+1:0] tmp_data[`MUL_STAGE_CNT];
assign data[0] = '0;
assign tmp_a[0] = a;
assign tmp_b[0] = b;
assign result = data[`MUL_STAGE_CNT];

always_comb begin
	for (int i=0; i < `MUL_STAGE_CNT; i++) begin
		/* // sigend bit of b need to be negetive
		if(i == `MUL_STAGE_CNT-1) begin
			tmp_data[i] = (tmp_b[i][i])? data[i] - tmp_a[i]: data[i];
		end
		else begin */
		//tmp_data[i] = $signed((tmp_b[i][i])? data[i] + tmp_a[i]: data[i]);
		tmp_data[i] = data[i];
		if(tmp_b[i][i])? tmp_data+=tmp_a[i];
		if(tmp_data[i][0]) tmp_data[i][`MUL_STAGE_CNT+2:`Q_M] = tmp_data[i][`MUL_STAGE_CNT+2:`Q_M]-`Q_K;
		//end
	end
end
always_ff @(posedge clk) begin
	for (int i=0; i < `MUL_STAGE_CNT; i++) begin
		data[i+1] <= tmp_data[i]>>1;
		tmp_a[i+1] <= tmp_a[i];
		tmp_b[i+1] <= tmp_b[i];
	end
end
endmodule
