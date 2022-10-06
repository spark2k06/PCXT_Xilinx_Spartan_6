`default_nettype none

module KF8255_Group (
	input		wire					clock,
	input		wire					reset,
	input		wire	[3:0]			internal_data_bus,
	input		wire					write_register,
	output	wire					update_group_mode,
	output	reg	[1:0]			mode_select_reg,
	output	reg					port_1_io_reg,
	output	reg					port_2_io_reg
	);

	assign update_group_mode = ({mode_select_reg[1:0], port_1_io_reg} != internal_data_bus[3:1]) & write_register;
	always @(posedge clock or posedge reset)
		if (reset)
			mode_select_reg <= 2'b00;
		else if (write_register)
			mode_select_reg <= internal_data_bus[3:2];
		else
			mode_select_reg <= mode_select_reg;
	always @(posedge clock or posedge reset)
		if (reset)
			port_1_io_reg <= 1'b1;
		else if (write_register)
			port_1_io_reg <= internal_data_bus[1];
		else
			port_1_io_reg <= port_1_io_reg;
	always @(posedge clock or posedge reset)
		if (reset)
			port_2_io_reg <= 1'b1;
		else if (write_register)
			port_2_io_reg <= internal_data_bus[0];
		else
			port_2_io_reg <= port_2_io_reg;
endmodule
