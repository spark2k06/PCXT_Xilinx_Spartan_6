module KF8259_Interrupt_Request (
	clock,
	reset,
	level_or_edge_toriggered_config,
	freeze,
	clear_interrupt_request,
	interrupt_request_pin,
	interrupt_request_register
);
	input wire clock;
	input wire reset;
	input wire level_or_edge_toriggered_config;
	input wire freeze;
	input wire [7:0] clear_interrupt_request;
	input wire [7:0] interrupt_request_pin;
	output reg [7:0] interrupt_request_register;
	reg [7:0] low_input_latch;
	wire [7:0] interrupt_request_edge;
	genvar ir_bit_no;
	generate
		for (ir_bit_no = 0; ir_bit_no <= 7; ir_bit_no = ir_bit_no + 1) begin : Request_Latch
			always @(posedge clock or posedge reset)
				if (reset)
					low_input_latch[ir_bit_no] <= 1'b0;
				else if (clear_interrupt_request[ir_bit_no])
					low_input_latch[ir_bit_no] <= 1'b0;
				else if (~interrupt_request_pin[ir_bit_no])
					low_input_latch[ir_bit_no] <= 1'b1;
				else
					low_input_latch[ir_bit_no] <= low_input_latch[ir_bit_no];
			assign interrupt_request_edge[ir_bit_no] = (low_input_latch[ir_bit_no] == 1'b1) & (interrupt_request_pin[ir_bit_no] == 1'b1);
			always @(posedge clock or posedge reset)
				if (reset)
					interrupt_request_register[ir_bit_no] <= 1'b0;
				else if (clear_interrupt_request[ir_bit_no])
					interrupt_request_register[ir_bit_no] <= 1'b0;
				else if (freeze)
					interrupt_request_register[ir_bit_no] <= interrupt_request_register[ir_bit_no];
				else if (level_or_edge_toriggered_config)
					interrupt_request_register[ir_bit_no] <= interrupt_request_pin[ir_bit_no];
				else
					interrupt_request_register[ir_bit_no] <= interrupt_request_edge[ir_bit_no];
		end
	endgenerate
endmodule
