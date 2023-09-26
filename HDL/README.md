# DHL(system verilog)
TODO:implement keygen & testbench  
probally the seed is given  
no random for test  
TRPG later...  

Only NTT currently  

## Files  

module hiercracy
<pre>
tb_mul
└────mo_mul

tb_ntt
└────top_ntt
     ├────fifo_cts
	 │    └────fifo_counter
	 ├────zeta_rom
	 │    └────duel_rom
	 ├────ntt
	 │    ├────ntt_s0
     │    │    ├mo_mul
     │    │    ├dp_ram
     │    │    └add_sub
     │    ├────ntt_sl
     │    │    ├mo_mul
     │    │    ├dp_ram
     │    │    └add_sub
     │    └────ntt_ss
     │         ├mo_mul
     │         ├dp_ram
     │         └add_sub
	 ├────intt
	 │    ├────intt_ss
     │    │    ├mo_mul
     │    │    ├dp_ram
     │    │    └add_sub
     │    ├────ntt_sl
     │    │    ├mo_mul
     │    │    ├dp_ram
     │    │    └add_sub
     │    └────ntt_sf
     │         ├mo_mul
     │         ├dp_ram
     │         └add_sub
     └────pwm(unfinish)
</pre>
### add_sub.sv
add and substract with modular  
If you change this design and have different number of pipeline stage
Remember to change add_sub.svh

<pre>
ntt(signed):  
	input: (0 ~ (2^^n)-1, 0 ~ Q)  
	add_sub: (0 ~ Q+(2^^n-1), -Q ~ (2^^n-1))  
	after mod: 0 ~ (2^^n-1)  
intt(unsigned):  
	input: (0 ~ Q, 0 ~ Q)  
	add_sub(with /2): (-Q/2 ~ Q, -Q ~ Q/2)  
	after mod: 0~Q  

input: in[0],in[1]  
output:  
	ntt:  
		out[0] = (in[0]+in[1]) %Q  
		out[1] = (in[0]-in[1]) %Q  
	intt:  
		out[0] = (in[0]+in[1])/2 %Q  
		out[1] = (in[0]-in[1])/2 %Q  
</pre>

### fifo_ctrl_io.sv
fifo controller interface.

### fifo.sv
for fifo related, fifo_cts & dp_ram inside

### intt.sv
<pre>
invert ntt
	intt_ss: intt stage when reorder delay smaller than mul stage count
	intt_sl: intt stage when reorder delay larger than mul stage count
	intt_sf: intt stage when final stage, no reorder inside
</pre>
### mo_mul.sv
modular multiplication  
If you change this design and have different number of pipeline stage  
Remember to change mo\_mul.svh  
if you change the way of multiplication, remember change tb\_mul to test correctly and change zeta2rom.c to make sure you generate correct zeta2rom.c  
### ntt.sv
<pre>
ntt
	ntt_s0: ntt stage when first stage, no reorder inside
	ntt_ss: ntt stage when reorder delay smaller than mul stage count
	ntt_sl: ntt stage when reorder delay larger than mul stage count
</pre>
### tb_ntt:
testbench for ntt and intt
pwm unfinish .w.

### tb_mul
testbench for mo_mul

### tb_ntt
testbench for ntt  
if your test data is not kyber, remember to modify your order.  
### top_ntt.sv:  
An example of using this ntt.  
For NTT to work, Require fifo\_cts & duel\_rom connect to ntt or intt,  
Only need one fifo\_cts. 
### zeta_rom.sv:
duel port rom store zeta values.
### zeta2rom.c
convert zetas to required data files for rom to read  
input : argv1=log2(poly size), argv2=prine, argv3=root_of_unit(optional)  
ex1: `zeta2rom 8 3329`  
ex2: `zeta2rom 8 3329 17`  
(for kyber is 8,3329,17)   
(https://www.ietf.org/archive/id/draft-cfrg-schwabe-kyber-01.html)  
output : multiple .dat files for rom to read  

