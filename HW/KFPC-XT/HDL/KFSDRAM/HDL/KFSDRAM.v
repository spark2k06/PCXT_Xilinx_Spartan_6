module KFSDRAM (
	sdram_clock,
	sdram_reset,
	address,
	access_num,
	data_in,
	data_out,
	write_request,
	read_request,
	enable_refresh,
	write_flag,
	read_flag,
	refresh_mode,
	idle,
	sdram_address,
	sdram_cke,
	sdram_cs,
	sdram_ras,
	sdram_cas,
	sdram_we,
	sdram_ba,
	sdram_dq_in,
	sdram_dq_out,
	sdram_dq_io
);
	parameter sdram_col_width = 9;
	parameter sdram_row_width = 13;
	parameter sdram_bank_width = 2;
	parameter sdram_data_width = 16;
	parameter sdram_no_refresh = 1'b0;
	parameter sdram_trc = 16'd5 - 16'd1;
	parameter sdram_trp = 16'd1 - 16'd1;
	parameter sdram_tmrd = 16'd2 - 16'd1;
	parameter sdram_trcd = 16'd1 - 16'd1;
	parameter sdram_tdpl = 16'd2 - 16'd1;
	parameter cas_latency = 3'b010;
	parameter sdram_init_wait = 16'd10000;
	parameter sdram_refresh_cycle = 16'd100;
	input wire sdram_clock;
	input wire sdram_reset;
	input wire [((sdram_col_width + sdram_row_width) + sdram_bank_width) - 1:0] address;
	input wire [sdram_col_width - 1:0] access_num;
	input wire [sdram_data_width - 1:0] data_in;
	output wire [sdram_data_width - 1:0] data_out;
	input wire write_request;
	input wire read_request;
	input wire enable_refresh;
	output wire write_flag;
	output wire read_flag;
	output wire refresh_mode;
	output wire idle;
	output reg [sdram_row_width - 1:0] sdram_address;
	output reg sdram_cke;
	output reg sdram_cs;
	output reg sdram_ras;
	output reg sdram_cas;
	output reg sdram_we;
	output reg [sdram_bank_width - 1:0] sdram_ba;
	input wire [sdram_data_width - 1:0] sdram_dq_in;
	output reg [sdram_data_width - 1:0] sdram_dq_out;
	output reg sdram_dq_io;
	reg [31:0] state;
	reg [31:0] next_state;
	reg [15:0] state_counter;
	reg [15:0] refresh_counter;
	reg [sdram_col_width - 1:0] access_counter;
	reg [sdram_col_width - 1:0] read_counter;
	wire send_cmd_timing;
	wire end_read_cmd;
	always @(*) begin
		next_state = state;
		casez (state)
			32'd0:
				if (state_counter == sdram_init_wait)
					next_state = 32'd1;
			32'd1:
				if (state_counter == sdram_trp)
					next_state = 32'd2;
			32'd2:
				if (state_counter == sdram_trc)
					next_state = 32'd3;
			32'd3:
				if (state_counter == sdram_trc)
					next_state = 32'd4;
			32'd4:
				if (state_counter == sdram_tmrd)
					next_state = 32'd7;
			32'd5:
				if (state_counter == sdram_trp)
					next_state = 32'd6;
			32'd6:
				if (state_counter == sdram_trc)
					next_state = 32'd7;
			32'd7:
				if (write_request)
					next_state = 32'd8;
				else if (read_request)
					next_state = 32'd10;
				else if ((~sdram_no_refresh && enable_refresh) && (refresh_counter == sdram_refresh_cycle))
					next_state = 32'd5;
			32'd8:
				if (access_counter == (access_num - 1))
					next_state = 32'd9;
			32'd9:
				if (state_counter == sdram_tdpl)
					next_state = 32'd11;
			32'd10:
				if (end_read_cmd && (read_counter == access_num))
					next_state = 32'd11;
			32'd11:
				if (state_counter == sdram_trp)
					next_state = 32'd7;
			default: next_state = 32'd0;
		endcase
	end
	always @(posedge sdram_clock or posedge sdram_reset)
		if (sdram_reset)
			state <= 32'd0;
		else
			state <= next_state;
	always @(posedge sdram_clock or posedge sdram_reset)
		if (sdram_reset)
			state_counter <= 0;
		else if (next_state != state)
			state_counter <= 0;
		else
			state_counter <= state_counter + 16'h0001;
	always @(posedge sdram_clock or posedge sdram_reset)
		if (sdram_reset)
			refresh_counter <= 0;
		else if (~sdram_cs && ((~sdram_ras & ~sdram_cas) & sdram_we))
			refresh_counter <= 0;
		else if (refresh_counter != sdram_refresh_cycle)
			refresh_counter <= refresh_counter + 16'h0001;
		else
			refresh_counter <= refresh_counter;
	always @(posedge sdram_clock or posedge sdram_reset)
		if (sdram_reset)
			access_counter <= 0;
		else if ((state == 32'd8) || (state == 32'd10))
			access_counter <= access_counter + 1;
		else
			access_counter <= 0;
	always @(posedge sdram_clock or posedge sdram_reset)
		if (sdram_reset)
			read_counter <= 0;
		else if (state != 32'd10)
			read_counter <= 0;
		else if (state_counter <= cas_latency)
			read_counter <= 0;
		else if (read_counter != access_num)
			read_counter <= read_counter + 1;
		else
			read_counter <= read_counter;
	assign send_cmd_timing = state_counter == 0;
	assign end_read_cmd = state_counter >= access_num;
	always @(posedge sdram_clock or posedge sdram_reset)
		if (sdram_reset) begin
			sdram_address <= 0;
			sdram_cke <= 1'b0;
			sdram_cs <= 1'b1;
			sdram_ras <= 1'b1;
			sdram_cas <= 1'b1;
			sdram_we <= 1'b1;
			sdram_ba <= 0;
			sdram_dq_out <= 0;
			sdram_dq_io <= 1'b1;
		end
		else
			casez (state)
				32'd0: begin
					sdram_address <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= 1'b1;
					sdram_cas <= 1'b1;
					sdram_we <= 1'b1;
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd1: begin
					sdram_address[9:0] <= 0;
					sdram_address[10] <= 1'b1;
					sdram_address[sdram_row_width - 1:11] <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= 1'b1;
					sdram_we <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd2: begin
					sdram_address <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_we <= 1'b1;
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd3: begin
					sdram_address <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_we <= 1'b1;
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd4: begin
					sdram_address[9:0] <= (send_cmd_timing ? {2'b00, cas_latency, 4'b0000} : 0);
					sdram_address[sdram_row_width - 1:10] <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_we <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd5: begin
					sdram_address[9:0] <= 0;
					sdram_address[10] <= 1'b1;
					sdram_address[sdram_row_width - 1:11] <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= 1'b1;
					sdram_we <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd6: begin
					sdram_address <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_we <= 1'b1;
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd7:
					if (next_state == 32'd8) begin
						sdram_address <= address[(sdram_col_width + sdram_row_width) - 1:sdram_col_width];
						sdram_cke <= 1'b1;
						sdram_cs <= 1'b0;
						sdram_ras <= 1'b0;
						sdram_cas <= 1'b1;
						sdram_we <= 1'b1;
						sdram_ba <= address[((sdram_col_width + sdram_row_width) + sdram_bank_width) - 1:sdram_col_width + sdram_row_width];
						sdram_dq_out <= 0;
						sdram_dq_io <= 1'b1;
					end
					else if (next_state == 32'd10) begin
						sdram_address <= address[(sdram_col_width + sdram_row_width) - 1:sdram_col_width];
						sdram_cke <= 1'b1;
						sdram_cs <= 1'b0;
						sdram_ras <= 1'b0;
						sdram_cas <= 1'b1;
						sdram_we <= 1'b1;
						sdram_ba <= address[((sdram_col_width + sdram_row_width) + sdram_bank_width) - 1:sdram_col_width + sdram_row_width];
						sdram_dq_out <= 0;
						sdram_dq_io <= 1'b1;
					end
					else begin
						sdram_address <= 0;
						sdram_cke <= 1'b1;
						sdram_cs <= 1'b0;
						sdram_ras <= 1'b1;
						sdram_cas <= 1'b1;
						sdram_we <= 1'b1;
						sdram_ba <= 0;
						sdram_dq_out <= 0;
						sdram_dq_io <= 1'b1;
					end
				32'd8: begin
					sdram_address[sdram_col_width - 1:0] <= address[sdram_col_width - 1:0] + access_counter;
					sdram_address[sdram_row_width - 1:sdram_col_width] <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= 1'b1;
					sdram_cas <= 1'b0;
					sdram_we <= 1'b0;
					sdram_ba <= address[((sdram_col_width + sdram_row_width) + sdram_bank_width) - 1:sdram_col_width + sdram_row_width];
					sdram_dq_out <= data_in;
					sdram_dq_io <= 1'b0;
				end
				32'd9: begin
					sdram_address <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= 1'b1;
					sdram_cas <= 1'b1;
					sdram_we <= 1'b1;
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd10: begin
					sdram_address[sdram_col_width - 1:0] <= (~end_read_cmd ? address[sdram_col_width - 1:0] + access_counter : 0);
					sdram_address[sdram_row_width - 1:sdram_col_width] <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= 1'b1;
					sdram_cas <= (~end_read_cmd ? 1'b0 : 1'b1);
					sdram_we <= 1'b1;
					sdram_ba <= (~end_read_cmd ? address[((sdram_col_width + sdram_row_width) + sdram_bank_width) - 1:sdram_col_width + sdram_row_width] : 0);
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				32'd11: begin
					sdram_address[9:0] <= 0;
					sdram_address[10] <= 1'b1;
					sdram_address[sdram_row_width - 1:11] <= 0;
					sdram_cke <= 1'b1;
					sdram_cs <= 1'b0;
					sdram_ras <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_cas <= 1'b1;
					sdram_we <= (send_cmd_timing ? 1'b0 : 1'b1);
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
				default: begin
					sdram_address <= 0;
					sdram_cke <= 1'b0;
					sdram_cs <= 1'b1;
					sdram_ras <= 1'b1;
					sdram_cas <= 1'b1;
					sdram_we <= 1'b1;
					sdram_ba <= 0;
					sdram_dq_out <= 0;
					sdram_dq_io <= 1'b1;
				end
			endcase
	assign data_out = sdram_dq_in;
	assign idle = state == 32'd7;
	assign refresh_mode = (state == 32'd5) || (state == 32'd6);
	assign write_flag = state == 32'd8;
	assign read_flag = ((state == 32'd10) && (next_state == 32'd10)) && (state_counter > cas_latency);
endmodule
