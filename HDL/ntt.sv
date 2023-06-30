module ntt(
	input clk,input rst,
	input in_en,input [15:0]in_data,
	output out_en,output [15:0]out_data,
);
endmodule


module df_ntt #(parameter LENGTH = 256)(
	input clk,input rst,
	input in_en,input [15:0]in_data,
	output out_en,output [15:0]out_data
);
logic signed [15:0] zetas[128] = {
  -1044,  -758,  -359, -1517,  1493,  1422,   287,   202,
   -171,   622,  1577,   182,   962, -1202, -1474,  1468,
    573, -1325,   264,   383,  -829,  1458, -1602,  -130,
   -681,  1017,   732,   608, -1542,   411,  -205, -1571,
   1223,   652,  -552,  1015, -1293,  1491,  -282, -1544,
    516,    -8,  -320,  -666, -1618, -1162,   126,  1469,
   -853,   -90,  -271,   830,   107, -1421,  -247,  -951,
   -398,   961, -1508,  -725,   448, -1065,   677, -1275,
  -1103,   430,   555,   843, -1251,   871,  1550,   105,
    422,   587,   177,  -235,  -291,  -460,  1574,  1653,
   -246,   778,  1159,  -147,  -777,  1483,  -602,  1119,
  -1590,   644,  -872,   349,   418,   329,  -156,   -75,
    817,  1097,   603,   610,  1322, -1285, -1465,   384,
  -1215,  -136,  1218, -1335,  -874,   220, -1187, -1659,
  -1185, -1530, -1278,   794, -1510,  -854,  -870,   478,
   -108,  -308,   996,   991,   958, -1460,  1522,  1628
};

localparam pipe_stage_cnt = 2;
logic out_en[pipe_stage_cnt + 1],calc_en[pipe_stage_cnt + 1];
logic [$clog2(LENGTH) - 2:0] cnt;
logic [15:0] buffer[LENGTH/2];

// circular buffer
always_ff @(posedge clk) begin
	if(in_en | out_en[pipe_stage_cnt]) begin
		for(logic [$clog2(LENGTH - 1) : 0] i = 0; i < LENGTH; i++) begin
			unique case(i)
				0: begin
					if(!calc_en[0]) buffer[i] <= in_data;
				end
				pipe_stage_cnt: begin
					if(calc_en[pipe_stage_cnt - 1]) buffer[i] <= calc_out[0];
				end
				default: buffer[i] <= buffer[i-1];
			endcase
		end
	end
end

// main ctrl
always_ff @(posedge clk,posedge rst) begin
	if (rst) begin
		cnt <= '0;
		calc_en[0] <= '0;
		out_en[0] <= '0;
	end
	else begin
		if(&cnt) begin
			calc_en[0] <= calc_en[0] ^ in_en;
			out_en[0] <= in_en;
		end
		if(in_en | out_en[pipe_stage_cnt]) cnt <= cnt + 1;
		else cnt <= '0;
	end
end

// calculate zone
// fqmul
logic signed [15:0] data_in1, data_in2;
assign data_in1 = 

fqmul(.clk(clk),.data_in1(),.data_in2(),.data_out());


endmodule


module fqmul(
	input clk,input signed[15:0] data_in1, input signed [15:0]data_in2,
	output logic signed [15:0] data_out
);
logic signed [15:0] QINV = -3327;
logic signed [15:0] Q = 3329;
logic signed [31:0] mul_result;
logic signed [15:0] t;
assign t = mul_result*QINV;
always_ff @(posedge clk) begin
	mul_result <= data_in1*data_in2;
	data_out <= mul_result - ((t*Q)>>16);
end
endmodule 
