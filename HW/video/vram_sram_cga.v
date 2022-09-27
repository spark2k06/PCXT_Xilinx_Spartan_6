module vram #(parameter AW=16)
(
  input clk,

  // Lines from other logic
  // Port 0 is read/write
  input [AW-1:0] isa_addr,  
  input [7:0] isa_din,
  output[7:0] isa_dout,  
  input isa_read,
  input isa_write,
  input isa_op_enable,

  // Port 1 is read only
  input[AW-1:0] pixel_addr,
  output [7:0] pixel_data,
  input pixel_read
  

);

reg[AW-1:0] op_addr = 20'd0;
reg[7:0] ram_write_data = 8'd0;
reg isa_write_old = 1'b0;
reg[2:0] write_del = 0;
reg[AW-1:0] ram_a = 20'd0;

//assign ram_we_l = ~(write_del == 3'd4);
//assign isa_dout = ram_d;

// Gated by clock so that we give the SRAM chip
// some time to tristate its data output after
// we begin the write operation. (tHZWE)

//assign ram_d = (~ram_we_l & ~clk) ? ram_write_data : 8'hZZ;


	vram_t #(.AW(15)) cga_t_vram	
	(
	     .clka                       (clk),
		  .ena                        (isa_read || (write_del == 3'd4)),
		  .wea                        (write_del == 3'd4),
		  .addra                      (ram_a),
		  .dina                       (ram_write_data),
		  .douta                      (isa_dout),
		  
	     .clkb                       (clk),
		  .enb                        (pixel_read),
		  .web                        (1'b0),
		  .addrb                      (ram_a),		  
		  .doutb                      (pixel_data)	
	);

// RAM address pin mux
always @ (*)
begin
    if (isa_read) begin
        ram_a <= isa_addr;
    end else if ((write_del == 3'd3) || (write_del == 3'd4)) begin
        ram_a <= op_addr;
    end else begin
        ram_a <= pixel_addr;
    end
end

// For edge detection of ISA writes
always @ (posedge clk)
begin
    isa_write_old <= isa_write;
end

// Address is latched on initial edge of write
always @ (posedge clk)
begin
    if (isa_write && !isa_write_old) begin
        op_addr <= isa_addr;
    end
end

// Wait a few cycles before latching data from ISA
// bus, since the data isn't valid right away.
always @ (posedge clk)
begin
    if (isa_write && !isa_write_old) begin
        write_del <= 3'd1;
    end else if (write_del != 3'd0) begin
        if (write_del == 3'd7) begin
            write_del <= 3'd0;
        end else begin
            write_del <= write_del + 1;
        end
    end
end

always @ (posedge clk)
begin
    if (write_del == 3'd2) begin
        ram_write_data <= isa_din;
    end
//	 if (write_del == 3'd4) begin
//	     vram[ram_a] <= ram_write_data;
//	 end
end

// Pixel data output mux
/*
always @ (posedge clk)
begin
    if (isa_read || (write_del == 3'd3) || (write_del == 3'd4)) begin
        // The cause of CGA snow!
        pixel_data <= 8'hff;
    end else begin
        pixel_data <= vram[ram_a];		  
    end
end
*/

endmodule


module vram_t #(parameter AW=16)
(
  input clka,
  input ena,  
  input wea,
  input [AW-1:0] addra,
  input [7:0] dina,
  output reg [7:0] douta,
  input clkb,
  input enb,
  input web,
  input [AW-1:0] addrb,
  input [7:0] dinb,
  output reg [7:0] doutb
);

reg [7:0] vram[(2**AW)-1:0];

initial $readmemh("splash.hex", vram);

always @(posedge clka)
  if (ena)
		if (wea)
			vram[addra] <= dina;
		else
			douta <= vram[addra];
		
			
always @(posedge clkb)
  if (enb)
		if (web)
			vram[addrb] <= dinb;
		else
			doutb <= vram[addrb];

endmodule