/************
modular multiplication
input: a,b (RANGE:unsigned 0~Q)
output: result = a*b*? %Q (? depend on algorithm)
output range depend on algorithm
************/
`include "ntt_macro.svh"
import ntt_pkg::*;

/*****
KRED
output: a*b*(k^^l)
output range: -Q ~ MSB(Q)
*****/
module KRED #(parameter WIDTH=DATA_WIDTH)(
	input clk,
	input [DATA_WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic signed [DATA_WIDTH:0] result
);
initial begin
	assert (WIDTH == DATA_WIDTH) else $display("error: Current K_RED only support WIDTH=DATA_WIDTH");
end
logic [DATA_WIDTH-1:0] aR[KRED_MULCUT],bR[KRED_MULCUT];
logic signed [DATA_WIDTH*2:0] c[KRED_L+1],cR[KRED_MULCUT];

genvar i;
always_ff @(posedge clk) begin
	cR[0] <= a*b;
	aR[0] <= a;
	bR[0] <= b;
end
for(i=1; i<KRED_MULCUT; i++) begin
	always_ff @(posedge clk) begin
		cR[i] <= cR[i-1];
		aR[i] <= aR[i-1];
		bR[i] <= bR[i-1];
	end
end

assign c[0] = cR[KRED_MULCUT-1];
generate
for(i=0; i<KRED_L; i++) begin
	always_ff @(posedge clk) begin
		c[i+1] <= $signed(DATA_WIDTH'(c[i][Q_M-1:0])*Q_K)-$signed(c[i][2*DATA_WIDTH-i*Q_M:Q_M]);
	end
end
endgenerate
always_ff @(posedge clk) begin
	if (c[KRED_L]>Q) result <= c[KRED_L]-Q;
	else if (c[KRED_L]<0) result <= c[KRED_L]+Q;
	else result <= c[KRED_L];
end
endmodule

/*****
KLMM
output: a*b*2^^(-t)
output range: -Q ~ Q
*****/

module KLMM #(parameter WIDTH=DATA_WIDTH)(
	input clk,
	input [DATA_WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic signed[DATA_WIDTH:0] result
);
initial begin
	assert (WIDTH == DATA_WIDTH) else $error("Current KLMM only support WIDTH=DATA_WIDTH");
end
logic [DATA_WIDTH-1:0] aR[KLMM_MULCUT],bR[KLMM_MULCUT];
logic signed [DATA_WIDTH*2:0] c[KLMM_L+1],cR[KLMM_MULCUT];

genvar i;
always_ff @(posedge clk) begin
	cR[0] <= a*b;
	aR[0] <= a;
	bR[0] <= b;
end
for(i=1; i<KLMM_MULCUT; i++) begin
	always_ff @(posedge clk) begin
		cR[i] <= cR[i-1];
		aR[i] <= aR[i-1];
		bR[i] <= bR[i-1];
	end
end

assign c[0] = cR[KLMM_MULCUT-1];
generate
for(i=0; i<KLMM_L; i++) begin
	always_ff @(posedge clk) begin
		c[i+1] <= $signed(c[i][2*DATA_WIDTH-i*Q_M:Q_M])-DATA_WIDTH'(c[i][Q_M-1:0])*Q_K;
	end
end
endgenerate
parameter Q_R = DATA_WIDTH-Q_M*KLMM_L;
logic signed [DATA_WIDTH:0] last_c;
assign last_c = $signed(c[KLMM_L][2*DATA_WIDTH-KLMM_L*Q_M:Q_R]) - ((Q_R)? ((c[KLMM_L][Q_R-1:0]*Q_K)<<(Q_M-Q_R)) : 0);
always_ff @(posedge clk) begin
	if (last_c<0) result <= last_c+Q;
	else result <= last_c;
end
endmodule

/*****
XLMM
output: a*b*2^^(-t)
output range: -Q ~ Q
*****/

module XLMM #(parameter WIDTH=DATA_WIDTH)(
	input clk,
	input [DATA_WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic signed [DATA_WIDTH:0] result
);
initial begin
	assert (WIDTH == DATA_WIDTH) else $error("Current XLMM only support WIDTH=DATA_WIDTH");
	assert (XLMM_MULSIZE<=Q_M) else $error("XLMM_MULSIZE should smaller than Q_M");
end
logic [DATA_WIDTH-1:0] a_cache[XLMM_L+1], b_cache[XLMM_L+1];
logic signed[DATA_WIDTH:0] xlmm_reduced[XLMM_L+1];
logic [DATA_WIDTH-1:0] xlmm_prev[XLMM_L];
// KRED: (4)
// no retiming:4.2,107+100
// retiming: 5.38,94+100
// KLMM:(4)
// no retiming: 5.002 78+100
// retiming: 5.305 78+100
// XLMM 4 stage
//5.40 210
// retiming : 4.992 217
//XLMM 6 stage
// 5.53 200
//logic [DATA_WIDTH+XLMM_MULSIZE-1:0] xlmm_mul[XLMM_L];
logic signed[DATA_WIDTH+XLMM_MULSIZE:0] xlmm_mul[XLMM_L];
assign xlmm_reduced[0]='0;
assign a_cache[0]=a;
assign b_cache[0]=b;
always_comb begin
	for(int i=0;i<XLMM_L;i++) begin
		//xlmm_prev[i] = (xlmm_reduced[i]<0)? xlmm_reduced[i]+Q:xlmm_reduced[i]; 
		//xlmm_mul[i] = xlmm_prev[i]+a_cache[i]*b_cache[i][i*XLMM_MULSIZE +:XLMM_MULSIZE];
		xlmm_mul[i] = (DATA_WIDTH+XLMM_MULSIZE+1)'(xlmm_reduced[i])+a_cache[i]*b_cache[i][i*XLMM_MULSIZE +:XLMM_MULSIZE];
	end
end
always_ff @(posedge clk) begin
	for(int i=0;i<XLMM_L;i++) begin
		//xlmm_reduced[i+1] <= xlmm_mul[i][DATA_WIDTH+XLMM_MULSIZE-1:XLMM_MULSIZE]-((xlmm_mul[i][XLMM_MULSIZE-1:0]*Q_K)<<(Q_M-XLMM_MULSIZE));
		xlmm_reduced[i+1] <= xlmm_mul[i][DATA_WIDTH+XLMM_MULSIZE:XLMM_MULSIZE]-((xlmm_mul[i][XLMM_MULSIZE-1:0]*Q_K)<<(Q_M-XLMM_MULSIZE));
		a_cache[i+1] <= a_cache[i];
		b_cache[i+1] <= b_cache[i];
	end
end
parameter Q_R = DATA_WIDTH-XLMM_MULSIZE*XLMM_L;
generate
if(Q_R>0) begin
	initial begin
		$display("this XLMM_MULSIZE cannot divide DATA_WIDTH");
		$display("Q_R = %d",Q_R);
	end
	logic [DATA_WIDTH-1:0] xlmm_r_prev;
	logic [DATA_WIDTH+XLMM_MULSIZE-1:0] xlmm_r_mul;
	always_comb begin
		xlmm_r_prev = (xlmm_reduced[XLMM_L]<0)? xlmm_reduced[XLMM_L]+Q:xlmm_reduced[XLMM_L]; 
		xlmm_r_mul = xlmm_r_prev+a_cache[XLMM_L]*b_cache[XLMM_L][XLMM_L*XLMM_MULSIZE +:Q_R];
	end
	always_ff @(posedge clk) begin
		result <= xlmm_r_mul[DATA_WIDTH+Q_R-1:Q_R]-((xlmm_r_mul[Q_R-1:0]*Q_K)<<(Q_M-Q_R));
	end
end
else begin
	assign result = xlmm_reduced[XLMM_L]; 
end
endgenerate

endmodule
/*****
MWR2MM
output: a*b*2^^(-t)
output range: -Q ~ Q
*****/

/*
typedef struct{
	logic [DATA_WIDTH-1:0]ss;
	logic [DATA_WIDTH-1:Q_M]snc;
	logic [Q_M-1:0] sc;
} mwr2mm_s;
module MWR2MM #(parameter WIDTH=DATA_WIDTH)(
	input clk,
	input [DATA_WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic [DATA_WIDTH-1:0] result
);
*/

/*old MWR2MM
logic [WIDTH-1:0] tmp_b[WIDTH+1];
logic [DATA_WIDTH-1:0] tmp_a[WIDTH+1];
assign tmp_a[0] = a;
assign tmp_b[0] = b;

logic signed [DATA_WIDTH:0] data[WIDTH+1];
logic signed [DATA_WIDTH+1:0] tmp_data[WIDTH];
assign data[0] = '0;

always_comb begin
	for (int i=0; i < WIDTH; i++) begin
		tmp_data[i] = data[i];
		if (tmp_b[i][i]) tmp_data[i] += tmp_a[i];
		if (tmp_data[i][0]) tmp_data[i][WIDTH+1:Q_M] -= Q_K;
	end
end
always_ff @(posedge clk) begin
	for (int i=0; i < WIDTH; i++) begin
		data[i+1] <= tmp_data[i]>>1;
		tmp_a[i+1] <= tmp_a[i];
		tmp_b[i+1] <= tmp_b[i];
	end
	result <= (data[WIDTH][DATA_WIDTH])? DATA_WIDTH'(data[WIDTH]+Q) : DATA_WIDTH'(data[WIDTH]);
end
*/
/*
logic [WIDTH-1:0] tmp_b[WIDTH+1];
logic [DATA_WIDTH-1:0] tmp_a[WIDTH+1];
assign tmp_a[0] = a;
assign tmp_b[0] = b;

mwr2mm_s data[WIDTH+1],tmp_data[WIDTH];
assign data[0] = '{default:'0};
generate
for (genvar i=0; i<WIDTH; i++) begin
	logic [DATA_WIDTH-1:0] stage_a;
	assign stage_a = tmp_b[i][i]? tmp_a[i]:'0;
	MWR2MM_stage mwr2mm_s(.a(stage_a), .in(data[i]), .out(tmp_data[i]));
	if (((i+1)%MWR2MM_D) && (i!=(WIDTH-1))) begin
		always_comb begin
			data[i+1] = tmp_data[i];
			tmp_a[i+1] = tmp_a[i];
			tmp_b[i+1] = tmp_b[i];
		end
	end else begin
		always_ff @(posedge clk) begin
			data[i+1] <= tmp_data[i];
			tmp_a[i+1] <= tmp_a[i];
			tmp_b[i+1] <= tmp_b[i];
		end
	end
end
endgenerate
logic [DATA_WIDTH:0] tmp_result;
always_ff @(posedge clk) begin
	tmp_result <= data[WIDTH].ss+data[WIDTH].sc-(data[WIDTH].snc<<Q_M);
	result <= (tmp_result[DATA_WIDTH])? DATA_WIDTH'(tmp_result+Q):DATA_WIDTH'(tmp_result);
end
endmodule

module MWR2MM_stage(
	input [DATA_WIDTH-1:0] a, input mwr2mm_s in,
	output mwr2mm_s out
);
logic [DATA_WIDTH-1:0] minus_q;
logic [DATA_WIDTH-1:0] out_ss;
logic [DATA_WIDTH:Q_M] t;
logic [DATA_WIDTH-1:Q_M] nu;
assign t[Q_M] = '0;
assign minus_q = (out_ss[0])? unsigned'(Q):0;
assign out.ss = {t[DATA_WIDTH],out_ss[DATA_WIDTH-1:1]};
always_comb begin
	for(int i=0; i<DATA_WIDTH; i++) begin
		case(i) inside
			[0:Q_M-1]: {out.sc[i],out_ss[i]} = in.ss[i]+in.sc[i]+a[i];
			[Q_M:DATA_WIDTH-1]: begin
				{t[i+1],nu[i]} = in.snc[i]-in.ss[i]-a[i];
				{out.snc[i],out_ss[i]} = t[i]-minus_q[i]-nu[i];
			end
		endcase
	end
end
endmodule
*/

module undefined_mo_mul #(parameter WIDTH=DATA_WIDTH)(
	input clk,
	input [DATA_WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic [DATA_WIDTH-1:0] result
);
initial begin
	$display("Undefined MUL_TYPE");
end
endmodule
