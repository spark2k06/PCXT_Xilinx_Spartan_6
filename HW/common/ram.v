`default_nettype none

module ram
(
	input		wire					clka,
	input		wire					ena,
	input		wire					enaxtide,
	input		wire					enabios,
	input		wire					enacga,
	input		wire					wea,
	input		wire					weaxtide,
	input		wire					weabios,  
	input		wire	[18:0]		addra,
	input		wire	[18:0]		addraxtide,
	input		wire	[18:0]		addrabios,
	input		wire	[18:0]		addracga,
	input		wire	[18:0]		dina,
	input		wire	[18:0]		dinaxtidebios,
	output	reg	[7:0]			douta,
	output	reg	[7:0]			doutaxtide,
	output	reg	[7:0]			doutabios,
	output	reg	[7:0]			doutacga,

	output	reg	[18:0]		SRAM_ADDR,
	input		wire	[7:0]			SRAM_DATA_i,
	output	reg	[7:0]			SRAM_DATA_o,  
	output	reg	[7:0]			SRAM_WE_n
);

wire	isa_dout;
assign isa_dout = SRAM_DATA_i;

always @(posedge clka)
begin
	SRAM_WE_n <= 1'b1;
	if (enaxtide) begin
      SRAM_ADDR = addraxtide;
		if (weaxtide) begin
		   SRAM_WE_n <= 1'b0;			
			SRAM_DATA_o <= dinaxtidebios;
		end
		else begin			
			doutaxtide <= SRAM_DATA_i;
		end
	end
	else if (enabios) begin
      SRAM_ADDR = addrabios;
		if (weabios) begin
		   SRAM_WE_n <= 1'b0;			
			SRAM_DATA_o <= dinaxtidebios;
		end
		else begin
			doutabios <= SRAM_DATA_i;
		end
	end
	else if (enacga) begin
		SRAM_ADDR = addracga;
		doutacga <= SRAM_DATA_i;
	end
	
	else if (ena) begin
      SRAM_ADDR = addra;
		if (wea) begin
		   SRAM_WE_n <= 1'b0;			
			SRAM_DATA_o <= dina;
		end
		else begin
			douta <= SRAM_DATA_i;
		end
	end
end
endmodule