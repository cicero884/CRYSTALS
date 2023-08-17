/************
modular multiplication
use modified MWR2MM

input: a,b
output: c = a*b*2^(DATA_WIDTH-1) %Q
************/
`define MUL_STAGE_CNT `DATA_WIDTH
// Q = Q_K*(2^Q_M)+1
// 3329 = 13*(2^8)+1
`define Q_M 8
`define Q_K 13

module mo_mul (
	input clk,
	input signed [`DATA_WIDTH] a, input signed [`DATA_WIDTH] b,
	output signed[`DATA_WIDTH] c
);

logic signed [`DATA_WIDTH-1:0] data[`MUL_STAGE_CNT+1], tmp_b[`MUL_STAGE_CNT], tmp_a[`MUL_STAGE_CNT];
logic signed [`DATA_WIDTH:0] tmp_data[`MUL_STAGE_CNT];
assign data[0] = 0;
assign tmp_a[0] = a;
assign tmp_b[0] = b;
assign c = data[`MUL_STAGE_CNT];

always_comb begin
	for (int i=0; i < `MUL_STAGE_CNT; i++) begin
		// sigend bit of b need to be negetive
		if(i == `MUL_STAGE_CNT-1) tmp_data[i] = (tmp_b[i][i])? data[i] - tmp_a[i]: data[i];
		else tmp_data[i] = (tmp_b[i][i])? data[i] + tmp_a[i]: data[i];

		if(tmp_data[i][0]) $signed(tmp_data[i][`MUL_STAGE_CNT:`Q_M]) -= `Q_K;
	end
end
always_ff @(posedge clk) begin
	for (int i=0; i < `MUL_STAGE_CNT-1; i++) begin
		data[i+1] <= tmp_data[i][`MUL_STAGE_CNT:1];
		tmp_a[i+1] <= tmp_a[i];
		tmp_b[i+1] <= tmp_b[i];
	end
	data[`MUL_STAGE_CNT] <= tmp_data[`MUL_STAGE_CNT-1];
end
endmodule
