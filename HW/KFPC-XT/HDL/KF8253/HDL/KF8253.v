`default_nettype none

module KF8253 (
	input		wire					clock,
	input		wire					reset,
	input		wire					chip_select_n,
	input		wire					read_enable_n,
	input		wire					write_enable_n,
	input		wire	[1:0]			address,
	input		wire	[7:0]			data_bus_in,
	output	reg	[7:0]			data_bus_out,
	input		wire					counter_0_clock,
	input		wire					counter_0_gate,
	output	wire					counter_0_out,
	input		wire					counter_1_clock,
	input		wire					counter_1_gate,
	output	wire					counter_1_out,
	input		wire					counter_2_clock,
	input		wire					counter_2_gate,
	output	wire					counter_2_out
	);

	wire [7:0] internal_data_bus;
	wire write_control_0;
	wire write_control_1;
	wire write_control_2;
	wire write_counter_0;
	wire write_counter_1;
	wire write_counter_2;
	wire read_counter_0;
	wire read_counter_1;
	wire read_counter_2;
	wire [7:0] read_counter_0_data;
	wire [7:0] read_counter_1_data;
	wire [7:0] read_counter_2_data;
	KF8253_Control_Logic u_KF8253_Control_Logic(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.read_enable_n(read_enable_n),
		.write_enable_n(write_enable_n),
		.address(address),
		.data_bus_in(data_bus_in),
		.internal_data_bus(internal_data_bus),
		.write_control_0(write_control_0),
		.write_control_1(write_control_1),
		.write_control_2(write_control_2),
		.write_counter_0(write_counter_0),
		.write_counter_1(write_counter_1),
		.write_counter_2(write_counter_2),
		.read_counter_0(read_counter_0),
		.read_counter_1(read_counter_1),
		.read_counter_2(read_counter_2)
	);
	KF8253_Counter u_KF8253_Counter_0(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_control(write_control_0),
		.write_counter(write_counter_0),
		.read_counter(read_counter_0),
		.read_counter_data(read_counter_0_data),
		.counter_clock(counter_0_clock),
		.counter_gate(counter_0_gate),
		.counter_out(counter_0_out)
	);
	KF8253_Counter u_KF8253_Counter_1(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_control(write_control_1),
		.write_counter(write_counter_1),
		.read_counter(read_counter_1),
		.read_counter_data(read_counter_1_data),
		.counter_clock(counter_1_clock),
		.counter_gate(counter_1_gate),
		.counter_out(counter_1_out)
	);
	KF8253_Counter u_KF8253_Counter_2(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_control(write_control_2),
		.write_counter(write_counter_2),
		.read_counter(read_counter_2),
		.read_counter_data(read_counter_2_data),
		.counter_clock(counter_2_clock),
		.counter_gate(counter_2_gate),
		.counter_out(counter_2_out)
	);
	always @(*)
		if (read_counter_0)
			data_bus_out = read_counter_0_data;
		else if (read_counter_1)
			data_bus_out = read_counter_1_data;
		else if (read_counter_2)
			data_bus_out = read_counter_2_data;
		else
			data_bus_out = 8'b00000000;
endmodule
