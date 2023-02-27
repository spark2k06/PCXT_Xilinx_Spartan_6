//
// XT2IDE written by kitune-san
//
`default_nettype none

module XT2IDE (
	input wire clock,
	input wire reset,
	input wire high_speed,
	input wire chip_select_n,
	input wire io_read_n,
	input wire io_write_n,
	input wire [4:0] address,
	input wire [7:0] data_bus_in,
	output reg [7:0] data_bus_out,
	output wire ide_cs1fx,
	output wire ide_cs3fx,
	output wire ide_io_read_n,
	output wire ide_io_write_n,
	output wire [2:0] ide_address,
	input wire [15:0] ide_data_bus_in,
	output reg [15:0] ide_data_bus_out
);

	wire select_1;
	wire select_2;
	reg latch_high_read_byte;
	reg read_high_byte;
	reg latch_high_write_byte;
	reg [7:0] read_buffer;
	assign select_1 = (high_speed ? address[0] : address[3]);
	assign select_2 = (high_speed ? address[3] : address[0]);
	always @(*) begin
		latch_high_read_byte = 1'b0;
		read_high_byte = 1'b0;
		latch_high_write_byte = 1'b0;
		if (((~address[2] & ~address[1]) & ~select_2) & ~chip_select_n)
			casez ({select_1, io_read_n, io_write_n})
				3'b001: latch_high_read_byte = 1'b1;
				3'b101: read_high_byte = 1'b1;
				3'b110: latch_high_write_byte = 1'b1;
			endcase
	end
	assign ide_io_read_n = io_read_n;
	assign ide_io_write_n = io_write_n;
	assign ide_cs1fx = select_1 | chip_select_n;
	assign ide_cs3fx = ~select_1 | chip_select_n;
	assign ide_address = {address[2:1], select_2};
	always @(posedge clock or posedge reset)
		if (reset)
			ide_data_bus_out[15:8] <= 8'hff;
		else if (~chip_select_n & latch_high_write_byte)
			ide_data_bus_out[15:8] <= data_bus_in;
		else
			ide_data_bus_out[15:8] <= ide_data_bus_out[15:8];
	always @(*)
		if (io_write_n | chip_select_n)
			ide_data_bus_out[7:0] = 8'hff;
		else
			ide_data_bus_out[7:0] = data_bus_in;
	always @(posedge clock or posedge reset)
		if (reset)
			read_buffer <= 8'hff;
		else if (~ide_io_read_n & latch_high_read_byte)
			read_buffer <= ide_data_bus_in[15:8];
		else
			read_buffer <= read_buffer;
	always @(*)
		if (read_high_byte)
			data_bus_out = read_buffer;
		else if (~io_read_n & ~chip_select_n)
			data_bus_out = ide_data_bus_in[7:0];
		else
			data_bus_out = 8'hff;
endmodule
