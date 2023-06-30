`define CYCLE      50.0
`define END_CYCLE 100000

module tb_ntt();

logic clk = '0,rst;
always begin 
	#(`CYCLE/2) clk = ~clk;
end

logic [15:0]data_in;
logic en_in, done;

logic [3:0]golden;
integer fd_in, fd_out;
initial begin
	rst = '0;

	$fsdbDumpfile("ntt.fsdb");
	$fsdbDumpvars();

	fd_in = $fopen("ntt_in.txt","r");
	fd_out = $fopen("ntt_out.txt","r");
	if (fd_in == 0 || fd_out == 0) begin
		$display("Failed open test data");
		$finish;
	end
	else begin
		#(`CYCLE*0.5) rst = '1; 
		#(`CYCLE*10); #0.5; rst = '0;
	end
end

int cnt;
logic busy;
// TODO remove mem, stream in, wait , stream out
always_ff @(posedge clk, posedge rst) begin
	if (rst) begin
		busy <= '0;
		en_in <= '0;
		cnt <= '0;
	end
	else begin
		if (!busy) begin
			if ($feof(fd_in)) $finish;
			else begin
				if(!$fscanf(fd_in, "%h", data_in)) $display("WHAT");
				cnt <= cnt + 1;

				en_in <= '1;
				busy <= '1;
			end
		end
		else begin
			case(1'b1) //unique0 
				en_in: begin
					if(!$fscanf(fd_in, "%h", data_in)) $display("WHAT_MID");
					cnt <= cnt + 1;
					if (cnt == 256) en_in <= '0;
				end
				done: begin
					//TODO: compare
					busy <= '0;
					en_in <= '0;
					cnt <= '0;
				end
			endcase
		end
	end
end
logic en_w ,en_r;
logic [7:0] addr_w ,addr_r;
logic [15:0] data_w ,data_r;
always_ff @(posedge clk) begin
	if (en_w) mem[addr_w] <= data_w;
	if (en_r) data_r <= mem[addr_r];
end
ntt u_ntt(.*);
endmodule
