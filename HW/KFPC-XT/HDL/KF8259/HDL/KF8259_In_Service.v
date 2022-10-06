`default_nettype none

module KF8259_In_Service (
	input		wire					clock,
	input		wire					reset,
	input		wire	[2:0]			priority_rotate,
	input		wire	[7:0]			interrupt_special_mask,
	input		wire	[7:0]			interrupt,
	input		wire					latch_in_service,
	input		wire	[7:0]			end_of_interrupt,
	output	reg	[7:0]			in_service_register,
	output	reg	[7:0]			highest_level_in_service
	);

	wire [7:0] next_in_service_register;
	assign next_in_service_register = (in_service_register & ~end_of_interrupt) | (latch_in_service == 1'b1 ? interrupt : 8'b00000000);
	always @(posedge clock or posedge reset)
		if (reset)
			in_service_register <= 8'b00000000;
		else
			in_service_register <= next_in_service_register;
	reg [7:0] next_highest_level_in_service;
	function [7:0] KF8259_Common_Package_resolv_priority;
		input [7:0] request;
		if (request[0] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b00000001;
		else if (request[1] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b00000010;
		else if (request[2] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b00000100;
		else if (request[3] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b00001000;
		else if (request[4] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b00010000;
		else if (request[5] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b00100000;
		else if (request[6] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b01000000;
		else if (request[7] == 1'b1)
			KF8259_Common_Package_resolv_priority = 8'b10000000;
		else
			KF8259_Common_Package_resolv_priority = 8'b00000000;
	endfunction
	function [7:0] KF8259_Common_Package_rotate_left;
		input [7:0] source;
		input [2:0] rotate;
		casez (rotate)
			3'b000: KF8259_Common_Package_rotate_left = {source[6:0], source[7]};
			3'b001: KF8259_Common_Package_rotate_left = {source[5:0], source[7:6]};
			3'b010: KF8259_Common_Package_rotate_left = {source[4:0], source[7:5]};
			3'b011: KF8259_Common_Package_rotate_left = {source[3:0], source[7:4]};
			3'b100: KF8259_Common_Package_rotate_left = {source[2:0], source[7:3]};
			3'b101: KF8259_Common_Package_rotate_left = {source[1:0], source[7:2]};
			3'b110: KF8259_Common_Package_rotate_left = {source[0], source[7:1]};
			3'b111: KF8259_Common_Package_rotate_left = source;
			default: KF8259_Common_Package_rotate_left = source;
		endcase
	endfunction
	function [7:0] KF8259_Common_Package_rotate_right;
		input [7:0] source;
		input [2:0] rotate;
		casez (rotate)
			3'b000: KF8259_Common_Package_rotate_right = {source[0], source[7:1]};
			3'b001: KF8259_Common_Package_rotate_right = {source[1:0], source[7:2]};
			3'b010: KF8259_Common_Package_rotate_right = {source[2:0], source[7:3]};
			3'b011: KF8259_Common_Package_rotate_right = {source[3:0], source[7:4]};
			3'b100: KF8259_Common_Package_rotate_right = {source[4:0], source[7:5]};
			3'b101: KF8259_Common_Package_rotate_right = {source[5:0], source[7:6]};
			3'b110: KF8259_Common_Package_rotate_right = {source[6:0], source[7]};
			3'b111: KF8259_Common_Package_rotate_right = source;
			default: KF8259_Common_Package_rotate_right = source;
		endcase
	endfunction
	always @(*) begin
		next_highest_level_in_service = next_in_service_register & ~interrupt_special_mask;
		next_highest_level_in_service = KF8259_Common_Package_rotate_right(next_highest_level_in_service, priority_rotate);
		next_highest_level_in_service = KF8259_Common_Package_resolv_priority(next_highest_level_in_service);
		next_highest_level_in_service = KF8259_Common_Package_rotate_left(next_highest_level_in_service, priority_rotate);
	end
	always @(posedge clock or posedge reset)
		if (reset)
			highest_level_in_service <= 8'b00000000;
		else
			highest_level_in_service <= next_highest_level_in_service;
endmodule
