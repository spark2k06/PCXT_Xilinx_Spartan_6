`default_nettype none

module BUS_ARBITER (
	input		wire					clock,
	input		wire					cpu_clock,
	input		wire					reset,
	input		wire	[19:0]		cpu_address,
	input		wire	[7:0]			cpu_data_bus,
	input		wire	[2:0]			processor_status,
	input		wire					processor_lock_n,
	output	wire					processor_transmit_or_receive_n,
	input		wire					dma_ready,
	output	wire					dma_wait_n,
	output	wire					interrupt_acknowledge_n,
	input		wire					dma_chip_select_n,
	input		wire					dma_page_chip_select_n,
	output	reg	[19:0]		address,
	input		wire	[19:0]		address_ext,
	output	reg					address_direction,
	input		wire	[7:0]			data_bus_ext,
	output	reg	[7:0]			internal_data_bus,
	output	reg					data_bus_direction,
	output	wire					address_latch_enable,
	output	wire					io_read_n,
	input		wire					io_read_n_ext,
	output	wire					io_read_n_direction,
	output	wire					io_write_n,
	input		wire					io_write_n_ext,
	output	wire					io_write_n_direction,
	output	wire					memory_read_n,
	input		wire					memory_read_n_ext,
	output	wire					memory_read_n_direction,
	output	wire					memory_write_n,
	input		wire					memory_write_n_ext,
	output	wire					memory_write_n_direction,
	input		wire	[3:0]			dma_request,
	output	wire	[3:0]			dma_acknowledge_n,
	output	reg					address_enable_n,
	output	wire					terminal_count_n
	);

	reg prev_cpu_clock;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_cpu_clock <= 1'b0;
		else
			prev_cpu_clock <= cpu_clock;
	wire cpu_clock_posedge = ~prev_cpu_clock & cpu_clock;
	wire cpu_clock_negedge = prev_cpu_clock & ~cpu_clock;
	reg hold_request_ff_1;
	reg hold_request_ff_2;
	wire hold_acknowledge;
	wire hold_request;
	always @(posedge clock or posedge reset)
		if (reset)
			hold_request_ff_1 <= 1'b0;
		else if (cpu_clock_posedge) begin
			if (((processor_status[0] & processor_status[1]) & processor_lock_n) & hold_request)
				hold_request_ff_1 <= 1'b1;
			else
				hold_request_ff_1 <= 1'b0;
		end
		else
			hold_request_ff_1 <= hold_request_ff_1;
	always @(posedge clock or posedge reset)
		if (reset)
			hold_request_ff_2 <= 1'b0;
		else if (cpu_clock_negedge) begin
			if (~hold_request)
				hold_request_ff_2 <= 1'b0;
			else if (hold_request_ff_2)
				hold_request_ff_2 <= 1'b1;
			else
				hold_request_ff_2 <= hold_request_ff_1;
		end
		else
			hold_request_ff_2 <= hold_request_ff_2;
	assign hold_acknowledge = (hold_request ? hold_request_ff_2 : 1'b0);
	always @(posedge clock or posedge reset)
		if (reset)
			address_enable_n <= 1'b0;
		else if (cpu_clock_posedge)
			address_enable_n <= hold_acknowledge;
		else
			address_enable_n <= address_enable_n;
	reg dma_wait;
	always @(posedge clock or posedge reset)
		if (reset)
			dma_wait <= 1'b0;
		else if (cpu_clock_posedge)
			dma_wait <= address_enable_n;
		else
			dma_wait <= dma_wait;
	assign dma_wait_n = ~dma_wait;
	wire dma_enable_n = ~(dma_wait & address_enable_n);
	wire bc_io_write_n;
	wire bc_io_read_n;
	wire bc_enable_io;
	wire bc_memory_write_n;
	wire bc_memory_read_n;
	wire bc_memory_enable;
	wire direction_transmit_or_receive_n;
	wire data_enable;
	KF8288 u_KF8288(
		.clock(clock),
		.cpu_clock(cpu_clock),
		.reset(reset),
		.address_enable_n(address_enable_n),
		.command_enable(~address_enable_n),
		.io_bus_mode(1'b0),
		.processor_status(processor_status),
		.enable_io_command(bc_enable_io),
		.advanced_io_write_command_n(bc_io_write_n),
		.io_read_command_n(bc_io_read_n),
		.interrupt_acknowledge_n(interrupt_acknowledge_n),
		.enable_memory_command(bc_memory_enable),
		.advanced_memory_write_command_n(bc_memory_write_n),
		.memory_read_command_n(bc_memory_read_n),
		.direction_transmit_or_receive_n(direction_transmit_or_receive_n),
		.data_enable(data_enable),
		.address_latch_enable(address_latch_enable)
	);
	assign processor_transmit_or_receive_n = direction_transmit_or_receive_n;
	wire dma_io_write_n;
	wire [7:0] dma_data_out;
	wire dma_io_read_n;
	wire terminal_count;
	wire [15:0] dma_address_out;
	wire dma_memory_read_n;
	wire dma_memory_write_n;
	KF8237 u_KF8237(
		.clock(clock),
		.cpu_clock(cpu_clock),
		.reset(reset),
		.chip_select_n(dma_chip_select_n),
		.ready(dma_ready),
		.hold_acknowledge(hold_acknowledge),
		.dma_request(dma_request),
		.data_bus_in(internal_data_bus),
		.data_bus_out(dma_data_out),
		.io_read_n_in(io_read_n),
		.io_read_n_out(dma_io_read_n),
		.io_write_n_in(io_write_n),
		.io_write_n_out(dma_io_write_n),
		.end_of_process_n_in(1'b1),
		.end_of_process_n_out(terminal_count),
		.address_in(address[3:0]),
		.address_out(dma_address_out),
		.hold_request(hold_request),
		.dma_acknowledge(dma_acknowledge_n),
		.memory_read_n(dma_memory_read_n),
		.memory_write_n(dma_memory_write_n)
	);
	assign terminal_count_n = ~terminal_count;
	reg [7:0] bit_select = 8'b00011011;
	reg [3:0] dma_page_register [0:3];
	genvar dma_page_i;
	generate
		for (dma_page_i = 0; dma_page_i < 4; dma_page_i = dma_page_i + 1) begin : DMA_PAGE_REGISTERS
			always @(posedge clock or posedge reset)
				if (reset)
					dma_page_register[dma_page_i] <= 0;
				else if ((~dma_page_chip_select_n && ~io_write_n) && (bit_select[(3 - dma_page_i) * 2+:2] == address[1:0]))
					dma_page_register[dma_page_i] <= internal_data_bus[3:0];
				else
					dma_page_register[dma_page_i] <= dma_page_register[dma_page_i];
		end
	endgenerate
	wire ab_io_write_n = ~((~bc_io_write_n & bc_enable_io) | ~dma_io_write_n);
	wire ab_io_read_n = ~((~bc_io_read_n & bc_enable_io) | ~dma_io_read_n);
	wire ab_memory_write_n = ~((~bc_memory_write_n & bc_memory_enable) | ~dma_memory_write_n);
	wire ab_memory_read_n = ~((~bc_memory_read_n & bc_memory_enable) | ~dma_memory_read_n);
	assign io_write_n_direction = ab_io_write_n;
	assign io_read_n_direction = ab_io_read_n;
	assign memory_write_n_direction = ab_memory_write_n;
	assign memory_read_n_direction = ab_memory_read_n;
	assign io_write_n = (io_write_n_direction ? io_write_n_ext : ab_io_write_n);
	assign io_read_n = (io_read_n_direction ? io_read_n_ext : ab_io_read_n);
	assign memory_write_n = (memory_write_n_direction ? memory_write_n_ext : ab_memory_write_n);
	assign memory_read_n = (memory_read_n_direction ? memory_read_n_ext : ab_memory_read_n);
	always @(*)
		if (~dma_enable_n) begin
			if (~dma_acknowledge_n[2]) begin
				address = {dma_page_register[1], dma_address_out};
				address_direction = 1'b0;
			end
			else if (~dma_acknowledge_n[3]) begin
				address = {dma_page_register[2], dma_address_out};
				address_direction = 1'b0;
			end
			else begin
				address = {dma_page_register[3], dma_address_out};
				address_direction = 1'b0;
			end
		end
		else if (~address_enable_n) begin
			address = cpu_address;
			address_direction = 1'b0;
		end
		else begin
			address = address_ext;
			address_direction = 1'b1;
		end
	always @(*)
		if (~interrupt_acknowledge_n) begin
			internal_data_bus = data_bus_ext;
			data_bus_direction = 1'b0;
		end
		else if (data_enable && direction_transmit_or_receive_n) begin
			internal_data_bus = cpu_data_bus;
			data_bus_direction = 1'b0;
		end
		else if (~dma_chip_select_n && ~io_read_n) begin
			internal_data_bus = dma_data_out;
			data_bus_direction = 1'b0;
		end
		else begin
			internal_data_bus = data_bus_ext;
			data_bus_direction = 1'b1;
		end
endmodule
