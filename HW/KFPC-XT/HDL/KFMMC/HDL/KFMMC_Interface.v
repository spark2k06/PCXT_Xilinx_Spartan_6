//
// KFMMC_Interface
// Access to MMC
//
// Written by kitune-san
//
`default_nettype none

module KFMMC_Interface #(
    parameter timeout = 32'hFFFFFFFF
) (
	input wire clock,
	input wire reset,
	input wire start_communication,
	input wire command_io,
	input wire data_io,
	input wire check_command_start_bit,
	input wire check_data_start_bit,
	input wire read_continuous_data,
	input wire clear_command_crc,
	input wire clear_data_crc,
	input wire clear_command_interrupt,
	input wire clear_data_interrupt,
	input wire mask_command_interrupt,
	input wire mask_data_interrupt,
	input wire set_send_command,
	input wire [7:0] send_command,
	input wire set_send_data,
	input wire [7:0] send_data,
	output wire [7:0] received_response,
	output reg [6:0] send_command_crc,
	output reg [6:0] received_response_crc,
	output wire [7:0] received_data,
	output reg [15:0] send_data_crc,
	output reg [15:0] received_data_crc,
	output wire in_connecting,
	output reg sent_command_interrupt,
	output reg received_response_interrupt,
	output reg sent_data_interrupt,
	output reg received_data_interrupt,
	output reg timeout_interrupt,
	input wire [7:0] mmc_clock_cycle,
	output reg mmc_clk,
	input wire mmc_cmd_in,
	output reg mmc_cmd_out,
	output reg mmc_cmd_io,
	input wire mmc_dat_in,
	output reg mmc_dat_out,
	output reg mmc_dat_io
);

	reg [7:0] clk_cycle_counter;
	wire edge_mmc_clk;
	wire sample_edge;
	wire shift_edge;
	reg detect_command_start_bit;
	reg [3:0] command_bit_count;
	reg [8:0] rx_cmd_register;
	reg [7:0] tx_cmd_register;
	reg detect_data_start_bit;
	reg [3:0] data_bit_count;
	reg [8:0] rx_data_register;
	reg [7:0] tx_data_register;
	reg [31:0] timeout_counter;
	reg mask_command_interrupt_ff;
	reg mask_data_interrupt_ff;
	wire disable_access;
	wire access_flag;
	function [6:0] crc_7;
		input data_in;
		input [6:0] prev_crc;
		begin
			crc_7[0] = prev_crc[6] ^ data_in;
			crc_7[1] = prev_crc[0];
			crc_7[2] = prev_crc[1];
			crc_7[3] = prev_crc[2] ^ (prev_crc[6] ^ data_in);
			crc_7[4] = prev_crc[3];
			crc_7[5] = prev_crc[4];
			crc_7[6] = prev_crc[5];
		end
	endfunction
	function [15:0] crc_16;
		input data_in;
		input [15:0] prev_crc;
		begin
			crc_16[0] = prev_crc[15] ^ data_in;
			crc_16[1] = prev_crc[0];
			crc_16[2] = prev_crc[1];
			crc_16[3] = prev_crc[2];
			crc_16[4] = prev_crc[3];
			crc_16[5] = prev_crc[4] ^ (prev_crc[15] ^ data_in);
			crc_16[6] = prev_crc[5];
			crc_16[7] = prev_crc[6];
			crc_16[8] = prev_crc[7];
			crc_16[9] = prev_crc[8];
			crc_16[10] = prev_crc[9];
			crc_16[11] = prev_crc[10];
			crc_16[12] = prev_crc[11] ^ (prev_crc[15] ^ data_in);
			crc_16[13] = prev_crc[12];
			crc_16[14] = prev_crc[13];
			crc_16[15] = prev_crc[14];
		end
	endfunction
	always @(posedge clock or posedge reset)
		if (reset)
			clk_cycle_counter <= 8'd1;
		else if (access_flag) begin
			if (edge_mmc_clk)
				clk_cycle_counter <= 8'd1;
			else
				clk_cycle_counter <= clk_cycle_counter + 8'd1;
		end
		else
			clk_cycle_counter <= 8'd1;
	always @(posedge clock or posedge reset)
		if (reset)
			mmc_clk <= 1'b0;
		else if (access_flag) begin
			if (edge_mmc_clk)
				mmc_clk <= ~mmc_clk;
			else
				mmc_clk <= mmc_clk;
		end
		else
			mmc_clk <= 1'b0;
	assign edge_mmc_clk = (clk_cycle_counter == {1'b0, mmc_clock_cycle[7:1]}) & access_flag;
	assign sample_edge = edge_mmc_clk & (mmc_clk == 1'b0);
	assign shift_edge = edge_mmc_clk & (mmc_clk == 1'b1);
	always @(posedge clock or posedge reset)
		if (reset)
			mmc_cmd_io <= 1'b1;
		else if (start_communication)
			mmc_cmd_io <= command_io;
		else
			mmc_cmd_io <= mmc_cmd_io;
	always @(posedge clock or posedge reset)
		if (reset)
			detect_command_start_bit <= 1'b0;
		else if (start_communication) begin
			if (mmc_cmd_io != command_io)
				detect_command_start_bit <= 1'b0;
			else if ((command_io == 1'b1) && check_command_start_bit)
				detect_command_start_bit <= 1'b0;
			else
				detect_command_start_bit <= detect_command_start_bit;
		end
		else if (((mmc_cmd_io == 1'b1) && sample_edge) && ~mmc_cmd_in)
			detect_command_start_bit <= 1'b1;
		else
			detect_command_start_bit <= detect_command_start_bit;
	always @(posedge clock or posedge reset)
		if (reset)
			command_bit_count <= 4'd0;
		else if (start_communication) begin
			if (mmc_cmd_io != command_io)
				command_bit_count <= 4'd0;
			else if ((command_io == 1'b1) && check_command_start_bit)
				command_bit_count <= 4'd0;
			else if ((command_io == 1'b0) && set_send_command)
				command_bit_count <= 4'd0;
			else if (command_bit_count == 4'd8)
				command_bit_count <= 4'd0;
			else
				command_bit_count <= command_bit_count;
		end
		else if (mmc_cmd_io == 1'b1) begin
			if (sample_edge && detect_command_start_bit)
				command_bit_count <= command_bit_count + 4'd1;
			else if (sample_edge && ~mmc_cmd_in)
				command_bit_count <= 4'd1;
			else
				command_bit_count <= command_bit_count;
		end
		else if (sample_edge)
			command_bit_count <= command_bit_count + 4'd1;
		else
			command_bit_count <= command_bit_count;
	always @(posedge clock or posedge reset)
		if (reset)
			rx_cmd_register <= 9'h000;
		else if (sample_edge)
			rx_cmd_register <= {rx_cmd_register[8:1], mmc_cmd_in};
		else if (shift_edge)
			rx_cmd_register <= {rx_cmd_register[7:0], 1'b0};
		else
			rx_cmd_register <= rx_cmd_register;
	assign received_response = rx_cmd_register[8:1];
	always @(posedge clock or posedge reset)
		if (reset)
			tx_cmd_register <= 8'h00;
		else if (start_communication && set_send_command)
			tx_cmd_register <= send_command;
		else if (shift_edge)
			tx_cmd_register <= {tx_cmd_register[6:0], 1'b1};
		else
			tx_cmd_register <= tx_cmd_register;
	always @(*)
		if (mmc_cmd_io == 1'b1)
			mmc_cmd_out = 1'b1;
		else
			mmc_cmd_out = tx_cmd_register[7];
	always @(posedge clock or posedge reset)
		if (reset)
			sent_command_interrupt <= 1'b0;
		else if (mmc_cmd_io == 1'b1)
			sent_command_interrupt <= 1'b0;
		else if (start_communication && clear_command_interrupt)
			sent_command_interrupt <= 1'b0;
		else if ((command_bit_count == 4'd8) && shift_edge)
			sent_command_interrupt <= 1'b1;
		else
			sent_command_interrupt <= sent_command_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			received_response_interrupt <= 1'b0;
		else if (mmc_cmd_io == 1'b0)
			received_response_interrupt <= 1'b0;
		else if (start_communication && clear_command_interrupt)
			received_response_interrupt <= 1'b0;
		else if ((command_bit_count == 4'd8) && shift_edge)
			received_response_interrupt <= 1'b1;
		else
			received_response_interrupt <= received_response_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			send_command_crc <= 7'b0000000;
		else if (clear_command_crc)
			send_command_crc <= 7'b0000000;
		else if (mmc_cmd_io == 1'b1)
			send_command_crc <= 7'b0000000;
		else if (sample_edge)
			send_command_crc <= crc_7(tx_cmd_register[7], send_command_crc);
		else
			send_command_crc <= send_command_crc;
	always @(posedge clock or posedge reset)
		if (reset)
			received_response_crc <= 7'b0000000;
		else if (clear_command_crc)
			received_response_crc <= 7'b0000000;
		else if (mmc_cmd_io == 1'b0)
			received_response_crc <= 7'b0000000;
		else if (sample_edge && detect_command_start_bit)
			received_response_crc <= crc_7(mmc_cmd_in, received_response_crc);
		else
			received_response_crc <= received_response_crc;
	always @(posedge clock or posedge reset)
		if (reset)
			mmc_dat_io <= 1'b1;
		else if (start_communication)
			mmc_dat_io <= data_io;
		else
			mmc_dat_io <= mmc_dat_io;
	always @(posedge clock or posedge reset)
		if (reset)
			detect_data_start_bit <= 1'b0;
		else if (start_communication) begin
			if (mmc_dat_io != data_io)
				detect_data_start_bit <= 1'b0;
			else if ((data_io == 1'b1) && check_data_start_bit)
				detect_data_start_bit <= 1'b0;
			else if ((data_io == 1'b1) && read_continuous_data)
				detect_data_start_bit <= 1'b1;
			else
				detect_data_start_bit <= detect_data_start_bit;
		end
		else if (((mmc_dat_io == 1'b1) && sample_edge) && ~mmc_dat_in)
			detect_data_start_bit <= 1'b1;
		else
			detect_data_start_bit <= detect_data_start_bit;
	always @(posedge clock or posedge reset)
		if (reset)
			data_bit_count <= 4'd0;
		else if (start_communication) begin
			if (mmc_dat_io != data_io)
				data_bit_count <= 4'd0;
			else if ((data_io == 1'b1) && check_data_start_bit)
				data_bit_count <= 4'd0;
			else if ((data_io == 1'b0) && set_send_data)
				data_bit_count <= 4'd0;
			else if (data_bit_count == 4'd8)
				data_bit_count <= 4'd0;
			else
				data_bit_count <= data_bit_count;
		end
		else if (mmc_dat_io == 1'b1) begin
			if (sample_edge && detect_data_start_bit)
				data_bit_count <= data_bit_count + 4'd1;
			else if (sample_edge && mmc_dat_in)
				data_bit_count <= 4'd0;
			else
				data_bit_count <= data_bit_count;
		end
		else if (sample_edge)
			data_bit_count <= data_bit_count + 4'd1;
		else
			data_bit_count <= data_bit_count;
	always @(posedge clock or posedge reset)
		if (reset)
			rx_data_register <= 9'h000;
		else if (sample_edge)
			rx_data_register <= {rx_data_register[8:1], mmc_dat_in};
		else if (shift_edge)
			rx_data_register <= {rx_data_register[7:0], 1'b0};
		else
			rx_data_register <= rx_data_register;
	assign received_data = rx_data_register[8:1];
	always @(posedge clock or posedge reset)
		if (reset)
			tx_data_register <= 8'h00;
		else if (start_communication && set_send_data)
			tx_data_register <= send_data;
		else if (shift_edge)
			tx_data_register <= {tx_data_register[6:0], 1'b1};
		else
			tx_data_register <= tx_data_register;
	always @(*)
		if (mmc_dat_io == 1'b1)
			mmc_dat_out = 1'b1;
		else
			mmc_dat_out = tx_data_register[7];
	always @(posedge clock or posedge reset)
		if (reset)
			sent_data_interrupt <= 1'b0;
		else if (mmc_dat_io == 1'b1)
			sent_data_interrupt <= 1'b0;
		else if (start_communication && clear_data_interrupt)
			sent_data_interrupt <= 1'b0;
		else if ((data_bit_count == 4'd8) && shift_edge)
			sent_data_interrupt <= 1'b1;
		else
			sent_data_interrupt <= sent_data_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			received_data_interrupt <= 1'b0;
		else if (mmc_dat_io == 1'b0)
			received_data_interrupt <= 1'b0;
		else if (start_communication && clear_data_interrupt)
			received_data_interrupt <= 1'b0;
		else if ((data_bit_count == 4'd8) && shift_edge)
			received_data_interrupt <= 1'b1;
		else
			received_data_interrupt <= received_data_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			send_data_crc <= 16'h0000;
		else if (clear_data_crc)
			send_data_crc <= 16'h0000;
		else if (mmc_dat_io == 1'b1)
			send_data_crc <= 16'h0000;
		else if (sample_edge)
			send_data_crc <= crc_16(tx_data_register[7], send_data_crc);
		else
			send_data_crc <= send_data_crc;
	always @(posedge clock or posedge reset)
		if (reset)
			received_data_crc <= 16'h0000;
		else if (clear_data_crc)
			received_data_crc <= 16'h0000;
		else if (mmc_dat_io == 1'b0)
			received_data_crc <= 16'h0000;
		else if (sample_edge && detect_data_start_bit)
			received_data_crc <= crc_16(mmc_dat_in, received_data_crc);
		else
			received_data_crc <= received_data_crc;
	always @(posedge clock or posedge reset)
		if (reset)
			timeout_counter <= timeout;
		else if (start_communication)
			timeout_counter <= timeout;
		else if ((timeout_counter != 32'h00000000) && sample_edge)
			timeout_counter <= timeout_counter - 32'h00000001;
		else
			timeout_counter <= timeout_counter;
	always @(posedge clock or posedge reset)
		if (reset)
			timeout_interrupt <= 1'b1;
		else if (start_communication)
			timeout_interrupt <= 1'b0;
		else if ((timeout_counter == 32'h00000000) && shift_edge)
			timeout_interrupt <= 1'b1;
		else
			timeout_interrupt <= timeout_interrupt;
	always @(posedge clock or posedge reset)
		if (reset) begin
			mask_command_interrupt_ff <= 1'b0;
			mask_data_interrupt_ff <= 1'b0;
		end
		else if (~access_flag || shift_edge) begin
			mask_command_interrupt_ff <= mask_command_interrupt;
			mask_data_interrupt_ff <= mask_data_interrupt;
		end
		else begin
			mask_command_interrupt_ff <= mask_command_interrupt_ff;
			mask_data_interrupt_ff <= mask_data_interrupt_ff;
		end
	assign disable_access = ((mask_command_interrupt_ff & mask_command_interrupt_ff) & mask_data_interrupt_ff) & mask_data_interrupt_ff;
	assign in_connecting = ~((((((sent_command_interrupt & ~mask_command_interrupt_ff) | (received_response_interrupt & ~mask_command_interrupt_ff)) | (sent_data_interrupt & ~mask_data_interrupt_ff)) | (received_data_interrupt & ~mask_data_interrupt_ff)) | timeout_interrupt) | disable_access);
	assign access_flag = (in_connecting & ~start_communication) & ~disable_access;
endmodule
