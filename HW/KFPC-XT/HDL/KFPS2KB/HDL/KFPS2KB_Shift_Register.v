module KFPS2KB_Shift_Register (
	clock,
	peripheral_clock,
	reset,
	device_clock,
	device_data,
	register,
	recieved_flag,
	error_flag
);
	parameter over_time = 16'd1000;
	input wire clock;
	input wire peripheral_clock;
	input wire reset;
	input wire device_clock;
	input wire device_data;
	output reg [7:0] register;
	output reg recieved_flag;
	output reg error_flag;
	reg prev_device_clock;
	wire device_clock_edge;
	reg [8:0] shift_register;
	reg [3:0] bit_count;
	wire parity_bit;
	reg [15:0] receiving_time;
	wire over_receiving_time;
	reg [31:0] next_state;
	reg [31:0] state;
	reg prev_p_clock_1;
	reg prev_p_clock_2;
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
	always @(posedge clock or posedge reset)
		if (reset)
			shift_register <= 9'b000000000;
		else if ((state == 32'd1) & device_clock_edge)
			shift_register <= {device_data, shift_register[8:1]};
		else
			shift_register <= shift_register;
	always @(posedge clock or posedge reset)
		if (reset)
			bit_count <= 4'b0000;
		else if (state == 32'd0)
			bit_count <= 4'b0000;
		else if ((state == 32'd1) & device_clock_edge)
			bit_count <= bit_count + 4'b0001;
		else
			bit_count <= bit_count;
	assign parity_bit = ~(((((((shift_register[0] + shift_register[1]) + shift_register[2]) + shift_register[3]) + shift_register[4]) + shift_register[5]) + shift_register[6]) + shift_register[7]);
	always @(posedge clock or posedge reset)
		if (reset)
			receiving_time <= 16'h0000;
		else if (state == 32'd0)
			receiving_time <= 16'h0000;
		else if (device_clock_edge)
			receiving_time <= 16'h0000;
		else if (p_clock_posedge && (over_receiving_time == 1'b0))
			receiving_time <= receiving_time + 16'h0001;
		else
			receiving_time <= receiving_time;
	assign over_receiving_time = (receiving_time >= over_time ? 1'b1 : 1'b0);
	always @(posedge clock or posedge reset)
		if (reset) begin
			recieved_flag <= 1'b0;
			error_flag <= 1'b0;
		end
		else if (over_receiving_time) begin
			recieved_flag <= 1'b0;
			error_flag <= 1'b1;
		end
		else if (state == 32'd2) begin
			if (device_clock_edge) begin
				if ((device_data == 1'b1) && (shift_register[8] == parity_bit)) begin
					recieved_flag <= 1'b1;
					error_flag <= 1'b0;
				end
				else begin
					recieved_flag <= 1'b0;
					error_flag <= 1'b1;
				end
			end
			else begin
				recieved_flag <= 1'b0;
				error_flag <= 1'b0;
			end
		end
		else begin
			recieved_flag <= 1'b0;
			error_flag <= 1'b0;
		end
	always @(posedge clock or posedge reset)
		if (reset)
			register <= 8'h00;
		else if ((state == 32'd2) && device_clock_edge)
			register <= shift_register[7:0];
		else
			register <= register;
	always @(*) begin
		next_state = 32'd0;
		case (state)
			32'd0:
				if (device_clock_edge && (device_data == 1'b0))
					next_state = 32'd1;
				else
					next_state = 32'd0;
			32'd1:
				if (bit_count >= 4'b1001)
					next_state = 32'd2;
				else
					next_state = 32'd1;
			32'd2:
				if (device_clock_edge)
					next_state = 32'd0;
				else
					next_state = 32'd2;
		endcase
		if (over_receiving_time)
			next_state = 32'd0;
	end
	always @(posedge clock or posedge reset)
		if (reset)
			state <= 32'd0;
		else
			state <= next_state;
endmodule
