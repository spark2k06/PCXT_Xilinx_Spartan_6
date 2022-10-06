`default_nettype none

module KF8253_Control_Logic (
	input		wire					clock,
	input		wire					reset,
	input		wire					chip_select_n,
	input		wire					read_enable_n,
	input		wire					write_enable_n,
	input		wire	[1:0]			address,
	input		wire	[7:0]			data_bus_in,
	output	reg	[7:0]			internal_data_bus,
	output	wire					write_control_0,
	output	wire					write_control_1,
	output	wire					write_control_2,
	output	wire					write_counter_0,
	output	wire					write_counter_1,
	output	wire					write_counter_2,
	output	wire					read_counter_0,
	output	wire					read_counter_1,
	output	wire					read_counter_2
	);

	reg prev_write_enable_n;
	wire write_flag;
	wire write_control;
	reg [2:0] stable_address;
	wire read_flag;
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
			stable_address <= 2'b00;
		else
			stable_address <= address;
	assign write_counter_0 = (stable_address == 2'b00) & write_flag;
	assign write_counter_1 = (stable_address == 2'b01) & write_flag;
	assign write_counter_2 = (stable_address == 2'b10) & write_flag;
	assign write_control = (stable_address == 2'b11) & write_flag;
	assign write_control_0 = (internal_data_bus[7:6] == 2'b00) & write_control;
	assign write_control_1 = (internal_data_bus[7:6] == 2'b01) & write_control;
	assign write_control_2 = (internal_data_bus[7:6] == 2'b10) & write_control;
	assign read_flag = ~read_enable_n & ~chip_select_n;
	assign read_counter_0 = (address == 2'b00) & read_flag;
	assign read_counter_1 = (address == 2'b01) & read_flag;
	assign read_counter_2 = (address == 2'b10) & read_flag;
endmodule
