/***********
testbench for duel port pipeline ntt,pwm,intt
the tb will convert test data from signed to unsigned
define NTT,PWM,INTT to test what function you want to test

You may need to edit this to read different data input!
***********/
//`define TB_PATH "/home/cicero/code/PQC-crystal-kyber/NTT/dat/"
//`define TB_PATH "/home/cicero/code/kyber/ref"
//`define TB_PATH "/home/ic_contest/509/kyber_test_data/"
//`define TB_PATH "/home/ic_contest/509/NTT/dat/sample256/"
//`define TB_PATH "/home/ic_contest/509/NTT/dat/"
`define TB_PATH "/home/ic_contest/509/CRYSTALS/HDL/testdata/"
// test which module
`define NTT 
// for kyber extracted testdata require separate odd and even
//`define SEPARATE_ODD_EVEN


`define CYCLE     10.0
`define MAX_CYCLE 14000000

`ifdef SDF 
	initial $sdf_annotate("syn/top_ntt_syn.sdf",u_top_ntt);
`endif


`ifdef SEPARATE_ODD_EVEN
	`define DATA_SIZE (2<<NTT_STAGE_CNT)
`else
	`define DATA_SIZE (1<<NTT_STAGE_CNT)
`endif

import ntt_pkg::*;
module tb_ntt();

logic clk = '0,rst;
always begin 
	#(`CYCLE/2) clk = ~clk;
end

