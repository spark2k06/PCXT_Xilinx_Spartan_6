`default_nettype none

module KF8255_Port (
	input		wire					clock,
	input		wire					reset,
	input		wire	[7:0]			internal_data_bus,
	input		wire					write_port,
	input		wire					update_mode,
	input		wire	[1:0]			mode_select_reg,
	input		wire					port_io_reg,
	input		wire					strobe,
	input		wire					hiz,
	output	reg					port_io,
	output	reg	[7:0]			port_out,
	input		wire	[7:0]			port_in,
	output	wire	[7:0]			read
	);

	always @(posedge clock or posedge reset)
		if (reset)
			port_io <= 1'b1;
		else
			casez (mode_select_reg)
				2'b00: port_io <= port_io_reg;
				2'b01: port_io <= port_io_reg;
				2'b1z: port_io <= (hiz == 1'b0 ? 1'b0 : 1'b1);
				default: port_io <= port_io_reg;
			endcase
	always @(posedge clock or posedge reset)
		if (reset)
			port_out <= 8'b00000000;
		else if (update_mode)
			port_out <= 8'b00000000;
		else if (write_port)
			port_out <= internal_data_bus;
		else
			port_out <= port_out;
	reg [7:0] read_tmp;
	always @(posedge clock or posedge reset)
		if (reset)
			read_tmp <= 8'b00000000;
		else if (update_mode)
			read_tmp <= 8'b00000000;
		else
			casez (mode_select_reg)
				2'b00: read_tmp <= port_in;
				2'b01: read_tmp <= (strobe == 1'b0 ? read_tmp : port_in);
				2'b1z: read_tmp <= (strobe == 1'b0 ? read_tmp : port_in);
				default: read_tmp <= read_tmp;
			endcase
	assign read = (port_io == 1'b1 ? read_tmp : port_out);
endmodule
