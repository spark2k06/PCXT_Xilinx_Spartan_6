`default_nettype none

module bram #(parameter AW=16, parameter filename="")
(	
	input		wire					clka,
	input		wire					ena,
	input		wire					wea,
	input		wire	[AW-1:0]		addra,
	input		wire	[7:0]			dina,
	output	reg	[7:0]			douta,
	output	wire					istandy
);

reg [7:0] bram[(2**AW)-1:0];

initial $readmemh(filename, bram);

reg [7:0] tandy_byte = 8'h00;
reg get_tandy_byte = 1'b0;

assign istandy = (tandy_byte == 8'h38);

always @(posedge clka) begin
  
  if (get_tandy_byte)
		tandy_byte <= douta;
  
  if (ena)
		if (wea)
			bram[addra] <= dina;
		else begin		
			douta <= bram[addra];
			if (addra == 0)
				get_tandy_byte <= 1'b1;
			else
				get_tandy_byte <= 1'b0;
		end

end
endmodule