// maybe need to remove *2 if it's not kyber, check your algorithm
logic [DATA_WIDTH-1:0]data_in[`DATA_SIZE];
logic [DATA_WIDTH-1:0]data_in2[`DATA_SIZE];
logic [DATA_WIDTH-1:0]data_out[`DATA_SIZE];

integer fd_in, fd_out;

/*
	rst ,clk ,open files
*/
int fd_in2;
initial begin
	rst = '0;

`ifdef NTT
	fd_in = $fopen({`TB_PATH,"/ntt_in.dat"},"r");
	fd_in2 = 1;
	fd_out = $fopen({`TB_PATH,"/ntt_out.dat"},"r");
	`elsif PWM
	fd_in = $fopen({`TB_PATH,"/pwm1_in.dat"},"r");
	fd_in2 = $fopen({`TB_PATH,"/pwm2_in.dat"},"r");
	fd_out = $fopen({`TB_PATH,"/pwm_out.dat"},"r");
	`elsif INTT
	fd_in = $fopen({`TB_PATH,"/intt_in.dat"},"r");
	fd_in2 = 1;
	fd_out = $fopen({`TB_PATH,"/intt_out.dat"},"r");
`else
	$display("please define 'NTT' or 'PWN' or 'INTT'.");
$display("require define things like Q=3329,NTT_STAGE_CNT=7,TB_PATH=\"~/code/kyber/\",\"NTT\"");
	$finish;
`endif
	if (!(fd_in && fd_in2 && fd_out)) begin
		$display("Failed open test data");
		$finish;
	end else begin
		#(`CYCLE*0.5) rst = '1; 
		#(`CYCLE*100); #0.5; rst = '0;
	end
	//$fsdbDumpfile("ntt.fsdb");
	//$fsdbDumpvars();
end

/*
	inout ctl
*/
int in_cnt, out_cnt;
int data_cnt,err_cnt;
logic [DATA_WIDTH-1:0] in[2],in2[2],out[2];
logic [$clog2(`DATA_SIZE)-1:0] out_addr[2];
logic [DATA_WIDTH-1:0] data_ignore[2][2];
logic en_ignore[2];
logic in_en, out_en;

`ifdef NTT
// for separate odd and even
// assume the order is odd number first(ex: data_size=16)
// the example is from right to left

always_comb begin
`ifdef SEPARATE_ODD_EVEN
	//separate odd and even(for kyber as tb)
	// in[0]: 0 2  4  6  1 3  5  7
	// in[1]: 8 10 12 14 9 11 13 15
	if (in_cnt < `DATA_SIZE/4) begin
		in[0] = data_in[`DATA_SIZE/2-1-2*in_cnt];
		in[1] = data_in[`DATA_SIZE  -1-2*in_cnt];
	end else begin
		in[0] = data_in[`DATA_SIZE/2-2-2*(in_cnt-`DATA_SIZE/4)];
		in[1] = data_in[`DATA_SIZE  -2-2*(in_cnt-`DATA_SIZE/4)];
	end

	// out[0]: 0 4 8  12 1 5 9  13
	// out[1]: 2 6 10 14 3 7 11 15
	if (out_cnt < `DATA_SIZE/4) begin
		out_addr[0] = `DATA_SIZE-3-4*out_cnt;
		out_addr[1] = `DATA_SIZE-1-4*out_cnt;
	end else begin
		out_addr[0] = `DATA_SIZE-4-4*(out_cnt-`DATA_SIZE/4);
		out_addr[1] = `DATA_SIZE-2-4*(out_cnt-`DATA_SIZE/4);
	end
`else
	in[0] = data_in[`DATA_SIZE/2-1-in_cnt];
	in[1] = data_in[`DATA_SIZE  -1-in_cnt];

`ifdef ALG_DIFDIT
	out_addr[0] = {<<{(NTT_STAGE_CNT)'(`DATA_SIZE-2-2*out_cnt)}};
	out_addr[1] = {<<{(NTT_STAGE_CNT)'(`DATA_SIZE-1-2*out_cnt)}};
`else
	out_addr[0] = `DATA_SIZE-2-2*out_cnt;
	out_addr[1] = `DATA_SIZE-1-2*out_cnt;
`endif

`endif
end


top_ntt u_top_ntt(
	.ntt_in_en(in_en), .ntt_in1(in[0]), .ntt_in2(in[1]),
	.ntt_out_en(out_en), .ntt_out1(out[0]), .ntt_out2(out[1]),
	.intt_in_en('0), .intt_in1(in[0]), .intt_in2(in[1]),
	.intt_out_en(en_ignore[0]), .intt_out1(data_ignore[0][0]), .intt_out2(data_ignore[0][1]),
	.pwm_in_en('0), .pwm_in11(in[0]),.pwm_in12(in[1]),.pwm_in21(in2[0]),.pwm_in22(in2[1]),
	.pwm_out_en(en_ignore[1]), .pwm_out1(data_ignore[1][0]),.pwm_out2(data_ignore[1][1]),
.*);


// for post sim in vivodo =_=
/*
top_ntt u_top_ntt(
	.ntt_in_en(in_en), .\ntt_in[0] (in[0]), .\ntt_in[1] (in[1]),
	.ntt_out_en(out_en), .\ntt_out[0] (out[0]), .\ntt_out[1] (out[1]),
	.intt_in_en('0), .\intt_in[0] (in[0]), .\intt_in[1] (in[1]),
	.intt_out_en(en_ignore[0]), .\intt_out[0] (data_ignore[0][0]),.\intt_out[1] (data_ignore[0][1]),
	.pwm_in_en('0), .\pwm_in[0][0] (in[0]), .\pwm_in[0][1] (in[1]),.\pwm_in[1][0] (in2[0]), .\pwm_in[1][1] (in2[1]),
	.pwm_out_en(en_ignore[1]), .\pwm_out[0] (data_ignore[1][0]), .\pwm_out[1] (data_ignore[1][1]),
.*);
*/

`elsif PWM
always_comb begin
	// in[0]: 14 10 6 2 15 11 7 3
	// in[1]: 12 8  4 0 13 9  5 1
	if (in_cnt < `DATA_SIZE/4) begin
		in[0] = data_in[3+4*in_cnt];
		in[1] = data_in[1+4*in_cnt];
	end else begin
		in[0] = data_in[2+4*(in_cnt-`DATA_SIZE/4)];
		in[1] = data_in[0+4*(in_cnt-`DATA_SIZE/4)];
	end
	// out[0]: 14 10 6 2 15 11 7 3
	// out[1]: 12 8  4 0 13 9  5 1
	if (out_cnt < `DATA_SIZE/4) begin
		out_addr[0] = 3+4*out_cnt;
		out_addr[1] = 1+4*out_cnt;
	end else begin
		out_addr[0] = 2+4*(out_cnt-`DATA_SIZE/4);
		out_addr[1] = 0+4*(out_cnt-`DATA_SIZE/4);
	end
end

// FIXME
top_ntt u_top_ntt(
	.ntt_in_en(in_en), .ntt_in1(in[0]), .ntt_in2(in[1]),
	.ntt_out_en(out_en), .ntt_out1(out[0]), .ntt_out2(out[1]),
	.intt_in_en('0), .intt_in1(in[0]), .intt_in2(in[1]),
	.intt_out_en(en_ignore[0]), .intt_out1(data_ignore[0][0]), .intt_out2(data_ignore[0][1]),
	.pwm_in_en('0), .pwm_in11(in[0]),.pwm_in12(in[1]),.pwm_in21(in2[0]),.pwm_in22(in2[1]),
	.pwm_out_en(en_ignore[1]), .pwm_out1(data_ignore[1][0]),.pwm_out2(data_ignore[1][1]),
.*);

`elsif INTT
always_comb begin
	// in[0]: 14 10 6 2 15 11 7 3
	// in[1]: 12 8  4 0 13 9  5 1
	if (in_cnt < `DATA_SIZE/4) begin
		in[0] = data_in[`DATA_SIZE-3-4*in_cnt];
		in[1] = data_in[`DATA_SIZE-1-4*in_cnt];
	end else begin
		in[0] = data_in[`DATA_SIZE-4-4*(in_cnt-`DATA_SIZE/4)];
		in[1] = data_in[`DATA_SIZE-2-4*(in_cnt-`DATA_SIZE/4)];
	end

	// out[0]: 8 10 12 14 9 11 13 15
	// out[1]: 0 2  4  6  1 3  5  7
	if (out_cnt < `DATA_SIZE/4) begin
		out_addr[0] =              1+2*out_cnt;
		out_addr[1] = `DATA_SIZE/2+1+2*out_cnt;
	end else begin
		out_addr[0] =              2*(out_cnt-`DATA_SIZE/4);
		out_addr[1] = `DATA_SIZE/2+2*(out_cnt-`DATA_SIZE/4);
	end
end

// FIXME
top_ntt u_top_ntt(
	.ntt_in_en(in_en), .ntt_in1(in[0]), .ntt_in2(in[1]),
	.ntt_out_en(out_en), .ntt_out1(out[0]), .ntt_out2(out[1]),
	.intt_in_en('0), .intt_in1(in[0]), .intt_in2(in[1]),
	.intt_out_en(en_ignore[0]), .intt_out1(data_ignore[0][0]), .intt_out2(data_ignore[0][1]),
	.pwm_in_en('0), .pwm_in11(in[0]),.pwm_in12(in[1]),.pwm_in21(in2[0]),.pwm_in22(in2[1]),
	.pwm_out_en(en_ignore[1]), .pwm_out1(data_ignore[1][0]),.pwm_out2(data_ignore[1][1]),
.*);

`endif

function logic [DATA_WIDTH-1:0] unsign_mod(logic signed [15:0] in);
	in %= Q;
	if (in<0) in += Q;
	return in;
endfunction

// FIXME: change this depend on your data
logic signed [15:0] origin_data;
always_ff @(negedge clk, posedge rst) begin
	if (rst) begin
		in_en <= '0;
		in_cnt <= `DATA_SIZE/2-1;
	end else begin
		// input cnt ctl
		if (in_cnt == `DATA_SIZE/2-1) begin
			for(int i = 0; i < `DATA_SIZE; ++i) begin
				if (!$fscanf(fd_in, "%h", origin_data)) $display("intput Read err");
				//$display("origin: %d",origin_data);
				data_in[i] = unsign_mod(origin_data);
				//$display("mod: %d",data_in[i]);
`ifdef PWM
				if (!$fscanf(fd_in2, "%h", origin_data)) $display("intput2 Read err");
				data_in2[i] = unsign_mod(origin_data);
`endif
			end
			if ($feof(fd_in)) in_en <= '0;
			else begin
				in_en <= '1;
				in_cnt <= 0;
				// FIXME: only test 1 data
			end
			in_cnt <= 0;
		end
		else in_cnt <= in_cnt+1;
		/*
		if (in_en) begin
			if (in_cnt < `DATA_SIZE/4) begin
				$display("%d, %d",`DATA_SIZE/2-1-2*in_cnt,`DATA_SIZE  -1-2*in_cnt);
			end
			else begin
				$display("%d, %d",`DATA_SIZE/2-2-2*(in_cnt-`DATA_SIZE/4),`DATA_SIZE  -2-2*(in_cnt-`DATA_SIZE/4));
			end                   
		end
		*/
	end
end

// output cnt ctl
// cache it~!
logic initial_read_out_data;
logic [DATA_WIDTH-1:0] out_delay[2];
logic out_en_delay[2];
int latency;
logic latency_cnt_en;
always_latch begin
	case(1'b1)
		out_en: latency_cnt_en <= '0;
		in_en: latency_cnt_en <= '1;
	endcase
end
always_ff @(posedge clk) begin
	out_delay <= out;
	out_en_delay[0] <= out_en;
	out_en_delay[1] <= out_en_delay[0];
end
always_ff @(posedge clk) begin
	if (rst) begin
		initial_read_out_data <= '0;
		out_cnt <= 0;
		data_cnt <= 0;
		err_cnt <= 0;
		latency <= 0;
	end else begin
		if (latency_cnt_en) latency <= latency+1;
		if ((out_en_delay[0]) &&(!out_en_delay[1])) $display("latency is : %d cycles",latency);
		if (!initial_read_out_data) begin
			initial_read_out_data <= '1;
			for(int i = 0; i < `DATA_SIZE; ++i) begin
				if (!$fscanf(fd_out, "%h", origin_data)) $display("output Read err");
				data_out[i] <= unsign_mod(origin_data);
			end
		end

		if (out_en_delay[0]) begin
			if (out_cnt == `DATA_SIZE/2-1) begin
				out_cnt <= 0;
				for(int i = 0; i < `DATA_SIZE; ++i) begin
					if (!$fscanf(fd_out, "%h", origin_data)) $display("output Read err");
					data_out[i] <= unsign_mod(origin_data);
				end
				out_cnt <= 0;
				data_cnt <= data_cnt+1;
			end
			else out_cnt <= out_cnt+1;

			for(int i = 0; i < 2; ++i) begin
				if (data_out[out_addr[i]] == unsign_mod(out_delay[i])) begin
					//$display("data correct!, %d == %d", data_out[out_addr[i]], out_delay[i]);
				end else begin
					$display("data %d error!,%d:[%d] %d != %d", data_cnt,out_cnt, out_addr[i], data_out[out_addr[i]], out_delay[i]);
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
	if (rst) begin
		total_cycle <= 0;
		countdown <= 0;
	end else begin
		total_cycle <= total_cycle+1;
		if (total_cycle > `MAX_CYCLE) $finish;
		if (data_cnt && (!in_en) && (!out_en)) begin
			$display("stop because no inout: tested %d data\n\n",data_cnt);
			$finish;
		end
	end
end

endmodule
