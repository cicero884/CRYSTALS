# DHL(system verilog)
TODO:implement keygen & testbench  
probally the seed is given  
no random for test  
TRPG later...  

Only NTT currently  

## Files  
Before running this project, you should change Q and N and run `make gen_files` to write basic parameters into svh.


module hiercracy
<pre>
tb_mul
└────mo_mul

tb_ntt
└────top_ntt
     ├────fifo_cts
     │    └────fifo_counter
     ├────gen_tf_rom
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
### mo\_mul.sv
modular multiplication  
If you change this design and have different number of pipeline stage  
Remember to change mo\_mul.svh  
if you change the way of multiplication, remember change tb\_mul to test correctly and change gen\_tf\_rom.c to make sure you generate correct twiddle factor rom  
### ntt.sv
<pre>
ntt
	ntt_s0: ntt stage when first stage, no reorder inside
	ntt_ss: ntt stage when reorder delay smaller than mul stage count
	ntt_sl: ntt stage when reorder delay larger than mul stage count
</pre>
### tb\_ntt:
testbench for ntt and intt
pwm unfinish .w.

### tb\_mul
testbench for mo_mul

### tb\_ntt
testbench for ntt  
if your test data is not kyber, remember to modify your order.  
### top\_ntt.sv:  
An example of using this ntt.  
For NTT to work, Require fifo\_cts & duel\_rom connect to ntt or intt,  
Only need one fifo\_cts. 
### tf\_rom.sv:
duel port rom store tf values.
### gen_tf_rom.c
calculate twiddle factor to required data files for rom to read  
input : argv1=log2(poly size), argv2=prine, argv3=root_of_unit(optional)  
ex1: `gen_tf_rom 7 3329`  
ex2: `gen_tf_rom 7 3329 17`  
(for kyber is 7,3329,17 since the odd and even is separate)   
(https://www.ietf.org/archive/id/draft-cfrg-schwabe-kyber-01.html)  
output : multiple .dat files for rom to read  

### rom.svh,ntt_param.svh,*.data
generated files, use make gen_files to generate.
