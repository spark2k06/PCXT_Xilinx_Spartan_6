`default_nettype none

module uart(
	input		wire					clk,
	input		wire					reset,
	input		wire  [2:0]			address,
	input		wire					write,
	input		wire	[7:0]			writedata,
	input		wire					read,
	output	reg	[7:0]			readdata,
	input		wire					cs,
	input		wire					br_clk,
	input		wire					rx,
	output	wire					tx,
	input		wire					cts_n,
	input		wire					dcd_n,
	input		wire					dsr_n,
	input		wire					ri_n,
	output	wire					rts_n,
	output	wire					br_out,
	output	wire					dtr_n,
	output	wire					irq
	);

wire [7:0] data;

always @(posedge clk) if(read & cs) readdata <= data;

uart_16750 uart_16750
(
	.CLK(clk),
	.RST(reset),
	.BAUDCE(br_clk),
	.CS(cs & (read | write)),
	.WR(write),
	.RD(read),
	.A(address),
	.DIN(writedata),
	.DOUT(data),
	.RCLK(br_out),
	
	.BAUDOUTN(br_out),

	.RTSN(rts_n),
	.DTRN(dtr_n),
	.CTSN(cts_n),
	.DSRN(dsr_n),
	.DCDN(dcd_n),
	
	.RIN(ri_n),	
	.SIN(rx),
	.SOUT(tx),

	.INT(irq)

);

endmodule
