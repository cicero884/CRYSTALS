/***************
duel pipelined ntt
***************/

module ntt(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic [`DATA_WIDTH-1:0]out[2]
);
logic signed [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT+1][2];
logic en[`NTT_STAGE_CNT+1];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[`NTT_STAGE_CNT];
assign out_en = en[`NTT_STAGE_CNT];

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT; i++) begin
	ntt_stage #(.STAGE(i)) staged_ntt (
		.in_en(en[i]), .in(data[i]),
		.out_en(en[i+1]), .out(data[i+1]),
	.*);
end
endgenerate
endmodule

// stage
module ntt_stage #(parameter STAGE = 0)(
	input clk,input rst,
	input in_en,input signed [`DATA_WIDTH-1:0]in[2],
	output out_en,output signed [`DATA_WIDTH-1:0]out[2]
);
// mo_mul clk, add_sub clk
logic m_clk, as_clk;
logic m_en, as_en;
logic stable;

logic [`DATA_WIDTH-1:0] add_sub_in[2];

genvar clk_max_cnt;
generate
if (STAGE == 0) begin
	// first stage
	// all data already ordered, so dont need reorder
	ctl_max_cnt = `MUL_STAGE_CNT + `ADD_SUB_STAGE_CNT;

	fifo #(`DATA_WIDTH, `MUL_STAGE_CNT) s0_fifo(
		.clk(m_clk) ,.in(data[0][0]), .out(add_sub_in[0]), 
	.*);

	// mul with zeta

	mo_mul s0_mul(
		.clk(m_clk) ,.a()
end
else begin
	logic [`DATA_WIDTH-1:0] switch_data[2];
	logic [`NTT_STAGE_CNT-STAGE-1:0] switch_cnt;
	logic switch;
	always_ff @(posedge clk) begin
		if (in_en) {switch,switch_cnt} <= {switch,switch_cnt} + 1;
		else {switch,switch_cnt} <= '0;
	end

	if (`DATA_SIZE/(2<<STAGE))
end
endcase

`ifdef CLK_GATING
// clock gating counter
logic [$clog2(clk_max_cnt+1)-1:0] clk_cnt;
always_ff @(posedge clk) begin
	if(in_en ^ stable) begin
		if(gclk_cnt < ctl_max_cnt) gclk_cnt <= gclk_cnt + 1;
	end
	else gclk_cnt <= '0;
end
`else
assign m_clk = clk;
assign as_clk = clk;

`endif
endgenerate
endmodule
