`timescale 1ns / 1ps
`default_nettype none

module system(
	input		wire					clk_100,
	input		wire					clk_chipset,
	input		wire					clk_vga,
	
	output	wire					turbo,

	output	wire	[20:0]		SRAM_ADDR,
	inout		wire	[7:0]			SRAM_DATA,
	output	wire					SRAM_WE_n,
	output	wire	[5:0]			VGA_R,
	output	wire	[5:0]			VGA_G,
	output	wire	[5:0]			VGA_B,
	output	wire					VGA_HSYNC,
	output	wire					VGA_VSYNC,

	inout		wire					clkps2,
	inout		wire					dataps2,
	inout    wire              mouseclk,
	inout    wire              mousedata,

	output	wire					AUD_L,
	output	wire					AUD_R,
	output 	wire					SD_nCS,
	output	wire					SD_DI,
	output	wire					SD_CK,
	input		wire					SD_DO,
	input		wire					btn_green_n_i,
	input		wire					btn_yellow_n_i
	
	/*
	output	wire					LED,

	input		wire					joy_up,
	input		wire					joy_down,
	input		wire					joy_left,
	input		wire					joy_right,
	input		wire					joy_fire1,
	input		wire					joy_fire2
	*/
	);
	
`include "config.vh"
	 
reg clk_14_318 = 1'b0;
reg clk_7_16 = 1'b0;
wire clk_4_77;
reg clk_cpu = 1'b0;
reg pclk = 1'b0;
reg peripheral_clock;
wire [7:0] xtctl;

reg ps2_clock_in;
reg ps2_data_in;
wire ps2_clock_out;
wire ps2_data_out;

reg ps2_mouseclk_in;
reg ps2_mousedat_in;
wire ps2_mouseclk_out;
wire ps2_mousedat_out;

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
assign mouseclk = (ps2_mouseclk_out == 1'b0) ? 1'b0 : 1'bZ;
assign mousedata = (ps2_mousedat_out == 1'b0) ? 1'b0 : 1'bZ;

always @(posedge peripheral_clock) begin
	ps2_clock_in <= clkps2;
	ps2_data_in <= dataps2;
	ps2_mouseclk_in <= mouseclk;
	ps2_mousedat_in <= mousedata;
end
	
wire  biu_done;
reg  turbo_mode;

always @(posedge clk_chipset) begin
    if (biu_done)
		  turbo_mode  <= turbo; // ? turbo : xtctl[0];
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

reg         clk_opl2; // 3.58MHz
reg  [15:0] cen_opl2_cnt;
wire [15:0] cen_opl2_cnt_next = cen_opl2_cnt + 16'd358;
always @(posedge clk_chipset) begin
	clk_opl2 <= 0;
	cen_opl2_cnt <= cen_opl2_cnt_next;
	if (cen_opl2_cnt_next >= 5000) begin // CPU_MHZ * 100
		clk_opl2 <= 1;
		cen_opl2_cnt <= cen_opl2_cnt_next - 5000;
	end
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

reg reset = 1'b0;
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

`ifdef SPLASH_ENABLE
	reg splashscreen = 1'b1;
`else
	reg splashscreen = 1'b0;
`endif	
	
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
		  .turbo		                          (turbo),
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
        .ps2_mouseclk_in                    (ps2_mouseclk_in),
        .ps2_mousedat_in                    (ps2_mousedat_in),
        .ps2_mouseclk_out                   (ps2_mouseclk_out),
        .ps2_mousedat_out                   (ps2_mousedat_out),
//		  .joy_opts                           (joy_opts),                          //Joy0-Disabled, Joy0-Type, Joy1-Disabled, Joy1-Type, turbo_sync
//      .joy0                               (status[28] ? joy1 : joy0),
//      .joy1                               (status[28] ? joy0 : joy1),
//		  .joya0                              (status[28] ? joya1 : joya0),
//		  .joya1                              (status[28] ? joya0 : joya1),
		  .clk_en_opl2                        (cen_opl2),
		  .jtopl2_snd_e                       (jtopl2_snd_e),
		  .tandy_snd_e                        (tandy_snd_e),
		  .clk_uart                           (clk_uart2_en),
