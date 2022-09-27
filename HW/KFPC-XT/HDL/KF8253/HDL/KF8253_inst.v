module TOP (
	clock,
	reset_in,
	chip_select_n,
	read_enable_n,
	write_enable_n,
	address,
	data_bus,
	clock_0,
	gate_0,
	out_0,
	clock_1,
	gate_1,
	out_1,
	gate_2,
	out_2
);
	input wire clock;
	input wire reset_in;
	input wire chip_select_n;
	input wire read_enable_n;
	input wire write_enable_n;
	input wire [1:0] address;
	inout wire [7:0] data_bus;
	input wire clock_0;
	input wire gate_0;
	output wire out_0;
	input wire clock_1;
	input wire gate_1;
	output wire out_1;
	input wire gate_2;
	output wire out_2;
	reg res_ff;
	reg reset;
	wire [7:0] data_bus_in;
	wire [7:0] data_bus_out;
	wire counter_0_clock;
	wire counter_0_gate;
	wire counter_0_out;
	reg clock_1_ff;
	reg gate_1_ff;
	reg counter_1_clock;
	reg counter_1_gate;
	wire counter_1_out;
	reg counter_2_clock;
	wire counter_2_gate;
	wire counter_2_out;
	always @(negedge clock or posedge reset_in)
		if (reset_in) begin
			res_ff <= 1'b1;
			reset <= 1'b1;
		end
		else begin
			res_ff <= 1'b0;
			reset <= res_ff;
		end
	assign data_bus = ((~chip_select_n & ~read_enable_n) & write_enable_n ? data_bus_out : 8'bzzzzzzzz);
	assign data_bus_in = data_bus;
	assign counter_0_clock = clock_0;
	assign counter_0_gate = gate_0;
	assign out_0 = counter_0_out;
	always @(negedge clock or posedge reset)
		if (reset) begin
			clock_1_ff <= 1'b0;
			counter_1_clock <= 1'b0;
		end
		else begin
			clock_1_ff <= clock_1;
			counter_1_clock <= clock_1_ff;
		end
	always @(negedge clock or posedge reset)
		if (reset) begin
			gate_1_ff <= 1'b0;
			counter_1_gate <= 1'b0;
		end
		else begin
			gate_1_ff <= gate_1;
			counter_1_gate <= gate_1_ff;
		end
	assign out_1 = counter_1_out;
	always @(negedge clock or posedge reset)
		if (reset)
			counter_2_clock = 1'b0;
		else
			counter_2_clock = ~counter_2_clock;
	assign counter_2_gate = gate_2;
	assign out_2 = counter_2_out;
	KF8253 u_KF8253(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.read_enable_n(read_enable_n),
		.write_enable_n(write_enable_n),
		.address(address),
		.data_bus_in(data_bus_in),
		.data_bus_out(data_bus_out),
		.counter_0_clock(counter_0_clock),
		.counter_0_gate(counter_0_gate),
		.counter_0_out(counter_0_out),
		.counter_1_clock(counter_1_clock),
		.counter_1_gate(counter_1_gate),
		.counter_1_out(counter_1_out),
		.counter_2_clock(counter_2_clock),
		.counter_2_gate(counter_2_gate),
		.counter_2_out(counter_2_out)
	);
endmodule
