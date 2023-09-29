/***************
duel pipelined intt
***************/

module intt(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic [`DATA_WIDTH-1:0]out[2],

	output logic[`NTT_STAGE_CNT-2:0] rom_addr[`NTT_STAGE_CNT],
	input [`DATA_WIDTH-1:0] rom_data[`NTT_STAGE_CNT],

	output logic fifo_en[`NTT_STAGE_CNT],
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr[`NTT_STAGE_CNT],
	input [`MAX_FIFO_ADDR_BITS-1:0] fifom_addr
);
logic [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT+1][2];
logic en[`NTT_STAGE_CNT+1], gclk[`NTT_STAGE_CNT];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[`NTT_STAGE_CNT];
assign out_en = en[`NTT_STAGE_CNT];

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT-1; i++) begin : stage_loop
	// TODO clock gating
	localparam HRS = 1<<(i);
	assign fifo_en[i] = en[i]|en[i+1];
	assign gclk[i] = clk;// & (en[i]|en[i+1]);
	if((1<<i) < `MUL_STAGE_CNT) begin
		intt_ss #(.STAGE(i)) staged_intt_s (
			.clk(gclk[i]),
			.in_en(en[i]), .in(data[i]),
			.out_en(en[i+1]), .out(data[i+1]),
			.rom_addr(rom_addr[`NTT_STAGE_CNT-i-1]), .rom_data(rom_data[`NTT_STAGE_CNT-i-1]),
			.fifo2_addr(fifo2_addr[i]),
		.*);
	end
	else begin
		intt_sl #(.STAGE(i)) staged_intt_l (
			.clk(gclk[i]),
			.in_en(en[i]), .in(data[i]),
			.out_en(en[i+1]), .out(data[i+1]),
			.rom_addr(rom_addr[`NTT_STAGE_CNT-i-1]), .rom_data(rom_data[`NTT_STAGE_CNT-i-1]),
			.fifo1_addr(fifom_addr), .fifo2_addr(fifo2_addr[i]),
		.*);
	end
end

assign fifo_en[`NTT_STAGE_CNT-1] = en[`NTT_STAGE_CNT-1]|en[`NTT_STAGE_CNT];
assign gclk[`NTT_STAGE_CNT-1] = clk;
intt_sf #(.STAGE(`NTT_STAGE_CNT-1)) staged_intt_f (
	.clk(gclk[`NTT_STAGE_CNT-1]),
	.in_en(en[`NTT_STAGE_CNT-1]), .in(data[`NTT_STAGE_CNT-1]),
	.out_en(en[`NTT_STAGE_CNT]), .out(data[`NTT_STAGE_CNT]),
	.rom_addr(rom_addr[0]), .rom_data(rom_data[0]),
	.fifo1_addr(fifom_addr),
.*);
endgenerate
endmodule

`define INTT_SWITCH_CNT_BITS STAGE-1:0
`define INTT_ROM_BITS `NTT_STAGE_CNT-2:STAGE
// helf reorder size smaller than mul cycle 
module intt_ss #(parameter STAGE)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output logic [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr
);
// component output
logic [`DATA_WIDTH-1:0] add_sub_out[2],mul_result;
logic [`DATA_WIDTH-1:0] switch_data[2],fifo2_out;
// add_sub
add_sub #(.isNTT(0)) as_i(
	.in(in),
	.out(add_sub_out),
.*);
logic in_en_delay[`ADD_SUB_STAGE_CNT];
assign in_en_delay[0] = in_en;
always_ff @(posedge clk) begin
	for(int i=1; i < `ADD_SUB_STAGE_CNT; i++) in_en_delay[i] <= in_en_delay[i-1];
end

// counter for control switch & rom
// prev clock for zeta read
logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
always_ff @(posedge clk) begin
	if (in_en_delay[`ADD_SUB_STAGE_CNT-1]|out_en) ctl_cnt <= ctl_cnt+1;
	else ctl_cnt <= '0;
end

assign rom_addr = ctl_cnt[`INTT_ROM_BITS];
logic switch_bit;
logic [STAGE:0] switch_cnt;
// mul with zeta
mo_mul si_mul(
	.a(rom_data), .b(add_sub_out[1]),
	.result(mul_result),
.*);

// helf reorder size
localparam HRS = 1<<(STAGE);
// fifo2
localparam fifo2_size = `MUL_STAGE_CNT-HRS-1;
dp_ram #(.WIDTH(`DATA_WIDTH), .DEPTH(fifo2_size)) fifo2(
	.addr($clog2(fifo2_size)'(fifo2_addr)),
	.in(add_sub_out[0]), .out(fifo2_out), 
.*);

// switch
assign switch_cnt = ctl_cnt[STAGE:0]-(`MUL_STAGE_CNT-HRS)-1;
assign switch_bit = switch_cnt[STAGE];
always_comb begin
	if (switch_bit) switch_data = {fifo2_out, mul_result};
	else switch_data = {mul_result, fifo2_out};
end
always_ff @(posedge clk) begin
	out[0] <= switch_data[0];
end

// fifo1
generate
if(STAGE == 0) begin
	logic tmp_addr;
	dp_ram #(.WIDTH(`DATA_WIDTH), .DEPTH(HRS)) fifo1(
		.addr(tmp_addr),
		.in(switch_data[1]), .out(out[1]), 
	.*);