//		  .adlibhide                          (adlibhide),
//		  .tandy_video                        (tandy_mode),
//		  .tandy_16_gfx                       (tandy_16_gfx),
//		  .ioctl_download                     (ioctl_download),
//		  .ioctl_index                        (ioctl_index),
//		  .ioctl_wr                           (ioctl_wr),
//		  .ioctl_addr                         (ioctl_addr),
//		  .ioctl_data                         (ioctl_data),
		  .spi_clk                            (spi_clk),
		  .spi_cs                             (spi_cs),
		  .spi_mosi                           (spi_mosi),
		  .spi_miso                           (spi_miso),
		  .SRAM_ADDR                          (SRAM_ADDR),
		  .xtctl                              (xtctl),
		  .SRAM_DATA                          (SRAM_DATA),
		  .SRAM_WE_n                          (SRAM_WE_n),
		  .ems_enabled                        (1'b1),
		  .ems_address                        (2'b00), // 00: 0xC000 01: 0xD000 11: 0xE000
		  .btn_green_n_i							  (btn_green_n_i),
		  .btn_yellow_n_i							  (btn_yellow_n_i)
    );

    //
    ///////////////////////   MMC     ///////////////////////
    //
    wire spi_clk;
    wire spi_cs;
    wire spi_mosi;
    wire spi_miso;
	 
	// output 	wire					SD_nCS, // OK
	// output	wire					SD_DI,
	// output	wire					SD_CK,
	// input		wire					SD_DO,
	//
	// output wire SD_CS, // OK
	// output wire SD_DI,
	// output reg SD_CK = 0, // OK
	// input SD_DO,

    assign  SD_CK      = spi_clk; // OK
    assign  SD_DI      = spi_mosi;
    assign  spi_miso   = SD_DO;
    assign  SD_nCS     = spi_cs; // OK
	 
    //
    ////////////////////////////  UART  ///////////////////////////////////
    //
	 
	 reg         clk_uart; // 14.815MHz
	 reg  [21:0] clk_uart_cnt;
	 wire [21:0] clk_uart_cnt_next = clk_uart_cnt + 22'd14815;
	 always @(posedge clk_chipset) begin
		clk_uart <= 0;
		clk_uart_cnt <= clk_uart_cnt_next;
	 	if (clk_uart_cnt_next >= 50000) begin // CPU_MHZ * 1000
	 		clk_uart <= 1;
	 		clk_uart_cnt <= clk_uart_cnt_next - 50000;
	 	end
	 end

    reg clk_uart_ff_1;
    reg clk_uart_ff_2;
    reg clk_uart_ff_3;
    reg clk_uart_en;
    reg clk_uart2_en;
    reg [2:0] clk_uart2_counter;

    always @(posedge clk_chipset)
    begin
        clk_uart_ff_1 <= clk_uart;
        clk_uart_ff_2 <= clk_uart_ff_1;
        clk_uart_ff_3 <= clk_uart_ff_2;
        clk_uart_en   <= ~clk_uart_ff_3 & clk_uart_ff_2;
    end

    always @(posedge clk_chipset)
    begin
        if (clk_uart_en)
        begin
            if (3'd7 != clk_uart2_counter)
            begin
                clk_uart2_counter <= clk_uart2_counter +3'd1;
                clk_uart2_en <= 1'b0;
            end
            else
            begin
                clk_uart2_counter <= 3'd0;
                clk_uart2_en <= 1'b1;
            end
        end
        else
        begin
            clk_uart2_counter <= clk_uart2_counter;
            clk_uart2_en <= 1'b0;
        end
    end



    wire uart_tx, uart_rts, uart_dtr;

//    assign UART_TXD = uart_tx;
//    assign UART_RTS = uart_rts;
//    assign UART_DTR = uart_dtr;

    wire uart_rx;//  = UART_RXD;
    wire uart_cts;// = UART_CTS;
    wire uart_dsr;// = UART_DSR;
    wire uart_dcd;// = UART_DTR;



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
