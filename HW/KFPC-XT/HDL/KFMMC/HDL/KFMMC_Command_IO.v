`default_nettype none

module KFMMC_Command_IO (
	input wire clock,
	input wire reset,
	input wire reset_command_state,
	input wire start_command,
	input wire [47:0] command,
	input wire enable_command_crc,
	input wire enable_response_crc,
	input wire [4:0] response_length,
	output wire command_busy,
	output reg [135:0] response,
	output reg response_error,
	output reg start_communication_to_mmc,
	output reg command_io_to_mmc,
	output reg check_command_start_bit_to_mmc,
	output reg clear_command_crc_to_mmc,
	output reg clear_command_interrupt_to_mmc,
	output reg mask_command_interrupt_to_mmc,
	output reg set_send_command_to_mmc,
	output reg [7:0] send_command_to_mmc,
	input wire [7:0] received_response_from_mmc,
	input wire [6:0] send_command_crc_from_mmc,
	input wire [6:0] received_response_crc_from_mmc,
	input wire mmc_is_in_connecting,
	input wire sent_command_interrupt_from_mmc,
	input wire received_response_interrupt_from_mmc
);

	reg [31:0] command_state;
	reg [31:0] next_command_state;
	reg [47:0] command_buffer;
	reg [2:0] send_count;
	reg [4:0] recv_count;
	reg enable_command_crc_ff;
	reg enable_response_crc_ff;
	reg [7:0] recv_crc;
	wire complete_receiving;
	always @(*) begin
		next_command_state = command_state;
		case (command_state)
			32'd0:
				if (start_command)
					next_command_state = 32'd1;
			32'd1:
				if (sent_command_interrupt_from_mmc && (send_count == 3'd0))
					next_command_state = 32'd2;
			32'd2:
				if (complete_receiving)
					next_command_state = 32'd0;
			default:
				;
		endcase
	end
	always @(posedge clock or posedge reset)
		if (reset)
			command_state <= 32'd0;
		else if (reset_command_state)
			command_state <= 32'd0;
		else
			command_state <= next_command_state;
	always @(posedge clock or posedge reset)
		if (reset) begin
			start_communication_to_mmc <= 1'b0;
			command_io_to_mmc <= 1'b1;
			check_command_start_bit_to_mmc <= 1'b0;
			clear_command_crc_to_mmc <= 1'b0;
			clear_command_interrupt_to_mmc <= 1'b0;
			mask_command_interrupt_to_mmc <= 1'b0;
			set_send_command_to_mmc <= 1'b0;
		end
		else if (command_state == 32'd1) begin
			if (~mmc_is_in_connecting && (send_count == 3'd7)) begin
				start_communication_to_mmc <= 1'b1;
				command_io_to_mmc <= 1'b0;
				check_command_start_bit_to_mmc <= 1'b0;
				clear_command_crc_to_mmc <= 1'b1;
				clear_command_interrupt_to_mmc <= 1'b1;
				mask_command_interrupt_to_mmc <= 1'b0;
				set_send_command_to_mmc <= 1'b1;
			end
			else if (sent_command_interrupt_from_mmc && (send_count != 3'd0)) begin
				start_communication_to_mmc <= 1'b1;
				command_io_to_mmc <= 1'b0;
				check_command_start_bit_to_mmc <= 1'b0;
				clear_command_crc_to_mmc <= (send_count == (3'd7 - 1) ? 1'b1 : 1'b0);
				clear_command_interrupt_to_mmc <= 1'b1;
				mask_command_interrupt_to_mmc <= 1'b0;
				set_send_command_to_mmc <= 1'b1;
			end
			else begin
				start_communication_to_mmc <= 1'b0;
				command_io_to_mmc <= 1'b0;
				check_command_start_bit_to_mmc <= 1'b0;
				clear_command_crc_to_mmc <= 1'b0;
				clear_command_interrupt_to_mmc <= 1'b0;
				mask_command_interrupt_to_mmc <= 1'b0;
				set_send_command_to_mmc <= 1'b0;
			end
		end
		else if ((command_state == 32'd2) && ~complete_receiving) begin
			if (sent_command_interrupt_from_mmc) begin
				start_communication_to_mmc <= 1'b1;
				command_io_to_mmc <= 1'b1;
				check_command_start_bit_to_mmc <= 1'b1;
				clear_command_crc_to_mmc <= 1'b1;
				clear_command_interrupt_to_mmc <= 1'b1;
				mask_command_interrupt_to_mmc <= 1'b0;
				set_send_command_to_mmc <= 1'b0;
			end
			else if (received_response_interrupt_from_mmc && (recv_count != 5'd1)) begin
				start_communication_to_mmc <= 1'b1;
				command_io_to_mmc <= 1'b1;
				check_command_start_bit_to_mmc <= 1'b0;
				clear_command_crc_to_mmc <= 1'b0;
				clear_command_interrupt_to_mmc <= 1'b1;
				mask_command_interrupt_to_mmc <= 1'b0;
				set_send_command_to_mmc <= 1'b0;
			end
			else begin
				start_communication_to_mmc <= 1'b0;
				command_io_to_mmc <= 1'b1;
				check_command_start_bit_to_mmc <= 1'b0;
				clear_command_crc_to_mmc <= 1'b0;
				clear_command_interrupt_to_mmc <= 1'b0;
				mask_command_interrupt_to_mmc <= 1'b0;
				set_send_command_to_mmc <= 1'b0;
			end
		end
		else begin
			start_communication_to_mmc <= 1'b0;
			command_io_to_mmc <= 1'b1;
			check_command_start_bit_to_mmc <= 1'b0;
			clear_command_crc_to_mmc <= 1'b0;
			clear_command_interrupt_to_mmc <= 1'b0;
			mask_command_interrupt_to_mmc <= 1'b1;
			set_send_command_to_mmc <= 1'b0;
		end
	wire shift_send_command_data = (start_communication_to_mmc & mmc_is_in_connecting) & (command_state == 32'd1);
	wire shift_recv_response_data = (~start_communication_to_mmc & received_response_interrupt_from_mmc) & (command_state == 32'd2);
	always @(posedge clock or posedge reset)
		if (reset)
			send_count <= 3'd7;
		else if (command_state != 32'd1)
			send_count <= 3'd7;
		else if (shift_send_command_data)
			send_count <= send_count - 3'd1;
		else
			send_count <= send_count;
	always @(posedge clock or posedge reset)
		if (reset)
			enable_command_crc_ff <= 1'b0;
		else if (start_command && (command_state == 32'd0))
			enable_command_crc_ff <= enable_command_crc;
		else
			enable_command_crc_ff <= enable_command_crc_ff;
	always @(posedge clock or posedge reset)
		if (reset) begin
			command_buffer <= 48'hffffffffffff;
			send_command_to_mmc <= 8'hff;
		end
		else if (start_command && (command_state == 32'd0)) begin
			command_buffer <= command;
			send_command_to_mmc <= 8'hff;
		end
		else if (enable_command_crc_ff && (send_count == 3'd1)) begin
			command_buffer <= command_buffer;
			send_command_to_mmc <= {send_command_crc_from_mmc, 1'b1};
		end
		else if (shift_send_command_data) begin
			command_buffer <= {command_buffer[39:0], 8'hff};
			send_command_to_mmc <= command_buffer[47:40];
		end
		else begin
			command_buffer <= command_buffer;
			send_command_to_mmc <= send_command_to_mmc;
		end
	always @(posedge clock or posedge reset)
		if (reset)
			recv_count <= 5'd0;
		else if (start_command && (command_state == 32'd0))
			recv_count <= response_length;
		else if (shift_recv_response_data && (recv_count != 5'd0))
			recv_count <= recv_count - 5'd1;
		else
			recv_count <= recv_count;
	assign complete_receiving = recv_count == 5'd0;
	always @(posedge clock or posedge reset)
		if (reset)
			response <= 136'hffffffffffffffffffffffffffffffffff;
		else if (command_state != 32'd2)
			response <= response;
		else if (complete_receiving)
			response <= response;
		else if (shift_recv_response_data)
			response <= {response[127:0], received_response_from_mmc};
		else
			response <= response;
	always @(posedge clock or posedge reset)
		if (reset)
			enable_response_crc_ff <= 1'b0;
		else if (start_command && (command_state == 32'd0))
			enable_response_crc_ff <= enable_response_crc;
		else
			enable_response_crc_ff <= enable_response_crc_ff;
	always @(posedge clock or posedge reset)
		if (reset)
			recv_crc <= 8'b00000000;
		else if ((enable_response_crc_ff && shift_recv_response_data) && (recv_count != 5'd1))
			recv_crc <= {received_response_crc_from_mmc, 1'b1};
		else
			recv_crc <= recv_crc;
	always @(posedge clock or posedge reset)
		if (reset)
			response_error <= 1'b0;
		else if (reset_command_state)
			response_error <= 1'b0;
		else if (start_command && (command_state == 32'd0))
			response_error <= 1'b0;
		else if ((enable_response_crc_ff && shift_recv_response_data) && (recv_count == 5'd0)) begin
			if (recv_crc != received_response_from_mmc)
				response_error <= 1'b1;
			else
				response_error <= 1'b0;
		end
		else
			response_error <= response_error;
	assign command_busy = command_state != 32'd0;
endmodule
