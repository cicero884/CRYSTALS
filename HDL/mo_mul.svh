/********
define MUL_STAGE_CNT for controller to control out_en and clk gating
change depend on your design of `MO_MUL
********/
`include "tool.svh"
`ifdef MO_MUL
// for KRED
// stage count of a*b
parameter KRED_MULCUT=1;
// ceil for integer DATA_WIDTH/Q_M
parameter KRED_L=(((DATA_WIDTH-1)/Q_M)+1);
//parameter MUL_STAGE_CNT=(KRED_L+KRED_MULCUT+1);

// for KLMM
parameter KLMM_MULCUT=1;
parameter KLMM_L=DATA_WIDTH/Q_M;

// mul stage count
parameter MUL_STAGE_CNT = (
	(`STRINGIFY(`MO_MUL)=="KRED")? (KRED_L+KRED_MULCUT+1):
	(`STRINGIFY(`MO_MUL)=="KLMM")? (KLMM_L+KLMM_MULCUT+1):
0);
`else // undefined
	`define MO_MUL undefined_mo_mul
`endif
