// need to edit mo_mul if Q is modified
`define Q 3329
`define DATA_WIDTH $clog2(`Q)
// DATA_SIZE is real NTT process size
// because kyber separate odd and even numbers
// real size is 256/2 = 128
`define DATA_SIZE 128
`define NTT_STAGE_CNT $clog2(`DATA_SIZE-1)
