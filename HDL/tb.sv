/***********
testbench for duel port pipeline ntt,pwm,intt
the tb will convert test data from signed to unsigned
define NTT,PWM,INTT to test what function you want to test
***********/
`include "ntt.svh"

`define CYCLE      10.0
`define MAX_CYCLE 14000000


module tb();

logic clk = '0,rst;
always begin 
	#(`CYCLE/2) clk = ~clk;
end

// maybe need to remove *2 if it's not kyber, check your algorithm
logic signed [`DATA_WIDTH-1:0]data_in[`DATA_SIZE*2];
logic signed [`DATA_WIDTH-1:0]data_in2[`DATA_SIZE*2];
logic signed [`DATA_WIDTH-1:0]data_out[`DATA_SIZE*2];

integer fd_in, fd_out;

/*
	rst ,clk ,open files
*/
initial begin
	rst = '0;
`ifdef NTT
	fd_in = $fopen("ntt_in.txt","r");
	fd_in2 = 1;
	fd_out = $fopen("ntt_out.txt","r");
`elsif PWM
	fd_in = $fopen("pwm1_in.txt","r");
	fd_in2 = $fopen("pwm2_in.txt","r");
	fd_out = $fopen("pwm_out.txt","r");
`elsif INTT
	fd_in = $fopen("intt_in.txt","r");
	fd_in2 = 1;
	fd_out = $fopen("intt_out.txt","r");
`else
	$display("please define 'NTT' or 'PWN' or 'INTT'.");
	$finish
`endif
	if (fd_in == 0 || fd_in2 || fd_out == 0) begin
		$display("Failed open test data");
		$finish;
	end
	else begin
		#(`CYCLE*0.5) rst = '1; 
		#(`CYCLE*10); #0.5; rst = '0;
	end
	//$fsdbDumpfile("ntt.fsdb");
	//$fsdbDumpvars();
end

