/*********
fifo
Separate controller since fifo in intt and ntt can use same controller.
You can also add more ntt and use same fifo controller.

controller for fifo for different size
	1. mul_stage	: X
	2. fifo1 		: 2^^n (ignore, combine with switch controller in ntt)
	3. fifo2 		: abs(2^^n-X)

Require -1 because ram will have a flipflop when output

TODO: clock gating with fifo_en.
*********/
/*
// designware
if (WIDTH < 256) begin 
	DW_fifo_s1_sf #(WIDTH,  DEPTH,  1,  1,  0,  3)
	U1 (.clk(inst_clk),   .rst_n(!rst),   .push_req_n(inst_push_req_n),
		.pop_req_n(inst_pop_req_n),   .diag_n(inst_diag_n),
		.data_in(inst_data_in),   .empty(empty_inst),
		.almost_empty(almost_empty_inst),   .half_full(half_full_inst),
		.almost_full(almost_full_inst),   .full(full_inst),
	.error(error_inst),   .data_out(data_out_inst) );
end
*/
//`define ABS(a,b) ((a>b)? a-b:b-a)
//`define MAX(a,b) ()
import ntt_pkg::*;
module fifo_cts (
	input clk, input rst,
	//fifo_ctrl_io fifo_ctrl_if
	input fifo_en[NTT_STAGE_CNT],
	output [`MAX_FIFO_ADDR_BITS-1:0] fifo2_addr[NTT_STAGE_CNT],
	output [`MAX_FIFO_ADDR_BITS-1:0] fifom_addr
);
// mul_stage fifo
localparam int sizem = MUL_STAGE_CNT-1;
logic [$clog2(sizem)-1:0] fifom_tmp_addr;
fifo_counter #(.size(sizem)) fifom_ctrl(
	.addr(fifom_tmp_addr),
.*);
if(sizem < 2) assign fifom_addr = '0;
else assign fifom_addr = `MAX_FIFO_ADDR_BITS'(fifom_tmp_addr);

// fifo2
// kyber 7 stage as example, HRS in intt=
// 0    1    2    3    4    5    6
// 2^^0 2^^1 2^^2 2^^3 2^^4 2^^5 (none)
// then calculate the abs with MUL_STAGE_CNT
genvar i;
generate
for (i=0; i<NTT_STAGE_CNT-1 ; i++) begin
	localparam int size2 = abs((1<<(i)), MUL_STAGE_CNT) - 1;
	logic [$clog2(size2)-1:0] fifo2_tmp_addr;
	fifo_counter #(.size(size2)) fifo2_ctrl(
		.addr(fifo2_tmp_addr),
	.*);
	if(size2 < 2) assign fifo2_addr[i] = '0;
	else assign fifo2_addr[i] = `MAX_FIFO_ADDR_BITS'(fifo2_tmp_addr);
end
endgenerate
endmodule: fifo_cts

module fifo_counter #(parameter size)(
	input clk,input rst,
	output logic [$clog2(size)-1:0] addr
);
always_ff @(posedge clk, posedge rst) begin
	if (rst) begin
		addr <= '0;
	end
	else begin
		if (signed'({1'b0,addr}) < size-1) addr <= addr+1;
		else addr <= '0;
	end
end
endmodule: fifo_counter

// duel port ram, read write at same addr
// write after read
// used on fifo will delay one more clock for output flipflop
module dp_ram #(parameter WIDTH, parameter DEPTH)(
	input clk,
	input [`MAX_FIFO_ADDR_BITS-1:0] addr,
	input [WIDTH-1:0] in,
	output logic[WIDTH-1:0] out
);
generate
case(DEPTH)
	-1: assign out = in;
	0 : always_ff @(posedge clk) out <= in;
	1 : begin
		logic [WIDTH-1:0] tmp;
		always_ff @(posedge clk) begin
			tmp <= in;
			out <= tmp;
		end
	end
	default: begin
		logic [$clog2(DEPTH)-1:0] in_range_addr;
		assign in_range_addr = addr[$clog2(DEPTH)-1:0];
		logic [WIDTH-1:0] ram[(DEPTH>0)? DEPTH:1];
		always_ff @(posedge clk) begin
			ram[in_range_addr] <= in;
			out <= ram[in_range_addr];
		end
	end
endcase
endgenerate
endmodule: dp_ram
