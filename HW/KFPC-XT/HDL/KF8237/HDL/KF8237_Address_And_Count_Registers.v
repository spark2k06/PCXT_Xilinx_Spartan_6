module KF8237_Address_And_Count_Registers (
	clock,
	cpu_clock_posedge,
	cpu_clock_negedge,
	reset,
	internal_data_bus,
	read_address_or_count,
	write_base_and_current_address,
	write_base_and_current_word_count,
	clear_byte_pointer,
	set_byte_pointer,
	master_clear,
	read_current_address,
	read_current_word_count,
	transfer_register_select,
	initialize_current_register,
	address_hold_config,
	decrement_address_config,
	next_word,
	underflow,
	update_high_address,
	transfer_address
);
	input wire clock;
	input wire cpu_clock_posedge;
	input wire cpu_clock_negedge;
	input wire reset;
	input wire [7:0] internal_data_bus;
	output reg [7:0] read_address_or_count;
	input wire [3:0] write_base_and_current_address;
	input wire [3:0] write_base_and_current_word_count;
	input wire clear_byte_pointer;
	input wire set_byte_pointer;
	input wire master_clear;
	input wire [3:0] read_current_address;
	input wire [3:0] read_current_word_count;
	input wire [3:0] transfer_register_select;
	input wire initialize_current_register;
	input wire address_hold_config;
	input wire decrement_address_config;
	input wire next_word;
	output wire underflow;
	output wire update_high_address;
	output reg [15:0] transfer_address;
	reg [3:0] prev_read_current_address;
	reg [3:0] prev_read_current_word_count;
	reg byte_pointer;
	reg [15:0] base_address [0:3];
	reg [15:0] current_address [0:3];
	reg [15:0] base_word_count [0:3];
	reg [15:0] current_word_count [0:3];
	reg [15:0] temporary_address;
	reg [16:0] temporary_word_count;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_read_current_address <= 0;
		else
			prev_read_current_address <= read_current_address;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_read_current_word_count <= 0;
		else
			prev_read_current_word_count <= read_current_word_count;
	wire update_byte_pointer = (((0 != write_base_and_current_address) || (0 != write_base_and_current_word_count)) || ((0 != prev_read_current_address) && (prev_read_current_address != read_current_address))) || ((0 != prev_read_current_word_count) && (prev_read_current_word_count != read_current_word_count));
	always @(posedge clock or posedge reset)
		if (reset)
			byte_pointer <= 1'b0;
		else if (master_clear || clear_byte_pointer)
			byte_pointer <= 1'b0;
		else if (set_byte_pointer)
			byte_pointer <= 1'b1;
		else if (update_byte_pointer) begin
			if (byte_pointer)
				byte_pointer <= 1'b0;
			else
				byte_pointer <= 1'b1;
		end
		else
			byte_pointer <= byte_pointer;
	genvar dma_ch_i;
	generate
		for (dma_ch_i = 0; dma_ch_i < 4; dma_ch_i = dma_ch_i + 1) begin : ADDRESS_AND_COUNT_REGISTERS
			always @(posedge clock or posedge reset)
				if (reset)
					base_address[dma_ch_i] <= 16'h0000;
				else if (master_clear)
					base_address[dma_ch_i] <= 16'h0000;
				else if (write_base_and_current_address[dma_ch_i]) begin
					if (~byte_pointer)
						base_address[dma_ch_i][7:0] <= internal_data_bus;
					else
						base_address[dma_ch_i][15:8] <= internal_data_bus;
				end
				else
					base_address[dma_ch_i] <= base_address[dma_ch_i];
			always @(posedge clock or posedge reset)
				if (reset)
					base_word_count[dma_ch_i] <= 16'h0000;
				else if (master_clear)
					base_word_count[dma_ch_i] <= 16'h0000;
				else if (write_base_and_current_word_count[dma_ch_i]) begin
					if (~byte_pointer)
						base_word_count[dma_ch_i][7:0] <= internal_data_bus;
					else
						base_word_count[dma_ch_i][15:8] <= internal_data_bus;
				end
				else
					base_word_count[dma_ch_i] <= base_word_count[dma_ch_i];
			always @(posedge clock or posedge reset)
				if (reset)
					current_address[dma_ch_i] <= 16'h0000;
				else if (master_clear)
					current_address[dma_ch_i] <= 16'h0000;
				else if (write_base_and_current_address[dma_ch_i]) begin
					if (~byte_pointer)
						current_address[dma_ch_i][7:0] <= internal_data_bus;
					else
						current_address[dma_ch_i][15:8] <= internal_data_bus;
				end
				else if (transfer_register_select[dma_ch_i] && initialize_current_register)
					current_address[dma_ch_i] <= base_address[dma_ch_i];
				else if ((transfer_register_select[dma_ch_i] && next_word) && cpu_clock_negedge)
					current_address[dma_ch_i] <= temporary_address;
				else
					current_address[dma_ch_i] <= current_address[dma_ch_i];
			always @(posedge clock or posedge reset)
				if (reset)
					current_word_count[dma_ch_i] <= 16'h0000;
				else if (master_clear)
					current_word_count[dma_ch_i] <= 16'h0000;
				else if (write_base_and_current_word_count[dma_ch_i]) begin
					if (~byte_pointer)
						current_word_count[dma_ch_i][7:0] <= internal_data_bus;
					else
						current_word_count[dma_ch_i][15:8] <= internal_data_bus;
				end
				else if (transfer_register_select[dma_ch_i] && initialize_current_register)
					current_word_count[dma_ch_i] <= base_word_count[dma_ch_i];
				else if ((transfer_register_select[dma_ch_i] && next_word) && cpu_clock_negedge)
					current_word_count[dma_ch_i] <= temporary_word_count[15:0];
				else
					current_word_count[dma_ch_i] <= current_word_count[dma_ch_i];
		end
	endgenerate
	function [1:0] KF8237_Common_Package_bit2num;
		input [3:0] source;
		if (source[0] == 1'b1)
			KF8237_Common_Package_bit2num = 2'b00;
		else if (source[1] == 1'b1)
			KF8237_Common_Package_bit2num = 2'b01;
		else if (source[2] == 1'b1)
			KF8237_Common_Package_bit2num = 2'b10;
		else if (source[3] == 1'b1)
			KF8237_Common_Package_bit2num = 2'b11;
		else
			KF8237_Common_Package_bit2num = 2'b00;
	endfunction
	wire [1:0] dma_select = KF8237_Common_Package_bit2num(transfer_register_select);
	always @(*) begin
		temporary_address = current_address[dma_select];
		if (next_word)
			if (address_hold_config)
				temporary_address = temporary_address;
			else if (decrement_address_config)
				temporary_address = temporary_address - 16'h0001;
			else
				temporary_address = temporary_address + 16'h0001;
	end
	always @(*) begin
		temporary_word_count = {1'b1, current_word_count[dma_select]};
		if (next_word)
			temporary_word_count = temporary_word_count - 17'h00001;
	end
	assign underflow = ~temporary_word_count[16];
	assign update_high_address = (next_word ? transfer_address[8] != temporary_address[8] : 1'b0);
	always @(posedge clock or posedge reset)
		if (reset)
			transfer_address <= 0;
		else if (master_clear)
			transfer_address <= 0;
		else if (cpu_clock_negedge)
			transfer_address <= current_address[dma_select];
		else
			transfer_address <= transfer_address;
	reg [15:0] read_register;
	always @(*) begin
		if (read_current_address[0])
			read_register = current_address[0];
		else if (read_current_address[1])
			read_register = current_address[1];
		else if (read_current_address[2])
			read_register = current_address[2];
		else if (read_current_address[3])
			read_register = current_address[3];
		else if (read_current_word_count[0])
			read_register = current_word_count[0];
		else if (read_current_word_count[1])
			read_register = current_word_count[1];
		else if (read_current_word_count[2])
			read_register = current_word_count[2];
		else if (read_current_word_count[3])
			read_register = current_word_count[3];
		else
			read_register = 16'h0000;
		if (~byte_pointer)
			read_address_or_count = read_register[7:0];
		else
			read_address_or_count = read_register[15:8];
	end
endmodule
