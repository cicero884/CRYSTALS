/***************
duel pipelined ntt
***************/
`include "ntt.svh"

module ntt(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic [`DATA_WIDTH-1:0]out[2],

	output logic[`NTT_STAGE_CNT-2:0] rom_addr[`NTT_STAGE_CNT],
	input [`DATA_WIDTH-1:0]rom_data[`NTT_STAGE_CNT]
	input [$clog2(`DATA_WIDTH)-1:0]fifo1_addr
);
logic signed [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT+1][2];
logic en[`NTT_STAGE_CNT+1], gclk[`NTT_STAGE_CNT];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[`NTT_STAGE_CNT];
assign out_en = en[`NTT_STAGE_CNT];

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT; i++) begin
	assign gclk[i] = clk & (in_en[i]|out_en[i]);
	ntt_stage #(.STAGE(i)) staged_ntt (
		.clk(gclk[i]);
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
	output logic out_en,output signed [`DATA_WIDTH-1:0]out[2]
	output logic [STAGE-1:0]rom_addr,input [`DATA_WIDTH-1:0]rom_data,
	input [$clog2(`DATA_WIDTH)-1:0]fifo1_addr
);
// mo_mul clk, add_sub clk
logic m_clk, as_clk;
logic m_en, as_en;

logic signed[`DATA_WIDTH:0] add_sub_in[2];

// twiddle factor rom
logic [`DATA_WIDTH-1:0] tw_rom[1<<(STAGE)];

// component output
logic [`DATA_WIDTH-1:0] fifo1_out, 
logic [`DATA_WIDTH:0] mul_result;

genvar ctl_max_cnt;
generate
// first stage
// all data already ordered, so dont need reorder
if (STAGE == 0) begin
	ctl_max_cnt = `DATA_WIDTH + `ADD_SUB_STAGE_CNT;

	// delay with mo_mul
	sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT)) s0_fifo(
		.addr(fifo1_addr),
		.in(in[0]), .out(fifo1_out), 
	.*);

	// mul with zeta
	assign rom_addr = '0;
	mo_mul s0_mul(
		.a(rom_data), .b(in[1]),
		.result(mul_result),
	.*);
	// TODO: check unmatch size is ok
	// add_sub
	add_sub #(.isNTT(1)) ntt(
		.in('{fifo1_out,mul_result}),
		.out(out),
	.*);

end
// other stage except 1
else begin
	ctl_max_cnt = `ADD_SUB_STAGE_CNT;

	// helf reorder size
	localparam HRS = 1<<(`NTT_STAGE_CNT-STAGE-1);
	// counter for control switch & rom
	logic [`NTT_STAGE_CNT-STAGE-1:0] switch_cnt;
	logic switch;
	assign switch = rom_addr[0];
	always_ff @(posedge clk) begin
		if (in_en|out_en) {rom_addr, switch_cnt} <= {rom_addr, switch_cnt} + 1;
		else {rom_addr, switch_cnt} <= '0;
	end
	logic [`DATA_WIDTH-1:0] switch_data[2];
	always_comb begin
		if(switch) switch_data = '{in[1], fifo1_out};
		else switch_data = '{fifo1_out, in[1]};
	end
	// mul with zeta
	mo_mul s0_mul(
		.a(rom_data), .b(switch_data[1]),
		.result(mul_result),
	.*);

	// helf reorder size larger than mul cycle 
	if (HRS > `MUL_STAGE_CNT) begin
		ctl_max_cnt += HRS;

		// fifo2
		logic [`DATA_WIDTH-1:0] fifo2_out[2];
		fifo #(.WIDTH(`DATA_WIDTH*2), .SIZE(HRS-`MUL_STAGE_CNT)) fifo2(
			.in({in[0], mul_result}), .out({fifo2_out[0], fifo2_out[1]}), 
		.*);
		// fifo1
		sio_ram #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT)) fifo1(
			.addr(fifo1_addr),
			.in(fifo2_out[0]), .out(fifo1_out), 
		.*);
		// add_sub
		add_sub #(.isNTT(1)) ntt(
			.in('{switch_data[0], fifo2_out[1]}),
			.out(out),
		.*);
	end
	// helf reorder size smaller than mul cycle
	else begin
		ctl_max_cnt += `DATA_WIDTH;

		// fifo1
		logic [`DATA_WIDTH-1:0] fifo2_out;
		sio_ram #(.WIDTH(DATA_WIDTH), .SIZE(HRS)) fifo1(
			.addr(switch_cnt),
			.in(in[0]), .out(fifo1_out), 
		.*);
		// fifo2
		fifo #(.WIDTH(`DATA_WIDTH), .SIZE(`MUL_STAGE_CNT-HRS)) fifo2(
			.in(switch_data[0]), .out(fifo2_out), 
		.*);
		// add_sub
		add_sub #(.isNTT(1)) ntt(
			.in('{fifo2_out, mul_result}),
			.out(out),
		.*);
	end
end
endcase

// counter for out_en
// TODO: combine with switch controller?
logic [$clog2(ctl_max_cnt+1)-1:0] out_cnt;
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
`endif
*/
endgenerate
endmodule
