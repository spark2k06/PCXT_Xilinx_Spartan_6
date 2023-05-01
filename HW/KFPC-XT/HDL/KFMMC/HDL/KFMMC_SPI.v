module KFMMC_SPI (
	clock,
	reset,
	send_data,
	recv_data,
	start_communication,
	busy_flag,
	spi_clock_cycle,
	spi_clk,
	spi_mosi,
	spi_miso
);
	input wire clock;
	input wire reset;
	input wire [7:0] send_data;
	output wire [7:0] recv_data;
	input wire start_communication;
	output wire busy_flag;
	input wire [7:0] spi_clock_cycle;
	output reg spi_clk;
	output reg spi_mosi;
	input wire spi_miso;
	reg [7:0] clk_cycle_counter;
	wire edge_spi_clk;
	wire sample_edge;
	wire shift_edge;
	reg [7:0] txd_register;
	reg [8:0] rxd_register;
	reg [3:0] bit_count;
	wire access_flag;
	always @(posedge clock or posedge reset)
		if (reset)
			clk_cycle_counter <= 8'd1;
		else if (access_flag) begin
			if (edge_spi_clk)
				clk_cycle_counter <= 8'd1;
			else
				clk_cycle_counter <= clk_cycle_counter + 1'd1;
		end
		else
			clk_cycle_counter <= 8'd1;
	always @(posedge clock or posedge reset)
		if (reset)
			spi_clk <= 1'b0;
		else if (access_flag && (bit_count != 4'd1)) begin
			if (edge_spi_clk)
				spi_clk <= ~spi_clk;
			else
				spi_clk <= spi_clk;
		end
		else
			spi_clk <= 1'b0;
	assign edge_spi_clk = clk_cycle_counter == {1'b0, spi_clock_cycle[7:1]};
	assign sample_edge = edge_spi_clk & (spi_clk == 1'b0);
	assign shift_edge = edge_spi_clk & (spi_clk == 1'b1);
	always @(posedge clock or posedge reset)
		if (reset)
			txd_register <= 8'h00;
		else if (access_flag) begin
			if (shift_edge)
				txd_register <= {txd_register[6:0], 1'b1};
			else
				txd_register <= txd_register;
		end
		else if (start_communication)
			txd_register <= send_data;
		else
			txd_register <= 8'h00;
	always @(*)
		if (access_flag)
			spi_mosi = txd_register[7];
		else
			spi_mosi = 1'b1;
	always @(posedge clock or posedge reset)
		if (reset)
			rxd_register <= 9'h000;
		else if (access_flag) begin
			if (sample_edge)
				rxd_register <= {rxd_register[8:1], spi_miso};
			else if (shift_edge)
				rxd_register <= {rxd_register[7:0], 1'b0};
			else
				rxd_register <= rxd_register;
		end
		else
			rxd_register <= rxd_register;
	assign recv_data = rxd_register[8:1];
	always @(posedge clock or posedge reset)
		if (reset)
			bit_count <= 4'd0;
		else if (access_flag) begin
			if (shift_edge)
				bit_count <= bit_count - 4'd1;
			else if (sample_edge && (bit_count == 4'd1))
				bit_count <= 4'd0;
			else
				bit_count <= bit_count;
		end
		else if (start_communication)
			bit_count <= 4'd9;
	assign access_flag = bit_count != 4'd0;
	assign busy_flag = (reset ? 1'b1 : access_flag);
endmodule
