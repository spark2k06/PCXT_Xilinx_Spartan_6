//
// KFMMC_Drive
// Written by kitune-san
//
`default_nettype none

module KFMMC_Drive #(
    parameter init_spi_clock_cycle = 8'd010,
    parameter normal_spi_clock_cycle = 8'd002,
    parameter timeout = 32'hFFFFFFFF
) (
	input wire clock,
	input wire reset,
	input wire [7:0] data_bus,
	input wire [24:0] data_bus_extension,
	input wire write_block_address_1,
	input wire write_block_address_2,
	input wire write_block_address_3,
	input wire write_block_address_4,
	input wire write_block_address_extension,
	input wire write_access_command,
	input wire write_data,
	output wire [7:0] read_data_byte,
	input wire read_data,
	output wire drive_busy,
	output wire [39:0] storage_size,
	output wire read_interface_error,
	output wire read_crc_error,
	output wire write_interface_error,
	output wire read_byte_interrupt,
	output wire read_completion_interrupt,
	output wire request_write_data_interrupt,
	output wire write_completion_interrupt,
	output wire mmc_clk,
	input wire mmc_cmd_in,
	output wire mmc_cmd_out,
	output wire mmc_cmd_io,
	input wire mmc_dat_in,
	output wire mmc_dat_out,
	output wire mmc_dat_io
);

	wire reset_command_state;
	wire start_command;
	wire [47:0] command;
	wire enable_command_crc;
	wire enable_response_crc;
	wire [4:0] response_length;
	wire command_busy;
	wire [135:0] response;
	wire response_error;
	wire disable_data_io;
	wire start_data_io;
	wire check_data_start_bit;
	wire clear_data_crc;
	wire data_io;
	wire [7:0] transmit_data;
	wire data_io_busy;
	wire [7:0] received_data;
	wire [7:0] mmc_clock_cycle;
	wire [15:0] send_data_crc;
	wire [15:0] received_data_crc;
	wire timeout_interrupt;
	KFMMC_Controller #(
		.init_spi_clock_cycle(init_spi_clock_cycle),
		.normal_spi_clock_cycle(normal_spi_clock_cycle)
	) u_KFMMC_Controller(
		.clock(clock),
		.reset(reset),
		.data_bus(data_bus),
		.data_bus_extension(data_bus_extension),
		.write_block_address_1(write_block_address_1),
		.write_block_address_2(write_block_address_2),
		.write_block_address_3(write_block_address_3),
		.write_block_address_4(write_block_address_4),
		.write_block_address_extension(write_block_address_extension),
		.write_access_command(write_access_command),
		.write_data(write_data),
		.read_data_byte(read_data_byte),
		.read_data(read_data),
		.reset_command_state(reset_command_state),
		.start_command(start_command),
		.command(command),
		.enable_command_crc(enable_command_crc),
		.enable_response_crc(enable_response_crc),
		.response_length(response_length),
		.command_busy(command_busy),
		.response(response),
		.response_error(response_error),
		.disable_data_io(disable_data_io),
		.start_data_io(start_data_io),
		.check_data_start_bit(check_data_start_bit),
		.clear_data_crc(clear_data_crc),
		.data_io(data_io),
		.transmit_data(transmit_data),
		.data_io_busy(data_io_busy),
		.received_data(received_data),
		.mmc_clock_cycle(mmc_clock_cycle),
		.send_data_crc(send_data_crc),
		.received_data_crc(received_data_crc),
		.timeout_interrupt(timeout_interrupt),
		.drive_busy(drive_busy),
		.storage_size(storage_size),
		.read_interface_error(read_interface_error),
		.read_crc_error(read_crc_error),
		.write_interface_error(write_interface_error),
		.read_byte_interrupt(read_byte_interrupt),
		.read_completion_interrupt(read_completion_interrupt),
		.request_write_data_interrupt(request_write_data_interrupt),
		.write_completion_interrupt(write_completion_interrupt)
	);
	wire start_communication_from_command_io;
	wire command_io_to_mmc;
	wire check_command_start_bit_to_mmc;
	wire clear_command_crc_to_mmc;
	wire clear_command_interrupt_to_mmc;
	wire mask_command_interrupt_to_mmc;
	wire set_send_command_to_mmc;
	wire [7:0] send_command_to_mmc;
	wire [7:0] received_response_from_mmc;
	wire [6:0] send_command_crc_from_mmc;
	wire [6:0] received_response_crc_from_mmc;
	wire mmc_is_in_connecting;
	wire sent_command_interrupt_from_mmc;
	wire received_response_interrupt_from_mmc;
	KFMMC_Command_IO u_KFMMC_Command_IO(
		.clock(clock),
		.reset(reset),
		.reset_command_state(reset_command_state),
		.start_command(start_command),
		.command(command),
		.enable_command_crc(enable_command_crc),
		.enable_response_crc(enable_response_crc),
		.response_length(response_length),
		.command_busy(command_busy),
		.response(response),
		.response_error(response_error),
		.start_communication_to_mmc(start_communication_from_command_io),
		.command_io_to_mmc(command_io_to_mmc),
		.check_command_start_bit_to_mmc(check_command_start_bit_to_mmc),
		.clear_command_crc_to_mmc(clear_command_crc_to_mmc),
		.clear_command_interrupt_to_mmc(clear_command_interrupt_to_mmc),
		.mask_command_interrupt_to_mmc(mask_command_interrupt_to_mmc),
		.set_send_command_to_mmc(set_send_command_to_mmc),
		.send_command_to_mmc(send_command_to_mmc),
		.received_response_from_mmc(received_response_from_mmc),
		.send_command_crc_from_mmc(send_command_crc_from_mmc),
		.received_response_crc_from_mmc(received_response_crc_from_mmc),
		.mmc_is_in_connecting(mmc_is_in_connecting),
		.sent_command_interrupt_from_mmc(sent_command_interrupt_from_mmc),
		.received_response_interrupt_from_mmc(received_response_interrupt_from_mmc)
	);
	wire start_communication_from_data_io;
	wire data_io_to_mmc;
	wire check_data_start_bit_to_mmc;
	wire read_continuous_data_to_mmc;
	wire clear_data_crc_to_mmc;
	wire clear_data_interrupt_to_mmc;
	wire mask_data_interrupt_to_mmc;
	wire set_send_data_to_mmc;
	wire [7:0] send_data_to_mmc;
	wire [7:0] received_data_from_mmc;
	wire sent_data_interrupt_from_mmc;
	wire received_data_interrupt_from_mmc;
	KFMMC_Data_IO u_KFMMC_Data_IO(
		.clock(clock),
		.reset(reset),
		.disable_data_io(disable_data_io),
		.start_data_io(start_data_io),
		.check_data_start_bit(check_data_start_bit),
		.clear_data_crc(clear_data_crc),
		.data_io(data_io),
		.transmit_data(transmit_data),
		.data_io_busy(data_io_busy),
		.received_data(received_data),
		.start_communication_to_mmc(start_communication_from_data_io),
		.data_io_to_mmc(data_io_to_mmc),
		.check_data_start_bit_to_mmc(check_data_start_bit_to_mmc),
		.read_continuous_data_to_mmc(read_continuous_data_to_mmc),
		.clear_data_crc_to_mmc(clear_data_crc_to_mmc),
		.clear_data_interrupt_to_mmc(clear_data_interrupt_to_mmc),
		.mask_data_interrupt_to_mmc(mask_data_interrupt_to_mmc),
		.set_send_data_to_mmc(set_send_data_to_mmc),
		.send_data_to_mmc(send_data_to_mmc),
		.received_data_from_mmc(received_data_from_mmc),
		.mmc_is_in_connecting(mmc_is_in_connecting),
		.sent_data_interrupt_from_mmc(sent_data_interrupt_from_mmc),
		.received_data_interrupt_from_mmc(received_data_interrupt_from_mmc)
	);
	wire start_communication = start_communication_from_command_io | start_communication_from_data_io;
	KFMMC_Interface #(.timeout(timeout)) u_KFMMC_Interface(
		.clock(clock),
		.reset(reset),
		.start_communication(start_communication),
		.command_io(command_io_to_mmc),
		.data_io(data_io_to_mmc),
		.check_command_start_bit(check_command_start_bit_to_mmc),
		.check_data_start_bit(check_data_start_bit_to_mmc),
		.read_continuous_data(read_continuous_data_to_mmc),
		.clear_command_crc(clear_command_crc_to_mmc),
		.clear_data_crc(clear_data_crc_to_mmc),
		.clear_command_interrupt(clear_command_interrupt_to_mmc),
		.clear_data_interrupt(clear_data_interrupt_to_mmc),
		.mask_command_interrupt(mask_command_interrupt_to_mmc),
		.mask_data_interrupt(mask_data_interrupt_to_mmc),
		.set_send_command(set_send_command_to_mmc),
		.send_command(send_command_to_mmc),
		.set_send_data(set_send_data_to_mmc),
		.send_data(send_data_to_mmc),
		.received_response(received_response_from_mmc),
		.send_command_crc(send_command_crc_from_mmc),
		.received_response_crc(received_response_crc_from_mmc),
		.received_data(received_data_from_mmc),
		.send_data_crc(send_data_crc),
		.received_data_crc(received_data_crc),
		.in_connecting(mmc_is_in_connecting),
		.sent_command_interrupt(sent_command_interrupt_from_mmc),
		.received_response_interrupt(received_response_interrupt_from_mmc),
		.sent_data_interrupt(sent_data_interrupt_from_mmc),
		.received_data_interrupt(received_data_interrupt_from_mmc),
		.timeout_interrupt(timeout_interrupt),
		.mmc_clock_cycle(mmc_clock_cycle),
		.mmc_clk(mmc_clk),
		.mmc_cmd_in(mmc_cmd_in),
		.mmc_cmd_out(mmc_cmd_out),
		.mmc_cmd_io(mmc_cmd_io),
		.mmc_dat_in(mmc_dat_in),
		.mmc_dat_out(mmc_dat_out),
		.mmc_dat_io(mmc_dat_io)
	);
endmodule
