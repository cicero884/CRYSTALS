/************
modular multiplication
use modified MWR2MM
switch a and b in this design will change range of output
it's better to let a<Q

TODO: optmize final stage to FA & HA(MWR2MM_N)

input: a,b (RANGE:unsigned 0~Q)
output: result = a*b*2^^(WIDTH) %Q (RANGE: 0~Q or 0~2^^(WIDTH)-1, depend on a)
************/
`include "ntt_macro.svh"
import ntt_pkg::*;
typedef struct{
	logic [DATA_WIDTH-1:0]ss;
	logic [DATA_WIDTH-1:Q_M]snc;
	logic [Q_M-1:0] sc;
} mwr2mm_s;

module mo_mul #(parameter WIDTH=DATA_WIDTH)(
	input clk,
	input [DATA_WIDTH-1:0] a, input [WIDTH-1:0] b,
	output logic [DATA_WIDTH-1:0] result
);

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
`ifdef MULTYPE_KRED
initial begin
	if (WIDTH != DATA_WIDTH) $display("error: Current K_RED only support WIDTH=DATA_WIDTH");
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
`elsif MULTYPE_GMWR2MM
initial begin
	if (WIDTH != DATA_WIDTH) $display("error: Current K_RED only support WIDTH=DATA_WIDTH");
end
logic [DATA_WIDTH-1:0] aR[GMWR2MM_MULCUT],bR[GMWR2MM_MULCUT];
logic signed [DATA_WIDTH*2:0] c[GMWR2MM_L+1],cR[GMWR2MM_MULCUT];

genvar i;
always_ff @(posedge clk) begin
	cR[0] <= a*b;
	aR[0] <= a;
	bR[0] <= b;
end
for(i=1; i<GMWR2MM_MULCUT; i++) begin
	always_ff @(posedge clk) begin
		cR[i] <= cR[i-1];
		aR[i] <= aR[i-1];
		bR[i] <= bR[i-1];
	end
end

assign c[0] = cR[GMWR2MM_MULCUT-1];
generate
for(i=0; i<GMWR2MM_L; i++) begin
	always_ff @(posedge clk) begin
		c[i+1] <= $signed(c[i][2*DATA_WIDTH-i*Q_M:Q_M])-DATA_WIDTH'(c[i][Q_M-1:0])*Q_K;
	end
end
endgenerate
parameter Q_R = DATA_WIDTH-Q_M*GMWR2MM_L;
logic signed [DATA_WIDTH:0] last_c;
assign last_c = $signed(c[GMWR2MM_L][2*DATA_WIDTH-GMWR2MM_L*Q_M:Q_R]) - ((Q_R)? ((c[GMWR2MM_L][Q_R-1:0]*Q_K)<<(Q_M-Q_R)) : 0);
always_ff @(posedge clk) begin
	if (last_c<0) result <= last_c+Q;
	else result <= last_c;
end

`else //default : MULTYPE_MWR2MM
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
`endif

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
