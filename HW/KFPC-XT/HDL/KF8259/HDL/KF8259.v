`default_nettype none

module KF8259 (
	input		wire					clock,
	input		wire					reset,
	input		wire					chip_select_n,
	input		wire					read_enable_n,
	input		wire					write_enable_n,
	input		wire					address,
	input		wire	[7:0]			data_bus_in,
	output	reg	[7:0]			data_bus_out,
	output	reg					data_bus_io,
	input		wire	[2:0]			cascade_in,
	output	wire	[2:0]			cascade_out,
	output	wire					cascade_io,
	input		wire					slave_program_n,
	output	wire					buffer_enable,
	output	wire					slave_program_or_enable_buffer,
	input		wire					interrupt_acknowledge_n,
	output	wire					interrupt_to_cpu,
	input		wire	[7:0]			interrupt_request
	);

	wire [7:0] internal_data_bus;
	wire write_initial_command_word_1;
	wire write_initial_command_word_2_4;
	wire write_operation_control_word_1;
	wire write_operation_control_word_2;
	wire write_operation_control_word_3;
	wire read;
	KF8259_Bus_Control_Logic u_Bus_Control_Logic(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.read_enable_n(read_enable_n),
		.write_enable_n(write_enable_n),
		.address(address),
		.data_bus_in(data_bus_in),
		.internal_data_bus(internal_data_bus),
		.write_initial_command_word_1(write_initial_command_word_1),
		.write_initial_command_word_2_4(write_initial_command_word_2_4),
		.write_operation_control_word_1(write_operation_control_word_1),
		.write_operation_control_word_2(write_operation_control_word_2),
		.write_operation_control_word_3(write_operation_control_word_3),
		.read(read)
	);
	wire out_control_logic_data;
	wire [7:0] control_logic_data;
	wire level_or_edge_toriggered_config;
	wire special_fully_nest_config;
	wire enable_read_register;
	wire read_register_isr_or_irr;
	wire [7:0] interrupt;
	wire [7:0] highest_level_in_service;
	wire [7:0] interrupt_mask;
	wire [7:0] interrupt_special_mask;
	wire [7:0] end_of_interrupt;
	wire [2:0] priority_rotate;
	wire freeze;
	wire latch_in_service;
	wire [7:0] clear_interrupt_request;
	KF8259_Control_Logic u_Control_Logic(
		.clock(clock),
		.reset(reset),
		.cascade_in(cascade_in),
		.cascade_out(cascade_out),
		.cascade_io(cascade_io),
		.slave_program_n(slave_program_n),
		.slave_program_or_enable_buffer(slave_program_or_enable_buffer),
		.interrupt_acknowledge_n(interrupt_acknowledge_n),
		.interrupt_to_cpu(interrupt_to_cpu),
		.internal_data_bus(internal_data_bus),
		.write_initial_command_word_1(write_initial_command_word_1),
		.write_initial_command_word_2_4(write_initial_command_word_2_4),
		.write_operation_control_word_1(write_operation_control_word_1),
		.write_operation_control_word_2(write_operation_control_word_2),
		.write_operation_control_word_3(write_operation_control_word_3),
		.read(read),
		.out_control_logic_data(out_control_logic_data),
		.control_logic_data(control_logic_data),
		.level_or_edge_toriggered_config(level_or_edge_toriggered_config),
		.special_fully_nest_config(special_fully_nest_config),
		.enable_read_register(enable_read_register),
		.read_register_isr_or_irr(read_register_isr_or_irr),
		.interrupt(interrupt),
		.highest_level_in_service(highest_level_in_service),
		.interrupt_mask(interrupt_mask),
		.interrupt_special_mask(interrupt_special_mask),
		.end_of_interrupt(end_of_interrupt),
		.priority_rotate(priority_rotate),
		.freeze(freeze),
		.latch_in_service(latch_in_service),
		.clear_interrupt_request(clear_interrupt_request)
	);
	wire [7:0] interrupt_request_register;
	KF8259_Interrupt_Request u_Interrupt_Request(
		.clock(clock),
		.reset(reset),
		.level_or_edge_toriggered_config(level_or_edge_toriggered_config),
		.freeze(freeze),
		.clear_interrupt_request(clear_interrupt_request),
		.interrupt_request_pin(interrupt_request),
		.interrupt_request_register(interrupt_request_register)
	);
	wire [7:0] in_service_register;
	KF8259_Priority_Resolver u_Priority_Resolver(
		.priority_rotate(priority_rotate),
		.interrupt_mask(interrupt_mask),
		.interrupt_special_mask(interrupt_special_mask),
		.special_fully_nest_config(special_fully_nest_config),
		.highest_level_in_service(highest_level_in_service),
		.interrupt_request_register(interrupt_request_register),
		.in_service_register(in_service_register),
		.interrupt(interrupt)
	);
	KF8259_In_Service u_In_Service(
		.clock(clock),
		.reset(reset),
		.priority_rotate(priority_rotate),
		.interrupt_special_mask(interrupt_special_mask),
		.interrupt(interrupt),
		.latch_in_service(latch_in_service),
		.end_of_interrupt(end_of_interrupt),
		.in_service_register(in_service_register),
		.highest_level_in_service(highest_level_in_service)
	);
	always @(*)
		if (out_control_logic_data == 1'b1) begin
			data_bus_io = 1'b0;
			data_bus_out = control_logic_data;
		end
		else if (read == 1'b0) begin
			data_bus_io = 1'b1;
			data_bus_out = 8'b00000000;
		end
		else if (address == 1'b1) begin
			data_bus_io = 1'b0;
			data_bus_out = interrupt_mask;
		end
		else if ((enable_read_register == 1'b1) && (read_register_isr_or_irr == 1'b0)) begin
			data_bus_io = 1'b0;
			data_bus_out = interrupt_request_register;
		end
		else if ((enable_read_register == 1'b1) && (read_register_isr_or_irr == 1'b1)) begin
			data_bus_io = 1'b0;
			data_bus_out = in_service_register;
		end
		else begin
			data_bus_io = 1'b1;
			data_bus_out = 8'b00000000;
		end
	assign buffer_enable = (slave_program_or_enable_buffer == 1'b1 ? 1'b0 : ~data_bus_io);
endmodule
