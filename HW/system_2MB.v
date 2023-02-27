`timescale 1ns / 1ps
`default_nettype none

module system_2MB(
	input		wire					clk_100,
	input		wire					clk_chipset,
	input		wire					clk_vga,	 
	input		wire					clk_uart,
	input		wire					clk_opl2,

	output	wire	[20:0]		SRAM_ADDR,
	inout		wire	[7:0]			SRAM_DATA,
	output	wire					SRAM_WE_n,
	output	wire	[5:0]			VGA_R,
	output	wire	[5:0]			VGA_G,
	output	wire	[5:0]			VGA_B,
	output	wire					VGA_HSYNC,
	output	wire					VGA_VSYNC,
	input		wire					uart_rx,
	output	wire					uart_tx,

	inout		wire					clkps2,
	inout		wire					dataps2,

	output	wire					AUD_L,
	output	wire					AUD_R,
	output	reg					SD_n_CS = 1,
	output	wire					SD_DI,
	output	wire					SD_CK,
	input	wire					SD_DO
	/*
	output	wire					LED,
	inout		wire					PS2_CLK1,
	inout		wire					PS2_CLK2,
	inout		wire					PS2_DATA1,
	inout		wire					PS2_DATA2

	input		wire					joy_up,
	input		wire					joy_down,
	input		wire					joy_left,
	input		wire					joy_right,
	input		wire					joy_fire1,
	input		wire					joy_fire2
	*/
	);
	 
reg clk_14_318 = 1'b0;
reg clk_7_16 = 1'b0;
wire clk_4_77;
reg clk_cpu = 1'b0;
reg pclk = 1'b0;
reg peripheral_clock;

reg ps2_clock_in;
reg ps2_data_in;
wire ps2_clock_out;
wire ps2_data_out;

/*
assign ps2_clock_in = clkps2;
assign clkps2 = (ps2_clock_out == 1'b0) ? 1'b0 : 1'bZ;

assign ps2_data_in = dataps2;
assign dataps2 = (ps2_data_out == 1'b0) ? 1'b0 : 1'bZ;
*/

always @(posedge clk_vga) begin // 28.636MHz
	clk_14_318 <= ~clk_14_318; // 14.318Mhz
end

always @(posedge clk_14_318)
	clk_7_16 <= ~clk_7_16; // 7.16Mhz

clk_div3 clk_normal // 4.77MHz
(
	.clk(clk_14_318),
	.clk_out(clk_4_77)
);

always @(posedge clk_4_77)
	peripheral_clock <= ~peripheral_clock; // 2.385Mhz
	

