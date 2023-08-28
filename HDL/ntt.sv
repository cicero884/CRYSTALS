/***************
duel pipelined ntt
***************/
`include "ntt.svh"

module ntt(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic [`DATA_WIDTH-1:0]out[2],
	output logic[`NTT_STAGE_CNT-2:0] rom_addr[`NTT_STAGE_CNT],
	input [`DATA_SIZE-1:0]rom_data[`NTT_STAGE_CNT]
);
logic signed [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT+1][2];
logic en[`NTT_STAGE_CNT+1];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[`NTT_STAGE_CNT];
assign out_en = en[`NTT_STAGE_CNT];

// counter for fifo which require delay `MUL_STAGE_CNT
// use same controller for those fifo
logic [$clog2(`MUL_STAGE_CNT)-1:0]fifo_addr;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		fifo_addr <= 0;
	end
	else begin
		if (fifo_addr == SIZE-1) fifo_addr <= 0;
		else fifo_addr <= fifo_addr+1;
	end
end

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT; i++) begin
	ntt_stage #(.STAGE(i)) staged_ntt (
		.in_en(en[i]), .in(data[i]),
		.out_en(en[i+1]), .out(data[i+1]),
		.rom_addr(rom_addr[i]), .rom_data(rom_data[i]),
	.*);
end
endgenerate
endmodule

// stage
module ntt_stage #(parameter STAGE = 0)(
	input clk,input rst,
	input in_en,input signed [`DATA_WIDTH-1:0]in[2],
	output out_en,output signed [`DATA_WIDTH-1:0]out[2]
	output [STAGE-1:0]rom_addr,input [`DATA_SIZE-1:0]rom_data,
	input [$clog2(`DATA_WIDTH)-1:0]fifo_addr
);
// mo_mul clk, add_sub clk
logic m_clk, as_clk;
logic m_en, as_en;

logic signed[`DATA_WIDTH:0] add_sub_in[2];

// twiddle factor rom
logic [`DATA_WIDTH-1:0] tw_rom[1<<(STAGE)];

genvar clk_max_cnt;
generate
if (STAGE == 0) begin
	// first stage
	// all data already ordered, so dont need reorder
	ctl_max_cnt = `DATA_WIDTH + `ADD_SUB_STAGE_CNT;

	fifo #(.WIDTH(`DATA_WIDTH), .SIZE(`DATA_WIDTH)) s0_fifo(
		.clk(m_clk), .in(in[0]), .out(add_sub_in[0][`DATA_WIDTH-1:0]), 
	.*);
	assign add_sub_in[0][`DATA_WIDTH] = '0;

	// mul with zeta
	mo_mul s0_mul(
		.clk(m_clk), 
		.a(rom_data), .b(in[1]),
		.result(add_sub_in[1]),
	);
	// add_sub
	add_sub #(.WIDTH(`DATA_WIDTH+1), .isNTT(1)) ntt(
		.in(add_sub_in),
		.out(out),

end
else begin
	// other stage except 1
	// counter for control switch & rom
	logic [`DATA_WIDTH-1:0] switch_data[2];
	logic [`NTT_STAGE_CNT-STAGE-1:0] switch_cnt;
	logic switch;
	logic [STAGE-1:0] rom_cnt;
	assign switch = rom_cnt[0];
	always_ff @(posedge clk) begin
		if (in_en) {rom_cnt,switch_cnt} <= {rom_cnt,switch_cnt} + 1;
		else {rom_cnt,switch_cnt} <= '0;
	end

	if ((1<<(`NTT_STAGE_CNT-STAGE-1)) > `MUL_STAGE_CNT) begin
		// reorder cycle larger than mul cycle
	end
	else begin
		// reorder cycle smaller than mul cycle
	end
end
endcase

// counter for out_en
logic [$clog2(clk_max_cnt+1)-1:0] out_cnt;
always_ff @(posedge clk,posedge rst) begin
	if(rst) begin
		out_en = '0;
	end
	if(in_en ^ out_en) begin
		if(out_cnt < ctl_max_cnt) out_cnt <= out_cnt + 1;
		else out_en = !out_en;
	end
	else out_cnt <= '0;
end
//TODO:more specific clock gating?
/*
`ifdef CLK_GATING
assign m_en  = (out_en&in_en)|((in_en^out_en)&(out_cnt>=0));
assign as_en = (out_en&in_en)|((in_en^out_en)&(out_cnt>=(ctl_max_cnt-`ADD_SUB_STAGE_CNT)));
`else
*/
assign m_clk  = (in_en|out_en)&clk;
assign as_clk = (en_en|out_en)&clk;
//`endif

endgenerate
endmodule
