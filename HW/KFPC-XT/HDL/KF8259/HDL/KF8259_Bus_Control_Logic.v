`default_nettype none

module KF8259_Bus_Control_Logic (
	input		wire					clock,
	input		wire					reset,
	input		wire					chip_select_n,
	input		wire					read_enable_n,
	input		wire					write_enable_n,
	input		wire					address,
	input		wire	[7:0]			data_bus_in,
	output	reg	[7:0]			internal_data_bus,
	output	wire					write_initial_command_word_1,
	output	wire					write_initial_command_word_2_4,
	output	wire					write_operation_control_word_1,
	output	wire					write_operation_control_word_2,
	output	wire					write_operation_control_word_3,
	output	wire					read
	);

	reg prev_write_enable_n;
	wire write_flag;
	reg stable_address;
	always @(posedge clock or posedge reset)
		if (reset)
			internal_data_bus <= 8'b00000000;
		else if (~write_enable_n & ~chip_select_n)
			internal_data_bus <= data_bus_in;
		else
			internal_data_bus <= internal_data_bus;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_write_enable_n <= 1'b1;
		else if (chip_select_n)
			prev_write_enable_n <= 1'b1;
		else
			prev_write_enable_n <= write_enable_n;
	assign write_flag = ~prev_write_enable_n & write_enable_n;
	always @(posedge clock or posedge reset)
		if (reset)
			stable_address <= 1'b0;
		else
			stable_address <= address;
	assign write_initial_command_word_1 = (write_flag & ~stable_address) & internal_data_bus[4];
	assign write_initial_command_word_2_4 = write_flag & stable_address;
	assign write_operation_control_word_1 = write_flag & stable_address;
	assign write_operation_control_word_2 = ((write_flag & ~stable_address) & ~internal_data_bus[4]) & ~internal_data_bus[3];
	assign write_operation_control_word_3 = ((write_flag & ~stable_address) & ~internal_data_bus[4]) & internal_data_bus[3];
	assign read = ~read_enable_n & ~chip_select_n;
endmodule
