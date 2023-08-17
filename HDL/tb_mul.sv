/************
testbench for check correct of mo_mul
************/

`define CYCLE 10.0

`define Q 3329
`define DATA_WIDTH 12
module tb_mul
logic clk = '0,rst;
always begin 
	#(`CYCLE/2) clk = ~clk;
end

logic signed [`DATA_WIDTH-1:0] in1='0,in2='0,out;
logic signed [`DATA_WIDTH-1:0] ans[`MUL_STAGE_CNT];
logic finish='0,out_en='0;
logic countdown;
always_ff @(posedge clk) begin
	{finish,in1,in2} <= {finish,in1,in2} + 1;
	ans[0] <= in1*in2%`Q;
	for(int i=1; i<`MUL_STAGE_CNT; i++) begin
		ans[i] <= ans[i-1];
	end

	if(in2>`MUL_STAGE_CNT) out_en<=1;
	if(out_en && ans[`MUL_STAGE_CNT-1] != (4096*out%`Q)) $display("%d * %d != %d\n",in1,in2,(4096*out%`Q));
	if(finish && in2 >= `MUL_STAGE_CNT) $finish
end
mo_mul(.a(in1),.b(in2),.c(out),.*);

endmodule
