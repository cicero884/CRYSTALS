/*********
fifo
Separate controller since fifo in intt and ntt can use same controller.
You can also add more ntt and use same fifo controller.

controller for fifo for different size
	1. mul_stage	: X
	2. fifo1 		: 2^^n (ignore, combine with switch controller in ntt)
	3. fifo2 		: abs(2^^n-X)

Require -1 because ram will have a flipflop when output

TODO: clock gating with en.
*********/
/*
// designware
if (WIDTH < 256) begin 
	DW_fifo_s1_sf #(WIDTH,  SIZE,  1,  1,  0,  3)
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

module fifo_cts (
	input clk,
	fifo_ctrl_io fifo_ctrl_if
);
// mul_stage fifo
localparam int sizem = `MUL_STAGE_CNT-1;
fifo_ctrl #(.size(sizem)) fifom_ctrl(
	.addr(($clog2(sizem))'fifo_ctrl_if.fifom_addr),
.*);

// fifo2
// kyber 7 stage as example, HRS in intt=
// 0    1    2    3    4    5    6
// 2^^0 2^^1 2^^2 2^^3 2^^4 2^^5 (none)
// then calculate the abs with MUL_STAGE_CNT
genvar i;
generate
for (i=0; i<`NTT_STAGE_CNT-1 ; i++) begin
	localparam int size2 = abs((1<<(i)) - `MUL_STAGE_CNT) - 1;
	fifo_ctrl #(.size(size2)) fifo2_ctrl(
		.addr(($clog2(size2))'fifo_ctrl_if.fifo2_addr[i]),
	.*);
end
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
		if (addr < size-1) addr <= addr+1;
		else addr <= '0;
	end
end
endmodule: fifo_counter

// duel port ram, read write at same addr
// write after read
// used on fifo will delay one more clock for output flipflop
module dp_ram #(parameter WIDTH, parameter SIZE)(
	input clk,
	input [$clog2(SIZE)-1:0] addr,
	input [WIDTH-1:0] in,
	output logic[WIDTH-1:0] out
);
generate
case(SIZE)
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
		logic [WIDTH-1:0] ram[SIZE];
		always_ff @(posedge clk) begin
			ram[addr] <= in;
			out <= ram[addr];
		end
	end
endcase
endgenerate
endmodule: dp_ram
