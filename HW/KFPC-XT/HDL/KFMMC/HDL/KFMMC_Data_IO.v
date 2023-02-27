//
// KFMMC_Data_IO
// Written by kitune-san
//
`default_nettype none

module KFMMC_Data_IO (
	input wire clock,
	input wire reset,
	input wire disable_data_io,
	input wire start_data_io,
	input wire check_data_start_bit,
	input wire clear_data_crc,
	input wire data_io,
	input wire [7:0] transmit_data,
	output wire data_io_busy,
	output reg [7:0] received_data,
	output reg start_communication_to_mmc,
	output reg data_io_to_mmc,
	output reg check_data_start_bit_to_mmc,
	output reg read_continuous_data_to_mmc,
	output reg clear_data_crc_to_mmc,
	output reg clear_data_interrupt_to_mmc,
	output reg mask_data_interrupt_to_mmc,
	output reg set_send_data_to_mmc,
	output reg [7:0] send_data_to_mmc,
	input wire [7:0] received_data_from_mmc,
	input wire mmc_is_in_connecting,
	input wire sent_data_interrupt_from_mmc,
	input wire received_data_interrupt_from_mmc
);

	reg [31:0] data_io_state;
	reg [31:0] next_data_io_state;
	wire idle_mode;
	reg ready_to_communicate;
	reg check_data_start_bit_ff;
	reg clear_data_crc_ff;
	always @(*) begin
		next_data_io_state = data_io_state;
		if (disable_data_io)
			next_data_io_state = 32'd0;
		else
			case (data_io_state)
				32'd0:
					if (start_data_io)
						if (data_io)
							next_data_io_state = 32'd2;
						else
							next_data_io_state = 32'd1;
				32'd1:
					if (~ready_to_communicate && sent_data_interrupt_from_mmc)
						next_data_io_state = 32'd0;
				32'd2:
					if (~ready_to_communicate && received_data_interrupt_from_mmc)
						next_data_io_state = 32'd0;
			endcase
	end
	always @(posedge clock or posedge reset)
		if (reset)
			data_io_state <= 32'd0;
		else
			data_io_state <= next_data_io_state;
	always @(posedge clock or posedge reset)
		if (reset) begin
			start_communication_to_mmc <= 1'b0;
			data_io_to_mmc <= 1'b1;
			check_data_start_bit_to_mmc <= 1'b0;
			read_continuous_data_to_mmc <= 1'b0;
			clear_data_crc_to_mmc <= 1'b0;
			clear_data_interrupt_to_mmc <= 1'b0;
			mask_data_interrupt_to_mmc <= 1'b0;
			set_send_data_to_mmc <= 1'b0;
		end
		else if (disable_data_io) begin
			start_communication_to_mmc <= 1'b0;
			data_io_to_mmc <= 1'b1;
			check_data_start_bit_to_mmc <= 1'b0;
			read_continuous_data_to_mmc <= 1'b0;
			clear_data_crc_to_mmc <= 1'b0;
			clear_data_interrupt_to_mmc <= 1'b0;
			mask_data_interrupt_to_mmc <= 1'b1;
			set_send_data_to_mmc <= 1'b0;
		end
		else
			case (data_io_state)
				32'd0: begin
					start_communication_to_mmc <= 1'b0;
					data_io_to_mmc <= 1'b1;
					check_data_start_bit_to_mmc <= 1'b0;
					read_continuous_data_to_mmc <= 1'b0;
					clear_data_crc_to_mmc <= 1'b0;
					clear_data_interrupt_to_mmc <= 1'b0;
					mask_data_interrupt_to_mmc <= 1'b0;
					set_send_data_to_mmc <= 1'b0;
				end
				32'd1:
					if (~mmc_is_in_connecting && ready_to_communicate) begin
						start_communication_to_mmc <= 1'b1;
						data_io_to_mmc <= 1'b0;
						check_data_start_bit_to_mmc <= 1'b0;
						read_continuous_data_to_mmc <= 1'b0;
						clear_data_crc_to_mmc <= clear_data_crc_ff;
						clear_data_interrupt_to_mmc <= 1'b1;
						mask_data_interrupt_to_mmc <= 1'b0;
						set_send_data_to_mmc <= 1'b1;
					end
					else begin
						start_communication_to_mmc <= 1'b0;
						data_io_to_mmc <= 1'b0;
						check_data_start_bit_to_mmc <= 1'b0;
						read_continuous_data_to_mmc <= 1'b0;
						clear_data_crc_to_mmc <= 1'b0;
						clear_data_interrupt_to_mmc <= 1'b0;
						mask_data_interrupt_to_mmc <= 1'b0;
						set_send_data_to_mmc <= 1'b0;
					end
				32'd2:
					if (~mmc_is_in_connecting && ready_to_communicate) begin
						start_communication_to_mmc <= 1'b1;
						data_io_to_mmc <= 1'b1;
						check_data_start_bit_to_mmc <= check_data_start_bit_ff;
						read_continuous_data_to_mmc <= ~check_data_start_bit_ff;
						clear_data_crc_to_mmc <= clear_data_crc_ff;
						clear_data_interrupt_to_mmc <= 1'b1;
						mask_data_interrupt_to_mmc <= 1'b0;
						set_send_data_to_mmc <= 1'b0;
					end
					else begin
						start_communication_to_mmc <= 1'b0;
						data_io_to_mmc <= 1'b1;
						check_data_start_bit_to_mmc <= 1'b0;
						read_continuous_data_to_mmc <= 1'b0;
						clear_data_crc_to_mmc <= 1'b0;
						clear_data_interrupt_to_mmc <= 1'b0;
						mask_data_interrupt_to_mmc <= 1'b0;
						set_send_data_to_mmc <= 1'b0;
					end
			endcase
	assign idle_mode = (data_io_state == 32'd0) || disable_data_io;
	always @(posedge clock or posedge reset)
		if (reset)
			ready_to_communicate <= 1'b0;
		else if (idle_mode)
			ready_to_communicate <= 1'b1;
		else if (mmc_is_in_connecting && start_communication_to_mmc)
			ready_to_communicate <= 1'b0;
		else
			ready_to_communicate <= ready_to_communicate;
	always @(posedge clock or posedge reset)
		if (reset)
			check_data_start_bit_ff <= 1'b0;
		else if (idle_mode)
			check_data_start_bit_ff <= check_data_start_bit;
		else
			check_data_start_bit_ff <= check_data_start_bit_ff;
	always @(posedge clock or posedge reset)
		if (reset)
			clear_data_crc_ff <= 1'b0;
		else if (idle_mode)
			clear_data_crc_ff <= clear_data_crc;
		else
			clear_data_crc_ff <= clear_data_crc_ff;
	always @(posedge clock or posedge reset)
		if (reset)
			send_data_to_mmc <= 8'h00;
		else if (idle_mode)
			send_data_to_mmc <= transmit_data;
		else
			send_data_to_mmc <= send_data_to_mmc;
	always @(posedge clock or posedge reset)
		if (reset)
			received_data <= 8'h00;
		else if (data_io_state == 32'd2)
			received_data <= received_data_from_mmc;
		else
			received_data <= received_data;
	assign data_io_busy = data_io_state != 32'd0;
endmodule
