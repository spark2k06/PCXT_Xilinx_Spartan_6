module PERIPHERALS (
	clock,
	clk_sys,
	peripheral_clock,
//	turbo_mode,
	reset,
	interrupt_to_cpu,
	interrupt_acknowledge_n,
	dma_chip_select_n,
	dma_page_chip_select_n,
	splashscreen,
	clk_vga_cga,
	de_o,
	VGA_R,
	VGA_G,
	VGA_B,
	VGA_HSYNC,
	VGA_VSYNC,
	VGA_HBlank,
	VGA_VBlank,
	address,
	internal_data_bus,
	data_bus_out,
	data_bus_out_from_chipset,
	interrupt_request,
	io_read_n,
	io_write_n,
	memory_read_n,
	memory_write_n,
	address_enable_n,
	timer_counter_out,
	speaker_out,
	port_a_out,
	port_a_io,
	port_b_in,
	port_b_out,
	port_b_io,
	port_c_in,
	port_c_out,
	port_c_io,
	ps2_clock,
	ps2_data,
	ps2_clock_out,
	ps2_data_out,
//	joy_opts,
//	joy0,
//	joy1,
//	joya0,
//	joya1,
	clk_en_opl2,
	jtopl2_snd_e,
	adlibhide,
	tandy_video,
	tandy_snd_e,
	tandy_snd_rdy,
	tandy_16_gfx,
	ioctl_download,
	ioctl_index,
	ioctl_wr,
	ioctl_addr,
	ioctl_data,
	clk_uart,
	uart_rx,
	uart_tx,
	uart_cts_n,
	uart_dcd_n,
	uart_dsr_n,
	uart_rts_n,
	uart_dtr_n,
	SRAM_ADDR,
	SRAM_DATA,
	SRAM_WE_n,
	ems_enabled,
	ems_address,
	bios_writable,
	cga_vram_rdy
);
	parameter ps2_over_time = 16'd1000;
	input wire clock;
	input wire clk_sys;
	input wire peripheral_clock;
//	input wire [1:0] turbo_mode;
	input wire reset;
	output wire interrupt_to_cpu;
	input wire interrupt_acknowledge_n;
	output wire dma_chip_select_n;
	output wire dma_page_chip_select_n;
	input wire splashscreen;
	input wire clk_vga_cga;
	output wire de_o;
	output wire [5:0] VGA_R;
	output wire [5:0] VGA_G;
	output wire [5:0] VGA_B;
	output wire VGA_HSYNC;
	output wire VGA_VSYNC;
	output wire VGA_HBlank;
	output wire VGA_VBlank;
	input wire [19:0] address;
	input wire [7:0] internal_data_bus;
	output reg [7:0] data_bus_out;
	output reg data_bus_out_from_chipset;
	input wire [7:0] interrupt_request;
	input wire io_read_n;
	input wire io_write_n;
	input wire memory_read_n;
	input wire memory_write_n;
	input wire address_enable_n;
	output wire [2:0] timer_counter_out;
	output wire speaker_out;
	output wire [7:0] port_a_out;
	output wire port_a_io;
	input wire [7:0] port_b_in;
	output wire [7:0] port_b_out;
	output wire port_b_io;
	input wire [7:0] port_c_in;
	output wire [7:0] port_c_out;
	output wire [7:0] port_c_io;
	input wire ps2_clock;
	input wire ps2_data;
	output reg ps2_clock_out;
	output wire ps2_data_out;
