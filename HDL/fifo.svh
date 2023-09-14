`define ABS(a,b) ((a>b)? a-b:b-a)
`define MAX(a,b) ((a>b)? a:b)

`define MAX_HRS (1<<(`NTT_STAGE_CNT-2))
`define MUL_STAGE_BITS $clog2(`MUL_STAGE_CNT-1)
`define MAX_FIFO2_ADDR_BITS $clog2(`MAX(`MAX_HRS,`MUL_STAGE_CNT))
