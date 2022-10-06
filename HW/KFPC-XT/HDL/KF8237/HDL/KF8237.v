`default_nettype none

module KF8237 (
	input		wire					clock,
	input		wire					cpu_clock,
	input		wire					reset,
	input		wire					chip_select_n,
	input		wire					ready,
	input		wire					hold_acknowledge,
	input		wire	[3:0] 		dma_request,
	input		wire	[7:0] 		data_bus_in,
	output	reg	[7:0] 		data_bus_out,
	input		wire					io_read_n_in,
	output	wire					io_read_n_out,
	output	wire					io_read_n_io,
	input		wire					io_write_n_in,
	output	wire					io_write_n_out,
	output	wire					io_write_n_io,
	input		wire					end_of_process_n_in,
	output	wire					end_of_process_n_out,
	input		wire	[3:0] 		address_in,
	output	wire	[15:0] 		address_out,
	output	wire					output_highst_address,
	output	wire					hold_request,
	output	wire	[3:0] 		dma_acknowledge,
	output	wire					address_enable,
	output	wire					address_strobe,
	output	wire					memory_read_n,
	output	wire					memory_write_n
	);

	reg prev_cpu_clock;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_cpu_clock <= 1'b0;
		else
			prev_cpu_clock <= cpu_clock;
	wire cpu_clock_posedge = ~prev_cpu_clock & cpu_clock;
	wire cpu_clock_negedge = prev_cpu_clock & ~cpu_clock;
	wire lock_bus_control;
	wire [7:0] internal_data_bus;
	wire write_command_register;
	wire write_mode_register;
	wire write_request_register;
	wire set_or_reset_mask_register;
	wire write_mask_register;
	wire [3:0] write_base_and_current_address;
	wire [3:0] write_base_and_current_word_count;
	wire clear_byte_pointer;
	wire set_byte_pointer;
	wire master_clear;
	wire clear_mask_register;
	wire read_temporary_register;
	wire read_status_register;
	wire [3:0] read_current_address;
	wire [3:0] read_current_word_count;
	KF8237_Bus_Control_Logic u_Bus_Control_Logic(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.io_read_n_in(io_read_n_in),
		.io_write_n_in(io_write_n_in),
		.address_in(address_in),
		.data_bus_in(data_bus_in),
		.lock_bus_control(lock_bus_control),
		.internal_data_bus(internal_data_bus),
		.write_command_register(write_command_register),
		.write_mode_register(write_mode_register),
		.write_request_register(write_request_register),
		.set_or_reset_mask_register(set_or_reset_mask_register),
		.write_mask_register(write_mask_register),
		.write_base_and_current_address(write_base_and_current_address),
		.write_base_and_current_word_count(write_base_and_current_word_count),
		.clear_byte_pointer(clear_byte_pointer),
		.set_byte_pointer(set_byte_pointer),
		.master_clear(master_clear),
		.clear_mask_register(clear_mask_register),
		.read_temporary_register(read_temporary_register),
		.read_status_register(read_status_register),
		.read_current_address(read_current_address),
		.read_current_word_count(read_current_word_count)
	);
	wire [1:0] dma_rotate;
	wire [3:0] edge_request;
	wire [3:0] dma_request_state;
	wire [3:0] encoded_dma;
	wire end_of_process_internal;
	wire [3:0] dma_acknowledge_internal;
	KF8237_Priority_Encoder u_Priority_Encoder(
		.clock(clock),
		.cpu_clock_posedge(cpu_clock_posedge),
		.cpu_clock_negedge(cpu_clock_negedge),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_command_register(write_command_register),
		.write_request_register(write_request_register),
		.set_or_reset_mask_register(set_or_reset_mask_register),
		.write_mask_register(write_mask_register),
		.master_clear(master_clear),
		.clear_mask_register(clear_mask_register),
		.dma_rotate(dma_rotate),
		.edge_request(edge_request),
		.dma_request_state(dma_request_state),
		.encoded_dma(encoded_dma),
		.end_of_process_internal(end_of_process_internal),
		.dma_acknowledge_internal(dma_acknowledge_internal),
		.dma_request(dma_request)
	);
	wire [7:0] read_address_or_count;
	wire [3:0] transfer_register_select;
	wire initialize_current_register;
	wire address_hold_config;
	wire decrement_address_config;
	wire next_word;
	wire update_high_address;
	wire underflow;
	KF8237_Address_And_Count_Registers u_Address_And_Count_Registers(
		.clock(clock),
		.cpu_clock_posedge(cpu_clock_posedge),
		.cpu_clock_negedge(cpu_clock_negedge),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.read_address_or_count(read_address_or_count),
		.write_base_and_current_address(write_base_and_current_address),
		.write_base_and_current_word_count(write_base_and_current_word_count),
		.clear_byte_pointer(clear_byte_pointer),
		.set_byte_pointer(set_byte_pointer),
		.master_clear(master_clear),
		.read_current_address(read_current_address),
		.read_current_word_count(read_current_word_count),
		.transfer_register_select(transfer_register_select),
		.initialize_current_register(initialize_current_register),
		.address_hold_config(address_hold_config),
		.decrement_address_config(decrement_address_config),
		.next_word(next_word),
		.update_high_address(update_high_address),
		.underflow(underflow),
		.transfer_address(address_out)
	);
	wire output_temporary_data;
	wire [7:0] temporary_register;
	wire [3:0] terminal_count_state;
	KF8237_Timing_And_Control u_Timing_And_Control(
		.clock(clock),
		.cpu_clock_posedge(cpu_clock_posedge),
		.cpu_clock_negedge(cpu_clock_negedge),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_command_register(write_command_register),
		.write_mode_register(write_mode_register),
		.read_status_register(read_status_register),
		.master_clear(master_clear),
		.dma_rotate(dma_rotate),
		.edge_request(edge_request),
		.dma_request_state(dma_request_state),
		.encoded_dma(encoded_dma),
		.dma_acknowledge_internal(dma_acknowledge_internal),
		.transfer_register_select(transfer_register_select),
		.initialize_current_register(initialize_current_register),
		.address_hold_config(address_hold_config),
		.decrement_address_config(decrement_address_config),
		.next_word(next_word),
		.update_high_address(update_high_address),
		.underflow(underflow),
		.end_of_process_internal(end_of_process_internal),
		.lock_bus_control(lock_bus_control),
		.output_temporary_data(output_temporary_data),
		.temporary_register(temporary_register),
		.terminal_count_state(terminal_count_state),
		.hold_request(hold_request),
		.hold_acknowledge(hold_acknowledge),
		.dma_acknowledge(dma_acknowledge),
		.address_enable(address_enable),
		.address_strobe(address_strobe),
		.output_highst_address(output_highst_address),
		.memory_read_n(memory_read_n),
		.memory_write_n(memory_write_n),
		.io_read_n_out(io_read_n_out),
		.io_read_n_io(io_read_n_io),
		.io_write_n_out(io_write_n_out),
		.io_write_n_io(io_write_n_io),
		.ready(ready),
		.end_of_process_n_in(end_of_process_n_in),
		.end_of_process_n_out(end_of_process_n_out)
	);
	always @(*)
		if (output_highst_address)
			data_bus_out = address_out[15:8];
		else if (read_temporary_register || output_temporary_data)
			data_bus_out = temporary_register;
		else if (read_status_register)
			data_bus_out = {dma_request_state, terminal_count_state};
		else if ((0 != read_current_address) || (0 != read_current_word_count))
			data_bus_out = read_address_or_count;
		else
			data_bus_out = 8'h00;
endmodule
