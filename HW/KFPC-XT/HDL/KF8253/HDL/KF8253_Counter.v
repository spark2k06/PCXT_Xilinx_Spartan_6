`default_nettype none

module KF8253_Counter (
	input		wire					clock,
	input		wire					reset,
	input		wire	[7:0]			internal_data_bus,
	input		wire					write_control,
	input		wire					write_counter,
	input		wire					read_counter,
	output	reg	[7:0]			read_counter_data,
	input		wire					counter_clock,
	input		wire					counter_gate,
	output	reg					counter_out
	);

	reg [1:0] select_read_write;
	wire update_counter_config;
	wire update_select_read_write;
	reg count_latched_flag;
	reg [2:0] select_mode;
	reg select_bcd;
	reg write_count_step;
	reg [15:0] count_preset;
	reg [16:0] count_preset_load;
	wire read_negedge;
	reg read_count_step;
	reg prev_read_counter;
	reg prev_counter_clock;
	wire count_edge;
	reg prev_counter_gate;
	wire gate_edge;
	reg load_edge;
	reg start_counting;
	reg [16:0] count_next;
	reg count_period;
	reg prev_count_period;
	reg [16:0] count;
	reg [16:0] count_latched;
	always @(posedge clock or posedge reset)
		if (reset)
			select_read_write <= 2'b10;
		else if (write_control)
			case (internal_data_bus[5:4])
				2'b10: select_read_write <= internal_data_bus[5:4];
				2'b01: select_read_write <= internal_data_bus[5:4];
				2'b11: select_read_write <= internal_data_bus[5:4];
				default: select_read_write <= select_read_write;
			endcase
		else
			select_read_write <= select_read_write;
	assign update_counter_config = (internal_data_bus[5:4] != 2'b00) & write_control;
	assign update_select_read_write = (select_read_write != internal_data_bus[5:4]) & update_counter_config;
	always @(posedge clock or posedge reset)
		if (reset)
			count_latched_flag <= 1'b0;
		else if (write_control && (internal_data_bus[5:4] == 2'b00))
			count_latched_flag <= 1'b1;
		else if ((count_latched_flag == 1'b1) && read_negedge) begin
			if (select_read_write != 2'b11)
				count_latched_flag <= 1'b0;
			else
				count_latched_flag <= (read_count_step == 1'b0 ? 1'b0 : 1'b1);
		end
		else
			count_latched_flag <= count_latched_flag;
	always @(posedge clock or posedge reset)
		if (reset)
			select_mode <= 3'b000;
		else if (update_counter_config)
			select_mode <= internal_data_bus[3:1];
		else
			select_mode <= select_mode;
	always @(posedge clock or posedge reset)
		if (reset)
			select_bcd <= 1'b0;
		else if (update_counter_config)
			select_bcd <= internal_data_bus[0];
		else
			select_bcd <= select_bcd;
	always @(posedge clock or posedge reset)
		if (reset)
			count_preset[15:0] <= 16'h0000;
		else if (write_counter) begin
			if (write_count_step == 1'b0)
				count_preset[15:0] <= {internal_data_bus, count_preset[7:0]};
			else
				count_preset[15:0] <= {count_preset[15:8], internal_data_bus};
		end
		else
			count_preset[15:0] <= count_preset[15:0];
	always @(posedge clock or posedge reset)
		if (reset)
			write_count_step <= 1'b0;
		else if (update_select_read_write)
			case (internal_data_bus[5:4])
				2'b10: write_count_step <= 1'b0;
				2'b01: write_count_step <= 1'b1;
				2'b11: write_count_step <= 1'b1;
				default: write_count_step <= write_count_step;
			endcase
		else if (write_counter && (select_read_write == 2'b11))
			write_count_step <= (write_count_step ? 1'b0 : 1'b1);
		else
			write_count_step <= write_count_step;
	always @(*) begin
		count_preset_load[15:0] = (select_read_write == 2'b10 ? {count_preset[15:8], 8'h00} : (select_read_write == 2'b01 ? {8'h00, count_preset[7:0]} : count_preset[15:0]));
		count_preset_load[16] = (count_preset_load[15:0] == 16'h0000 ? 1'b1 : 1'b0);
	end
	always @(*)
		if (read_count_step == 1'b0)
			read_counter_data <= count_latched[15:8];
		else
			read_counter_data <= count_latched[7:0];
	always @(posedge clock or posedge reset)
		if (reset)
			prev_read_counter <= 1'b0;
		else
			prev_read_counter <= read_counter;
	assign read_negedge = (prev_read_counter != read_counter) & (read_counter == 1'b0);
	always @(posedge clock or posedge reset)
		if (reset)
			read_count_step <= 1'b0;
		else if (update_select_read_write)
			case (internal_data_bus[5:4])
				2'b10: read_count_step <= 1'b0;
				2'b01: read_count_step <= 1'b1;
				2'b11: read_count_step <= 1'b1;
				default: read_count_step <= read_count_step;
			endcase
		else if (read_negedge && (select_read_write == 2'b11))
			read_count_step <= (read_count_step ? 1'b0 : 1'b1);
		else
			read_count_step <= read_count_step;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_counter_clock <= 1'b0;
		else
			prev_counter_clock <= counter_clock;
	assign count_edge = (prev_counter_clock != counter_clock) & (counter_clock == 1'b0);
	always @(posedge clock or posedge reset)
		if (reset)
			prev_counter_gate <= 1'b0;
		else if (count_edge)
			prev_counter_gate <= counter_gate;
		else if (prev_counter_gate != 1'b0)
			prev_counter_gate <= counter_gate;
		else
			prev_counter_gate <= prev_counter_gate;
	assign gate_edge = (prev_counter_gate != counter_gate) & (counter_gate == 1'b1);
	always @(posedge clock or posedge reset)
		if (reset)
			load_edge <= 1'b0;
		else if (write_counter)
			load_edge <= 1'b1;
		else if (count_edge)
			load_edge <= 1'b0;
		else
			load_edge <= load_edge;
	always @(posedge clock or posedge reset)
		if (reset)
			start_counting <= 1'b0;
		else if (update_counter_config)
			start_counting <= 1'b0;
		else if (write_counter) begin
			if (select_read_write != 2'b11)
				start_counting <= 1'b1;
			else
				casez (select_mode)
					3'b000:
						if (write_count_step == 1'b0)
							start_counting <= 1'b1;
						else
							start_counting <= 1'b0;
					3'b100:
						if (write_count_step == 1'b0)
							start_counting <= 1'b1;
						else
							start_counting <= 1'b0;
					default:
						if (start_counting == 1'b1)
							start_counting <= 1'b1;
						else if (write_count_step == 1'b0)
							start_counting <= 1'b1;
						else
							start_counting <= 1'b0;
				endcase
		end
		else
			start_counting <= start_counting;
	function [16:0] decrement;
		input [16:0] count;
		input is_bcd;
		if (count == 17'b00000000000000000)
			decrement = 17'b00000000000000000;
		else if (is_bcd == 1'b0)
			decrement = count - 17'b00000000000000001;
		else if (count[3:0] == 4'b0000) begin
			if (count[7:4] == 4'b0000) begin
				if (count[11:8] == 4'b0000) begin
					if (count[15:12] == 4'b0000) begin
						decrement[16] = 1'b0;
						decrement[15:12] = 4'd9;
					end
					else begin
						decrement[16] = count[16];
						decrement[15:12] = count[15:12] - 4'd1;
					end
					decrement[11:8] = 4'd9;
				end
				else begin
					decrement[16:12] = count[16:12];
					decrement[11:8] = count[11:8] - 4'd1;
				end
				decrement[7:4] = 4'd9;
			end
			else begin
				decrement[16:8] = count[16:8];
				decrement[7:4] = count[7:4] - 4'd1;
			end
			decrement[3:0] = 4'd9;
		end
		else begin
			decrement[16:4] = count[16:4];
			decrement[3:0] = count[3:0] - 4'd1;
		end
	endfunction
	wire [16:0] dec_count;
	wire [16:0] dec2_count;
	assign dec_count = decrement(count, select_bcd);
	assign dec2_count = decrement(dec_count, select_bcd);
	always @(*) begin
		count_next = dec_count;
		count_period = 1'b0;
		casez (select_mode)
			3'b000: begin
				if (counter_gate == 1'b0)
					count_next = count;
				if (load_edge)
					count_next = count_preset_load;
			end
			3'b001:
				if (gate_edge)
					count_next = count_preset_load;
			3'bz10: begin
				if (counter_gate == 1'b0)
					count_next = count;
				if (count_next == 16'h0000)
					count_next = count_preset_load;
				if (gate_edge)
					count_next = count_preset_load;
			end
			3'bz11: begin
				if (count[0] == 1'b1) begin
					if (counter_out == 1'b0)
						count_next = {dec2_count[16:1], 1'b0};
				end
				else
					count_next = dec2_count;
				if (counter_gate == 1'b0)
					count_next = count;
				if (count_next == 17'b00000000000000000) begin
					count_period = 1'b1;
					count_next = count_preset_load;
				end
				if (gate_edge)
					count_next = count_preset_load;
			end
			3'b100: begin
				if (counter_gate == 1'b0)
					count_next = count;
				if (load_edge)
					count_next = count_preset_load;
			end
			3'b101:
				if (gate_edge)
					count_next = count_preset_load;
			default:
				;
		endcase
		if (count_next == 17'b00000000000000000)
			count_period = 1'b1;
	end
	always @(posedge clock or posedge reset)
		if (reset) begin
			count <= 17'b00000000000000000;
			count_latched <= 17'b00000000000000000;
		end
		else if (start_counting == 1'b0) begin
			count <= 17'b00000000000000000;
			if (count_latched_flag == 1'b0)
				count_latched <= 17'b00000000000000000;
			else
				count_latched <= count_latched;
		end
		else if (start_counting & count_edge) begin
			count <= count_next;
			if (count_latched_flag == 1'b0)
				count_latched <= count_next;
			else
				count_latched <= count_latched;
		end
		else begin
			count <= count;
			if (count_latched_flag == 1'b0)
				count_latched <= count;
			else
				count_latched <= count_latched;
		end
	always @(posedge clock or posedge reset)
		if (reset)
			prev_count_period <= 1'b1;
		else if (start_counting == 1'b0)
			prev_count_period <= 1'b1;
		else if (count_edge)
			prev_count_period <= count_period;
		else
			prev_count_period <= prev_count_period;
	always @(posedge clock or posedge reset)
		if (reset)
			counter_out <= 1'b0;
		else if (start_counting == 1'b0)
			casez (select_mode)
				3'b000: counter_out <= 1'b0;
				3'b001: counter_out <= 1'b1;
				3'bz10: counter_out <= 1'b1;
				3'bz11: counter_out <= 1'b1;
				3'b100: counter_out <= 1'b1;
				3'b101: counter_out <= 1'b1;
				default: counter_out <= 1'b0;
			endcase
		else if (count_edge)
			casez (select_mode)
				3'b000:
					if (count_period)
						counter_out <= 1'b1;
					else
						counter_out <= 1'b0;
				3'b001:
					if (count_period)
						counter_out <= 1'b1;
					else
						counter_out <= 1'b0;
				3'bz10:
					if (counter_gate == 1'b0)
						counter_out <= 1'b1;
					else if (count_next == 17'b00000000000000001)
						counter_out <= 1'b0;
					else
						counter_out <= 1'b1;
				3'bz11:
					if (counter_gate == 1'b0)
						counter_out <= 1'b1;
					else if (count_period)
						counter_out <= ~counter_out;
					else
						counter_out <= counter_out;
				3'b100:
					if (count_period && (prev_count_period == 1'b0))
						counter_out <= 1'b0;
					else
						counter_out <= 1'b1;
				3'b101:
					if (count_period && (prev_count_period == 1'b0))
						counter_out <= 1'b0;
					else
						counter_out <= 1'b1;
				default: counter_out <= counter_out;
			endcase
		else
			casez (select_mode)
				3'bz10:
					if ((counter_gate == 1'b0) || (prev_counter_gate == 1'b0))
						counter_out <= 1'b1;
					else
						counter_out <= counter_out;
				3'bz11:
					if ((counter_gate == 1'b0) || (prev_counter_gate == 1'b0))
						counter_out <= 1'b1;
					else
						counter_out <= counter_out;
				default: counter_out <= counter_out;
			endcase
endmodule
