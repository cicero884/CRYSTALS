/********
define MUL_STAGE_CNT for controller to control out_en and clk gating
change depend on your design of `MO_MUL
********/
`include "tool.svh"
`ifdef MO_MUL

// --- KRED
// stage count of a*b
parameter KRED_MULCUT=1;
// ceil for integer DATA_WIDTH/Q_M
parameter KRED_L=(((DATA_WIDTH-1)/Q_M)+1);
//parameter MUL_STAGE_CNT=(KRED_L+KRED_MULCUT+1);

// --- KLMM
// stage count of a*b
parameter KLMM_MULCUT=1;
// floor for integer DATA_WIDTH/Q_M
parameter KLMM_L=DATA_WIDTH/Q_M;

// --- XLMM
// total stage count(depend on your design, it should smaller than Q_M)
parameter XLMM_MULSIZE=3;
// floor for integer DATA_WIDTH/MULSIZE
parameter XLMM_L=DATA_WIDTH/XLMM_MULSIZE;

// mul stage count
parameter MUL_STAGE_CNT = (
	(`STRINGIFY(`MO_MUL)=="KRED")? (KRED_L+KRED_MULCUT+1):
	(`STRINGIFY(`MO_MUL)=="KLMM")? (KLMM_L+KLMM_MULCUT+1):
	(`STRINGIFY(`MO_MUL)=="XLMM")? ((XLMM_MULSIZE*XLMM_L == DATA_WIDTH)? XLMM_L:XLMM_L+1):
0);
`else // undefined
	`define MO_MUL undefined_mo_mul
`endif
