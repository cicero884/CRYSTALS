/********
define MUL_STAGE_CNT for controller to control out_en and clk gating
change depend on your design of mo_mul
********/
`ifndef MO_MUL_SVH
`define MO_MUL_SVH
`define MUL_STAGE_CNT (`DATA_WIDTH+2)
`endif
