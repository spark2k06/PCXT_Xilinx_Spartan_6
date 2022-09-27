module KF8288 (
	clock,
	cpu_clock,
	reset,
	address_enable_n,
	command_enable,
	io_bus_mode,
	processor_status,
	enable_io_command,
	advanced_io_write_command_n,
	io_write_command_n,
	io_read_command_n,
	interrupt_acknowledge_n,
	enable_memory_command,
	advanced_memory_write_command_n,
	memory_write_command_n,
	memory_read_command_n,
	direction_transmit_or_receive_n,
	data_enable,
	master_cascade_enable,
	peripheral_data_enable_n,
	address_latch_enable
);
	input wire clock;
	input wire cpu_clock;
	input wire reset;
	input wire address_enable_n;
	input wire command_enable;
	input wire io_bus_mode;
	input wire [2:0] processor_status;
	output reg enable_io_command;
	output reg advanced_io_write_command_n;
	output reg io_write_command_n;
	output reg io_read_command_n;
	output reg interrupt_acknowledge_n;
	output reg enable_memory_command;
	output reg advanced_memory_write_command_n;
	output reg memory_write_command_n;
	output reg memory_read_command_n;
	output reg direction_transmit_or_receive_n;
	output wire data_enable;
	output wire master_cascade_enable;
	output wire peripheral_data_enable_n;
	output wire address_latch_enable;
	reg prev_cpu_clock;
	always @(posedge clock or posedge reset)
		if (reset)
			prev_cpu_clock <= 1'b0;
		else
			prev_cpu_clock <= cpu_clock;
	wire cpu_clock_posedge = ~prev_cpu_clock & cpu_clock;
	wire cpu_clock_negedge = prev_cpu_clock & ~cpu_clock;
	wire is_interrupt_acknowledge_status = processor_status == 3'b000;
	wire is_read_io_port_status = processor_status == 3'b001;
	wire is_write_io_port_status = processor_status == 3'b010;
	wire is_halt_status = processor_status == 3'b011;
	wire is_code_access_status = processor_status == 3'b100;
	wire is_read_memory_status = processor_status == 3'b101;
	wire is_write_memory_status = processor_status == 3'b110;
	wire is_passive_status = processor_status == 3'b111;
	reg strobed_interrupt_acknowledge_status;
	reg strobed_read_io_port_status;
	reg strobed_write_io_port_status;
	reg strobed_halt_status;
	reg strobed_code_access_status;
	reg strobed_read_memory_status;
	reg strobed_write_memory_status;
	always @(posedge clock or posedge reset)
		if (reset) begin
			strobed_interrupt_acknowledge_status <= 1'b0;
			strobed_read_io_port_status <= 1'b0;
			strobed_write_io_port_status <= 1'b0;
			strobed_halt_status <= 1'b0;
			strobed_code_access_status <= 1'b0;
			strobed_read_memory_status <= 1'b0;
			strobed_write_memory_status <= 1'b0;
		end
		else if (cpu_clock_negedge) begin
			strobed_interrupt_acknowledge_status <= is_interrupt_acknowledge_status;
			strobed_read_io_port_status <= is_read_io_port_status;
			strobed_write_io_port_status <= is_write_io_port_status;
			strobed_halt_status <= is_halt_status;
			strobed_code_access_status <= is_code_access_status;
			strobed_read_memory_status <= is_read_memory_status;
			strobed_write_memory_status <= is_write_memory_status;
		end
		else begin
			strobed_interrupt_acknowledge_status <= strobed_interrupt_acknowledge_status;
			strobed_read_io_port_status <= strobed_read_io_port_status;
			strobed_write_io_port_status <= strobed_write_io_port_status;
			strobed_halt_status <= strobed_halt_status;
			strobed_code_access_status <= strobed_code_access_status;
			strobed_read_memory_status <= strobed_read_memory_status;
			strobed_write_memory_status <= strobed_write_memory_status;
		end
	reg machine_cycle_period;
	reg [2:0] machine_cycle;
	always @(posedge clock or posedge reset)
		if (reset)
			machine_cycle_period <= 1'b1;
		else if (cpu_clock_posedge) begin
			if (machine_cycle == 3'b000) begin
				if (is_passive_status)
					machine_cycle_period <= 1'b1;
				else
					machine_cycle_period <= 1'b0;
			end
			else
				machine_cycle_period <= 1'b0;
		end
		else
			machine_cycle_period <= machine_cycle_period;
	always @(posedge clock or posedge reset)
		if (reset)
			machine_cycle <= 3'b000;
		else if (cpu_clock_negedge) begin
			if (is_passive_status)
				machine_cycle <= 3'b000;
			else if (machine_cycle_period)
				machine_cycle <= 3'b000;
			else
				machine_cycle <= {machine_cycle[1:0], 1'b1};
		end
		else
			machine_cycle <= machine_cycle;
	wire read_and_advanced_write_command_n = ~(machine_cycle[0] == 1'b1);
	wire write_command_n = ~(machine_cycle[1] == 1'b1);
	always @(*) begin
		advanced_io_write_command_n = 1'b1;
		io_write_command_n = 1'b1;
		io_read_command_n = 1'b1;
		advanced_memory_write_command_n = 1'b1;
		memory_write_command_n = 1'b1;
		memory_read_command_n = 1'b1;
		interrupt_acknowledge_n = 1'b1;
		if (command_enable) begin
			if (strobed_interrupt_acknowledge_status)
				interrupt_acknowledge_n = read_and_advanced_write_command_n;
			if (strobed_read_io_port_status)
				io_read_command_n = read_and_advanced_write_command_n;
			if (strobed_write_io_port_status) begin
				io_write_command_n = write_command_n;
				advanced_io_write_command_n = read_and_advanced_write_command_n;
			end
			if (strobed_code_access_status)
				memory_read_command_n = read_and_advanced_write_command_n;
			if (strobed_read_memory_status)
				memory_read_command_n = read_and_advanced_write_command_n;
			if (strobed_write_memory_status) begin
				advanced_memory_write_command_n = read_and_advanced_write_command_n;
				memory_write_command_n = write_command_n;
			end
		end
	end
	always @(*) begin
		if (address_enable_n) begin
			enable_io_command = 1'b0;
			enable_memory_command = 1'b0;
		end
		else begin
			enable_io_command = 1'b1;
			enable_memory_command = 1'b1;
		end
		if (io_bus_mode)
			enable_io_command = 1'b1;
	end
	reg write_command_tmp;
	wire write_data_enable;
	reg read_command_tmp;
	wire read_data_enable;
	always @(posedge clock or posedge reset)
		if (reset)
			direction_transmit_or_receive_n <= 1'b1;
		else if (cpu_clock_posedge) begin
			if (machine_cycle_period) begin
				if (is_interrupt_acknowledge_status)
					direction_transmit_or_receive_n <= 1'b0;
				else if (is_read_io_port_status)
					direction_transmit_or_receive_n <= 1'b0;
				else if (is_write_io_port_status)
					direction_transmit_or_receive_n <= 1'b1;
				else if (is_halt_status)
					direction_transmit_or_receive_n <= 1'b1;
				else if (is_code_access_status)
					direction_transmit_or_receive_n <= 1'b0;
				else if (is_read_memory_status)
					direction_transmit_or_receive_n <= 1'b0;
				else if (is_write_memory_status)
					direction_transmit_or_receive_n <= 1'b1;
				else
					direction_transmit_or_receive_n <= 1'b1;
			end
			else if (strobed_interrupt_acknowledge_status)
				direction_transmit_or_receive_n <= 1'b0;
			else if (strobed_read_io_port_status)
				direction_transmit_or_receive_n <= 1'b0;
			else if (strobed_write_io_port_status)
				direction_transmit_or_receive_n <= 1'b1;
			else if (strobed_halt_status)
				direction_transmit_or_receive_n <= 1'b1;
			else if (strobed_code_access_status)
				direction_transmit_or_receive_n <= 1'b0;
			else if (strobed_read_memory_status)
				direction_transmit_or_receive_n <= 1'b0;
			else if (strobed_write_memory_status)
				direction_transmit_or_receive_n <= 1'b1;
			else
				direction_transmit_or_receive_n <= 1'b1;
		end
		else
			direction_transmit_or_receive_n <= direction_transmit_or_receive_n;
	always @(posedge clock or posedge reset)
		if (reset)
			write_command_tmp <= 1'b0;
		else if (cpu_clock_negedge) begin
			if (machine_cycle_period)
				write_command_tmp <= 1'b0;
			else if (is_halt_status)
				write_command_tmp <= 1'b0;
			else if (strobed_halt_status)
				write_command_tmp <= 1'b0;
			else
				write_command_tmp <= 1'b1;
		end
		else
			write_command_tmp <= write_command_tmp;
	always @(posedge clock or posedge reset)
		if (reset)
			read_command_tmp <= 1'b0;
		else if (cpu_clock_posedge)
			read_command_tmp <= ~read_and_advanced_write_command_n;
		else
			read_command_tmp <= read_command_tmp;
	assign write_data_enable = write_command_tmp & ~machine_cycle_period;
	assign read_data_enable = read_command_tmp & ~read_and_advanced_write_command_n;
	assign data_enable = (direction_transmit_or_receive_n ? write_data_enable : read_data_enable);
	assign master_cascade_enable = (machine_cycle == 3'b000) & ~is_passive_status;
	assign peripheral_data_enable_n = ~data_enable;
	assign address_latch_enable = machine_cycle_period & ~is_passive_status;
endmodule
