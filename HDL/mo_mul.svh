/********
define MUL_STAGE_CNT for controller to control out_en and clk gating
change depend on your design of mo_mul
********/
`include "ntt_param.svh"
`ifndef MO_MUL_SVH
`define MO_MUL_SVH

`ifdef MULTYPE_MWR2MM_O
`define MUL_STAGE_CNT (`DATA_WIDTH+1)

`elsif MULTYPE_KRED
`define KRED_L int'($ceil(real'(`DATA_WIDTH)/`Q_M))
`define MUL_STAGE_CNT (`KRED_L+2)

`else // MULTYPE_MWR2MM_N
`define MUL_STAGE_CNT (`DATA_WIDTH+2)
`endif
`endif
