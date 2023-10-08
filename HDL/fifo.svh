function automatic int abs (input int a,input int b);
	abs = ((a>b)? a-b:b-a);
endfunction
function automatic int max (input int a,input int b);
	max = ((a>b)? a:b);
endfunction

localparam MAX_HRS=(1<<(NTT_STAGE_CNT-2));
// this should larger than that, but I need define to use streaming operator
//parameter `MAX_FIFO_ADDR_BITS=$clog2(max(MAX_HRS,MUL_STAGE_CNT));
//moved to gen_files(ntt_param.svh)
