module KF8237_Bus_Control_Logic (
	clock,
	reset,
	chip_select_n,
	io_read_n_in,
	io_write_n_in,
	address_in,
	data_bus_in,
	lock_bus_control,
	internal_data_bus,
	write_command_register,
	write_mode_register,
	write_request_register,
	set_or_reset_mask_register,
	write_mask_register,
	write_base_and_current_address,
	write_base_and_current_word_count,
	clear_byte_pointer,
	set_byte_pointer,
	master_clear,
	clear_mask_register,
	read_temporary_register,
	read_status_register,
	read_current_address,
	read_current_word_count
);
	input wire clock;
	input wire reset;
	input wire chip_select_n;
	input wire io_read_n_in;
	input wire io_write_n_in;
	input wire [3:0] address_in;
	input wire [7:0] data_bus_in;
	input wire lock_bus_control;
	output reg [7:0] internal_data_bus;
	output wire write_command_register;
	output wire write_mode_register;
	output wire write_request_register;
	output wire set_or_reset_mask_register;
	output wire write_mask_register;
	output wire [3:0] write_base_and_current_address;
	output wire [3:0] write_base_and_current_word_count;
	output wire clear_byte_pointer;
	output wire set_byte_pointer;
	output wire master_clear;
	output wire clear_mask_register;
	output wire read_temporary_register;
	output wire read_status_register;
	output wire [3:0] read_current_address;
	output wire [3:0] read_current_word_count;
	reg prev_write_enable_n;
	wire write_flag;
	reg [3:0] stable_address;
	wire read_flag;
	always @(posedge clock or posedge reset)
		if (reset)
			internal_data_bus <= 8'b00000000;
		else if (~io_write_n_in & ~chip_select_n)
			internal_data_bus <= data_bus_in;
		else
			internal_data_bus <= internal_data_bus;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_write_enable_n <= 1'b1;
		else if (chip_select_n)
			prev_write_enable_n <= 1'b1;
		else
			prev_write_enable_n <= io_write_n_in;
	assign write_flag = (~prev_write_enable_n & io_write_n_in) & ~lock_bus_control;
	always @(posedge clock or posedge reset)
		if (reset)
			stable_address <= 4'b0000;
		else
			stable_address <= address_in;
	assign write_command_register = write_flag & (stable_address == 4'b1000);
	assign write_mode_register = write_flag & (stable_address == 4'b1011);
	assign write_request_register = write_flag & (stable_address == 4'b1001);
	assign set_or_reset_mask_register = write_flag & (stable_address == 4'b1010);
	assign write_mask_register = write_flag & (stable_address == 4'b1111);
	assign write_base_and_current_address[0] = write_flag & (stable_address == 4'b0000);
	assign write_base_and_current_address[1] = write_flag & (stable_address == 4'b0010);
	assign write_base_and_current_address[2] = write_flag & (stable_address == 4'b0100);
	assign write_base_and_current_address[3] = write_flag & (stable_address == 4'b0110);
	assign write_base_and_current_word_count[0] = write_flag & (stable_address == 4'b0001);
	assign write_base_and_current_word_count[1] = write_flag & (stable_address == 4'b0011);
	assign write_base_and_current_word_count[2] = write_flag & (stable_address == 4'b0101);
	assign write_base_and_current_word_count[3] = write_flag & (stable_address == 4'b0111);
	assign clear_byte_pointer = write_flag & (stable_address == 4'b1100);
	assign set_byte_pointer = read_flag & (stable_address == 4'b1100);
	assign master_clear = write_flag & (stable_address == 4'b1101);
	assign clear_mask_register = write_flag & (stable_address == 4'b1110);
	assign read_flag = (~io_read_n_in & ~chip_select_n) & ~lock_bus_control;
	assign read_temporary_register = read_flag & (address_in == 4'b1101);
	assign read_status_register = read_flag & (address_in == 4'b1000);
	assign read_current_address[0] = read_flag & (address_in == 4'b0000);
	assign read_current_address[1] = read_flag & (address_in == 4'b0010);
	assign read_current_address[2] = read_flag & (address_in == 4'b0100);
	assign read_current_address[3] = read_flag & (address_in == 4'b0110);
	assign read_current_word_count[0] = read_flag & (address_in == 4'b0001);
	assign read_current_word_count[1] = read_flag & (address_in == 4'b0011);
	assign read_current_word_count[2] = read_flag & (address_in == 4'b0101);
	assign read_current_word_count[3] = read_flag & (address_in == 4'b0111);
endmodule
