module TOP (
	clock,
	reset_in,
	chip_select_n,
	read_enable_n,
	write_enable_n,
	address,
	data_bus,
	port_a,
	port_b,
	port_c
);
	input wire clock;
	input wire reset_in;
	input wire chip_select_n;
	input wire read_enable_n;
	input wire write_enable_n;
	input wire [1:0] address;
	inout wire [7:0] data_bus;
	inout wire [7:0] port_a;
	inout wire [7:0] port_b;
	inout wire [7:0] port_c;
	reg res_ff;
	reg reset;
	wire [7:0] data_bus_in;
	wire [7:0] data_bus_out;
	reg [7:0] port_a_in_ff;
	reg [7:0] port_a_in;
	wire [7:0] port_a_out;
	wire port_a_io;
	reg [7:0] port_b_in_ff;
	reg [7:0] port_b_in;
	wire [7:0] port_b_out;
	wire port_b_io;
	reg [7:0] port_c_in_ff;
	reg [7:0] port_c_in;
	wire [7:0] port_c_out;
	wire [7:0] port_c_io;
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
	assign port_a = (~port_a_io ? port_a_out : 8'bzzzzzzzz);
	assign port_b = (~port_b_io ? port_b_out : 8'bzzzzzzzz);
	assign port_c[0] = (~port_c_io[0] ? port_c_out[0] : 1'bz);
	assign port_c[1] = (~port_c_io[1] ? port_c_out[1] : 1'bz);
	assign port_c[2] = (~port_c_io[2] ? port_c_out[2] : 1'bz);
	assign port_c[3] = (~port_c_io[3] ? port_c_out[3] : 1'bz);
	assign port_c[4] = (~port_c_io[4] ? port_c_out[4] : 1'bz);
	assign port_c[5] = (~port_c_io[5] ? port_c_out[5] : 1'bz);
	assign port_c[6] = (~port_c_io[6] ? port_c_out[6] : 1'bz);
	assign port_c[7] = (~port_c_io[7] ? port_c_out[7] : 1'bz);
	always @(negedge clock or posedge reset)
		if (reset) begin
			port_a_in_ff <= 8'b00000000;
			port_a_in <= 8'b00000000;
		end
		else begin
			port_a_in_ff <= port_a;
			port_a_in <= port_a_in_ff;
		end
	always @(negedge clock or posedge reset)
		if (reset) begin
			port_b_in_ff <= 8'b00000000;
			port_b_in <= 8'b00000000;
		end
		else begin
			port_b_in_ff <= port_b;
			port_b_in <= port_b_in_ff;
		end
	always @(negedge clock or posedge reset)
		if (reset) begin
			port_c_in_ff <= 8'b00000000;
			port_c_in <= 8'b00000000;
		end
		else begin
			port_c_in_ff <= port_c;
			port_c_in <= port_c_in_ff;
		end
	KF8255 u_KF8255(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.read_enable_n(read_enable_n),
		.write_enable_n(write_enable_n),
		.address(address),
		.data_bus_in(data_bus_in),
		.data_bus_out(data_bus_out),
		.port_a_in(port_a_in),
		.port_a_out(port_a_out),
		.port_a_io(port_a_io),
		.port_b_in(port_b_in),
		.port_b_out(port_b_out),
		.port_b_io(port_b_io),
		.port_c_in(port_c_in),
		.port_c_out(port_c_out),
		.port_c_io(port_c_io)
	);
endmodule
