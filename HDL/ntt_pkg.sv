`ifndef NTT_PKG_SVH
`define NTT_PKG_SVH
`resetall
`timescale 1ns/100fs
`include "ntt_macro.svh"
package ntt_pkg;
`include "ntt_param.svh"
`include "rom.svh"
`include "ntt.svh"
`include "mo_mul.svh"
`include "add_sub.svh"
`include "fifo.svh"
endpackage

`endif
