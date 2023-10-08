/********
define MUL_STAGE_CNT for controller to control out_en and clk gating
change depend on your design of mo_mul
********/
`ifndef MO_MUL_SVH
`define MO_MUL_SVH

`ifdef MULTYPE_MWR2MM_O
	parameter MUL_STAGE_CNT=(DATA_WIDTH+1);

`elsif MULTYPE_KRED
	// ceil for integer DATA_WIDTH/Q_M
	parameter KRED_L=(((DATA_WIDTH-1)/Q_M)+1);
	parameter MUL_STAGE_CNT=(KRED_L+2);

`else // MULTYPE_MWR2MM_N
	parameter MUL_STAGE_CNT=(DATA_WIDTH+2);
`endif
`endif