assign clkps2 = (ps2_clock_out == 1'b0) ? 1'b0 : 1'bZ;
assign dataps2 = (ps2_data_out == 1'b0) ? 1'b0 : 1'bZ;

always @(posedge peripheral_clock) begin
	ps2_clock_in <= clkps2;
	ps2_data_in <= dataps2;
end
	
wire  biu_done;
reg  turbo_mode;

always @(posedge clk_chipset) begin
    if (biu_done)
        //turbo_mode  <= (status[18:17] == 2'b01 || status[18:17] == 2'b10);
		  turbo_mode  <= 1'b1;
    else
        turbo_mode  <= turbo_mode;
end

reg  clk_cpu_ff_1;
reg  clk_cpu_ff_2;

reg  pclk_ff_1;
reg  pclk_ff_2;

always @(posedge clk_chipset) begin
    //clk_cpu_ff_1 <= (status[18:17] == 2'b10) ? clk_14_318 : (status[18:17] == 2'b01) ? clk_7_16 : clk_4_77;
	 clk_cpu_ff_1 <= clk_14_318;
    clk_cpu_ff_2 <= clk_cpu_ff_1;
    clk_cpu      <= clk_cpu_ff_2;
    pclk_ff_1    <= peripheral_clock;
    pclk_ff_2    <= pclk_ff_1;
    pclk         <= pclk_ff_2;
end

reg   clk_opl2_ff_1;
reg   clk_opl2_ff_2;
reg   clk_opl2_ff_3;
reg   cen_opl2;

always @(posedge clk_chipset) begin
    clk_opl2_ff_1 <= clk_opl2;
    clk_opl2_ff_2 <= clk_opl2_ff_1;
    clk_opl2_ff_3 <= clk_opl2_ff_2;
    cen_opl2 <= clk_opl2_ff_2 & ~clk_opl2_ff_3;
end

wire reset_wire = splashscreen;

//////////////////////////////////////////////////////////////////

reg reset = 1'b1;
reg [15:0] reset_count = 16'h0000;

always @(posedge clk_chipset, posedge reset_wire) begin
	if (reset_wire) begin
		reset <= 1'b1;
		reset_count <= 16'h0000;
	end
	else if (reset) begin
		if (reset_count != 16'hffff) begin
			reset <= 1'b1;
			reset_count <= reset_count + 16'h0001;
		end
		else begin
			reset <= 1'b0;
			reset_count <= reset_count;
		end
	end 
	else begin
		reset <= 1'b0;
		reset_count <= reset_count;
	end
end

reg reset_cpu_ff = 1'b1;
reg reset_cpu = 1'b1;
reg [15:0] reset_cpu_count = 16'h0000;

always @(negedge clk_chipset, posedge reset) begin
	if (reset)
		reset_cpu_ff <= 1'b1;
	else
		reset_cpu_ff <= reset;
end

reg tandy_mode = 0;

always @(negedge clk_chipset, posedge reset) begin
	if (reset) begin
		tandy_mode <= 1'b0; // status[3]
		reset_cpu <= 1'b1;
		reset_cpu_count <= 16'h0000;
	end
	else if (reset_cpu) begin
		reset_cpu <= reset_cpu_ff;
		reset_cpu_count <= 16'h0000;
	end
	else begin
		if (reset_cpu_count != 16'h002A) begin
			reset_cpu <= reset_cpu_ff;
			reset_cpu_count <= reset_cpu_count + 16'h0001;
		end
		else begin
			reset_cpu <= 1'b0;
			reset_cpu_count <= reset_cpu_count;
		end
	end
end

reg splash_status = 1'b0;
//////////////////////////////////////////////////////////////////
	
	reg [24:0] splash_cnt = 0;
	reg [3:0] splash_cnt2 = 0;
	reg splashscreen = 1;
	
	always @ (posedge clk_14_318) begin
	
		if (splashscreen) begin
			if (splash_status) // status[7]
				splashscreen <= 0;
			else if(splash_cnt2 == 5) // 5 seconds delay
				splashscreen <= 0;
			else if (splash_cnt == 14318000) begin // 1 second at 14.318Mhz
					splash_cnt2 <= splash_cnt2 + 1;				
					splash_cnt <= 0;
				end
			else
				splash_cnt <= splash_cnt + 1;			
		end
	
	end
	
    wire [7:0] data_bus;
    wire INTA_n;	
    wire [19:0] cpu_ad_out;
    reg  [19:0] cpu_address;
    wire [7:0] cpu_data_bus;    
    wire processor_ready;	
    wire interrupt_to_cpu;
    wire address_latch_enable;

    wire lock_n;
    wire [2:0]processor_status;
	 
	 wire [7:0] port_b_out;
    wire [7:0] port_c_in;	 
	 wire [7:0] sw;
	 wire speaker_out;
	 
//	 wire [1:0] scale = status[2:1];
//	 wire [2:0] screen_mode = status[16:14];	 
	 
	 assign  sw = 8'b00101101; // PCXT DIP Switches (CGA 80)
	 assign  port_c_in[3:0] = port_b_out[3] ? sw[7:4] : sw[3:0];
	 
	reg clk_uart_ff_1;
	reg clk_uart_ff_2;
	reg clk_uart_ff_3;
	reg clk_uart_en;

	always @(posedge clk_chipset) begin
		clk_uart_ff_1 <= clk_uart;
		clk_uart_ff_2 <= clk_uart_ff_1;
		clk_uart_ff_3 <= clk_uart_ff_2;
		clk_uart_en   <= ~clk_uart_ff_3 & clk_uart_ff_2;
   end
	
   wire [15:0]jtopl2_snd_e;
	wire [15:0]tandy_snd_e;
	reg [31:0]sndval = 0;	
	
	wire [16:0]sndmix = (({jtopl2_snd_e[15], jtopl2_snd_e}) << 1) + {tandy_snd_e, 6'd0} + (speaker_out << 13); // signed mixer
	//wire [16:0]sndmix = (({jtopl2_snd_e[15], jtopl2_snd_e}) << 2) + (speaker_out << 15); // signed mixer
	wire [15:0]sndamp = (~|sndmix[16:15] | &sndmix[16:15]) ? {!sndmix[15], sndmix[14:0]} : {16{!sndmix[16]}}; // clamp to [-32768..32767] and add 32878
	wire sndsign = sndval[31:16] < sndamp;
	
	always @(posedge clk_vga) begin	
		sndval <= sndval - sndval[31:7] + (sndsign << 25);
	end
	
	assign AUD_L = sndsign;
	assign AUD_R = sndsign;
		 
   CHIPSET u_CHIPSET (
        .clock                              (clk_chipset),
        .cpu_clock                          (clk_cpu),
		  .clk_sys                            (clk_chipset),
		  .peripheral_clock                   (pclk),
//		  .turbo_mode                         (1'b1), // status[18:17]
        .reset                              (reset_cpu),
        .cpu_address                        (cpu_address),
        .cpu_data_bus                       (cpu_data_bus),
        .processor_status                   (processor_status),
        .processor_lock_n                   (lock_n),
 //     .processor_transmit_or_receive_n    (processor_transmit_or_receive_n),
		  .processor_ready                    (processor_ready),
        .interrupt_to_cpu                   (interrupt_to_cpu),
        .splashscreen                       (splashscreen),
        .clk_vga_cga                        (clk_vga),
//      .de_o                               (VGA_DE),
        .VGA_R                              (VGA_R),
        .VGA_G                              (VGA_G),
        .VGA_B                              (VGA_B),
        .VGA_HSYNC                          (VGA_HSYNC),
        .VGA_VSYNC                          (VGA_VSYNC),
//		  .VGA_HBlank	  				           (HBlank),
//		  .VGA_VBlank							     (VBlank),
//      .address                            (address),
        .address_ext                        (20'hFFFFF),
//      .address_direction                  (address_direction),
        .data_bus                           (data_bus),
        .data_bus_ext                       (8'hFF),
//      .data_bus_direction                 (data_bus_direction),
        .address_latch_enable               (address_latch_enable),
//      .io_channel_check                   (),
        .io_channel_ready                   (1'b1),
        .interrupt_request                  (0),    // use?	-> It does not seem to be necessary.
//      .io_read_n                          (io_read_n),
        .io_read_n_ext                      (1'b1),
//      .io_read_n_direction                (io_read_n_direction),
//      .io_write_n                         (io_write_n),
        .io_write_n_ext                     (1'b1),
//      .io_write_n_direction               (io_write_n_direction),
//      .memory_read_n                      (memory_read_n),
        .memory_read_n_ext                  (1'b1),
//      .memory_read_n_direction            (memory_read_n_direction),
//      .memory_write_n                     (memory_write_n),
        .memory_write_n_ext                 (1'b1),
//      .memory_write_n_direction           (memory_write_n_direction),
        .dma_request                        (0),    // use?	-> I don't know if it will ever be necessary, at least not during testing.
//      .dma_acknowledge_n                  (dma_acknowledge_n),
//      .address_enable_n                   (address_enable_n),
//      .terminal_count_n                   (terminal_count_n)
        .port_b_out                         (port_b_out),
		  .port_c_in                          (port_c_in),
	     .speaker_out                        (speaker_out),   
		  .ps2_clock                          (ps2_clock_in),
	     .ps2_data                           (ps2_data_in),
	     .ps2_clock_out                      (ps2_clock_out),
	     .ps2_data_out                       (ps2_data_out),
//		  .joy_opts                           (joy_opts),                          //Joy0-Disabled, Joy0-Type, Joy1-Disabled, Joy1-Type, turbo_sync
//      .joy0                               (status[28] ? joy1 : joy0),
//      .joy1                               (status[28] ? joy0 : joy1),
//		  .joya0                              (status[28] ? joya1 : joya0),
//		  .joya1                              (status[28] ? joya0 : joya1),
		  .clk_en_opl2                        (cen_opl2),
		  .jtopl2_snd_e                       (jtopl2_snd_e),
		  .tandy_snd_e                        (tandy_snd_e),
//		  .adlibhide                          (adlibhide),
//		  .tandy_video                        (tandy_mode),
//		  .tandy_16_gfx                       (tandy_16_gfx),
//		  .ioctl_download                     (ioctl_download),
//		  .ioctl_index                        (ioctl_index),
//		  .ioctl_wr                           (ioctl_wr),
//		  .ioctl_addr                         (ioctl_addr),
//		  .ioctl_data                         (ioctl_data),		  
		  .clk_uart                           (clk_uart_en),
	     .uart_rx                            (uart_rx),
	     .uart_tx                            (uart_tx),
	     .uart_cts_n                         (1'b0), // uart_cts
	     .uart_dcd_n                         (1'b0), // uart_dcd
	     .uart_dsr_n                         (1'b0), // uart_dsr
//	     .uart_rts_n                         (uart_rts),
//	     .uart_dtr_n                         (uart_dtr),
		  .mmc_clk                            (mmc_clk),
		  .mmc_cmd_in                         (mmc_cmd_in),
		  .mmc_cmd_out                        (mmc_cmd_out),
		  .mmc_cmd_io                         (mmc_cmd_io),
		  .mmc_dat_in                         (mmc_dat_in),
		  .mmc_dat_out                        (mmc_dat_out),
		  .mmc_dat_io                         (mmc_dat_io),
		  .SRAM_ADDR                          (SRAM_ADDR),
		  .SRAM_DATA                          (SRAM_DATA),
		  .SRAM_WE_n                          (SRAM_WE_n),
		  .ems_enabled                        (1'b1), // ~status[11]
		  .ems_address                        (2'b0), // status[13:12]
		  .bios_writable                      (2'b1) // status[31:30]
    );

   //
   ///////////////////////   MMC     ///////////////////////
   //
   wire mmc_clk;
   wire mmc_cmd_in;
   wire mmc_cmd_out;
   wire mmc_cmd_io;
   wire mmc_dat_in;
   wire mmc_dat_out;
   wire mmc_dat_io;
	
   assign  SD_CK    = mmc_clk;
   assign  SD_DI    = (~mmc_cmd_io & ~mmc_cmd_out) ? 1'b0 : 1'bz;
   assign  mmc_cmd_in  = SD_DI;

   assign  mmc_dat_in = (~mmc_dat_io & ~mmc_dat_out) ? 1'b0 : 1'bz;
   assign  SD_DO = mmc_dat_in;

   //
   ///////////////////////   CPU     ///////////////////////
   //
	
	wire s6_3_mux;
	wire [2:0] SEGMENT;
	 
	i8088 B1(
	  .CORE_CLK(clk_100),
	  .CLK(clk_cpu),

	  .RESET(reset_cpu),
	  .READY(processor_ready),
	  .NMI(1'b0),
	  .INTR(interrupt_to_cpu),

	  .ad_out(cpu_ad_out),
	  .dout(cpu_data_bus),
	  .din(data_bus),
	  
	  .lock_n(lock_n),
	  .s6_3_mux(s6_3_mux),
	  .s2_s0_out(processor_status),
	  .SEGMENT(SEGMENT),

      .biu_done(biu_done),
      .turbo_mode(turbo_mode)
	);
	
	always @(posedge clk_100) begin
		if (address_latch_enable)
			cpu_address <= cpu_ad_out;
		else
			cpu_address <= cpu_address;
	end	
	
endmodule