//	input wire [4:0] joy_opts;
//	input wire [31:0] joy0;
//	input wire [31:0] joy1;
//	input wire [15:0] joya0;
//	input wire [15:0] joya1;
	input wire clk_en_opl2;
	output wire [15:0] jtopl2_snd_e;
	input wire adlibhide;
	input wire tandy_video;
	output wire [7:0] tandy_snd_e;
	output wire tandy_snd_rdy;
	output wire tandy_16_gfx;
	input wire ioctl_download;
	input wire [7:0] ioctl_index;
	input wire ioctl_wr;
	input wire [24:0] ioctl_addr;
	input wire [7:0] ioctl_data;
	input wire clk_uart;
	input wire uart_rx;
	output wire uart_tx;
	input wire uart_cts_n;
	input wire uart_dcd_n;
	input wire uart_dsr_n;
	output wire uart_rts_n;
	output wire uart_dtr_n;
	output wire [20:0] SRAM_ADDR;
	inout [7:0] SRAM_DATA;
	output wire SRAM_WE_n;
	input wire ems_enabled;
	input wire [1:0] ems_address;
	input wire [2:0] bios_writable;
	output wire cga_vram_rdy;
	wire [7:0] SRAM_DATA_A_i;
	wire [7:0] SRAM_DATA_A_o;
	wire grph_mode;
	wire hres_mode;
	assign tandy_16_gfx = (tandy_video & grph_mode) & hres_mode;
	reg [7:0] chip_select_n;
	wire CGA_VRAM_ENABLE;
	assign cga_vram_rdy = ~CGA_VRAM_ENABLE;
	always @(*)
		if ((~address_enable_n & ~address[9]) & ~address[8])
			casez (address[7:5])
				3'b000: chip_select_n = 8'b11111110;
				3'b001: chip_select_n = 8'b11111101;
				3'b010: chip_select_n = 8'b11111011;
				3'b011: chip_select_n = 8'b11110111;
				3'b100: chip_select_n = 8'b11101111;
				3'b101: chip_select_n = 8'b11011111;
				3'b110: chip_select_n = 8'b10111111;
				3'b111: chip_select_n = 8'b01111111;
				default: chip_select_n = 8'b11111111;
			endcase
		else
			chip_select_n = 8'b11111111;
	wire iorq = ~io_read_n | ~io_write_n;
	assign dma_chip_select_n = iorq && chip_select_n[0];
	wire interrupt_chip_select_n = iorq && chip_select_n[1];
	wire timer_chip_select_n = iorq && chip_select_n[2];
	wire ppi_chip_select_n = iorq && chip_select_n[3];
	assign dma_page_chip_select_n = iorq && chip_select_n[4];
