//
// KFMMC_Controller
// Written by kitune-san
//
`default_nettype none

module KFMMC_Controller #(
    parameter init_spi_clock_cycle = 8'd010,
    parameter normal_spi_clock_cycle = 8'd002,
    parameter access_block_size = 16'd512
) (
	input wire clock,
	input wire reset,
	input wire [7:0] data_bus,
	input wire [24:0] data_bus_extension,
	input wire write_block_address_1,
	input wire write_block_address_2,
	input wire write_block_address_3,
	input wire write_block_address_4,
	input wire write_block_address_extension,
	input wire write_access_command,
	input wire write_data,
	output wire [7:0] read_data_byte,
	input wire read_data,
	output reg reset_command_state,
	output reg start_command,
	output reg [47:0] command,
	output reg enable_command_crc,
	output reg enable_response_crc,
	output reg [4:0] response_length,
	input wire command_busy,
	input wire [135:0] response,
	input wire response_error,
	output reg disable_data_io,
	output reg start_data_io,
	output reg check_data_start_bit,
	output reg clear_data_crc,
	output reg data_io,
	output reg [7:0] transmit_data,
	input wire data_io_busy,
	input wire [7:0] received_data,
	output reg [7:0] mmc_clock_cycle,
	input wire [15:0] send_data_crc,
	input wire [15:0] received_data_crc,
	input wire timeout_interrupt,
	output wire drive_busy,
	output reg [39:0] storage_size,
	output reg read_interface_error,
	output reg read_crc_error,
	output reg write_interface_error,
	output reg read_byte_interrupt,
	output wire read_completion_interrupt,
	output reg request_write_data_interrupt,
	output wire write_completion_interrupt
);

	reg [31:0] control_state;
	reg [31:0] next_control_state;
	wire busy;
	wire error;
	reg [3:0] reset_pulse_count;
	reg mmc_reset;
	reg emmc_reset;
	reg read_next_byte;
	reg write_next_byte;
	reg [7:0] write_data_buffer;
	reg [15:0] write_data_crc;
	reg send_crc_count;
	reg [16:0] access_count;
	reg [32:0] ocr;
	reg [127:0] cid;
	reg [15:0] rca;
	reg [127:0] csd;
	reg [31:0] block_address;
	always @(*) begin
		next_control_state = control_state;
		case (control_state)
			32'd0:
				if (~busy)
					next_control_state = 32'd1;
			32'd1:
				if (busy)
					next_control_state = 32'd2;
			32'd2:
				if (~busy)
					if (reset_pulse_count != 4'd0)
						next_control_state = 32'd1;
					else
						next_control_state = 32'd3;
			32'd3:
				if (busy)
					next_control_state = 32'd4;
			32'd4:
				if (~busy)
					next_control_state = 32'd5;
			32'd5:
				if (busy)
					next_control_state = 32'd6;
			32'd6:
				if (~busy)
					if (emmc_reset)
						next_control_state = 32'd3;
					else if (mmc_reset)
						next_control_state = 32'd9;
					else
						next_control_state = 32'd7;
			32'd7:
				if (busy)
					next_control_state = 32'd8;
			32'd8:
				if (error)
					next_control_state = 32'd0;
				else if (~busy)
					if (response[19:8] != 12'h1aa)
						next_control_state = 32'd0;
					else
						next_control_state = 32'd11;
			32'd9:
				if (busy)
					next_control_state = 32'd10;
			32'd10: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					if (response[39] == 1'b0)
						next_control_state = 32'd16;
					else
						next_control_state = 32'd18;
			end
			32'd11:
				if (busy)
					next_control_state = 32'd12;
			32'd12: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					next_control_state = 32'd13;
			end
			32'd13:
				if (busy)
					next_control_state = 32'd14;
			32'd14: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					if (response[39] == 1'b0)
						next_control_state = 32'd16;
					else
						next_control_state = 32'd18;
			end
			32'd16:
				if (busy)
					next_control_state = 32'd17;
			32'd17:
				if (~busy)
					if (mmc_reset)
						next_control_state = 32'd9;
					else
						next_control_state = 32'd11;
			32'd18:
				if (busy)
					next_control_state = 32'd19;
			32'd19: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					next_control_state = 32'd20;
			end
			32'd20:
				if (busy)
					next_control_state = 32'd21;
			32'd21: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					if (response[21] == 1'b1)
						next_control_state = 32'd0;
					else
						next_control_state = 32'd22;
			end
			32'd22:
				if (busy)
					next_control_state = 32'd23;
			32'd23: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					next_control_state = 32'd24;
			end
			32'd24:
				if (busy)
					next_control_state = 32'd25;
			32'd25: begin
				if (error)
					next_control_state = 32'd0;
				if (~busy)
					if (response[27] == 1'b1)
						next_control_state = 32'd0;
					else
						next_control_state = 32'd26;
			end
			32'd26:
				if (busy)
					next_control_state = 32'd27;
			32'd27:
				if (timeout_interrupt)
					next_control_state = 32'd28;
				else if (~busy)
					if (received_data[0] == 1'b1)
						next_control_state = 32'd28;
					else
						next_control_state = 32'd26;
			32'd28:
				if (write_access_command)
					if (data_bus == 8'b10000000)
						next_control_state = 32'd29;
					else if (data_bus == 8'b10000001)
						next_control_state = 32'd32;
			32'd29:
				if (busy)
					next_control_state = 32'd30;
			32'd30:
				if (~busy)
					if (access_count == 16'h0000)
						next_control_state = 32'd31;
			32'd31:
				if (read_data)
					if (read_interface_error)
						next_control_state = 32'd0;
					else
						next_control_state = 32'd26;
			32'd32:
				if (busy)
					next_control_state = 32'd33;
			32'd33:
				if (~busy || error)
					next_control_state = 32'd34;
			32'd34:
				if (busy)
					next_control_state = 32'd36;
			32'd35:
				if (busy)
					next_control_state = 32'd36;
			32'd36:
				if (~busy)
					if (access_count != 16'h0000)
						next_control_state = 32'd35;
					else
						next_control_state = 32'd37;
			32'd37:
				if (busy)
					next_control_state = 32'd38;
			32'd38:
				if (~busy)
					if (send_crc_count != 1'b0)
						next_control_state = 32'd37;
					else
						next_control_state = 32'd39;
			32'd39:
				if (busy)
					next_control_state = 32'd40;
			32'd40:
				if (~busy || error)
					next_control_state = 32'd41;
			32'd41:
				if (read_data)
					if (write_interface_error)
						next_control_state = 32'd0;
					else
						next_control_state = 32'd26;
			default: next_control_state = 32'd0;
		endcase
	end
	always @(posedge clock or posedge reset)
		if (reset)
			control_state <= 32'd0;
		else
			control_state <= next_control_state;
	always @(*) begin
		reset_command_state = 1'b0;
		start_command = 1'b0;
		command = 48'hffffffffffff;
		enable_command_crc = 1'b0;
		enable_response_crc = 1'b0;
		response_length = 5'd0;
		disable_data_io = 1'b1;
		start_data_io = 1'b0;
		check_data_start_bit = 1'b0;
		clear_data_crc = 1'b0;
		data_io = 1'b1;
		transmit_data = 8'hff;
		case (control_state)
			32'd0: reset_command_state = 1'b1;
			32'd1: start_command = 1'b1;
			32'd2:
				;
			32'd3: begin
				start_command = 1'b1;
				if (emmc_reset)
					command = 48'h40f0f0f0f000;
				else
					command = 48'h400000000000;
				enable_command_crc = 1'b1;
			end
			32'd4:
				;
			32'd5: start_command = 1'b1;
			32'd6:
				;
			32'd7: begin
				start_command = 1'b1;
				command = 48'h48000001aa00;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd8:
				;
			32'd9: begin
				start_command = 1'b1;
				command = 48'h6940ff800000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd10:
				;
			32'd11: begin
				start_command = 1'b1;
				command = 48'h770000000000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd12:
				;
			32'd13: begin
				start_command = 1'b1;
				command = 48'h6940ff800000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd14:
				;
			32'd16: start_command = 1'b1;
			32'd17:
				;
			32'd18: begin
				start_command = 1'b1;
				command = 48'h420000000000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd17;
			end
			32'd19:
				;
			32'd20: begin
				start_command = 1'b1;
				command[47:40] = 8'h43;
				if (~mmc_reset)
					command[39:24] = 16'h0000;
				else
					command[39:24] = 16'h0001;
				command[23:0] = 24'h000000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd21:
				;
			32'd22: begin
				start_command = 1'b1;
				command[47:40] = 8'h49;
				command[39:24] = rca;
				command[23:0] = 24'h000000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd17;
			end
			32'd23:
				;
			32'd24: begin
				start_command = 1'b1;
				command[47:40] = 8'h47;
				command[39:24] = rca;
				command[23:0] = 24'h000000;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd25:
				;
			32'd26: begin
				disable_data_io = 1'b0;
				start_data_io = 1'b1;
				check_data_start_bit = 1'b0;
				data_io = 1'b1;
			end
			32'd27: disable_data_io = 1'b0;
			32'd28:
				;
			32'd29: begin
				start_command = 1'b1;
				command[47:40] = 8'h51;
				if (ocr[30] == 1'b0)
					command[39:8] = {block_address[22:0], 9'b000000000};
				else
					command[39:8] = block_address;
				command[7:0] = 8'h00;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
				disable_data_io = 1'b0;
				start_data_io = 1'b1;
				check_data_start_bit = 1'b1;
				clear_data_crc = 1'b1;
				data_io = 1'b1;
			end
			32'd30: begin
				disable_data_io = 1'b0;
				start_data_io = 1'b0;
				check_data_start_bit = 1'b0;
				clear_data_crc = 1'b0;
				data_io = 1'b1;
				if (data_io_busy && timeout_interrupt)
					disable_data_io = 1'b1;
				if (~data_io_busy && read_next_byte)
					start_data_io = 1'b1;
			end
			32'd31:
				;
			32'd32: begin
				start_command = 1'b1;
				command[47:40] = 8'h58;
				if (ocr[30] == 1'b0)
					command[39:8] = {block_address[22:0], 9'b000000000};
				else
					command[39:8] = block_address;
				command[7:0] = 8'h00;
				enable_command_crc = 1'b1;
				enable_response_crc = 1'b1;
				response_length = 5'd6;
			end
			32'd33:
				;
			32'd34: begin
				disable_data_io = 1'b0;
				start_data_io = 1'b1;
				check_data_start_bit = 1'b0;
				clear_data_crc = 1'b0;
				data_io = 1'b0;
				transmit_data = 8'hfe;
			end
			32'd35: begin
				disable_data_io = 1'b0;
				start_data_io = write_next_byte;
				check_data_start_bit = 1'b0;
				clear_data_crc = (access_count == access_block_size ? 1'b1 : 1'b0);
				data_io = 1'b0;
				transmit_data = write_data_buffer;
			end
			32'd36: disable_data_io = 1'b0;
			32'd37: begin
				disable_data_io = 1'b0;
				start_data_io = 1'b1;
				check_data_start_bit = 1'b0;
				clear_data_crc = 1'b0;
				data_io = 1'b0;
				transmit_data = (send_crc_count == 1'b1 ? write_data_crc[15:8] : write_data_crc[7:0]);
			end
			32'd38: disable_data_io = 1'b0;
			32'd39: begin
				disable_data_io = 1'b0;
				start_data_io = 1'b1;
				check_data_start_bit = 1'b1;
				clear_data_crc = 1'b0;
				data_io = 1'b1;
			end
			32'd40: disable_data_io = 1'b0;
			32'd41:
				;
			default:
				;
		endcase
	end
	assign busy = command_busy | data_io_busy;
	assign error = response_error | timeout_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			reset_pulse_count <= 4'd2;
		else if (control_state == 32'd0)
			reset_pulse_count <= 4'd2;
		else if ((control_state == 32'd1) && (next_control_state == 32'd2))
			reset_pulse_count <= reset_pulse_count - 4'd1;
		else
			reset_pulse_count <= reset_pulse_count;
	always @(posedge clock or posedge reset)
		if (reset) begin
			mmc_reset <= 1'b0;
			emmc_reset <= 1'b0;
		end
		else if (control_state == 32'd0) begin
			mmc_reset <= 1'b0;
			emmc_reset <= 1'b0;
		end
		else if ((control_state == 32'd8) && timeout_interrupt) begin
			mmc_reset <= 1'b1;
			emmc_reset <= 1'b1;
		end
		else if ((control_state == 32'd5) && emmc_reset) begin
			mmc_reset <= 1'b1;
			emmc_reset <= 1'b0;
		end
		else if ((control_state == 32'd10) && timeout_interrupt) begin
			mmc_reset <= 1'b0;
			emmc_reset <= 1'b0;
		end
		else begin
			mmc_reset <= mmc_reset;
			emmc_reset <= emmc_reset;
		end
	always @(posedge clock or posedge reset)
		if (reset)
			mmc_clock_cycle <= init_spi_clock_cycle;
		else if (control_state == 32'd0)
			mmc_clock_cycle <= init_spi_clock_cycle;
		else if (control_state == 32'd28)
			mmc_clock_cycle <= normal_spi_clock_cycle;
		else
			mmc_clock_cycle <= mmc_clock_cycle;
	wire reading_crc_byte = (access_count == 16'h0001) || (access_count == 16'h0000);
	always @(posedge clock or posedge reset)
		if (reset)
			read_byte_interrupt <= 1'b0;
		else if (read_data && read_byte_interrupt)
			read_byte_interrupt <= 1'b0;
		else if ((((control_state == 32'd30) && ~data_io_busy) && ~read_next_byte) && ~reading_crc_byte)
			read_byte_interrupt <= 1'b1;
		else
			read_byte_interrupt <= read_byte_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			read_next_byte <= 1'b0;
		else if (data_io_busy)
			read_next_byte <= 1'b0;
		else if (read_data && read_byte_interrupt)
			read_next_byte <= 1'b1;
		else if (reading_crc_byte)
			read_next_byte <= 1'b1;
		else
			read_next_byte <= read_next_byte;
	assign read_completion_interrupt = control_state == 32'd31;
	always @(posedge clock or posedge reset)
		if (reset)
			read_interface_error <= 1'b0;
		else if (control_state == 32'd28)
			read_interface_error <= 1'b0;
		else if ((control_state == 32'd30) && error)
			read_interface_error <= 1'b1;
		else
			read_interface_error <= read_interface_error;
	always @(posedge clock or posedge reset)
		if (reset)
			read_crc_error <= 1'b0;
		else if (control_state == 32'd28)
			read_crc_error <= 1'b0;
		else if ((((control_state == 32'd30) && ~data_io_busy) && (access_count == 16'h0000)) && (received_data_crc != 16'h0000))
			read_crc_error <= 1'b1;
		else
			read_crc_error <= read_crc_error;
	always @(posedge clock or posedge reset)
		if (reset)
			request_write_data_interrupt <= 1'b0;
		else if (write_next_byte && request_write_data_interrupt)
			request_write_data_interrupt <= 1'b0;
		else if ((control_state == 32'd35) && ~write_next_byte)
			request_write_data_interrupt <= 1'b1;
		else
			request_write_data_interrupt <= request_write_data_interrupt;
	always @(posedge clock or posedge reset)
		if (reset)
			write_next_byte <= 1'b0;
		else if (data_io_busy)
			write_next_byte <= 1'b0;
		else if (write_data && request_write_data_interrupt)
			write_next_byte <= 1'b1;
		else
			write_next_byte <= write_next_byte;
	always @(posedge clock or posedge reset)
		if (reset)
			write_data_buffer <= 8'h00;
		else if (write_data)
			write_data_buffer <= data_bus;
		else
			write_data_buffer <= write_data_buffer;
	always @(posedge clock or posedge reset)
		if (reset)
			write_data_crc <= 16'h0000;
		else if (control_state == 32'd36)
			write_data_crc <= send_data_crc;
		else
			write_data_crc <= write_data_crc;
	always @(posedge clock or posedge reset)
		if (reset)
			send_crc_count <= 1'b1;
		else if (control_state == 32'd36)
			send_crc_count <= 1'b1;
		else if ((control_state == 32'd38) && ~busy)
			send_crc_count <= 1'b0;
		else
			send_crc_count <= send_crc_count;
	assign write_completion_interrupt = control_state == 32'd41;
	always @(posedge clock or posedge reset)
		if (reset)
			write_interface_error <= 1'b0;
		else if (control_state == 32'd28)
			write_interface_error <= 1'b0;
		else if ((control_state == 32'd40) && ~busy) begin
			if ((received_data[7:4] != 4'b0101) || error)
				write_interface_error <= 1'b1;
			else
				write_interface_error <= 1'b0;
		end
		else
			write_interface_error <= write_interface_error;
	wire read_count_down = read_next_byte & data_io_busy;
	wire write_count_down = write_next_byte & data_io_busy;
	always @(posedge clock or posedge reset)
		if (reset)
			access_count <= 16'h0000;
		else if (control_state == 32'd29)
			access_count <= access_block_size + 1;
		else if (control_state == 32'd32)
			access_count <= access_block_size;
		else if ((control_state == 32'd30) && read_count_down)
			access_count <= access_count - 16'h0001;
		else if ((control_state == 32'd35) && write_count_down)
			access_count <= access_count - 16'h0001;
		else
			access_count <= access_count;
	always @(posedge clock or posedge reset)
		if (reset)
			ocr <= 32'h00000000;
		else if ((control_state == 32'd14) || (control_state == 32'd10))
			ocr <= response[39:8];
		else
			ocr <= ocr;
	always @(posedge clock or posedge reset)
		if (reset)
			cid <= 0;
		else if (control_state == 32'd19)
			cid <= response[127:0];
		else
			cid <= cid;
	always @(posedge clock or posedge reset)
		if (reset)
			rca <= 16'h0001;
		else if (~mmc_reset && (control_state == 32'd21))
			rca <= response[39:24];
		else
			rca <= rca;
	always @(posedge clock or posedge reset)
		if (reset)
			csd <= 0;
		else if (control_state == 32'd23)
			csd <= response[127:0];
		else
			csd <= csd;
	always @(posedge clock or posedge reset)
		if (reset)
			storage_size <= 0;
		else if (csd[127:126] == 2'b00)
			storage_size <= (csd[73:62] + 40'd1) << ((csd[49:47] + csd[83:80]) + 5'd2);
		else if (csd[127:126] == 2'b01)
			storage_size <= {csd[69:48] + 22'd1, 19'b0000000000000000000};
		else
			storage_size <= 0;
	always @(posedge clock or posedge reset)
		if (reset)
			block_address <= 32'h00000000;
		else if (write_block_address_extension)
			block_address <= {data_bus_extension, data_bus};
		else if (write_block_address_1)
			block_address <= {block_address[31:8], data_bus};
		else if (write_block_address_2)
			block_address <= {block_address[31:16], data_bus, block_address[7:0]};
		else if (write_block_address_3)
			block_address <= {block_address[31:24], data_bus, block_address[15:0]};
		else if (write_block_address_4)
			block_address <= {data_bus, block_address[23:0]};
		else
			block_address <= block_address;
	assign read_data_byte = received_data;
	assign drive_busy = ~(control_state == 32'd28);
endmodule
