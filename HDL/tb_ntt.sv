`define CYCLE      50.0
`define END_CYCLE 100000

always begin 
	#(`CYCLE/2) clk = ~clk;
end

logic [3:0]data_in;
logic in_en,done;

logic [3:0]golden;
initial begin
	reset = '0;
	for (int i = 0; i < pat_number; i++) begin
		fd_in = $fopen("ntt_in.txt","r");
		fd_out = $fopen("ntt_out.txt","r");
		if (fd_in == 0 || fd_out == 0) begin
			$display("Failed open test data");
			$finish;
		end
		else begin
			#(`CYCLE*0.5) reset = '1; 
			#(`CYCLE*5); #0.5; reset = '0; en = '1;
		end
	end
end

int cnt;
logic busy;
logic [3:0] mem [256];
always_ff @(posedge clk, posedge reset) begin
	if (reset) begin
		busy <= '0;
		in_en <= '0;
		cnt <= '0;
	end
	if (!busy) begin
		if ($feof(fd_in)) $finish
		else begin
			$fscanf(fd_in, "%h", data_in);
			cnt <= cnt + 1;

			in_en <= '1;
			shbusy <= '1;
		end
	end
	else begin
		unique case(1'b1)
			in_en: begin
				$fscanf(fd, "%h", data_in);
				$display("%h ",data_in);
				cnt <= cnt + 1;
				if (cnt == 255) in_en <= '0;
			end
			done: begin
				//TODO: compare
				busy <= '0;
				in_en <= '0;
				cnt <= '0;
			end
		endcase
	end
end
logic w_en ,r_en;
logic [7:0] w_addr ,r_addr;
logic [3:0] w_data ,r_data;
always_ff @(posedge clk) begin
	if (w_en) mem[w_addr] <= w_data;
	if (r_en) mem[r_addr] <= r_data;
end
//ntt u_ntt//TODO
