/********
define MUL_STAGE_CNT for controller to control out_en and clk gating
change depend on your design of mo_mul
********/
`ifndef MO_MUL_SVH
`define MO_MUL_SVH

/*
`ifdef MULTYPE_MWR2MM_O
	parameter MUL_STAGE_CNT=(DATA_WIDTH+1);
*/
`ifdef MULTYPE_KRED
	// stage count of a*b
	parameter KRED_MULCUT=1;
	// ceil for integer DATA_WIDTH/Q_M
	parameter KRED_L=(((DATA_WIDTH-1)/Q_M)+1);
	parameter MUL_STAGE_CNT=(KRED_L+KRED_MULCUT+1);
`elsif MULTYPE_GMWR2MM
	parameter GMWR2MM_MULCUT=1;
	parameter GMWR2MM_L=DATA_WIDTH/Q_M;
	parameter MUL_STAGE_CNT=(GMWR2MM_L+GMWR2MM_MULCUT+1);

`else // MULTYPE_MWR2MM
	parameter int MWR2MM_D=2;
	parameter MUL_STAGE_CNT=(((DATA_WIDTH-1)/MWR2MM_D)+1+2);
`endif
`endif
