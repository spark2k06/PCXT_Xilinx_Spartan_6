module KF8259_Priority_Resolver (
	priority_rotate,
	interrupt_mask,
	interrupt_special_mask,
	special_fully_nest_config,
	highest_level_in_service,
	interrupt_request_register,
	in_service_register,
	interrupt
);
	input wire [2:0] priority_rotate;
	input wire [7:0] interrupt_mask;
	input wire [7:0] interrupt_special_mask;
	input wire special_fully_nest_config;
	input wire [7:0] highest_level_in_service;
	input wire [7:0] interrupt_request_register;
	input wire [7:0] in_service_register;
	output wire [7:0] interrupt;
	wire [7:0] masked_interrupt_request;
	assign masked_interrupt_request = interrupt_request_register & ~interrupt_mask;
	wire [7:0] masked_in_service;
	assign masked_in_service = in_service_register & ~interrupt_special_mask;
	wire [7:0] rotated_request;
	reg [7:0] rotated_in_service;
	wire [7:0] rotated_highest_level_in_service;
	reg [7:0] priority_mask;
	wire [7:0] rotated_interrupt;
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
	assign rotated_request = KF8259_Common_Package_rotate_right(masked_interrupt_request, priority_rotate);
	assign rotated_highest_level_in_service = KF8259_Common_Package_rotate_right(highest_level_in_service, priority_rotate);
	always @(*) begin
		rotated_in_service = KF8259_Common_Package_rotate_right(masked_in_service, priority_rotate);
		if (special_fully_nest_config == 1'b1)
			rotated_in_service = (rotated_in_service & ~rotated_highest_level_in_service) | {rotated_highest_level_in_service[6:0], 1'b0};
	end
	always @(*)
		if (rotated_in_service[0] == 1'b1)
			priority_mask = 8'b00000000;
		else if (rotated_in_service[1] == 1'b1)
			priority_mask = 8'b00000001;
		else if (rotated_in_service[2] == 1'b1)
			priority_mask = 8'b00000011;
		else if (rotated_in_service[3] == 1'b1)
			priority_mask = 8'b00000111;
		else if (rotated_in_service[4] == 1'b1)
			priority_mask = 8'b00001111;
		else if (rotated_in_service[5] == 1'b1)
			priority_mask = 8'b00011111;
		else if (rotated_in_service[6] == 1'b1)
			priority_mask = 8'b00111111;
		else if (rotated_in_service[7] == 1'b1)
			priority_mask = 8'b01111111;
		else
			priority_mask = 8'b11111111;
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
	assign rotated_interrupt = KF8259_Common_Package_resolv_priority(rotated_request) & priority_mask;
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
	assign interrupt = KF8259_Common_Package_rotate_left(rotated_interrupt, priority_rotate);
endmodule