end
else begin
	dp_ram #(.WIDTH(`DATA_WIDTH), .DEPTH(HRS)) fifo1(
		.addr(ctl_cnt[`INTT_SWITCH_CNT_BITS]),
		.in(switch_data[1]), .out(out[1]), 
	.*);
end
endgenerate

// counter for out_en
localparam out_max_cnt = `MUL_STAGE_CNT;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		out_en <= '0;
	end
	else begin
		if (in_en ^ out_en) begin
			if (ctl_cnt > out_max_cnt) out_en <= in_en;
		end
	end
end
endmodule: intt_ss

// helf reorder size larger than mul cycle 
module intt_sl #(parameter STAGE = `NTT_STAGE_CNT-1)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output logic [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo1_addr, input [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr
);
logic [`DATA_WIDTH-1:0] switch_data, fifo2_out, add_sub_out[2], mul_result;
// add_sub
add_sub #(.isNTT(0)) as_i(
	.in(in),
	.out(add_sub_out),
.*);
logic in_en_delay[`ADD_SUB_STAGE_CNT];
assign in_en_delay[0] = in_en;
always_ff @(posedge clk) begin
	for(int i=1; i < `ADD_SUB_STAGE_CNT; i++) in_en_delay[i] <= in_en_delay[i-1];
end

// counter for control switch & rom
// prev clock for zeta read
logic [`NTT_STAGE_CNT-2:0] ctl_cnt;
`define INTT_SWITCH_CNT_BITS STAGE-1:0
`define INTT_ROM_BITS `NTT_STAGE_CNT-2:STAGE
always_ff @(posedge clk) begin
	if (in_en_delay[`ADD_SUB_STAGE_CNT-1]|out_en) ctl_cnt <= ctl_cnt+1;
	else ctl_cnt <= '0;
end

assign rom_addr = ctl_cnt[`INTT_ROM_BITS];
logic switch_bit;
logic [STAGE:0] switch_cnt;
// mul with zeta
mo_mul si_mul(
	.a(rom_data), .b(add_sub_out[1]),
	.result(mul_result),
.*);

// helf reorder size
localparam HRS = 1<<(STAGE);
// fifo2
logic [`DATA_WIDTH-1:0] fifo1_out;
localparam fifo2_size = HRS-`MUL_STAGE_CNT-1;
dp_ram #(.WIDTH(`DATA_WIDTH*2), .DEPTH(fifo2_size)) fifo2(
	.addr($clog2(fifo2_size)'(fifo2_addr)),
	.in({mul_result,fifo1_out}), .out({fifo2_out, out[1]}), 
.*);
// switch
assign switch_cnt = ctl_cnt-1;
assign switch_bit = switch_cnt[STAGE];
always_ff @(posedge clk) begin
	if (switch_bit) {out[0],switch_data} <= {add_sub_out[0], fifo2_out};
	else {out[0],switch_data} <= {fifo2_out, add_sub_out[0]};
end
// fifo1
dp_ram #(.WIDTH(`DATA_WIDTH), .DEPTH(`MUL_STAGE_CNT-1)) fifo1(
	.addr(fifo1_addr),
	.in(switch_data), .out(fifo1_out), 
.*);
// counter for out_en
localparam out_max_cnt = HRS;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		out_en <= '0;
	end
	else begin
		if (ctl_cnt>out_max_cnt) begin
			out_en <= in_en;
		end
	end
end
endmodule: intt_sl


// final stage
module intt_sf #(parameter STAGE = `NTT_STAGE_CNT-1)(
	input clk,input rst,
	input in_en,input [`DATA_WIDTH-1:0] in[2],
	output logic out_en,output logic [`DATA_WIDTH-1:0] out[2],
	output logic [`NTT_STAGE_CNT-2:0] rom_addr,input [`DATA_WIDTH-1:0] rom_data,
	input [`MAX_FIFO_ADDR_BITS-1:0] fifo1_addr
);
logic [`DATA_WIDTH-1:0] add_sub_out[2],mul_result;
add_sub #(.isNTT(0)) as_0(
	.in(in),
	.out(add_sub_out),
.*);

// delay with mo_mul
dp_ram #(.WIDTH(`DATA_WIDTH), .DEPTH(`MUL_STAGE_CNT-1)) s0_fifo(
	.addr(fifo1_addr),
	.in(add_sub_out[0]), .out(out[0]), 
.*);

// mul with zeta
assign rom_addr = '0;
mo_mul s0_mul(
	.a(rom_data), .b(add_sub_out[1]),
	.result(out[1]),
.*);
// counter for out_en
localparam out_max_cnt = `MUL_STAGE_CNT+`ADD_SUB_STAGE_CNT-1;
logic [$clog2(out_max_cnt+1)-1:0] out_cnt;
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		out_en <= '0;
		out_cnt <= '0;
	end
	else begin
		if (in_en ^ out_en) begin
			if (out_cnt < out_max_cnt) out_cnt <= out_cnt + 1;
			else out_en <= in_en;
		end
		else out_cnt <= '0;
	end
end
endmodule: intt_sf

//TODO:more specific clock gating?
/*
`ifdef CLK_GATING
assign m_en  = (out_en&in_en)|((in_en^out_en)&(out_cnt>=0));
assign as_en = (out_en&in_en)|((in_en^out_en)&(out_cnt>=(out_max_cnt-`ADD_SUB_STAGE_CNT)));
`else
`endif
*/
