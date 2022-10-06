`default_nettype none

module KFPS2KB_Send_Data (
	input		wire					clock,
	input		wire					peripheral_clock,
	input		wire					reset,
	input		wire					device_clock,
	output	reg					device_clock_out,
	output	reg					device_data_out,
	output	wire					sending_data_flag,
	input		wire					send_request,
	input		wire	[7:0]			send_data
	);
	parameter device_out_clock_wait = 16'd240;
	reg prev_device_clock;
	wire device_clock_edge;
	reg prev_send_request;
	wire send_request_trigger;
	reg [9:0] shift_register;
	wire [7:0] parity_bit;
	reg [31:0] state;
	reg [31:0] next_state;
	reg [15:0] state_counter;
	reg [7:0] send_bit_count;
	reg prev_p_clock_1;
	reg prev_p_clock_2;
	wire device_clock_last_edge;
	always @(posedge clock or posedge reset)
		if (reset) begin
			prev_p_clock_1 <= 1'b0;
			prev_p_clock_2 <= 1'b0;
		end
		else begin
			prev_p_clock_1 <= peripheral_clock;
			prev_p_clock_2 <= prev_p_clock_1;
		end
	wire p_clock_posedge = prev_p_clock_1 & ~prev_p_clock_2;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_device_clock <= 1'b0;
		else
			prev_device_clock <= device_clock;
	assign device_clock_edge = (prev_device_clock != device_clock) & (device_clock == 1'b0);
	assign device_clock_last_edge = (prev_device_clock != device_clock) & (device_clock == 1'b1);
	always @(posedge clock or posedge reset)
		if (reset)
			prev_send_request <= 1'b0;
		else
			prev_send_request <= send_request;
	assign send_request_trigger = ~prev_send_request & send_request;
	assign parity_bit = ~(((((((send_data[0] + send_data[1]) + send_data[2]) + send_data[3]) + send_data[4]) + send_data[5]) + send_data[6]) + send_data[7]);
	always @(posedge clock or posedge reset)
		if (reset)
			shift_register <= 10'b1111111111;
		else if (send_request_trigger)
			shift_register <= {parity_bit, send_data, 1'b0};
		else if ((state == 32'd3) && device_clock_edge)
			shift_register <= {1'b1, shift_register[9:1]};
		else
			shift_register <= shift_register;
	always @(*) begin
		next_state = state;
		case (state)
			32'd0:
				if (send_request_trigger)
					next_state = 32'd1;
			32'd1:
				if (state_counter == device_out_clock_wait)
					next_state = 32'd2;
			32'd2:
				if (state_counter == device_out_clock_wait)
					next_state = 32'd3;
			32'd3:
				if (send_bit_count == 8'd10)
					next_state = 32'd4;
			32'd4:
				if (device_clock_edge)
					next_state = 32'd5;
			32'd5:
				if (device_clock_last_edge)
					next_state = 32'd0;
		endcase
	end
	always @(posedge clock or posedge reset)
		if (reset)
			state <= 32'd0;
		else
			state <= next_state;
	always @(posedge clock or posedge reset)
		if (reset)
			state_counter <= 16'h0000;
		else if (state != next_state)
			state_counter <= 16'h0000;
		else if (p_clock_posedge)
			state_counter <= state_counter + 16'h0001;
		else
			state_counter <= state_counter;
	always @(posedge clock or posedge reset)
		if (reset)
			send_bit_count <= 8'h00;
		else if (state == 32'd3) begin
			if (device_clock_edge)
				send_bit_count <= send_bit_count + 8'h01;
			else
				send_bit_count <= send_bit_count;
		end
		else
			send_bit_count <= 8'h00;
	always @(posedge clock or posedge reset)
		if (reset)
			device_clock_out <= 1'b1;
		else if ((state == 32'd1) || (state == 32'd2))
			device_clock_out <= 1'b0;
		else
			device_clock_out <= 1'b1;
	always @(posedge clock or posedge reset)
		if (reset)
			device_data_out <= 1'b1;
		else if (state == 32'd2)
			device_data_out <= 1'b0;
		else if (state == 32'd3)
			device_data_out <= shift_register[0];
		else
			device_data_out <= 1'b1;
	assign sending_data_flag = state != 32'd0;
endmodule