/*
	inout ctl
*/
int in_cnt, out_cnt;
int data_cnt,err_cnt;
logic [`DATA_WIDTH-1:0] in[2],out[2],gold_out[2];

`ifdef NTT
// for separate odd and even
// assume the order is odd number first(ex: data_size=16)
// the example is from right to left
always_comb begin
	// in[0]: 0 2  4  6  1 3  5  7
	// in[1]: 8 10 12 14 9 11 13 15
	if(in_cnt < `DATA_SIZE/2) begin
		in[0] = data_in[`DATA_SIZE/2-1-2*in_cnt]%Q;
		in[1] = data_in[`DATA_SIZE  -1-2*in_cnt]%Q;
	end
	else begin
		in[0] = data_in[`DATA_SIZE/2-2-2*(in_cnt-`DATA_SIZE/2)]%Q;
		in[1] = data_in[`DATA_SIZE  -2-2*(in_cnt-`DATA_SIZE/2)]%Q;
	end

	// out[0]: 0 4 8  12 1 5 9  13
	// out[1]: 2 6 10 14 3 7 11 15
	if(out_cnt < `DATA_SIZE/2) begin
		gold_out[0] = data_out[`DATA_SIZE-3-4*out_cnt]%Q;
		gold_out[1] = data_out[`DATA_SIZE-1-4*out_cnt]%Q;
	end
	else begin
		gold_out[0] = data_out[`DATA_SIZE-4-4*(out_cnt-`DATA_SIZE/2)]%Q;
		gold_out[1] = data_out[`DATA_SIZE-2-4*(out_cnt-`DATA_SIZE/2)]%Q;
	end
end

`elsif PWM
always_comb begin
	// in[0]: 14 10 6 2 15 11 7 3
	// in[1]: 12 8  4 0 13 9  5 1
	if(in_cnt < `DATA_SIZE/4) begin
		in[0] = data_in[3+4*in_cnt];
		in[1] = data_in[1+4*in_cnt];
	end
	else begin
		in[0] = data_in[2+4*(in_cnt-`DATA_SIZE/4)];
		in[1] = data_in[0+4*(in_cnt-`DATA_SIZE/4)];
	end
	// out[0]: 14 10 6 2 15 11 7 3
	// out[1]: 12 8  4 0 13 9  5 1
	if(out_cnt < `DATA_SIZE/4) begin
		gold_out[0] = data_out[3+4*out_cnt];
		gold_out[1] = data_out[1+4*out_cnt];
	end
	else begin
		gold_out[0] = data_out[2+4*(out_cnt-`DATA_SIZE/4)];
		gold_out[1] = data_out[0+4*(out_cnt-`DATA_SIZE/4)];
	end
end

`elsif INTT
always_comb begin
	// in[0]: 14 10 6 2 15 11 7 3
	// in[1]: 12 8  4 0 13 9  5 1
	if(in_cnt < `DATA_SIZE/4) begin
		in[0] = data_in[3+4*in_cnt];
		in[1] = data_in[1+4*in_cnt];
	end
	else begin
		in[0] = data_in[2+4*(in_cnt-`DATA_SIZE/4)];
		in[1] = data_in[0+4*(in_cnt-`DATA_SIZE/4)];
	end

	// out[0]: 8 10 12 14 9 11 13 15
	// out[1]: 0 2  4  6  1 3  5  7
	if(out_cnt < `DATA_SIZE/4) begin
		gold_out[0] = data_out[`DATA_SIZE  -1-2*out_cnt];
		gold_out[1] = data_out[`DATA_SIZE/2-1-2*out_cnt];
	end
	else begin
		gold_out[0] = data_out[`DATA_SIZE  -2-2*out_cnt];
		gold_out[1] = data_out[`DATA_SIZE/2-2-2*out_cnt];
	end
end
`endif

logic in_en, out_en;
always_ff @(posedge clk, posedge rst) begin
	if (rst) begin
		in_en <= '0;
		in_cnt <= `DATA_SIZE/2-1;
		out_cnt <= `DATA_SIZE/2-1;
		data_cnt <= 0;
		err_cnt <= 0;
	end
	else begin
		// input cnt ctl
		if(in_cnt == DATA_SIZE/2-1) begin
			if ($feof(fd_in)) in_en <= 0;
			else begin
				in_en <= 1;
				in_cnt <= 0;
				for(int i = 0; i < `DATA_SIZE; ++i) begin
					if(!$fscanf(fd_in, "%h", data_in[i])) $display("intput Read err");
`ifdef PWM
					if(!$fscanf(fd_in2, "%h", data_in2[i])) $display("intput2 Read err");
`endif
				end
			end
			in_cnt <= 0;
		end
		else in_cnt <= in_cnt+1;
		// output cnt ctl
		if(out_en) begin
			if(out_cnt == `DATA_SIZE/2-1) begin
				out_cnt <= 0;
				for(int i = 0; i < `DATA_SIZE; ++i) begin
					if(!$fscanf(fd_out, "%h", data_out[i])) $display("output Read err");
				end
				out_cnt <= 0;
				data_cnt <= data_cnt+1;
			end
			else out_cnt <= out_cnt+1;

			for(int i = 0; i < 2; ++i) begin
				if( gold_out[i] != out[i] &&
					gold_out[i]+`Q != out[i] &&
					gold_out[i]-`Q != out[i]
				) begin
					$display("data %d error!\n", data_cnt);
					err_cnt <= err_cnt + 1;
				end
			end
		end
	end
end

/*
	end ctl
*/
int total_cycle, countdown;
always_ff @(posedge clk, posedge rst) begin
	if(rst) begin
		total_cycle <= 0;
		countdown <= 0;
	end
	else begin
		total_cycle <= total_cycle+1;
		if(total_cycle > `MAX_CYCLE) $finish;
	end
end

top u_top()

endmodule
