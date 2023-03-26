`default_nettype none

module bram_dualport #(parameter AW=16, parameter filename="empty")
(	
	input		wire					clka,
	input		wire					ena,
	input		wire					wea,
	input		wire	[AW-1:0]		addra,
	input		wire	[7:0]			dina,
	output	reg	[7:0]			douta,
	input		wire					clkb,
	input		wire					enb,
	input		wire					web,
	input		wire	[AW-1:0]		addrb,
	input		wire	[7:0]			dinb,
	output	reg	[7:0]			doutb
);

reg [7:0] bram[(2**AW)-1:0];

initial $readmemh(filename, bram);

always @(posedge clka) begin

  if (ena)
		if (wea)
			bram[addra] <= dina;
		else
			douta <= bram[addra];
end
always @(posedge clkb) begin
  if (enb)
		if (web)
			bram[addrb] <= dinb;
		else
			doutb <= bram[addrb];
end
endmodule