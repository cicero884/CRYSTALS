/******
interface that need to use same fifo controller
change NTT_CNT to number of ntt
******/
`define NTT_CNT 1
`define INTT_CNT 1

interface fifo_ctrl_io;
localparam int max_hrs = 1<<(`NTT_STAGE_CNT-2);
localparam mul_stage_bits = $clog2(`MUL_STAGE_CNT-1);
localparam max_fifo2_addr_bits = $clog2(max(max_hrs,`MUL_STAGE_CNT));

begin: controller
	logic en[`NTT_STAGE_CNT];
	logic [mul_stage_bits-1:0] fifom_addr;
	logic [max_fifo2_addr_bits-1:0] fifo2_addr[`NTT_STAGE_CNT];
	modport counter(
		input en,
		output fifom_addr, fifo2_addr
	);
end

// TODO use method
//function logic [max_fifo2_addr_bits-1:0] req_fifo2(logic en);
//
//endfunction

genvar i;
generate
for (i=0; i<`NTT_CNT; i++) begin: ntts
	logic en[`NTT_STAGE_CNT];
	logic [max_fifo2_addr_bits-1:0] fifo2_addr[`NTT_STAGE_CNT];
	assign fifo2_addr = {<<max_fifo2_addr_bits{controller.fifo2_addr}};
	modport client(
		output en,
		input fifom_addr, fifo2_addr
	);
end
for (i=0; i<`INTT_CNT; i++) begin: intts
	logic en[`NTT_STAGE_CNT];
	logic [max_fifo2_addr_bits-1:0] fifo2_addr[`NTT_STAGE_CNT];
	assign fifo2_addr = controller.fifo2_addr;
	modport client(
		output en,
		input fifom_addr, fifo2_addr
	);
end
for (i=0; i<`NTT_STAGE_CNT) begin
	//always_comb begin
	//	controller.en[i] = '0;
	//	for(int j=0; j<`NTT_CNT; j++) controller.en|=ntts[j].en[`NTT_STAGE_CNT-i-1];
	//	for(int j=0; j<`INTT_CNT; j++) controller.en|=ntts[j].en[i];
	//end
	assign controller.en[i] = (
		(|ntts[0:`NTT_CNT-1].en[`NTT_STAGE_CNT-i-1])|
		(|intts[0:`INTT_CNT-1].en[i])
	);
end
endgenerate
endinterface
