`default_nettype none

module CHIPSET (
	input		wire					clock,
	input		wire					cpu_clock,
	input		wire					clk_sys,
	input		wire					peripheral_clock,
	output	wire					turbo,
	input		wire					reset,
	input		wire	[19:0]		cpu_address,
	input		wire	[7:0]			cpu_data_bus,
	input		wire	[2:0]			processor_status,
	input		wire					processor_lock_n,
	output	wire					processor_transmit_or_receive_n,
	output	wire					processor_ready,
	output	wire					interrupt_to_cpu,
	input		wire					splashscreen,
	input		wire					clk_vga_cga,
	output	wire					de_o,
	output	wire	[5:0]			VGA_R,
	output	wire	[5:0]			VGA_G,
	output	wire	[5:0]			VGA_B,
	output	wire					VGA_HSYNC,
	output	wire					VGA_VSYNC,
	output	wire					VGA_HBlank,
	output	wire					VGA_VBlank,
	output	wire	[19:0]		address,
	input		wire	[19:0]		address_ext,
	output	wire					address_direction,
	output	wire	[7:0]			data_bus,
	input		wire	[7:0]			data_bus_ext,
	output	reg					data_bus_direction,
	output	wire					address_latch_enable,
	input		wire					io_channel_check,
	input		wire					io_channel_ready,
	input		wire	[7:0]			interrupt_request,
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
	output	wire					address_enable_n,
	output	wire					terminal_count_n,
	output	wire	[2:0]			timer_counter_out,
	output	wire					speaker_out,
	output	wire	[7:0]			port_a_out,
	output	wire					port_a_io,
	input		wire	[7:0]			port_b_in,
	output	wire	[7:0]			port_b_out,
	output	wire					port_b_io,
	input		wire	[7:0]			port_c_in,
	output	wire	[7:0]			port_c_out,
	output	wire	[7:0]			port_c_io,
	input		wire					ps2_clock,
	input		wire					ps2_data,
	output	wire					ps2_clock_out,
	output	wire					ps2_data_out,
   input    wire              ps2_mouseclk_in,
   input    wire              ps2_mousedat_in,
   output   wire              ps2_mouseclk_out,
   output   wire              ps2_mousedat_out,
	input		wire	[4:0]			joy_opts,
	input		wire	[31:0] 		joy0,
	input		wire	[31:0] 		joy1,
	input		wire	[15:0]		joya0,
	input		wire	[15:0]		joya1,
	input		wire					clk_en_opl2,
	output	wire	[15:0]		jtopl2_snd_e,
	input		wire					adlibhide,
//	input		wire					tandy_video,
	output	wire	[7:0]			tandy_snd_e,
	output	wire					tandy_16_gfx,
	input		wire					ioctl_download,
	input		wire	[7:0]			ioctl_index,
	input		wire					ioctl_wr,
	input		wire	[24:0]		ioctl_addr,
	input		wire	[7:0]			ioctl_data,
	input		wire					clk_uart,
	input		wire					uart_rx,
	output	wire					uart_tx,
	input		wire					uart_cts_n,
	input		wire					uart_dcd_n,
	input		wire					uart_dsr_n,
	output	wire					uart_rts_n,
	output	wire					uart_dtr_n,
// MMC interface
   output   wire              spi_clk,
   output   wire              spi_cs,
   output   wire              spi_mosi,
   input    wire              spi_miso,
//
   output   wire  [7:0]       xtctl,
	output	wire	[20:0]		SRAM_ADDR,
	inout 	wire	[7:0] 		SRAM_DATA,
	output	wire					SRAM_WE_n,
	input		wire					ems_enabled,
	input		wire	[1:0]			ems_address,
	input		wire					btn_green_n_i,
	input		wire					btn_yellow_n_i
	);

	wire dma_ready;
	wire dma_wait_n;
	wire interrupt_acknowledge_n;
	wire dma_chip_select_n;
	wire dma_page_chip_select_n;
	wire ram_address_select_n;
	wire [7:0] internal_data_bus;
	reg [7:0] internal_data_bus_ext;
	wire [7:0] internal_data_bus_chipset;
	wire [7:0] internal_data_bus_ram;
	wire data_bus_out_from_chipset;
	wire internal_data_bus_direction;
	reg prev_timer_count_1;
	reg DRQ0;
	wire [5:0] map_ems [0:3];
	wire ena_ems [0:3];
	wire ems_b1;
	wire ems_b2;
	wire ems_b3;
	wire ems_b4;
	wire tandy_snd_rdy;
	wire cga_vram_rdy;

	always @(posedge clock)
		if (reset)
			prev_timer_count_1 <= 1'b1;
		else
			prev_timer_count_1 <= timer_counter_out[1];
	always @(posedge clock or posedge reset)
		if (reset)
			DRQ0 <= 1'b0;
		else if (~dma_acknowledge_n[0])
			DRQ0 <= 1'b0;
		else if (~prev_timer_count_1 & timer_counter_out[1])
			DRQ0 <= 1'b1;
		else
			DRQ0 <= DRQ0;
	READY u_READY(
		.clock(clock),
		.cpu_clock(cpu_clock),
		.reset(reset),
		.processor_ready(processor_ready),
		.dma_ready(dma_ready),
		.dma_wait_n(dma_wait_n),
		.io_channel_ready((io_channel_ready & tandy_snd_rdy) && cga_vram_rdy),
		.io_read_n(io_read_n),
		.io_write_n(io_write_n),
		.memory_read_n(memory_read_n),
		.dma0_acknowledge_n(dma_acknowledge_n[0]),
		.address_enable_n(address_enable_n)
	);
	BUS_ARBITER u_BUS_ARBITER(
		.clock(clock),
		.cpu_clock(cpu_clock),
		.reset(reset),
		.cpu_address(cpu_address),
		.cpu_data_bus(cpu_data_bus),
		.processor_status(processor_status),
		.processor_lock_n(processor_lock_n),
		.processor_transmit_or_receive_n(processor_transmit_or_receive_n),
		.dma_ready(dma_ready),
		.dma_wait_n(dma_wait_n),
		.interrupt_acknowledge_n(interrupt_acknowledge_n),
		.dma_chip_select_n(dma_chip_select_n),
		.dma_page_chip_select_n(dma_page_chip_select_n),
		.address(address),
		.address_ext(address_ext),
		.address_direction(address_direction),
		.data_bus_ext(internal_data_bus_ext),
		.internal_data_bus(internal_data_bus),
		.data_bus_direction(internal_data_bus_direction),
		.address_latch_enable(address_latch_enable),
		.io_read_n(io_read_n),
		.io_read_n_ext(io_read_n_ext),
		.io_read_n_direction(io_read_n_direction),
		.io_write_n(io_write_n),
		.io_write_n_ext(io_write_n_ext),
		.io_write_n_direction(io_write_n_direction),
		.memory_read_n(memory_read_n),
		.memory_read_n_ext(memory_read_n_ext),
		.memory_read_n_direction(memory_read_n_direction),
		.memory_write_n(memory_write_n),
		.memory_write_n_ext(memory_write_n_ext),
		.memory_write_n_direction(memory_write_n_direction),
		.dma_request({dma_request[3:1], DRQ0}),
		.dma_acknowledge_n(dma_acknowledge_n),
		.address_enable_n(address_enable_n),
		.terminal_count_n(terminal_count_n)
	);
//	wire cga_vram_rdy;
	PERIPHERALS u_PERIPHERALS(
		.clock(clock),
		.cpu_clock(cpu_clock),
      .clk_uart(clk_uart),
		.peripheral_clock(peripheral_clock),
		.turbo(turbo),
		.reset(reset),
		.interrupt_to_cpu(interrupt_to_cpu),
		.interrupt_acknowledge_n(interrupt_acknowledge_n),
		.dma_chip_select_n(dma_chip_select_n),
		.dma_page_chip_select_n(dma_page_chip_select_n),
		.splashscreen(splashscreen),
		.clk_vga_cga(clk_vga_cga),
		.de_o(de_o),
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HSYNC(VGA_HSYNC),
		.VGA_VSYNC(VGA_VSYNC),
		.VGA_HBlank(VGA_HBlank),
		.VGA_VBlank(VGA_VBlank),
		.address(address),
		.internal_data_bus(internal_data_bus),
		.data_bus_out(internal_data_bus_chipset),
		.data_bus_out_from_chipset(data_bus_out_from_chipset),
		.interrupt_request(interrupt_request),
		.io_read_n(io_read_n),
		.io_write_n(io_write_n),
		.memory_read_n(memory_read_n),
		.memory_write_n(memory_write_n),
		.address_enable_n(address_enable_n),
		.timer_counter_out(timer_counter_out),
		.speaker_out(speaker_out),
		.port_a_out(port_a_out),
		.port_a_io(port_a_io),
		.port_b_in(port_b_in),
		.port_b_out(port_b_out),
		.port_b_io(port_b_io),
		.port_c_in(port_c_in),
		.port_c_out(port_c_out),
		.port_c_io(port_c_io),
		.ps2_clock(ps2_clock),
		.ps2_data(ps2_data),
      .ps2_mouseclk_in(ps2_mouseclk_in),
      .ps2_mousedat_in(ps2_mousedat_in),
      .ps2_mouseclk_out(ps2_mouseclk_out),
      .ps2_mousedat_out(ps2_mousedat_out),
//		.joy_opts(joy_opts),
//		.joy0(joy0),
//		.joy1(joy1),
//		.joya0(joya0),
//		.joya1(joya1),
		.ps2_clock_out(ps2_clock_out),
		.ps2_data_out(ps2_data_out),
		.clk_en_opl2(clk_en_opl2),
		.jtopl2_snd_e(jtopl2_snd_e),
		.adlibhide(adlibhide),
//		.tandy_video(tandy_video),
		.tandy_snd_e(tandy_snd_e),
		.tandy_snd_rdy(tandy_snd_rdy),
		.tandy_16_gfx(tandy_16_gfx),
		.ioctl_download(ioctl_download),
		.ioctl_index(ioctl_index),
		.ioctl_wr(ioctl_wr),
		.ioctl_addr(ioctl_addr),
		.ioctl_data(ioctl_data),
		.SRAM_ADDR(SRAM_ADDR),
		.SRAM_DATA(SRAM_DATA),
		.SRAM_WE_n(SRAM_WE_n),
		.ems_enabled(ems_enabled),
		.ems_address(ems_address),
		.cga_vram_rdy(cga_vram_rdy),
      .spi_clk(spi_clk),
      .spi_cs(spi_cs),
      .spi_mosi(spi_mosi),
      .spi_miso(spi_miso),
		.xtctl(xtctl),
		.btn_green_n_i(btn_green_n_i),
		.btn_yellow_n_i(btn_yellow_n_i)
	);
	assign data_bus = internal_data_bus;
	always @(*)
		if (data_bus_out_from_chipset) begin
			internal_data_bus_ext = internal_data_bus_chipset;
			data_bus_direction = 1'b0;
		end
		else if (~ram_address_select_n && ~memory_read_n) begin
			internal_data_bus_ext = internal_data_bus_ram;
			data_bus_direction = 1'b0;
		end
		else if (internal_data_bus_direction == 1'b1) begin
			internal_data_bus_ext = data_bus_ext;
			data_bus_direction = 1'b1;
		end
		else begin
			internal_data_bus_ext = 0;
			data_bus_direction = 1'b0;
		end
endmodule
