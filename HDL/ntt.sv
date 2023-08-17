/***************
duel pipelined ntt
***************/

module ntt(
	input clk,input rst,
	input in_en,input signed [`DATA_WIDTH-1:0]in[2],
	output out_en,output logic signed [`DATA_WIDTH-1:0]out[2]
);
logic signed [`DATA_WIDTH-1:0] data[`NTT_STAGE_CNT+1][2];
logic en[`NTT_STAGE_CNT+1];
assign data[0] = in;
assign en[0] = in_en;
assign out = data[`NTT_STAGE_CNT];
assign out_en = en[`NTT_STAGE_CNT];

genvar i;
generate
for (i=0; i < `NTT_STAGE_CNT; i++) begin
	ntt_stage #(.STAGE(i)) staged_ntt (
		.in_en(en[i]), .in(data[i]),
		.out_en(en[i+1]), .out(data[i+1]),
	.*);
end
endgenerate
endmodule

// stage
module ntt_stage #(parameter STAGE = 0)(
	input clk,input rst,
	input in_en,input signed [`DATA_WIDTH-1:0]in[2],
	output out_en,output signed [`DATA_WIDTH-1:0]out[2]
);
generate
case(STAGE)
	// first stage
	// all data already ordered, so dont need reorder
	0: begin
	end
	// final stage
	`NTT_STAGE_CNT-1: begin
	end
	default: begin
		if(`DATA_SIZE/(2<<STAGE))
	end
endcase
endgenerate
endmodule
