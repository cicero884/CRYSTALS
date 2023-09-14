`ifndef NTT_SVH
`define NTT_SVH
//`define Q 343576577
`define Q 3329
// Q = Q_K*(2^Q_M)+1
// kyber: 3329 = 13*(2^8)+1
`define Q_M ($clog2((`Q-2)^`Q)-1)
`define Q_K ((`Q-1)/(1<<`Q_M))
`define DATA_WIDTH $clog2(`Q)

// DATA_SIZE is real NTT process size
// because kyber separate odd and even numbers
// real size for kyber is 256/2 = 128 = 2^7
// `define NTT_STAGE_CNT 9
`define NTT_STAGE_CNT 7

`endif
