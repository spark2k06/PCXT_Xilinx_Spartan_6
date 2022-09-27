module KF8255_Control_Logic (
	clock,
	reset,
	chip_select_n,
	read_enable_n,
	write_enable_n,
	address,
	data_bus_in,
	internal_data_bus,
	write_port_a,
	write_port_b,
	write_port_c,
	write_control,
	read_port_a,
	read_port_b,
	read_port_c
);
	input wire clock;
	input wire reset;
	input wire chip_select_n;
	input wire read_enable_n;
	input wire write_enable_n;
	input wire [1:0] address;
	input wire [7:0] data_bus_in;
	output reg [7:0] internal_data_bus;
	output wire write_port_a;
	output wire write_port_b;
	output wire write_port_c;
	output wire write_control;
	output reg read_port_a;
	output reg read_port_b;
	output reg read_port_c;
	reg prev_write_enable_n;
	wire write_flag;
	reg [2:0] stable_address;
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
	assign write_port_a = (stable_address == 2'b00) & write_flag;
	assign write_port_b = (stable_address == 2'b01) & write_flag;
	assign write_port_c = (stable_address == 2'b10) & write_flag;
	assign write_control = (stable_address == 2'b11) & write_flag;
	always @(*) begin
		read_port_a = 1'b0;
		read_port_b = 1'b0;
		read_port_c = 1'b0;
		if (~read_enable_n & ~chip_select_n)
			case (address)
				2'b00: read_port_a = 1'b1;
				2'b01: read_port_b = 1'b1;
				2'b10: read_port_c = 1'b1;
				default: read_port_a = 1'b1;
			endcase
	end
endmodule
