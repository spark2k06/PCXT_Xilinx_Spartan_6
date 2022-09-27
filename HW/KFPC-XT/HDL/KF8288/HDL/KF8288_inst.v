module TOP (
	clock,
	reset_in,
	AEN_n,
	IOB,
	CEN,
	S_n,
	AIOWC_n,
	AMWC_n,
	IOWC_n,
	MWTC_n,
	MRDC_n,
	IORC_n,
	INTA_n,
	DT_R_n,
	ALE,
	MCE_PDEN_n,
	DEN
);
	input wire clock;
	input wire reset_in;
	input wire AEN_n;
	input wire IOB;
	input wire CEN;
	input wire [2:0] S_n;
	output wire AIOWC_n;
	output wire AMWC_n;
	output wire IOWC_n;
	output wire MWTC_n;
	output wire MRDC_n;
	output wire IORC_n;
	output wire INTA_n;
	output wire DT_R_n;
	output wire ALE;
	output wire MCE_PDEN_n;
	output wire DEN;
	reg res_ff;
	reg reset;
	wire enable_io_command;
	wire advanced_io_write_command_n;
	wire io_write_command_n;
	wire io_read_command_n;
	wire interrupt_acknowledge_n;
	wire enable_memory_command;
	wire advanced_memory_write_command_n;
	wire memory_write_command_n;
	wire memory_read_command_n;
	wire peripheral_data_enable_n;
	wire master_cascade_enable;
	always @(negedge clock or posedge reset_in)
		if (reset_in) begin
			res_ff <= 1'b1;
			reset <= 1'b1;
		end
		else begin
			res_ff <= 1'b0;
			reset <= res_ff;
		end
	KF8288 u_KF8288(
		.clock(clock),
		.reset(reset),
		.address_enable_n(AEN_n),
		.command_enable(CEN),
		.io_bus_mode(IOB),
		.processor_status(S_n),
		.enable_io_command(enable_io_command),
		.advanced_io_write_command_n(advanced_io_write_command_n),
		.io_write_command_n(io_write_command_n),
		.io_read_command_n(io_read_command_n),
		.interrupt_acknowledge_n(interrupt_acknowledge_n),
		.enable_memory_command(enable_memory_command),
		.advanced_memory_write_command_n(advanced_memory_write_command_n),
		.memory_write_command_n(memory_write_command_n),
		.memory_read_command_n(memory_read_command_n),
		.direction_transmit_or_receive_n(DT_R_n),
		.data_enable(DEN),
		.master_cascade_enable(master_cascade_enable),
		.peripheral_data_enable_n(peripheral_data_enable_n),
		.address_latch_enable(ALE)
	);
	assign AIOWC_n = (enable_io_command ? advanced_io_write_command_n : 1'bz);
	assign AMWC_n = (enable_memory_command ? advanced_memory_write_command_n : 1'bz);
	assign IOWC_n = (enable_io_command ? io_write_command_n : 1'bz);
	assign MWTC_n = (enable_memory_command ? memory_write_command_n : 1'bz);
	assign MRDC_n = (enable_memory_command ? memory_read_command_n : 1'bz);
	assign IORC_n = (enable_io_command ? io_read_command_n : 1'bz);
	assign INTA_n = (enable_io_command ? interrupt_acknowledge_n : 1'bz);
	assign MCE_PDEN_n = (IOB ? peripheral_data_enable_n : master_cascade_enable);
endmodule
