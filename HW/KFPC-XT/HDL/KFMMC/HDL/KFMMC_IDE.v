//
// KFMMC_IDE
// IDE(PIO) wrapper to access MMC
//
// Written by kitune-san
//
`default_nettype none

module KFMMC_IDE #(
    parameter init_spi_clock_cycle = 8'd010,
    parameter normal_spi_clock_cycle = 8'd002,
    parameter access_block_size = 16'd512,
    parameter timeout = 32'hFFFFFFFF
) (
	input wire clock,
	input wire reset,
	input wire ide_cs1fx_n,
	input wire ide_cs3fx_n,
	input wire ide_io_read_n,
	input wire ide_io_write_n,
	input wire [2:0] ide_address,
	input wire [15:0] ide_data_bus_in,
	output reg [15:0] ide_data_bus_out,
	input wire device_master,
	output wire mmc_od_mode,
	output wire mmc_clk,
	input wire mmc_cmd_in,
	output wire mmc_cmd_out,
	output wire mmc_cmd_io,
	input wire mmc_dat_in,
	output wire mmc_dat_out,
	output wire mmc_dat_io
);

	reg mmc_reset;
	reg [7:0] mmc_data_bus;
	reg [24:0] mmc_ext_data_bus;
	reg mmc_write_block_address;
	reg mmc_write_access_command;
	reg mmc_write_data;
	wire [7:0] mmc_read_data_byte;
	reg mmc_read_data;
	wire mmc_drive_busy;
	wire [39:0] mmc_storage_size;
	wire mmc_read_interface_error;
	wire mmc_read_crc_error;
	wire mmc_write_interface_error;
	wire mmc_read_byte_interrupt;
	wire mmc_read_completion_interrupt;
	wire mmc_request_write_data_interrupt;
	wire mmc_write_completion_interrupt;
	KFMMC_Drive #(
		.init_spi_clock_cycle(init_spi_clock_cycle),
		.normal_spi_clock_cycle(normal_spi_clock_cycle),
		.timeout(timeout)
	) u_KFMMC_Drive(
		.clock(clock),
		.reset(reset | mmc_reset),
		.data_bus(mmc_data_bus),
		.data_bus_extension(mmc_ext_data_bus),
		.write_block_address_1(1'b0),
		.write_block_address_2(1'b0),
		.write_block_address_3(1'b0),
		.write_block_address_4(1'b0),
		.write_block_address_extension(mmc_write_block_address),
		.write_access_command(mmc_write_access_command),
		.write_data(mmc_write_data),
		.read_data_byte(mmc_read_data_byte),
		.read_data(mmc_read_data),
		.drive_busy(mmc_drive_busy),
		.storage_size(mmc_storage_size),
		.read_interface_error(mmc_read_interface_error),
		.read_crc_error(mmc_read_crc_error),
		.write_interface_error(mmc_write_interface_error),
		.read_byte_interrupt(mmc_read_byte_interrupt),
		.read_completion_interrupt(mmc_read_completion_interrupt),
		.request_write_data_interrupt(mmc_request_write_data_interrupt),
		.write_completion_interrupt(mmc_write_completion_interrupt),
		.mmc_od_mode(mmc_od_mode),
		.mmc_clk(mmc_clk),
		.mmc_cmd_in(mmc_cmd_in),
		.mmc_cmd_out(mmc_cmd_out),
		.mmc_cmd_io(mmc_cmd_io),
		.mmc_dat_in(mmc_dat_in),
		.mmc_dat_out(mmc_dat_out),
		.mmc_dat_io(mmc_dat_io)
	);
	reg [2:0] latch_address;
	reg [15:0] latch_data;
	reg prev_read_n;
	reg prev_write_n;
	reg read_edge;
	wire write_edge;
	reg command_cs;
	reg control_cs;
	wire write_command;
	wire write_control;
	always @(posedge clock or posedge reset)
		if (reset) begin
			latch_address <= 3'b000;
			latch_data <= 16'h0000;
			prev_read_n <= 1'b1;
			prev_write_n <= 1'b1;
			read_edge <= 1'b0;
			command_cs <= 1'b0;
			control_cs <= 1'b0;
		end
		else begin
			if (~ide_cs1fx_n | ~ide_cs3fx_n) begin
				latch_address <= ide_address;
				latch_data <= ide_data_bus_in;
			end
			else begin
				latch_address <= latch_address;
				latch_data <= latch_data;
			end
			prev_read_n <= ide_io_read_n;
			prev_write_n <= ide_io_write_n;
			read_edge <= prev_read_n & ~ide_io_read_n;
			command_cs <= ~ide_cs1fx_n;
			control_cs <= ~ide_cs3fx_n;
		end
	assign write_edge = ~prev_write_n & ide_io_write_n;
	assign write_command = command_cs & write_edge;
	assign write_control = control_cs & write_edge;
	wire [31:0] storage_total_sectors = {1'b0, mmc_storage_size[39:9]};
	reg [31:0] calc_storage_chs_state;
	reg calc_storage_chs;
	wire end_of_storage_chs_calc;
	reg [15:0] calc_storage_head_x_spt;
	reg [31:0] calc_storage_temp;
	reg [15:0] storage_cylinder;
	reg [3:0] storage_head;
	reg [7:0] storage_spt;
	always @(posedge clock or posedge reset)
		if (reset) begin
			calc_storage_chs_state <= 32'd0;
			calc_storage_head_x_spt <= 16'h0000;
			calc_storage_temp <= 31'h00000000;
			storage_cylinder <= 16'h0000;
			storage_head <= 4'h0;
			storage_spt <= 8'h00;
		end
		else if (~calc_storage_chs) begin
			calc_storage_chs_state <= 32'd0;
			calc_storage_head_x_spt <= calc_storage_head_x_spt;
			calc_storage_temp <= calc_storage_temp;
			storage_cylinder <= storage_cylinder;
			storage_head <= storage_head;
			storage_spt <= storage_spt;
		end
		else
			casez (calc_storage_chs_state)
				32'd0: begin
					calc_storage_head_x_spt <= 16'h00fc;
					calc_storage_temp <= storage_total_sectors;
					storage_cylinder <= 16'h0000;
					storage_head <= 4'h4;
					storage_spt <= 8'h3f;
					calc_storage_chs_state <= 32'd1;
				end
				32'd1: begin
					calc_storage_head_x_spt <= calc_storage_head_x_spt;
					storage_head <= storage_head;
					storage_spt <= storage_spt;
					if (~|calc_storage_temp || (calc_storage_temp < calc_storage_head_x_spt)) begin
						calc_storage_temp <= calc_storage_temp;
						storage_cylinder <= storage_cylinder;
						calc_storage_chs_state <= 32'd3;
					end
					else if (((storage_head != 4'hf) && (storage_cylinder >= 16'h03ff)) || (storage_cylinder >= 16'h3fff)) begin
						calc_storage_temp <= calc_storage_temp;
						storage_cylinder <= storage_cylinder;
						calc_storage_chs_state <= 32'd2;
					end
					else begin
						calc_storage_temp <= calc_storage_temp - calc_storage_head_x_spt;
						storage_cylinder <= storage_cylinder + 1'b1;
					end
				end
				32'd2:
					if (storage_head == 4'hf) begin
						calc_storage_head_x_spt <= calc_storage_head_x_spt;
						calc_storage_temp <= calc_storage_temp;
						storage_cylinder <= 16'h3fff;
						storage_head <= storage_head;
						storage_spt <= storage_spt;
						calc_storage_chs_state <= 32'd3;
					end
					else begin
						calc_storage_head_x_spt <= calc_storage_head_x_spt + storage_spt;
						calc_storage_temp <= storage_total_sectors;
						storage_cylinder <= 16'h0000;
						storage_head <= storage_head + 1'b1;
						storage_spt <= storage_spt;
						calc_storage_chs_state <= 32'd1;
					end
				32'd3: begin
					calc_storage_head_x_spt <= calc_storage_head_x_spt;
					calc_storage_temp <= calc_storage_temp;
					storage_cylinder <= storage_cylinder;
					storage_head <= storage_head;
					storage_spt <= storage_spt;
					calc_storage_chs_state <= 32'd3;
				end
				default: calc_storage_chs_state <= 32'd0;
			endcase
	assign end_of_storage_chs_calc = calc_storage_chs_state == 32'd3;
	reg [15:0] logical_cylinder;
	reg [3:0] logical_head;
	reg [7:0] logical_spt;
	reg [31:0] calc_lc_state;
	reg start_logical_cylinder;
	wire end_logical_cylinder;
	reg [3:0] calc_lc_head_count;
	reg [9:0] calc_lc_temp;
	reg [31:0] calc_lc_temp_2;
	reg [15:0] result_calc_logical_cylinder;
	always @(posedge clock or posedge reset)
		if (reset) begin
			calc_lc_head_count <= 4'h0;
			calc_lc_temp <= 10'h000;
			calc_lc_temp_2 <= 32'h00000000;
			result_calc_logical_cylinder <= 16'h0000;
			calc_lc_state <= 32'd0;
		end
		else if (~start_logical_cylinder) begin
			calc_lc_head_count <= calc_lc_head_count;
			calc_lc_temp <= calc_lc_temp;
			calc_lc_temp_2 <= calc_lc_temp_2;
			result_calc_logical_cylinder <= result_calc_logical_cylinder;
			calc_lc_state <= 32'd0;
		end
		else
			casez (calc_lc_state)
				32'd0: begin
					calc_lc_head_count <= logical_head;
					calc_lc_temp <= 10'h000;
					calc_lc_temp_2 <= storage_total_sectors;
					result_calc_logical_cylinder <= 16'h0000;
					calc_lc_state <= 32'd1;
				end
				32'd1:
					if (|calc_lc_head_count) begin
						calc_lc_head_count <= calc_lc_head_count - 1'b1;
						calc_lc_temp <= calc_lc_temp + logical_spt;
						calc_lc_temp_2 <= calc_lc_temp_2;
						result_calc_logical_cylinder <= result_calc_logical_cylinder;
						calc_lc_state <= 32'd1;
					end
					else begin
						calc_lc_head_count <= calc_lc_head_count;
						calc_lc_temp <= calc_lc_temp;
						calc_lc_temp_2 <= calc_lc_temp_2;
						result_calc_logical_cylinder <= result_calc_logical_cylinder;
						calc_lc_state <= 32'd2;
					end
				32'd2:
					if ((calc_lc_temp <= calc_lc_temp_2) && ~&result_calc_logical_cylinder) begin
						calc_lc_head_count <= calc_lc_head_count;
						calc_lc_temp <= calc_lc_temp;
						calc_lc_temp_2 <= calc_lc_temp_2 - calc_lc_temp;
						result_calc_logical_cylinder <= result_calc_logical_cylinder + 1'b1;
						calc_lc_state <= 32'd2;
					end
					else begin
						calc_lc_head_count <= calc_lc_head_count;
						calc_lc_temp <= calc_lc_temp;
						result_calc_logical_cylinder <= result_calc_logical_cylinder;
						calc_lc_state <= 32'd3;
					end
				32'd3: begin
					calc_lc_head_count <= calc_lc_head_count;
					calc_lc_temp <= calc_lc_temp;
					result_calc_logical_cylinder <= result_calc_logical_cylinder;
					calc_lc_state <= 32'd3;
				end
				default: begin
					calc_lc_head_count <= calc_lc_head_count;
					calc_lc_temp <= calc_lc_temp;
					result_calc_logical_cylinder <= result_calc_logical_cylinder;
					calc_lc_state <= 32'd0;
				end
			endcase
	assign end_logical_cylinder = calc_lc_state == 32'd3;
	reg [31:0] chs2lba_state;
	reg start_chs2lba;
	wire end_chs2lba;
	reg [3:0] chs2lba_head_count;
	reg [7:0] chs2lba_spt_count;
	reg [19:0] chs2lba_calc_temp;
	reg [31:0] chs2lba;
	reg [31:0] cylinder;
	reg [3:0] head_number;
	reg [15:0] sector_number;
	always @(posedge clock or posedge reset)
		if (reset) begin
			chs2lba_head_count <= 4'h0;
			chs2lba_spt_count <= 8'h00;
			chs2lba_calc_temp <= 20'h00000;
			chs2lba <= 32'h00000000;
			chs2lba_state <= 32'd0;
		end
		else if (~start_chs2lba) begin
			chs2lba_head_count <= chs2lba_head_count;
			chs2lba_spt_count <= chs2lba_spt_count;
			chs2lba_calc_temp <= chs2lba_calc_temp;
			chs2lba <= chs2lba;
			chs2lba_state <= 32'd0;
		end
		else
			casez (chs2lba_state)
				32'd0: begin
					chs2lba_head_count <= logical_head;
					chs2lba_spt_count <= chs2lba_spt_count;
					chs2lba_calc_temp <= {16'h0000, head_number};
					chs2lba <= chs2lba;
					chs2lba_state <= 32'd1;
				end
				32'd1:
					if (|chs2lba_head_count) begin
						chs2lba_head_count <= chs2lba_head_count - 1'b1;
						chs2lba_spt_count <= chs2lba_spt_count;
						chs2lba_calc_temp <= chs2lba_calc_temp + cylinder[15:0];
						chs2lba <= chs2lba;
						chs2lba_state <= 32'd1;
					end
					else begin
						chs2lba_head_count <= chs2lba_head_count;
						chs2lba_spt_count <= logical_spt;
						chs2lba_calc_temp <= chs2lba_calc_temp;
						chs2lba <= 32'h00000000;
						chs2lba_state <= 32'd2;
					end
				32'd2:
					if (|chs2lba_spt_count) begin
						chs2lba_head_count <= chs2lba_head_count;
						chs2lba_spt_count <= chs2lba_spt_count - 1'b1;
						chs2lba_calc_temp <= chs2lba_calc_temp;
						chs2lba <= chs2lba + chs2lba_calc_temp;
						chs2lba_state <= 32'd2;
					end
					else begin
						chs2lba_head_count <= chs2lba_head_count;
						chs2lba_spt_count <= chs2lba_spt_count;
						chs2lba_calc_temp <= chs2lba_calc_temp;
						chs2lba <= (chs2lba + sector_number[7:0]) - 1'b1;
						chs2lba_state <= 32'd3;
					end
				32'd3: begin
					chs2lba_head_count <= chs2lba_head_count;
					chs2lba_spt_count <= chs2lba_spt_count;
					chs2lba_calc_temp <= chs2lba_calc_temp;
					chs2lba <= chs2lba;
					chs2lba_state <= 32'd3;
				end
				default: begin
					chs2lba_head_count <= chs2lba_head_count;
					chs2lba_spt_count <= chs2lba_spt_count;
					chs2lba_calc_temp <= chs2lba_calc_temp;
					chs2lba <= chs2lba;
					chs2lba_state <= 32'd0;
				end
			endcase
	assign end_chs2lba = chs2lba_state == 32'd3;
	reg [7:0] fifo [0:access_block_size - 1];
	reg [7:0] fifo_in;
	reg shift_fifo;
	always @(posedge clock or posedge reset)
		if (reset)
			fifo[0] <= 8'h00;
		else if (shift_fifo)
			fifo[0] <= fifo_in;
		else
			fifo[0] <= fifo[0];
	genvar fifo_index;
	generate
		for (fifo_index = 1; fifo_index < access_block_size; fifo_index = fifo_index + 1) begin : Fifo_Shift
			always @(posedge clock or posedge reset)
				if (reset)
					fifo[fifo_index] <= 8'h00;
				else if (shift_fifo)
					fifo[fifo_index] <= fifo[fifo_index - 1];
				else
					fifo[fifo_index] <= fifo[fifo_index];
		end
	endgenerate
	reg busy;
	reg device_ready;
	reg data_request;
	reg error_flag;
	wire [7:0] status = {busy, device_ready, 2'b00, data_request, 2'b00, error_flag};
	reg [7:0] error;
	reg [7:0] features;
	reg [15:0] sector_count;
	reg select_drive;
	reg select_lba;
	wire [27:0] lba28_address = {head_number, cylinder[15:0], sector_number[7:0]};
	wire [47:0] lba48_address = {cylinder[31:16], sector_number[15:8], cylinder[15:0], sector_number[7:0]};
	wire [15:0] identify [0:256];
	reg [9:0] identify_index;
	wire [15:0] identify_out = identify[identify_index[8:1]];
	reg [31:0] state;
	reg [31:0] ret_state;
	reg [7:0] command;
	reg [10:0] trans_fifo_index;
	reg [31:0] mmc_access_block;
	reg [8:0] remaining_sector_count;
	always @(posedge clock or posedge reset)
		if (reset) begin
			state <= 32'd0;
			ret_state <= 32'd0;
			mmc_reset <= 1'b0;
			busy <= 1'b1;
			device_ready <= 1'b0;
			data_request <= 1'b0;
			error_flag <= 1'b0;
			error <= 8'h01;
			calc_storage_chs <= 1'b0;
			logical_cylinder <= 16'h03ff;
			logical_head <= 4'hf;
			logical_spt <= 8'h3f;
			fifo_in <= 1'b0;
			shift_fifo <= 1'b0;
			identify_index <= 10'h000;
			mmc_data_bus <= 8'hff;
			mmc_ext_data_bus <= 24'hffffff;
			mmc_write_block_address <= 1'b0;
			mmc_write_access_command <= 1'b0;
			mmc_write_data <= 1'b0;
			mmc_read_data <= 1'b0;
			command <= 8'h00;
			trans_fifo_index <= 10'h000;
			mmc_access_block <= 32'h00000000;
			remaining_sector_count <= 9'h000;
		end
		else if ((write_control && (latch_address == 3'b110)) && (latch_data[2] == 1'b1))
			mmc_reset <= 1'b1;
		else if (mmc_reset) begin
			mmc_reset <= 1'b0;
			state <= 32'd0;
			busy <= 1'b1;
			device_ready <= 1'b0;
		end
		else
			casez (state)
				32'd0: begin
					state <= 32'd1;
					mmc_reset <= 1'b0;
					busy <= 1'b1;
					device_ready <= 1'b0;
					data_request <= 1'b0;
					error_flag <= 1'b0;
					error <= 8'h01;
					mmc_data_bus <= 8'hff;
					mmc_ext_data_bus <= 24'hffffff;
					mmc_write_block_address <= 1'b0;
					mmc_write_access_command <= 1'b0;
					mmc_write_data <= 1'b0;
					mmc_read_data <= 1'b0;
					command <= 8'h00;
					trans_fifo_index <= 10'h000;
				end
				32'd1:
					if (~mmc_drive_busy)
						state <= 32'd2;
				32'd2: begin
					calc_storage_chs <= 1'b1;
					logical_cylinder <= storage_cylinder;
					logical_head <= storage_head;
					logical_spt <= storage_spt;
					if (end_of_storage_chs_calc) begin
						calc_storage_chs <= 1'b0;
						state <= 32'd3;
					end
				end
				32'd3:
					if ((~write_command || (latch_address != 3'b111)) || (~device_master != select_drive)) begin
						busy <= 1'b0;
						device_ready <= 1'b1;
					end
					else begin
						busy <= 1'b1;
						device_ready <= 1'b0;
						command <= latch_data;
						state <= 32'd4;
					end
				32'd4: begin
					busy <= 1'b1;
					device_ready <= 1'b0;
					data_request <= 1'b0;
					error_flag <= 1'b0;
					error <= 8'b00000000;
					casez (command)
						8'h08: state <= 32'd5; // DEVICE_RESET
						8'h90: state <= 32'd6; // EXECUTE DEVICE DIAGNOSTIC
						8'hec: state <= 32'd7; // IDENTIFY DEVICE
						8'hef: state <= 32'd26; // SET FEATURES
						8'h91: state <= 32'd9; // INITIALIZE DEVICE PARAMETERS
						8'h20: state <= 32'd10; // READ SECTOR(S)
						8'h21: state <= 32'd10; // READ SECTOR(S) with retry
						8'h30: state <= 32'd16; // WRITE SECTOR(S)
						8'h31: state <= 32'd16; // WRITE SECTOR(S) with retry
						8'h40: state <= 32'd10; // READ VERIFY SECTOR(S)
						8'h41: state <= 32'd10; // READ VERIFY SECTOR(S) with retry
						8'hc4: state <= 32'd10; // READ MULTIPLE
						8'hc5: state <= 32'd16; // WRITE MULTIPLE 
//						8'hc6: state <= 32'd24; // SET MULTIPLE (IDLE) -> No boot MS-Dos
						8'h70: state <= 32'd25; // SEEK
						default: state <= 32'd26; // CMD_NO_SUPPORT
					endcase
				end
				32'd5: begin
					mmc_reset <= 1'b1;
					state <= 32'd1;
				end
				32'd6: begin
					mmc_reset <= 1'b1;
					state <= 32'd1;
				end
				32'd7: begin
					identify_index <= 10'h000;
					state <= 32'd8;
				end
				32'd8:
					if (identify_index < access_block_size) begin
						identify_index <= identify_index + 1'b1;
						fifo_in <= (identify_index[0] ? identify_out[15:8] : identify_out[7:0]);
						shift_fifo <= 1'b1;
					end
					else begin
						fifo_in <= 8'h00;
						shift_fifo <= 1'b0;
						ret_state <= 32'd3;
						state <= 32'd28;
					end
				32'd9: begin
					logical_head <= head_number;
					logical_spt <= sector_count[7:0];
					logical_cylinder <= result_calc_logical_cylinder;
					if (~end_logical_cylinder)
						start_logical_cylinder <= 1'b1;
					else begin
						start_logical_cylinder <= 1'b0;
						state <= 32'd3;
					end
				end
				32'd10: begin
					state <= 32'd27;
					ret_state <= 32'd11;
				end
				32'd11: begin
					mmc_data_bus <= mmc_access_block[7:0];
					mmc_ext_data_bus <= mmc_access_block[31:8];
					if (|remaining_sector_count) begin
						if (mmc_drive_busy)
							mmc_read_data <= 1'b1;
						else begin
							mmc_read_data <= 1'b0;
							mmc_write_block_address <= 1'b1;
							state <= 32'd12;
						end
					end
					else
						state <= 32'd3;
				end
				32'd12: begin
					mmc_data_bus <= 8'h80;
					mmc_write_block_address <= 1'b0;
					mmc_write_access_command <= 1'b1;
					state <= 32'd13;
				end
				32'd13: begin
					mmc_write_access_command <= 1'b0;
					if (mmc_read_interface_error | mmc_read_crc_error) begin
						shift_fifo <= 1'b0;
						mmc_read_data <= 1'b1;
						error_flag <= 1'b1;
						error <= 8'b01000000;
						state <= 32'd15;
					end
					else if (mmc_read_completion_interrupt) begin
						shift_fifo <= 1'b0;
						mmc_read_data <= 1'b1;
						remaining_sector_count <= remaining_sector_count - 1'b1;
						state <= 32'd15;
					end
					else if (mmc_read_byte_interrupt) begin
						fifo_in <= mmc_read_data_byte;
						shift_fifo <= 1'b1;
						mmc_read_data <= 1'b1;
						state <= 32'd14;
					end
					else begin
						shift_fifo <= 1'b0;
						mmc_read_data <= 1'b0;
					end
				end
				32'd14: begin
					shift_fifo <= 1'b0;
					mmc_read_data <= 1'b0;
					state <= 32'd13;
				end
				32'd15: begin
					shift_fifo <= 1'b0;
					mmc_read_data <= 1'b0;
					mmc_access_block <= mmc_access_block + 1'b1;
					if (error_flag)
						state <= 32'd3;
					else if ((command == 8'h40) || (command == 8'h41))
						state <= 32'd11;
					else begin
						state <= 32'd28;
						ret_state <= 32'd11;
					end
				end
				32'd16: begin
					state <= 32'd27;
					ret_state <= 32'd17;
				end
				32'd17: begin
					mmc_data_bus <= mmc_access_block[7:0];
					mmc_ext_data_bus <= mmc_access_block[31:8];
					if (|remaining_sector_count) begin
						mmc_write_block_address <= 1'b1;
						trans_fifo_index <= access_block_size;
						state <= 32'd18;
					end
					else
						state <= 32'd3;
				end
				32'd18: begin
					busy <= 1'b0;
					data_request <= 1'b1;
					mmc_write_block_address <= 1'b0;
					fifo_in <= latch_data[7:0];
					if (~write_command || (ide_address != 3'b000))
						shift_fifo <= 1'b0;
					else begin
						shift_fifo <= 1'b1;
						trans_fifo_index <= {trans_fifo_index[10:1] - 1'b1, 1'b0};
						state <= 32'd19;
					end
				end
				32'd19: begin
					fifo_in <= latch_data[15:8];
					shift_fifo <= 1'b1;
					if (|trans_fifo_index)
						state <= 32'd18;
					else begin
						busy <= 1'b1;
						data_request <= 1'b0;
						state <= 32'd20;
					end
				end
				32'd20:
					if (mmc_drive_busy)
						mmc_read_data <= 1'b1;
					else begin
						mmc_read_data <= 1'b0;
						shift_fifo <= 1'b0;
						mmc_data_bus <= 8'h81;
						mmc_write_access_command <= 1'b1;
						state <= 32'd21;
					end
				32'd21: begin
					mmc_write_access_command <= 1'b0;
					if (mmc_write_interface_error) begin
						shift_fifo <= 1'b0;
						mmc_read_data <= 1'b1;
						mmc_write_data <= 1'b0;
						error_flag <= 1'b1;
						error <= 8'b01000000;
						state <= 32'd23;
					end
					else if (mmc_write_completion_interrupt) begin
						shift_fifo <= 1'b0;
						mmc_read_data <= 1'b1;
						mmc_write_data <= 1'b0;
						remaining_sector_count <= remaining_sector_count - 1'b1;
						state <= 32'd23;
					end
					else if (mmc_request_write_data_interrupt) begin
						mmc_data_bus <= fifo[access_block_size - 1];
						shift_fifo <= 1'b1;
						mmc_read_data <= 1'b0;
						mmc_write_data <= 1'b1;
						state <= 32'd22;
					end
					else begin
						shift_fifo <= 1'b0;
						mmc_read_data <= 1'b0;
						mmc_write_data <= 1'b0;
					end
				end
				32'd22: begin
					shift_fifo <= 1'b0;
					mmc_write_data <= 1'b0;
					if (~mmc_request_write_data_interrupt)
						state <= 32'd21;
				end
				32'd23: begin
					shift_fifo <= 1'b0;
					mmc_read_data <= 1'b0;
					mmc_write_data <= 1'b0;
					mmc_access_block <= mmc_access_block + 1'b1;
					if (error_flag)
						state <= 32'd3;
					else
						state <= 32'd17;
				end
				32'd24: state <= 32'd3;
				32'd25: state <= 32'd3;
				32'd26: begin
					error_flag <= 1'b1;
					error <= 8'b00000100;
					state <= 32'd3;
				end
				32'd27: begin
					remaining_sector_count <= {(sector_count[7:0] == 8'h00 ? 1'b1 : 1'b0), sector_count[7:0]};
					if (select_lba) begin
						start_chs2lba <= 1'b0;
						mmc_access_block <= {4'h0, lba28_address};
						state <= ret_state;
					end
					else if (~end_chs2lba)
						start_chs2lba <= 1'b1;
					else begin
						start_chs2lba <= 1'b0;
						mmc_access_block <= chs2lba;
						state <= ret_state;
					end
				end
				32'd28: begin
					trans_fifo_index <= access_block_size;
					state <= 32'd29;
				end
				32'd29: begin
					busy <= 1'b0;
					data_request <= 1'b1;
					if ((read_edge && command_cs) && (ide_address == 3'b000)) begin
						shift_fifo <= 1'b1;
						state <= 32'd30;
					end
				end
				32'd30: begin
					trans_fifo_index <= {trans_fifo_index[10:1] - 1'b1, 1'b0};
					shift_fifo <= 1'b1;
					state <= 32'd31;
				end
				32'd31: begin
					shift_fifo <= 1'b0;
					if (|trans_fifo_index)
						state <= 32'd29;
					else begin
						busy <= 1'b1;
						data_request <= 1'b0;
						state <= ret_state;
					end
				end
				default: state <= 32'd1;
			endcase
	always @(posedge clock or posedge reset)
		if (reset)
			features <= 8'h00;
		else if (mmc_reset)
			features <= 8'h00;
		else if (write_command && (latch_address == 3'b001))
			features <= latch_data;
		else
			features <= features;
	always @(posedge clock or posedge reset)
		if (reset)
			sector_count <= 16'h0001;
		else if (mmc_reset)
			sector_count <= 16'h0001;
		else if (write_command && (latch_address == 3'b010))
			sector_count <= {sector_count[7:0], latch_data[7:0]};
		else
			sector_count <= sector_count;
	always @(posedge clock or posedge reset)
		if (reset)
			sector_number <= 16'h0001;
		else if (mmc_reset)
			sector_number <= 16'h0001;
		else if (write_command && (latch_address == 3'b011))
			sector_number <= {sector_number[7:0], latch_data[7:0]};
		else
			sector_number <= sector_number;
	always @(posedge clock or posedge reset)
		if (reset)
			cylinder <= 32'h00000000;
		else if (mmc_reset)
			cylinder <= 32'h00000000;
		else if (write_command && (latch_address == 3'b100))
			cylinder <= {cylinder[31:24], cylinder[7:0], cylinder[15:8], latch_data[7:0]};
		else if (write_command && (latch_address == 3'b101))
			cylinder <= {cylinder[15:8], cylinder[23:16], latch_data[7:0], cylinder[7:0]};
		else
			cylinder <= cylinder;
	always @(posedge clock or posedge reset)
		if (reset)
			head_number <= 4'h0;
		else if (mmc_reset)
			head_number <= 4'h0;
		else if (write_command && (latch_address == 3'b110))
			head_number <= latch_data[3:0];
		else
			head_number <= head_number;
	always @(posedge clock or posedge reset)
		if (reset)
			select_drive <= 1'b0;
		else if (mmc_reset)
			select_drive <= 1'b0;
		else if (write_command && (latch_address == 3'b110))
			select_drive <= latch_data[4];
		else
			select_drive <= select_drive;
	always @(posedge clock or posedge reset)
		if (reset)
			select_lba <= 1'b0;
		else if (mmc_reset)
			select_lba <= 1'b0;
		else if (write_command && (latch_address == 3'b110))
			select_lba <= latch_data[6];
		else
			select_lba <= select_lba;
	always @(posedge clock or posedge reset)
		if (reset)
			ide_data_bus_out <= 16'hffff;
		else if (~read_edge)
			ide_data_bus_out <= ide_data_bus_out;
		else if (command_cs)
			casez (ide_address)
				3'b000: ide_data_bus_out <= {fifo[access_block_size - 2], fifo[access_block_size - 1]};
				3'b001: ide_data_bus_out <= {8'h00, error};
				3'b010: ide_data_bus_out <= {8'h00, sector_count[7:0]};
				3'b011: ide_data_bus_out <= {8'h00, sector_number[7:0]};
				3'b100: ide_data_bus_out <= {8'h00, cylinder[7:0]};
				3'b101: ide_data_bus_out <= {8'h00, cylinder[15:8]};
				3'b110: ide_data_bus_out <= {1'b1, select_lba, 1'b1, select_drive, head_number};
				3'b111: ide_data_bus_out <= {8'h00, status};
				default: ide_data_bus_out <= 16'hffff;
			endcase
		else if (control_cs)
			casez (ide_address[0])
				1'b0: ide_data_bus_out <= {8'h00, status};
				1'b1: ide_data_bus_out <= {2'b01, head_number, ~select_drive, select_drive};
				default: ide_data_bus_out <= 16'hffff;
			endcase
		else
			ide_data_bus_out <= ide_data_bus_out;
	assign identify[0] = 16'b0000000001000000;
	assign identify[1] = storage_cylinder;
	assign identify[2] = 16'h0000;
	assign identify[3] = {12'h000, storage_head};
	assign identify[4] = 16'h0000;
	assign identify[5] = 16'h0000;
	assign identify[6] = {8'h00, storage_spt};
	assign identify[7] = 16'h0000;
	assign identify[8] = 16'h0000;
	assign identify[9] = 16'h0000;
	assign identify[10] = 16'h4b46;
	assign identify[11] = 16'h4d4d;
	assign identify[12] = 16'h4349;
	assign identify[13] = 16'h4445;
	assign identify[14] = 16'h3030;
	assign identify[15] = 16'h3030;
	assign identify[16] = 16'h3020;
	assign identify[17] = 16'h2020;
	assign identify[18] = 16'h2020;
	assign identify[19] = 16'h2020;
	assign identify[20] = 16'h0000;
	assign identify[21] = 16'h0000;
	assign identify[22] = 16'h0000;
	assign identify[23] = 16'h3030;
	assign identify[24] = 16'h3030;
	assign identify[25] = 16'h3030;
	assign identify[26] = 16'h3030;
	assign identify[27] = 16'h4b46;
	assign identify[28] = 16'h4d4d;
	assign identify[29] = 16'h4349;
	assign identify[30] = 16'h4445;
	assign identify[31] = 16'h3030;
	assign identify[32] = 16'h3030;
	assign identify[33] = 16'h3020;
	assign identify[34] = 16'h2020;
	assign identify[35] = 16'h2020;
	assign identify[36] = 16'h2020;
	assign identify[37] = 16'h2020;
	assign identify[38] = 16'h2020;
	assign identify[39] = 16'h2020;
	assign identify[40] = 16'h2020;
	assign identify[41] = 16'h2020;
	assign identify[42] = 16'h2020;
	assign identify[43] = 16'h2020;
	assign identify[44] = 16'h2020;
	assign identify[45] = 16'h2020;
	assign identify[46] = 16'h2020;
	assign identify[47] = 16'h8001;
	assign identify[48] = 16'h0000;
	assign identify[49] = 16'b0000001000000000;
	assign identify[50] = 16'b0100000000000001;
	assign identify[51] = 16'h0200;
	assign identify[52] = 16'h0200;
	assign identify[53] = 16'b0000000000000111;
	assign identify[54] = logical_cylinder;
	assign identify[55] = {12'h000, logical_head};
	assign identify[56] = {8'h00, logical_spt};
	assign identify[57] = storage_total_sectors[15:0];
	assign identify[58] = storage_total_sectors[31:16];
	assign identify[59] = 16'b0000000000000000;
	assign identify[60] = storage_total_sectors[15:0];
	assign identify[61] = storage_total_sectors[31:16];
	assign identify[62] = 16'h0000;
	assign identify[63] = 16'b0000000000000000;
	assign identify[64] = 16'b0000000000000000;
	assign identify[65] = 16'h0078;
	assign identify[66] = 16'h0078;
	assign identify[67] = 16'h0078;
	assign identify[68] = 16'h0078;
	assign identify[69] = 16'h0000;
	assign identify[70] = 16'h0000;
	assign identify[71] = 16'h0000;
	assign identify[72] = 16'h0000;
	assign identify[73] = 16'h0000;
	assign identify[74] = 16'h0000;
	assign identify[75] = 16'h0000;
	assign identify[76] = 16'h0000;
	assign identify[77] = 16'h0000;
	assign identify[78] = 16'h0000;
	assign identify[79] = 16'h0000;
	assign identify[80] = 16'b0000000001111110;
	assign identify[81] = 16'h0000;
	assign identify[82] = 16'b0000000000000000;
	assign identify[83] = 16'b0000000000000000;
	assign identify[84] = 16'b0000000000000000;
	assign identify[85] = 16'b0000000000000000;
	assign identify[86] = 16'b0000000000000000;
	assign identify[87] = 16'b0000000000000000;
	assign identify[88] = 16'b0000000000000000;
	assign identify[89] = 16'h0000;
	assign identify[90] = 16'h0000;
	assign identify[91] = 16'h0000;
	assign identify[92] = 16'h0000;
	assign identify[93] = 16'b0110001100001011;
	assign identify[94] = 16'h0000;
	assign identify[95] = 16'h0000;
	assign identify[96] = 16'h0000;
	assign identify[97] = 16'h0000;
	assign identify[98] = 16'h0000;
	assign identify[99] = 16'h0000;
	assign identify[100] = 16'h0000;
	assign identify[101] = 16'h0000;
	assign identify[102] = 16'h0000;
	assign identify[103] = 16'h0000;
	assign identify[104] = 16'h0000;
	assign identify[105] = 16'h0000;
	assign identify[106] = 16'h0000;
	assign identify[107] = 16'h0000;
	assign identify[108] = 16'h0000;
	assign identify[109] = 16'h0000;
	assign identify[110] = 16'h0000;
	assign identify[111] = 16'h0000;
	assign identify[112] = 16'h0000;
	assign identify[113] = 16'h0000;
	assign identify[114] = 16'h0000;
	assign identify[115] = 16'h0000;
	assign identify[116] = 16'h0000;
	assign identify[117] = 16'h0000;
	assign identify[118] = 16'h0000;
	assign identify[119] = 16'h0000;
	assign identify[120] = 16'h0000;
	assign identify[121] = 16'h0000;
	assign identify[122] = 16'h0000;
	assign identify[123] = 16'h0000;
	assign identify[124] = 16'h0000;
	assign identify[125] = 16'h0000;
	assign identify[126] = 16'h0000;
	assign identify[127] = 16'h0000;
	assign identify[128] = 16'h0000;
	assign identify[129] = 16'h0000;
	assign identify[130] = 16'h0000;
	assign identify[131] = 16'h0000;
	assign identify[132] = 16'h0000;
	assign identify[133] = 16'h0000;
	assign identify[134] = 16'h0000;
	assign identify[135] = 16'h0000;
	assign identify[136] = 16'h0000;
	assign identify[137] = 16'h0000;
	assign identify[138] = 16'h0000;
	assign identify[139] = 16'h0000;
	assign identify[140] = 16'h0000;
	assign identify[141] = 16'h0000;
	assign identify[142] = 16'h0000;
	assign identify[143] = 16'h0000;
	assign identify[144] = 16'h0000;
	assign identify[145] = 16'h0000;
	assign identify[146] = 16'h0000;
	assign identify[147] = 16'h0000;
	assign identify[148] = 16'h0000;
	assign identify[149] = 16'h0000;
	assign identify[150] = 16'h0000;
	assign identify[151] = 16'h0000;
	assign identify[152] = 16'h0000;
	assign identify[153] = 16'h0000;
	assign identify[154] = 16'h0000;
	assign identify[155] = 16'h0000;
	assign identify[156] = 16'h0000;
	assign identify[157] = 16'h0000;
	assign identify[158] = 16'h0000;
	assign identify[159] = 16'h0000;
	assign identify[160] = 16'h0000;
	assign identify[161] = 16'h0000;
	assign identify[162] = 16'h0000;
	assign identify[163] = 16'h0000;
	assign identify[164] = 16'h0000;
	assign identify[165] = 16'h0000;
	assign identify[166] = 16'h0000;
	assign identify[167] = 16'h0000;
	assign identify[168] = 16'h0000;
	assign identify[169] = 16'h0000;
	assign identify[170] = 16'h0000;
	assign identify[171] = 16'h0000;
	assign identify[172] = 16'h0000;
	assign identify[173] = 16'h0000;
	assign identify[174] = 16'h0000;
	assign identify[175] = 16'h0000;
	assign identify[176] = 16'h0000;
	assign identify[177] = 16'h0000;
	assign identify[178] = 16'h0000;
	assign identify[179] = 16'h0000;
	assign identify[180] = 16'h0000;
	assign identify[181] = 16'h0000;
	assign identify[182] = 16'h0000;
	assign identify[183] = 16'h0000;
	assign identify[184] = 16'h0000;
	assign identify[185] = 16'h0000;
	assign identify[186] = 16'h0000;
	assign identify[187] = 16'h0000;
	assign identify[188] = 16'h0000;
	assign identify[189] = 16'h0000;
	assign identify[190] = 16'h0000;
	assign identify[191] = 16'h0000;
	assign identify[192] = 16'h0000;
	assign identify[193] = 16'h0000;
	assign identify[194] = 16'h0000;
	assign identify[195] = 16'h0000;
	assign identify[196] = 16'h0000;
	assign identify[197] = 16'h0000;
	assign identify[198] = 16'h0000;
	assign identify[199] = 16'h0000;
	assign identify[200] = 16'h0000;
	assign identify[201] = 16'h0000;
	assign identify[202] = 16'h0000;
	assign identify[203] = 16'h0000;
	assign identify[204] = 16'h0000;
	assign identify[205] = 16'h0000;
	assign identify[206] = 16'h0000;
	assign identify[207] = 16'h0000;
	assign identify[208] = 16'h0000;
	assign identify[209] = 16'h0000;
	assign identify[210] = 16'h0000;
	assign identify[211] = 16'h0000;
	assign identify[212] = 16'h0000;
	assign identify[213] = 16'h0000;
	assign identify[214] = 16'h0000;
	assign identify[215] = 16'h0000;
	assign identify[216] = 16'h0000;
	assign identify[217] = 16'h0000;
	assign identify[218] = 16'h0000;
	assign identify[219] = 16'h0000;
	assign identify[220] = 16'h0000;
	assign identify[221] = 16'h0000;
	assign identify[222] = 16'h0000;
	assign identify[223] = 16'h0000;
	assign identify[224] = 16'h0000;
	assign identify[225] = 16'h0000;
	assign identify[226] = 16'h0000;
	assign identify[227] = 16'h0000;
	assign identify[228] = 16'h0000;
	assign identify[229] = 16'h0000;
	assign identify[230] = 16'h0000;
	assign identify[231] = 16'h0000;
	assign identify[232] = 16'h0000;
	assign identify[233] = 16'h0000;
	assign identify[234] = 16'h0000;
	assign identify[235] = 16'h0000;
	assign identify[236] = 16'h0000;
	assign identify[237] = 16'h0000;
	assign identify[238] = 16'h0000;
	assign identify[239] = 16'h0000;
	assign identify[240] = 16'h0000;
	assign identify[241] = 16'h0000;
	assign identify[242] = 16'h0000;
	assign identify[243] = 16'h0000;
	assign identify[244] = 16'h0000;
	assign identify[245] = 16'h0000;
	assign identify[246] = 16'h0000;
	assign identify[247] = 16'h0000;
	assign identify[248] = 16'h0000;
	assign identify[249] = 16'h0000;
	assign identify[250] = 16'h0000;
	assign identify[251] = 16'h0000;
	assign identify[252] = 16'h0000;
	assign identify[253] = 16'h0000;
	assign identify[254] = 16'h0000;
	assign identify[255] = 16'h0000;
endmodule
