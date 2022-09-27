module KF8255 (
	clock,
	reset,
	chip_select_n,
	read_enable_n,
	write_enable_n,
	address,
	data_bus_in,
	data_bus_out,
	port_a_in,
	port_a_out,
	port_a_io,
	port_b_in,
	port_b_out,
	port_b_io,
	port_c_in,
	port_c_out,
	port_c_io
);
	input wire clock;
	input wire reset;
	input wire chip_select_n;
	input wire read_enable_n;
	input wire write_enable_n;
	input wire [1:0] address;
	input wire [7:0] data_bus_in;
	output reg [7:0] data_bus_out;
	input wire [7:0] port_a_in;
	output wire [7:0] port_a_out;
	output wire port_a_io;
	input wire [7:0] port_b_in;
	output wire [7:0] port_b_out;
	output wire port_b_io;
	input wire [7:0] port_c_in;
	output wire [7:0] port_c_out;
	output wire [7:0] port_c_io;
	wire [7:0] internal_data_bus;
	wire write_port_a;
	wire write_port_b;
	wire write_port_c;
	wire write_control;
	wire read_port_a;
	wire read_port_b;
	wire read_port_c;
	KF8255_Control_Logic u_Control_Logic(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.read_enable_n(read_enable_n),
		.write_enable_n(write_enable_n),
		.address(address),
		.data_bus_in(data_bus_in),
		.internal_data_bus(internal_data_bus),
		.write_port_a(write_port_a),
		.write_port_b(write_port_b),
		.write_port_c(write_port_c),
		.write_control(write_control),
		.read_port_a(read_port_a),
		.read_port_b(read_port_b),
		.read_port_c(read_port_c)
	);
	wire [3:0] group_a_bus;
	wire write_group_a;
	wire update_group_a_mode;
	assign group_a_bus = internal_data_bus[6:3];
	assign write_group_a = write_control & internal_data_bus[7];
	wire [1:0] group_a_mode_reg;
	wire group_a_port_a_io_reg;
	wire group_a_port_c_io_reg;
	KF8255_Group u_Group_A(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(group_a_bus),
		.write_register(write_group_a),
		.update_group_mode(update_group_a_mode),
		.mode_select_reg(group_a_mode_reg),
		.port_1_io_reg(group_a_port_a_io_reg),
		.port_2_io_reg(group_a_port_c_io_reg)
	);
	wire [3:0] group_b_bus;
	wire write_group_b;
	wire update_group_b_mode;
	assign group_b_bus = {1'b0, internal_data_bus[2:0]};
	assign write_group_b = write_control & internal_data_bus[7];
	wire [1:0] group_b_mode_reg;
	wire group_b_port_b_io_reg;
	wire group_b_port_c_io_reg;
	KF8255_Group u_Group_B(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(group_b_bus),
		.write_register(write_group_b),
		.update_group_mode(update_group_b_mode),
		.mode_select_reg(group_b_mode_reg),
		.port_1_io_reg(group_b_port_b_io_reg),
		.port_2_io_reg(group_b_port_c_io_reg)
	);
	wire port_a_strobe;
	wire port_a_hiz;
	wire [7:0] port_a_read_data;
	KF8255_Port u_Port_A(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_port(write_port_a),
		.update_mode(update_group_a_mode),
		.mode_select_reg(group_a_mode_reg),
		.port_io_reg(group_a_port_a_io_reg),
		.strobe(port_a_strobe),
		.hiz(port_a_hiz),
		.port_io(port_a_io),
		.port_out(port_a_out),
		.port_in(port_a_in),
		.read(port_a_read_data)
	);
	wire port_b_strobe;
	wire [7:0] port_b_read_data;
	KF8255_Port u_Port_B(
		.clock(clock),
		.reset(reset),
		.internal_data_bus(internal_data_bus),
		.write_port(write_port_b),
		.update_mode(update_group_b_mode),
		.mode_select_reg(group_b_mode_reg),
		.port_io_reg(group_b_port_b_io_reg),
		.strobe(port_b_strobe),
		.hiz(1'b0),
		.port_io(port_b_io),
		.port_out(port_b_out),
		.port_in(port_b_in),
		.read(port_b_read_data)
	);
	wire write_port_c_bit_set;
	wire [7:0] port_c_read_data;
	assign write_port_c_bit_set = write_control & ~internal_data_bus[7];
	KF8255_Port_C u_Port_C(
		.clock(clock),
		.reset(reset),
		.chip_select_n(chip_select_n),
		.read_enable_n(read_enable_n),
		.internal_data_bus(internal_data_bus),
		.write_port_a(write_port_a),
		.write_port_b(write_port_b),
		.write_port_c_bit_set(write_port_c_bit_set),
		.write_port_c(write_port_c),
		.read_port_a(read_port_a),
		.read_port_b(read_port_b),
		.read_port_c(read_port_c),
		.update_group_a_mode(update_group_a_mode),
		.update_group_b_mode(update_group_b_mode),
		.group_a_mode_reg(group_a_mode_reg),
		.group_b_mode_reg(group_b_mode_reg),
		.group_a_port_a_io_reg(group_a_port_a_io_reg),
		.group_b_port_b_io_reg(group_b_port_b_io_reg),
		.group_a_port_c_io_reg(group_a_port_c_io_reg),
		.group_b_port_c_io_reg(group_b_port_c_io_reg),
		.port_a_strobe(port_a_strobe),
		.port_b_strobe(port_b_strobe),
		.port_a_hiz(port_a_hiz),
		.port_c_io(port_c_io),
		.port_c_out(port_c_out),
		.port_c_in(port_c_in),
		.port_c_read(port_c_read_data)
	);
	always @(*) begin
		data_bus_out = 8'b00000000;
		if (read_port_a)
			data_bus_out = port_a_read_data;
		else if (read_port_b)
			data_bus_out = port_b_read_data;
		else if (read_port_c)
			data_bus_out = port_c_read_data;
	end
endmodule
