`default_nettype none

module KF8237_Timing_And_Control (
	input		wire					clock,
	input		wire					cpu_clock_posedge,
	input		wire					cpu_clock_negedge,
	input		wire					reset,
	input		wire	[7:0]			internal_data_bus,
	input		wire					write_command_register,
	input		wire					write_mode_register,
	input		wire					read_status_register,
	input		wire					master_clear,
	output	reg	[1:0]			dma_rotate,
	output	wire	[3:0]			edge_request,
	input		wire	[3:0]			dma_request_state,
	input		wire	[3:0]			encoded_dma,
	output	reg	[3:0]			dma_acknowledge_internal,
	output	reg	[3:0]			transfer_register_select,
	output	reg					initialize_current_register,
	output	reg					address_hold_config,
	output	reg					decrement_address_config,
	output	reg					next_word,
	input		wire					update_high_address,
	input		wire					underflow,
	output	reg					end_of_process_internal,
	output	reg					lock_bus_control,
	output	wire					output_temporary_data,
	output	wire	[7:0]			temporary_register,
	output	reg	[3:0]			terminal_count_state,
	output	reg					hold_request,
	input		wire					hold_acknowledge,
	output	wire	[3:0]			dma_acknowledge,
	output	reg					address_enable,
	output	reg					address_strobe,
	output	reg					output_highst_address,
	output	reg					memory_read_n,
	output	reg					memory_write_n,
	output	reg					io_read_n_out,
	output	reg					io_read_n_io,
	output	reg					io_write_n_out,
	output	reg					io_write_n_io,
	input		wire					ready,
	input		wire					end_of_process_n_in,
	output	wire					end_of_process_n_out
	);

	reg [31:0] state;
	reg [31:0] next_state;
	reg [7:0] bit_select = 8'b00011011;
	reg memory_to_memory_enable;
	reg chanel_0_address_hold_enable;
	reg compressed_timing;
	reg extended_write_selection;
	reg dack_sense_active_high;
	reg [1:0] transfer_type [0:3];
	reg autoinitialization_enable [0:3];
	reg address_decrement_select [0:3];
	reg [1:0] transfer_mode [0:3];
	wire [1:0] dma_select;
	reg [3:0] dma_acknowledge_ff;
	reg terminal_count;
	reg terminal_count_internal;
	reg reoutput_high_address;
	reg external_end_of_process;
	reg prev_read_status_register;
	always @(posedge clock or posedge reset)
		if (reset) begin
			memory_to_memory_enable <= 1'b0;
			chanel_0_address_hold_enable <= 1'b0;
			compressed_timing <= 1'b0;
			extended_write_selection <= 1'b0;
			dack_sense_active_high <= 1'b0;
		end
		else if (master_clear) begin
			memory_to_memory_enable <= 1'b0;
			chanel_0_address_hold_enable <= 1'b0;
			compressed_timing <= 1'b0;
			extended_write_selection <= 1'b0;
			dack_sense_active_high <= 1'b0;
		end
		else if (write_command_register) begin
			memory_to_memory_enable <= internal_data_bus[0];
			chanel_0_address_hold_enable <= internal_data_bus[1];
			compressed_timing <= internal_data_bus[3];
			extended_write_selection <= internal_data_bus[5];
			dack_sense_active_high <= internal_data_bus[7];
		end
		else begin
			memory_to_memory_enable <= memory_to_memory_enable;
			chanel_0_address_hold_enable <= chanel_0_address_hold_enable;
			compressed_timing <= compressed_timing;
			extended_write_selection <= extended_write_selection;
			dack_sense_active_high <= dack_sense_active_high;
		end
	genvar mode_reg_bit_i;
	generate
		for (mode_reg_bit_i = 0; mode_reg_bit_i < 4; mode_reg_bit_i = mode_reg_bit_i + 1) begin : MODE_REGISTERS
			always @(posedge clock or posedge reset)
				if (reset) begin
					transfer_type[mode_reg_bit_i] <= 2'b00;
					autoinitialization_enable[mode_reg_bit_i] <= 1'b0;
					address_decrement_select[mode_reg_bit_i] <= 1'b0;
					transfer_mode[mode_reg_bit_i] <= 2'b00;
				end
				else if (master_clear) begin
					transfer_type[mode_reg_bit_i] <= 2'b00;
					autoinitialization_enable[mode_reg_bit_i] <= 1'b0;
					address_decrement_select[mode_reg_bit_i] <= 1'b0;
					transfer_mode[mode_reg_bit_i] <= 2'b00;
				end
				else if (write_mode_register && (internal_data_bus[1:0] == bit_select[(3 - mode_reg_bit_i) * 2+:2])) begin
					transfer_type[mode_reg_bit_i] <= (internal_data_bus[7:6] != 2'b11 ? internal_data_bus[3:2] : 2'b11);
					autoinitialization_enable[mode_reg_bit_i] <= internal_data_bus[4];
					address_decrement_select[mode_reg_bit_i] <= internal_data_bus[5];
					transfer_mode[mode_reg_bit_i] <= internal_data_bus[7:6];
				end
				else begin
					transfer_type[mode_reg_bit_i] <= transfer_type[mode_reg_bit_i];
					autoinitialization_enable[mode_reg_bit_i] <= autoinitialization_enable[mode_reg_bit_i];
					address_decrement_select[mode_reg_bit_i] <= address_decrement_select[mode_reg_bit_i];
					transfer_mode[mode_reg_bit_i] <= transfer_mode[mode_reg_bit_i];
				end
			assign edge_request[mode_reg_bit_i] = (transfer_mode[mode_reg_bit_i] == 2'b01) || (transfer_mode[mode_reg_bit_i] == 2'b10);
		end
	endgenerate
	always @(*) begin
		next_state = state;
		casez (state)
			32'd0:
				if (0 != encoded_dma)
					next_state = 32'd1;
			32'd1:
				if (hold_acknowledge)
					next_state = 32'd2;
			32'd2:
				if (transfer_mode[dma_select] == 2'b11)
					next_state = 32'd6;
				else
					next_state = 32'd3;
			32'd3:
				if (~compressed_timing)
					next_state = 32'd4;
				else if (ready || (transfer_type[dma_select] == 2'b00))
					next_state = 32'd6;
				else
					next_state = 32'd5;
			32'd4:
				if (ready || (transfer_type[dma_select] == 2'b00))
					next_state = 32'd6;
				else
					next_state = 32'd5;
			32'd5:
				if (ready)
					next_state = 32'd6;
			32'd6:
				if (transfer_mode[dma_select] == 2'b11) begin
					if (0 == (dma_acknowledge_internal & dma_request_state))
						next_state = 32'd0;
					else
						next_state = 32'd6;
				end
				else if (transfer_mode[dma_select] == 2'b01)
					next_state = 32'd0;
				else if ((transfer_mode[dma_select] == 2'b00) && (0 == (dma_acknowledge_internal & dma_request_state)))
					next_state = 32'd0;
				else if (end_of_process_internal)
					next_state = 32'd0;
				else
					next_state = (reoutput_high_address ? 32'd2 : 32'd3);
			default:
				;
		endcase
	end
	always @(posedge clock or posedge reset)
		if (reset)
			state <= 32'd0;
		else if (master_clear)
			state <= 32'd0;
		else if (cpu_clock_negedge)
			state <= next_state;
		else
			state <= state;
	always @(posedge clock or posedge reset)
		if (reset)
			dma_acknowledge_internal <= 0;
		else if (master_clear)
			dma_acknowledge_internal <= 0;
		else if (state == 32'd0)
			dma_acknowledge_internal <= encoded_dma;
		else
			dma_acknowledge_internal <= dma_acknowledge_internal;
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
	assign dma_select = KF8237_Common_Package_bit2num(dma_acknowledge_internal);
	always @(posedge clock or posedge reset)
		if (reset)
			dma_rotate <= 2'd3;
		else if (master_clear)
			dma_rotate <= 2'd3;
		else if (state == 32'd1)
			dma_rotate <= dma_select;
		else
			dma_rotate <= dma_rotate;
	always @(*) begin
		address_hold_config = (4'b0001 == dma_acknowledge_internal) & chanel_0_address_hold_enable;
		decrement_address_config = address_decrement_select[dma_select];
		next_word = ((next_state == 32'd6) && (transfer_mode[dma_select] != 2'b11) ? 1'b1 : 1'b0);
		casez (state)
			32'd0: begin
				transfer_register_select = 0;
				initialize_current_register = 0;
				lock_bus_control = 0;
			end
			32'd1: begin
				transfer_register_select = dma_acknowledge_internal;
				initialize_current_register = 0;
				lock_bus_control = 1'b1;
			end
			32'd2: begin
				transfer_register_select = dma_acknowledge_internal;
				initialize_current_register = 0;
				lock_bus_control = 1'b1;
			end
			32'd3: begin
				transfer_register_select = dma_acknowledge_internal;
				initialize_current_register = 0;
				lock_bus_control = 1'b1;
			end
			32'd4: begin
				transfer_register_select = dma_acknowledge_internal;
				initialize_current_register = 0;
				lock_bus_control = 1'b1;
			end
			32'd5: begin
				transfer_register_select = dma_acknowledge_internal;
				initialize_current_register = 0;
				lock_bus_control = 1'b1;
			end
			32'd6: begin
				transfer_register_select = dma_acknowledge_internal;
				initialize_current_register = autoinitialization_enable[dma_select] & end_of_process_internal;
				lock_bus_control = 1'b1;
			end
			default: begin
				transfer_register_select = 0;
				initialize_current_register = 0;
				lock_bus_control = 0;
			end
		endcase
	end
	always @(posedge clock or posedge reset)
		if (reset)
			hold_request <= 1'b0;
		else if (master_clear)
			hold_request <= 1'b0;
		else if (cpu_clock_posedge) begin
			if (next_state == 32'd1)
				hold_request <= 1'b1;
			else if (next_state == 32'd0)
				hold_request <= 1'b0;
			else
				hold_request <= hold_request;
		end
		else
			hold_request <= hold_request;
	always @(posedge clock or posedge reset)
		if (reset)
			address_enable <= 1'b0;
		else if (master_clear)
			address_enable <= 1'b0;
		else if (cpu_clock_posedge) begin
			if (transfer_mode[dma_select] == 2'b11)
				address_enable <= 1'b0;
			else if (state == 32'd2)
				address_enable <= 1'b1;
			else if (state == 32'd0)
				address_enable <= 1'b0;
			else
				address_enable <= address_enable;
		end
		else
			address_enable <= address_enable;
	always @(posedge clock or posedge reset)
		if (reset)
			address_strobe <= 1'b0;
		else if (master_clear)
			address_strobe <= 1'b0;
		else if (cpu_clock_posedge) begin
			if (transfer_mode[dma_select] == 2'b11)
				address_strobe <= 1'b0;
			else if (state == 32'd2)
				address_strobe <= 1'b1;
			else
				address_strobe <= 1'b0;
		end
		else
			address_strobe <= address_strobe;
	always @(posedge clock or posedge reset)
		if (reset)
			output_highst_address <= 1'b0;
		else if (master_clear)
			output_highst_address <= 1'b0;
		else if (cpu_clock_negedge) begin
			if (transfer_mode[dma_select] == 2'b11)
				output_highst_address <= 1'b0;
			else if ((state == 32'd2) && (next_state == 32'd3))
				output_highst_address <= 1'b1;
			else
				output_highst_address <= 1'b0;
		end
		else
			output_highst_address <= output_highst_address;
	always @(posedge clock or posedge reset)
		if (reset)
			dma_acknowledge_ff <= 0;
		else if (master_clear)
			dma_acknowledge_ff <= 0;
		else if (cpu_clock_negedge) begin
			if (next_state == 32'd3)
				dma_acknowledge_ff <= dma_acknowledge_internal;
			else if (next_state == 32'd0)
				dma_acknowledge_ff <= 0;
			else
				dma_acknowledge_ff <= dma_acknowledge_ff;
		end
		else
			dma_acknowledge_ff <= dma_acknowledge_ff;
	assign dma_acknowledge = (dack_sense_active_high ? dma_acknowledge_ff : ~dma_acknowledge_ff);
	always @(posedge clock or posedge reset)
		if (reset)
			io_read_n_io <= 1'b1;
		else if (master_clear)
			io_read_n_io <= 1'b1;
		else if (cpu_clock_posedge) begin
			if ((state == 32'd2) && (transfer_type[dma_select] == 2'b01))
				io_read_n_io <= 1'b0;
			else if (state == 32'd0)
				io_read_n_io <= 1'b1;
			else
				io_read_n_io <= io_read_n_io;
		end
		else
			io_read_n_io <= io_read_n_io;
	always @(posedge clock or posedge reset)
		if (reset)
			io_read_n_out <= 1'b1;
		else if (master_clear)
			io_read_n_out <= 1'b1;
		else if (cpu_clock_posedge) begin
			if ((state == 32'd3) && (transfer_type[dma_select] == 2'b01))
				io_read_n_out <= 1'b0;
			else if (state == 32'd6)
				io_read_n_out <= 1'b1;
			else
				io_read_n_out <= io_read_n_out;
		end
		else
			io_read_n_out <= io_read_n_out;
	always @(posedge clock or posedge reset)
		if (reset)
			memory_read_n <= 1'b1;
		else if (master_clear)
			memory_read_n <= 1'b1;
		else if (cpu_clock_posedge) begin
			if ((state == 32'd3) && (transfer_type[dma_select] == 2'b10))
				memory_read_n <= 1'b0;
			else if (state == 32'd6)
				memory_read_n <= 1'b1;
			else
				memory_read_n <= memory_read_n;
		end
		else
			memory_read_n <= memory_read_n;
	always @(posedge clock or posedge reset)
		if (reset)
			io_write_n_io <= 1'b1;
		else if (master_clear)
			io_write_n_io <= 1'b1;
		else if (cpu_clock_posedge) begin
			if ((state == 32'd2) && (transfer_type[dma_select] == 2'b10))
				io_write_n_io <= 1'b0;
			else if (state == 32'd0)
				io_write_n_io <= 1'b1;
			else
				io_write_n_io <= io_write_n_io;
		end
		else
			io_write_n_io <= io_write_n_io;
	always @(posedge clock or posedge reset)
		if (reset)
			io_write_n_out <= 1'b1;
		else if (master_clear)
			io_write_n_out <= 1'b1;
		else if (cpu_clock_posedge) begin
			if (state == 32'd6)
				io_write_n_out <= 1'b1;
			else if (transfer_type[dma_select] == 2'b10) begin
				if ((state == 32'd3) && (extended_write_selection || compressed_timing))
					io_write_n_out <= 1'b0;
				else if (state == 32'd4)
					io_write_n_out <= 1'b0;
				else
					io_write_n_out <= io_write_n_out;
			end
			else
				io_write_n_out <= io_write_n_out;
		end
		else
			io_write_n_out <= io_write_n_out;
	always @(posedge clock or posedge reset)
		if (reset)
			memory_write_n <= 1'b1;
		else if (master_clear)
			memory_write_n <= 1'b1;
		else if (cpu_clock_posedge) begin
			if (state == 32'd6)
				memory_write_n <= 1'b1;
			else if (transfer_type[dma_select] == 2'b01) begin
				if ((state == 32'd3) && (extended_write_selection || compressed_timing))
					memory_write_n <= 1'b0;
				else if (state == 32'd4)
					memory_write_n <= 1'b0;
				else
					memory_write_n <= memory_write_n;
			end
			else
				memory_write_n <= memory_write_n;
		end
		else
			memory_write_n <= memory_write_n;
	always @(posedge clock or posedge reset)
		if (reset)
			reoutput_high_address <= 1'b0;
		else if (master_clear)
			reoutput_high_address <= 1'b0;
		else if (cpu_clock_posedge) begin
			if (state == 32'd3)
				reoutput_high_address <= 1'b0;
			else if (next_word)
				reoutput_high_address <= update_high_address;
			else
				reoutput_high_address <= reoutput_high_address;
		end
		else
			reoutput_high_address <= reoutput_high_address;
	always @(posedge clock or posedge reset)
		if (reset) begin
			terminal_count <= 1'b0;
			terminal_count_internal <= 1'b0;
		end
		else if (master_clear) begin
			terminal_count <= 1'b0;
			terminal_count_internal <= 1'b0;
		end
		else if (cpu_clock_posedge) begin
			if (state == 32'd6) begin
				terminal_count <= 1'b0;
				terminal_count_internal <= 1'b0;
			end
			else if (next_word) begin
				terminal_count <= underflow;
				terminal_count_internal <= underflow;
			end
			else begin
				terminal_count <= 1'b0;
				terminal_count_internal <= terminal_count_internal;
			end
		end
		else begin
			terminal_count <= terminal_count;
			terminal_count_internal <= terminal_count_internal;
		end
	assign end_of_process_n_out = ~terminal_count;
	always @(posedge clock or posedge reset)
		if (reset)
			external_end_of_process <= 1'b0;
		else if (master_clear)
			external_end_of_process <= 1'b0;
		else if (cpu_clock_negedge) begin
			if (state == 32'd0)
				external_end_of_process <= 1'b0;
			else if ((next_state == 32'd3) && ~end_of_process_n_in)
				external_end_of_process <= 1'b1;
			else
				external_end_of_process <= external_end_of_process;
		end
		else
			external_end_of_process <= external_end_of_process;
	always @(posedge clock or posedge reset)
		if (reset)
			end_of_process_internal <= 1'b0;
		else if (master_clear)
			end_of_process_internal <= 1'b0;
		else if (cpu_clock_negedge) begin
			if (next_state == 32'd6)
				end_of_process_internal <= terminal_count_internal | external_end_of_process;
			else
				end_of_process_internal <= 1'b0;
		end
		else
			end_of_process_internal <= end_of_process_internal;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_read_status_register <= 1'b0;
		else if (cpu_clock_negedge)
			prev_read_status_register <= read_status_register;
		else
			prev_read_status_register <= prev_read_status_register;
	always @(posedge clock or posedge reset)
		if (reset)
			terminal_count_state <= 0;
		else if (master_clear)
			terminal_count_state <= 0;
		else if (cpu_clock_negedge) begin
			if (prev_read_status_register & ~read_status_register)
				terminal_count_state <= 0;
			else if (end_of_process_internal)
				terminal_count_state <= terminal_count_state | dma_acknowledge_internal;
			else
				terminal_count_state <= terminal_count_state;
		end
		else
			terminal_count_state <= terminal_count_state;
endmodule
