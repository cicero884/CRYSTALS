/************
testbench for check correct of mo_mul
************/

`define CYCLE 10.0

module tb_mul();
logic clk = '0;
logic rst;
always begin 
	#(`CYCLE/2) clk = ~clk;
end
initial begin
	$fsdbDumpfile("mul.fsdb");
	//$fsdbDumpvars(0, mo_mul, "+mda");
	//$vcdplusmemon();
	//$fsdbDumpfile("mul.fsdb");
	//#5 $mpvars(0,tb_mul,"+mda");
	//#5 $dumpoff;
	//#5 $dumpall;
	//$dumpon;
end

//logic signed [`DATA_WIDTH-1:0] in2='0;
logic [`DATA_WIDTH-1:0] in1='0,in2='0;
logic signed [`DATA_WIDTH:0] out,min='0,max='0;
logic [`DATA_WIDTH-1:0] in1_delay[`MUL_STAGE_CNT+1],in2_delay[`MUL_STAGE_CNT+1];
int gold,real_out;
assign gold = (in1_delay[`MUL_STAGE_CNT]*in2_delay[`MUL_STAGE_CNT])%`Q;
assign real_out = (1<<`DATA_WIDTH)*out%`Q;
logic finish='0,out_en='0;
logic countdown;
assign in1_delay[0] = in1;
assign in2_delay[0] = in2;
always_ff @(posedge clk) begin
	if(in1 < `Q) begin
		{in1,in2} <= {in1,in2}+1;
		/*
		if(in2 < `Q) in2 <= in2+1;
		else begin
			in2 <= '0;
			in1 <= in1+1;
		end
		*/
	end
	else begin
		finish <= '1;
		in1 <= '0;
	end
	//{finish,in1,in2} <= {finish,in1,in2} + 1;
	for(int i=1; i<=`MUL_STAGE_CNT; i++) begin
		in1_delay[i] <= in1_delay[i-1];
		in2_delay[i] <= in2_delay[i-1];
	end

	// record min max
	if(out < min) min <= out;
	if(out > max) max <= out;
	if(!in1[3:0] && !in2) $display("current min = %d, max = %d",min,max);

	if($unsigned(in2)>`MUL_STAGE_CNT) out_en<=1;
	if(out_en) begin
		if(gold == real_out) begin end
		else $display("%d * %d = %d != %d (%d)\n",in1_delay[`MUL_STAGE_CNT],in2_delay[`MUL_STAGE_CNT],gold,real_out,out);
	end

	if(finish && in2 >= `MUL_STAGE_CNT+1) $finish;
end
mo_mul u_mul(.a(in1),.b(in2),.result(out),.*);

endmodule
