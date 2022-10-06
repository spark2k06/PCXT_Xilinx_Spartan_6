`default_nettype none

module KF8237_Priority_Encoder (
	input		wire					clock,
	input		wire					cpu_clock_posedge,
	input		wire					cpu_clock_negedge,
	input		wire					reset,
	input		wire	[7:0]			internal_data_bus,
	input		wire					write_command_register,
	input		wire					write_request_register,
	input		wire					set_or_reset_mask_register,
	input		wire					write_mask_register,
	input		wire					master_clear,
	input		wire					clear_mask_register,
	input		wire	[1:0]			dma_rotate,
	input		wire	[3:0]			edge_request,
	output	reg	[3:0]			dma_request_state,
	output	reg	[3:0]			encoded_dma,
	input		wire					end_of_process_internal,
	input		wire	[3:0]			dma_acknowledge_internal,
	input		wire	[3:0]			dma_request
	);

	reg [7:0] bit_select = 8'b00011011;
	reg controller_disable;
	reg rotating_priority;
	reg dreq_sense_active_low;
	reg [3:0] mask_register;
	reg [3:0] request_register;
	reg [3:0] dma_request_ff;
	reg [3:0] dma_request_lock;
	always @(posedge clock or posedge reset)
		if (reset)
			controller_disable <= 1'b0;
		else if (master_clear)
			controller_disable <= 1'b0;
		else if (write_command_register)
			controller_disable <= internal_data_bus[2];
		else
			controller_disable <= controller_disable;
	always @(posedge clock or posedge reset)
		if (reset)
			rotating_priority <= 1'b0;
		else if (master_clear)
			rotating_priority <= 1'b0;
		else if (write_command_register)
			rotating_priority <= internal_data_bus[4];
		else
			rotating_priority <= rotating_priority;
	always @(posedge clock or posedge reset)
		if (reset)
			dreq_sense_active_low <= 1'b0;
		else if (master_clear)
			dreq_sense_active_low <= 1'b0;
		else if (write_command_register)
			dreq_sense_active_low <= internal_data_bus[6];
		else
			dreq_sense_active_low <= dreq_sense_active_low;
	genvar mask_bit_i;
	generate
		for (mask_bit_i = 0; mask_bit_i < 4; mask_bit_i = mask_bit_i + 1) begin : MASK_REGISTER
			always @(posedge clock or posedge reset)
				if (reset)
					mask_register[mask_bit_i] <= 1'b1;
				else if (master_clear || clear_mask_register)
					mask_register[mask_bit_i] <= 1'b1;
				else if (set_or_reset_mask_register && (internal_data_bus[1:0] == bit_select[(3 - mask_bit_i) * 2+:2]))
					mask_register[mask_bit_i] <= internal_data_bus[2];
				else if (write_mask_register)
					mask_register[mask_bit_i] <= internal_data_bus[mask_bit_i];
				else
					mask_register[mask_bit_i] <= mask_register[mask_bit_i];
		end
	endgenerate
	genvar req_reg_bit_i;
	generate
		for (req_reg_bit_i = 0; req_reg_bit_i < 4; req_reg_bit_i = req_reg_bit_i + 1) begin : REQUEST_REGISTER
			always @(posedge clock or posedge reset)
				if (reset)
					request_register[req_reg_bit_i] <= 1'b0;
				else if (master_clear || clear_mask_register)
					request_register[req_reg_bit_i] <= 1'b0;
				else if (write_request_register && (internal_data_bus[1:0] == bit_select[(3 - req_reg_bit_i) * 2+:2]))
					request_register[req_reg_bit_i] <= internal_data_bus[2];
				else if (end_of_process_internal && dma_acknowledge_internal[req_reg_bit_i])
					request_register[req_reg_bit_i] <= 1'b0;
				else
					request_register[req_reg_bit_i] <= request_register[req_reg_bit_i];
		end
	endgenerate
	always @(posedge clock or posedge reset)
		if (reset)
			dma_request_ff <= 0;
		else if (master_clear)
			dma_request_ff <= 0;
		else
			dma_request_ff <= (dreq_sense_active_low ? ~dma_request : dma_request);
	genvar req_lock_bit_i;
	generate
		for (req_lock_bit_i = 0; req_lock_bit_i < 4; req_lock_bit_i = req_lock_bit_i + 1) begin : REQUEST_LCOK
			always @(posedge clock or posedge reset)
				if (reset)
					dma_request_lock[req_lock_bit_i] <= 1'b0;
				else if (master_clear || clear_mask_register)
					dma_request_lock[req_lock_bit_i] <= 1'b0;
				else if (~edge_request[req_lock_bit_i])
					dma_request_lock[req_lock_bit_i] <= 1'b0;
				else if ((cpu_clock_negedge & encoded_dma[req_lock_bit_i]) & dma_acknowledge_internal[req_lock_bit_i])
					dma_request_lock[req_lock_bit_i] <= 1'b1;
				else if (~dma_request_ff[req_lock_bit_i] & ~dma_acknowledge_internal[req_lock_bit_i])
					dma_request_lock[req_lock_bit_i] <= 1'b0;
				else
					dma_request_lock[req_lock_bit_i] <= dma_request_lock[req_lock_bit_i];
		end
	endgenerate
	function [3:0] KF8237_Common_Package_resolv_priority;
		input [3:0] request;
		if (request[0] == 1'b1)
			KF8237_Common_Package_resolv_priority = 4'b0001;
		else if (request[1] == 1'b1)
			KF8237_Common_Package_resolv_priority = 4'b0010;
		else if (request[2] == 1'b1)
			KF8237_Common_Package_resolv_priority = 4'b0100;
		else if (request[3] == 1'b1)
			KF8237_Common_Package_resolv_priority = 4'b1000;
		else
			KF8237_Common_Package_resolv_priority = 4'b0000;
	endfunction
	function [3:0] KF8237_Common_Package_rotate_left;
		input [3:0] source;
		input [1:0] rotate;
		casez (rotate)
			2'b00: KF8237_Common_Package_rotate_left = {source[2:0], source[3]};
			2'b01: KF8237_Common_Package_rotate_left = {source[1:0], source[3:2]};
			2'b10: KF8237_Common_Package_rotate_left = {source[0], source[3:1]};
			2'b11: KF8237_Common_Package_rotate_left = source;
			default: KF8237_Common_Package_rotate_left = source;
		endcase
	endfunction
	function [3:0] KF8237_Common_Package_rotate_right;
		input [3:0] source;
		input [1:0] rotate;
		casez (rotate)
			2'b00: KF8237_Common_Package_rotate_right = {source[0], source[3:1]};
			2'b01: KF8237_Common_Package_rotate_right = {source[1:0], source[3:2]};
			2'b10: KF8237_Common_Package_rotate_right = {source[2:0], source[3]};
			2'b11: KF8237_Common_Package_rotate_right = source;
			default: KF8237_Common_Package_rotate_right = source;
		endcase
	endfunction
	always @(*) begin
		dma_request_state = dma_request_ff;
		dma_request_state = dma_request_state & ~dma_request_lock;
		dma_request_state = dma_request_state & ~mask_register;
		dma_request_state = dma_request_state | request_register;
		encoded_dma = dma_request_state;
		encoded_dma = (rotating_priority ? KF8237_Common_Package_rotate_right(encoded_dma, dma_rotate) : encoded_dma);
		encoded_dma = KF8237_Common_Package_resolv_priority(encoded_dma);
		encoded_dma = (rotating_priority ? KF8237_Common_Package_rotate_left(encoded_dma, dma_rotate) : encoded_dma);
		encoded_dma = (controller_disable ? 4'b0000 : encoded_dma);
	end
endmodule
