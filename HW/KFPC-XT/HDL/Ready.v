`default_nettype none

module READY (
	input		wire					clock,
	input		wire					cpu_clock,
	input		wire					reset,
	output	wire					processor_ready,
	output	wire					dma_ready,
	input		wire					dma_wait_n,
	input		wire					io_channel_ready,
	input		wire					io_read_n,
	input		wire					io_write_n,
	input		wire					memory_read_n,
	input		wire					dma0_acknowledge_n,
	input		wire					address_enable_n
	);

	reg prev_cpu_clock;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_cpu_clock <= 1'b0;
		else
			prev_cpu_clock <= cpu_clock;
	wire cpu_clock_posedge = ~prev_cpu_clock & cpu_clock;
	wire cpu_clock_negedge = prev_cpu_clock & ~cpu_clock;
	reg prev_bus_state;
	reg ready_n_or_wait;
	reg ready_n_or_wait_Qn;
	reg prev_ready_n_or_wait;
	wire bus_state = (~io_read_n | ~io_write_n) | ((dma0_acknowledge_n & ~memory_read_n) & address_enable_n);
	always @(posedge clock or posedge reset)
		if (reset)
			prev_bus_state <= 1'b1;
		else
			prev_bus_state <= bus_state;
	always @(posedge clock or posedge reset)
		if (reset) begin
			ready_n_or_wait <= 1'b1;
			ready_n_or_wait_Qn <= 1'b0;
		end
		else if (~io_channel_ready & prev_ready_n_or_wait) begin
			ready_n_or_wait <= 1'b1;
			ready_n_or_wait_Qn <= 1'b1;
		end
		else if (~io_channel_ready & ~prev_ready_n_or_wait) begin
			ready_n_or_wait <= 1'b1;
			ready_n_or_wait_Qn <= 1'b0;
		end
		else if (io_channel_ready & prev_ready_n_or_wait) begin
			ready_n_or_wait <= 1'b0;
			ready_n_or_wait_Qn <= 1'b1;
		end
		else if (~prev_bus_state & bus_state) begin
			ready_n_or_wait <= 1'b1;
			ready_n_or_wait_Qn <= 1'b0;
		end
		else begin
			ready_n_or_wait <= ready_n_or_wait;
			ready_n_or_wait_Qn <= ready_n_or_wait_Qn;
		end
	always @(posedge clock or posedge reset)
		if (reset)
			prev_ready_n_or_wait <= 1'b0;
		else if (cpu_clock_posedge)
			prev_ready_n_or_wait <= ready_n_or_wait;
		else
			prev_ready_n_or_wait <= prev_ready_n_or_wait;
	assign dma_ready = ~prev_ready_n_or_wait & ready_n_or_wait_Qn;
	reg processor_ready_ff_1;
	reg processor_ready_ff_2;
	always @(posedge clock or posedge reset)
		if (reset)
			processor_ready_ff_1 <= 1'b0;
		else if (cpu_clock_posedge)
			processor_ready_ff_1 <= dma_wait_n & ~ready_n_or_wait;
		else
			processor_ready_ff_1 <= processor_ready_ff_1;
	always @(posedge clock or posedge reset)
		if (reset)
			processor_ready_ff_2 <= 1'b0;
		else if (cpu_clock_negedge)
			processor_ready_ff_2 <= (processor_ready_ff_1 & dma_wait_n) & ~ready_n_or_wait;
		else
			processor_ready_ff_2 <= processor_ready_ff_2;
	assign processor_ready = processor_ready_ff_2;
endmodule
