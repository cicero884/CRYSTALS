/************
testbench for check correct of `MO_MUL
************/
`include "tool.svh"
import ntt_pkg::*;
`define CYCLE 10.0

module tb_mul();
logic clk = '0;
logic rst;
always begin 
	#(`CYCLE/2) clk = ~clk;
end
initial begin
	//$fsdbDumpfile("mul.fsdb");
	//$fsdbDumpvars(0, `MO_MUL, "+mda");
	//$vcdplusmemon();
	//$fsdbDumpfile("mul.fsdb");
	//#5 $mpvars(0,tb_mul,"+mda");
	//#5 $dumpoff;
	//#5 $dumpall;
	//$dumpon;
end

//logic signed [DATA_WIDTH-1:0] in2='0;
logic [DATA_WIDTH-1:0] in1=1,in2=1;
logic signed [DATA_WIDTH:0] out,min=Q,max='0;
logic [DATA_WIDTH-1:0] in1_delay[MUL_STAGE_CNT+1],in2_delay[MUL_STAGE_CNT+1];
int gold,mod_out,real_out;
`ifdef MO_MUL
if(`STRINGIFY(`MO_MUL) == "KRED") begin
	assign gold = (in1_delay[MUL_STAGE_CNT]*in2_delay[MUL_STAGE_CNT]*(Q_K**KRED_L))%Q;
	assign mod_out = out%Q;
	assign real_out = (mod_out<0)? mod_out+Q:mod_out;
end
else begin
	assign gold = (in1_delay[MUL_STAGE_CNT]*in2_delay[MUL_STAGE_CNT])%Q;
	assign mod_out = ($signed(1<<DATA_WIDTH)*out)%Q;
	assign real_out = (mod_out<0)? mod_out+Q:mod_out;
end
initial begin
	$display("MUL_TYPE : %s",`STRINGIFY(`MO_MUL));
	$display("MUL_STAGE_CNT = %d",MUL_STAGE_CNT);
end
`else
initial begin
	$display("`MO_MUL is not defined!!");
end
`endif
logic finish='0,out_en='0;
logic countdown;
int en_cnt=0;
assign in1_delay[0] = in1;
assign in2_delay[0] = in2;
always_ff @(posedge clk) begin
	if (in1 < Q) begin
		{in1,in2} <= {in1,in2}+1;
	end
	else begin
		finish <= '1;
		in1 <= '0;
	end
	//{finish,in1,in2} <= {finish,in1,in2} + 1;
	for(int i=1; i<=MUL_STAGE_CNT; i++) begin
		in1_delay[i] <= in1_delay[i-1];
		in2_delay[i] <= in2_delay[i-1];
	end

	// record min max
	if (!in1[3:0] && !in2) $display("current min = %d, max = %d",min,max);
	if (out<min) min <= out;
	if (out>max) max <= out;
	if (en_cnt>MUL_STAGE_CNT) out_en<=1;
	else en_cnt <= en_cnt+1;
	if (out_en) begin
		assert (gold == real_out) else begin
			$display("%d * %d = %d != %d (%d)\n",in1_delay[MUL_STAGE_CNT],in2_delay[MUL_STAGE_CNT],gold,real_out,out);
			$finish;
		end
	end

	if (finish && in2 >= MUL_STAGE_CNT+1) $finish;
end
`MO_MUL u_mul(.a(in1),.b(in2),.result(out),.*);

endmodule