//	wire joystick_select = (iorq && ~address_enable_n) && (address[15:3] == (16'h0200 >> 3));
	wire nmi_mask_register_n = ~(((tandy_video && iorq) && ~address_enable_n) && (address[15:3] == (16'h00a0 >> 3)));
	wire tandy_chip_select_n = ~((iorq && ~address_enable_n) && (address[15:3] == (16'h00c0 >> 3)));
	wire opl_chip_select_n = ~((iorq && ~address_enable_n) && (address[15:1] == (16'h0388 >> 1)));
	wire cga_chip_select_n = ~((~iorq && ~address_enable_n) && (address[19:15] == 5'b10111));
	wire bios_select_n = ~((~iorq && ~address_enable_n) && (address[19:13] == 7'b1111111));
	wire xtide_select_n = ~((~iorq && ~address_enable_n) && (address[19:14] == 6'b111011));
	wire uart_cs = ~address_enable_n && ({address[15:3], 3'd0} == 16'h03f8);
	wire lpt_cs = (iorq && ~address_enable_n) && (address[15:0] == 16'h0378);
	wire tandy_page_cs = (iorq && ~address_enable_n) && (address[15:0] == 16'h03df);
	wire ram_select_n;
	//assign ram_select_n = ~(((~iorq && ~address_enable_n) && ~(address[19:16] == 4'b1111)) && ~(address[19:14] == 6'b111011));
	assign ram_select_n = ~((~iorq && ~address_enable_n) && ~(address[19:13] == 7'b1111111) && ~(address[19:16] == 4'b1101));
	wire [3:0] ems_page_address = (ems_address == 2'b00 ? 4'b1010 : (ems_address == 2'b01 ? 4'b1100 : 4'b1101));
	wire ems_oe = ((iorq && ~address_enable_n) && ems_enabled) && ({address[15:2], 2'd0} == 16'h0260);
	reg [0:3] ena_ems;
	wire ems_b1 = (~iorq && ena_ems[0]) && (address[19:14] == {ems_page_address, 2'b00});
	wire ems_b2 = (~iorq && ena_ems[1]) && (address[19:14] == {ems_page_address, 2'b01});
	wire ems_b3 = (~iorq && ena_ems[2]) && (address[19:14] == {ems_page_address, 2'b10});
	wire ems_b4 = (~iorq && ena_ems[3]) && (address[19:14] == {ems_page_address, 2'b11});
	reg [23:0] map_ems;
	reg [1:0] ems_access_address;
	reg ems_write_enable;
	reg [7:0] write_map_ems_data;
	reg write_map_ena_data;
	always @(posedge clock or posedge reset)
		if (reset) begin
			ems_access_address <= 2'b11;
			ems_write_enable <= 1'b0;
			write_map_ems_data <= 8'd0;
			write_map_ena_data <= 1'b0;
		end
		else begin
			ems_access_address <= address[1:0];
			ems_write_enable <= ems_oe && ~io_write_n;
			write_map_ems_data <= (internal_data_bus == 8'hff ? 8'hff : (internal_data_bus < 8'h80 ? internal_data_bus[6:0] : map_ems[(3 - address[1:0]) * 6+:6]));
			write_map_ena_data <= (internal_data_bus == 8'hff ? 1'b0 : (internal_data_bus < 8'h80 ? 1'b1 : ena_ems[address[1:0]]));
		end
	always @(posedge clock or posedge reset)
		if (reset) begin
			map_ems <= 24'h000000;
			ena_ems <= 4'b0000;
		end
		else if (ems_write_enable) begin
			map_ems[(3 - ems_access_address) * 6+:6] <= write_map_ems_data;
			ena_ems[ems_access_address] <= write_map_ena_data;
		end
	wire timer_interrupt;
	reg keybord_interrupt;
	wire uart_interrupt;
	wire [7:0] interrupt_data_bus_out;
	KF8259 u_KF8259(
		.clock(clock),
		.reset(reset),
		.chip_select_n(interrupt_chip_select_n),
		.read_enable_n(io_read_n),
		.write_enable_n(io_write_n),
		.address(address[0]),
		.data_bus_in(internal_data_bus),
		.data_bus_out(interrupt_data_bus_out),
		.cascade_in(3'b000),
		.slave_program_n(1'b1),
		.interrupt_acknowledge_n(interrupt_acknowledge_n),
		.interrupt_to_cpu(interrupt_to_cpu),
		.interrupt_request({interrupt_request[7:5], uart_interrupt, interrupt_request[3:2], keybord_interrupt, timer_interrupt})
	);
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
	reg timer_clock;
	always @(posedge clock or posedge reset)
		if (reset)
			timer_clock <= 1'b0;
		else if (p_clock_posedge)
			timer_clock <= ~timer_clock;
		else
			timer_clock <= timer_clock;
	wire [7:0] timer_data_bus_out;
	wire tim2gatespk = port_b_out[0] & ~port_b_io;
	wire spkdata = port_b_out[1] & ~port_b_io;
	KF8253 u_KF8253(
		.clock(clock),
		.reset(reset),
		.chip_select_n(timer_chip_select_n),
		.read_enable_n(io_read_n),
		.write_enable_n(io_write_n),
		.address(address[1:0]),
		.data_bus_in(internal_data_bus),
		.data_bus_out(timer_data_bus_out),
		.counter_0_clock(timer_clock),
		.counter_0_gate(1'b1),
		.counter_0_out(timer_counter_out[0]),
		.counter_1_clock(timer_clock),
		.counter_1_gate(1'b1),
		.counter_1_out(timer_counter_out[1]),
		.counter_2_clock(timer_clock),
		.counter_2_gate(tim2gatespk),
		.counter_2_out(timer_counter_out[2])
	);
	assign timer_interrupt = timer_counter_out[0];
	assign speaker_out = timer_counter_out[2] & spkdata;
	wire [7:0] ppi_data_bus_out;
	reg [7:0] port_a_in;
	KF8255 u_KF8255(
		.clock(clock),
		.reset(reset),
		.chip_select_n(ppi_chip_select_n),
		.read_enable_n(io_read_n),
		.write_enable_n(io_write_n),
		.address(address[1:0]),
		.data_bus_in(internal_data_bus),
		.data_bus_out(ppi_data_bus_out),
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
	wire ps2_send_clock;
	wire keybord_irq;
	wire [7:0] keycode;
	wire [7:0] tandy_keycode;
	wire prev_ps2_reset;
	reg prev_ps2_reset_n;
	wire lock_recv_clock;
	wire clear_keycode = port_b_out[7];
	wire ps2_reset_n = (~tandy_video ? port_b_out[6] : 1'b1);
	always @(posedge clock or posedge reset)
		if (reset)
			prev_ps2_reset_n <= 1'b0;
		else
			prev_ps2_reset_n <= ps2_reset_n;
	KFPS2KB u_KFPS2KB(
		.clock(clock),
		.peripheral_clock(peripheral_clock),
		.reset(reset),
		.device_clock(ps2_clock | lock_recv_clock),
		.device_data(ps2_data),
		.irq(keybord_irq),
		.keycode(keycode),
		.clear_keycode(clear_keycode)
	);
	KFPS2KB_Send_Data u_KFPS2KB_Send_Data(
		.clock(clock),
		.peripheral_clock(peripheral_clock),
		.reset(reset),
		.device_clock(ps2_clock),
		.device_clock_out(ps2_send_clock),
		.device_data_out(ps2_data_out),
		.sending_data_flag(lock_recv_clock),
		.send_request(~prev_ps2_reset_n & ps2_reset_n),
		.send_data(8'hff)
	);
	Tandy_Scancode_Converter u_Tandy_Scancode_Converter(
		.clock(clock),
		.reset(reset),
		.scancode(keycode),
		.keybord_irq(keybord_irq),
		.convert_data(tandy_keycode)
	);
	always @(posedge clock or posedge reset)
		if (reset)
			ps2_clock_out = 1'b1;
		else
			ps2_clock_out = ~((keybord_irq | ~ps2_send_clock) | ~ps2_reset_n);
	
	wire [7:0] jtopl2_dout;
	wire [7:0] opl32_data;
	assign opl32_data = (adlibhide ? 8'hff : jtopl2_dout);
	jtopl2 jtopl2_inst(
		.rst(reset),
		.clk(clock),
		.cen(clk_en_opl2),
		.din(internal_data_bus),
		.dout(jtopl2_dout),
		.addr(address[0]),
		.cs_n(opl_chip_select_n),
		.wr_n(io_write_n),
		.irq_n(),
		.snd(jtopl2_snd_e),
		.sample()
	);
	sn76489_top sn76489(
		.clock_i(clock),
		.clock_en_i(clk_en_opl2),
		.res_n_i(~reset),
		.ce_n_i(tandy_chip_select_n),
		.we_n_i(io_write_n),
		.ready_o(tandy_snd_rdy),
		.d_i(internal_data_bus),
		.aout_o(tandy_snd_e)
	);
	reg keybord_interrupt_ff;
	always @(posedge clock or posedge reset)
		if (reset) begin
			keybord_interrupt_ff <= 1'b0;
			keybord_interrupt <= 1'b0;
		end
		else begin
			keybord_interrupt_ff <= keybord_irq;
			keybord_interrupt <= keybord_interrupt_ff;
		end
	reg prev_io_read_n;
	reg prev_io_write_n;
	reg [7:0] write_to_uart;
	wire [7:0] uart_readdata_1;
	wire [7:0] uart_readdata_2;
	reg [7:0] uart_readdata;
	always @(posedge clock) begin
		prev_io_read_n <= io_read_n;
		prev_io_write_n <= io_write_n;
	end
	reg [7:0] keycode_ff;
	always @(posedge clock or posedge reset)
		if (reset) begin
			keycode_ff <= 8'h00;
			port_a_in <= 8'h00;
		end
		else begin
			keycode_ff <= (~tandy_video ? keycode : tandy_keycode);
			port_a_in <= keycode_ff;
		end
	reg [7:0] lpt_data = 8'hff;
	reg [7:0] tandy_page_data = 8'h00;
	reg [7:0] nmi_mask_register_data = 8'hff;
	always @(posedge clock) begin
		if (~io_write_n)
			write_to_uart <= internal_data_bus;
		else
			write_to_uart <= write_to_uart;
		if (lpt_cs && ~io_write_n)
			lpt_data <= internal_data_bus;
		if (tandy_page_cs && ~io_write_n)
			tandy_page_data <= internal_data_bus;
		if (~nmi_mask_register_n && ~io_write_n)
			nmi_mask_register_data <= internal_data_bus;
	end
	wire iorq_uart = (io_write_n & ~prev_io_write_n) || (~io_read_n & prev_io_read_n);
	uart uart1(
		.clk(clock),
		.br_clk(clk_uart),
		.reset(reset),
		.address(address[2:0]),
		.writedata(write_to_uart),
		.read(~io_read_n & prev_io_read_n),
		.write(io_write_n & ~prev_io_write_n),
		.readdata(uart_readdata_1),
		.cs(uart_cs & iorq_uart),
		.rx(uart_rx),
		.tx(uart_tx),
		.cts_n(uart_cts_n),
		.dcd_n(uart_dcd_n),
		.dsr_n(uart_dsr_n),
		.rts_n(uart_rts_n),
		.dtr_n(uart_dtr_n),
		.ri_n(1),
		.irq(uart_interrupt)
	);
	always @(posedge clock)
		if (~io_read_n)
			uart_readdata <= uart_readdata_1;
		else
			uart_readdata <= uart_readdata;
	reg [19:0] video_ram_address;
	reg [7:0] video_ram_data;
	reg video_memory_write_n;
	reg video_memory_read_n;
	reg cga_chip_select_n_1;
	reg [14:0] video_io_address;
	reg [7:0] video_io_data;
	reg video_io_write_n;
	reg video_io_read_n;
	reg video_address_enable_n;
	reg [14:0] cga_io_address_1;
	reg [14:0] cga_io_address_2;
	reg [7:0] cga_io_data_1;
	reg [7:0] cga_io_data_2;
	reg cga_io_write_n_1;
	reg cga_io_write_n_2;
	reg cga_io_write_n_3;
	reg cga_io_read_n_1;
	reg cga_io_read_n_2;
	reg cga_io_read_n_3;
	reg cga_address_enable_n_1;
	reg cga_address_enable_n_2;
	always @(posedge clock)
		if (~io_write_n | ~io_read_n) begin
			video_io_address <= address[14:0];
			video_io_data <= internal_data_bus;
		end
		else begin
			video_io_address <= video_io_address;
			video_io_data <= video_io_data;
		end
	always @(posedge clock) begin
		video_ram_address <= address[19:0];
		video_ram_data <= internal_data_bus;
		video_memory_write_n <= memory_write_n;
		video_memory_read_n <= memory_read_n;
		cga_chip_select_n_1 <= cga_chip_select_n;
		video_io_write_n <= io_write_n;
		video_io_read_n <= io_read_n;
		video_address_enable_n <= address_enable_n;
	end
	reg [7:0] cga_vram_cpu_dout;
	always @(posedge clk_vga_cga) begin
		cga_io_address_1 <= video_io_address;
		cga_io_address_2 <= cga_io_address_1;
		cga_io_data_1 <= video_io_data;
		cga_io_data_2 <= cga_io_data_1;
		cga_io_write_n_1 <= video_io_write_n;
		cga_io_write_n_2 <= cga_io_write_n_1;
		cga_io_write_n_3 <= cga_io_write_n_2;
		cga_io_read_n_1 <= video_io_read_n;
		cga_io_read_n_2 <= cga_io_read_n_1;
		cga_io_read_n_3 <= cga_io_read_n_2;
		cga_address_enable_n_1 <= video_address_enable_n;
		cga_address_enable_n_2 <= cga_address_enable_n_1;
		cga_vram_cpu_dout <= SRAM_DATA;
	end
	wire [3:0] video_cga;
	wire [18:0] CGA_VRAM_ADDR;
	wire [7:0] CGA_VRAM_DOUT;
	
	wire CGA_CRTC_OE;
	reg CGA_CRTC_OE_1;
	reg CGA_CRTC_OE_2;
	wire [7:0] CGA_CRTC_DOUT;
	reg [7:0] CGA_CRTC_DOUT_1;
	reg [7:0] CGA_CRTC_DOUT_2;
	localparam MDA_70HZ = 0;
	wire thin_font;
	assign thin_font = 1'b0;
	cga_vgaport vga_cga(
		.clk(clk_vga_cga),
		.video(video_cga),
		.red(VGA_R),
		.green(VGA_G),
		.blue(VGA_B)
	);
	wire isa_op_enable;
	cga cga1(
		.clk(clk_vga_cga),
		.bus_a(cga_io_address_1), // cga_io_address_2
		.bus_ior_l(cga_io_read_n_2), // cga_io_read_n_3
		.bus_iow_l(cga_io_write_n_2), // cga_io_write_n_3
		.bus_memr_l(1'd0),
		.bus_memw_l(1'd0),
		.bus_d(cga_io_data_2),
		.bus_out(CGA_CRTC_DOUT),
		.bus_dir(CGA_CRTC_OE),
		.bus_aen(cga_address_enable_n_1), // cga_address_enable_n_2
		.vram_enable(CGA_VRAM_ENABLE),
		.vram_addr(CGA_VRAM_ADDR),
		.vram_din((splashscreen ? CGA_VRAM_DOUT : cga_vram_cpu_dout)),
		.hsync(VGA_HSYNC),
		.hblank(VGA_HBlank),
		.vsync(VGA_VSYNC),
		.vblank(VGA_VBlank),
		.de_o(de_o),
		.video(video_cga),
		.splashscreen(splashscreen),
		.thin_font(thin_font),
		.tandy_video(tandy_video),
		.grph_mode(grph_mode),
		.hres_mode(hres_mode),
		.isa_op_enable(isa_op_enable)
	);
	always @(posedge clock) begin
		CGA_CRTC_OE_1 <= CGA_CRTC_OE;
		CGA_CRTC_OE_2 <= CGA_CRTC_OE_1;
		CGA_CRTC_DOUT_1 <= CGA_CRTC_DOUT;
		CGA_CRTC_DOUT_2 <= CGA_CRTC_DOUT_1;
	end
	wire pcxt_loading = ioctl_download && (ioctl_index[5:0] == 0);
	wire tandy_loading = ioctl_download && (ioctl_index[5:0] == 1);
	wire xtide_loading = ioctl_download && (ioctl_index == 2);
	wire pcxt_loader = pcxt_loading && (ioctl_addr[24:16] == 9'b000000000);
	wire tandy_loader = tandy_loading && (ioctl_addr[24:16] == 9'b000000000);
	wire bios_loader = pcxt_loader || tandy_loader;
	reg bios_loaded = 1'b0;
	reg bios_loading = 1'b0;
	reg [20:0] latch_address;
	always @(*)
		if (ems_b1)
			latch_address = {1'b1, map_ems[18+:6], address[13:0]};
		else if (ems_b2)
			latch_address = {1'b1, map_ems[12+:6], address[13:0]};
		else if (ems_b3)
			latch_address = {1'b1, map_ems[6+:6], address[13:0]};
		else if (ems_b4)
			latch_address = {1'b1, map_ems[0+:6], address[13:0]};
		else
			latch_address = {1'b0, address};
	defparam cga1.BLINK_MAX = 24'd4772727;
	wire [7:0] bios_cpu_dout;
	wire [7:0] xtide_cpu_dout;
	wire [7:0] ram_cpu_dout;
	wire [20:0] tandy_processor = {1'b0, nmi_mask_register_data[3:1], tandy_page_data[5:4], (tandy_page_data[3] ? tandy_page_data[3] : latch_address[14]), latch_address[13:0]};
	wire [20:0] tandy_crtc = {1'b0, nmi_mask_register_data[3:1], tandy_page_data[2:1], (tandy_page_data[0] ? tandy_page_data[0] : CGA_VRAM_ADDR[14]), CGA_VRAM_ADDR[13:0]};
	wire [20:0] cga_crtc = {6'b010111, CGA_VRAM_ADDR[14:0]};
	wire [20:0] SRAM_ADDR_A;
	wire SRAM_WE_n_A;
	ram ram(
		.clka(clock),
		.ena((~iorq && ~address_enable_n) && ~ram_select_n),
//		.enaxtide(~xtide_select_n || xtide_loading),
//		.enabios(~bios_select_n || bios_loader),
		.wea(~memory_write_n),
//		.weaxtide((xtide_loading && ioctl_wr) || (~memory_write_n && bios_writable[0])),
//		.weabios((bios_loader && ioctl_wr) || (~memory_write_n && bios_writable[1])),
		.addra(((tandy_16_gfx && ~cga_chip_select_n) && ~latch_address[20] ? tandy_processor : latch_address)),
//		.addraxtide({7'b0111011, (xtide_loading ? ioctl_addr[13:0] : address[13:0])}),
//		.addrabios((bios_loader ? {tandy_loader, 4'b1111, ioctl_addr[15:0]} : {tandy_video, 4'b1111, address[15:0]})),
		.dina(internal_data_bus),
//		.dinaxtidebios((xtide_loading || bios_loader ? ioctl_data : internal_data_bus)),
		.douta(ram_cpu_dout),
//		.doutaxtide(xtide_cpu_dout),
//		.doutabios(bios_cpu_dout),
		.SRAM_ADDR(SRAM_ADDR_A),
		.SRAM_DATA_i(SRAM_DATA),
		.SRAM_DATA_o(SRAM_DATA_A_o),
		.SRAM_WE_n(SRAM_WE_n_A)
	);
	assign SRAM_WE_n = (CGA_VRAM_ENABLE && ~(xtide_loading || bios_loader) ? 1'b1 : SRAM_WE_n_A);
	assign SRAM_ADDR = (CGA_VRAM_ENABLE && ~(xtide_loading || bios_loader) ? (tandy_16_gfx ? tandy_crtc : cga_crtc) : SRAM_ADDR_A);
	assign SRAM_DATA = (~SRAM_WE_n ? SRAM_DATA_A_o : 8'hzz);
	
	/*
	reg [12:0] rom_address;
	reg bios_select_n_1;
	
	always @(posedge clock) begin
		  rom_address      <= address[12:0];
        bios_select_n_1  <= bios_select_n;
   end
	*/
	BRAM_8KB_BIOS bios(
		.clka(clock),
		.ena(~bios_select_n), // bios_select_n_1
//		.wea(~memory_write_n),		
		.addra(address[12:0]), // rom_address
//		.dina(internal_data_bus),
		.douta(bios_cpu_dout)
	);
	
	BRAM_16KB_XTIDE xtide(
		.clka(clock),
		.ena(~xtide_select_n),
//		.wea(~memory_write_n),		
		.addra(address[13:0]), // rom_address
//		.dina(internal_data_bus),
		.douta(xtide_cpu_dout)
	);

	splash splash_screen(
		.clka(clk_vga_cga),
		.wea(1'b0),
		.ena(splashscreen && CGA_VRAM_ENABLE),
		.addra(CGA_VRAM_ADDR[11:0]),
		.dina(8'h00),
		.douta(CGA_VRAM_DOUT)
	);
	/*
	wire [7:0] joy_data;
	tandy_pcjr_joy joysticks(
		.clk(clock),
		.reset(reset),
		.en(joystick_select && ~io_write_n),
		.turbo_mode(turbo_mode),
		.joy_opts(joy_opts),
		.joy0(joy0),
		.joy1(joy1),
		.joya0(joya0),
		.joya1(joya1),
		.d_out(joy_data)
	);
	*/
	always @(posedge clock)
		if (~interrupt_acknowledge_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= interrupt_data_bus_out;
		end
		else if (~interrupt_chip_select_n && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= interrupt_data_bus_out;
		end
		else if (~timer_chip_select_n && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= timer_data_bus_out;
		end
		else if (~ppi_chip_select_n && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= ppi_data_bus_out;
		end
		else if (~bios_select_n && ~memory_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= bios_cpu_dout;
		end
		else if (~xtide_select_n && ~memory_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= xtide_cpu_dout;
		end
		else if (CGA_CRTC_OE_2) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= CGA_CRTC_DOUT_2;
		end
		else if (~opl_chip_select_n && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= opl32_data;
		end
		else if (uart_cs && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= uart_readdata;
		end
		else if (~ram_select_n && ~memory_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= ram_cpu_dout;
		end
		else if (ems_oe && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= (ena_ems[address[1:0]] ? map_ems[(3 - address[1:0]) * 6+:6] : 8'hff);
		end
		else if (lpt_cs && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= lpt_data;
		end
		else if (~nmi_mask_register_n && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= nmi_mask_register_data;
		end
		/*
		else if (joystick_select && ~io_read_n) begin
			data_bus_out_from_chipset <= 1'b1;
			data_bus_out <= joy_data;
		end
		*/
		else begin
			data_bus_out_from_chipset <= 1'b0;
			data_bus_out <= 8'b00000000;
		end
endmodule
