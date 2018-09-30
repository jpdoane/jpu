module mem_write_align(/*AUTOARG*/
   // Outputs
   data_align, mask, align_except,
   // Inputs
   data, addr_lsb, size, en
   );

   input [31:0] data;
   input [1:0] 	addr_lsb;
   input memsize_s size;
   input       en;   
   output reg [31:0] data_align;
   output reg [3:0]  mask;
   output reg align_except;

   always @(*) begin
      mask = 4'h0;
      data_align = 32'h0;
      align_except = 1'b0;
      if(en) begin
	 case(size)
	   BYTE: //BYTE (these come from the lest sig bits of mips opcode)
	     case(addr_lsb)
	       2'b00:
		 begin
		    mask = 4'b0001;
		    data_align = data;
		 end
	       2'b01:
		 begin
		    mask = 4'b0010;
		    data_align = data << 8;
		 end
	       2'b10:
		 begin
		    mask = 4'b0100;
		    data_align = data << 16;
		 end
	       2'b11:
		 begin
		    mask = 4'b1000;
		    data_align = data << 24;
		 end
	     endcase // case (addr[1:0])	
	   HALF: //HALFWORD
	     case(addr_lsb)
	       2'b00:
		 begin
		    mask = 4'b0011;
		    data_align = data;
		 end
	       2'b10:
		 begin
		    mask = 4'b1100;
		    data_align = data << 16;
		 end
	       default:
		 align_except = 1'b1;
	     endcase // case (addr[1:0])
	   WORD: //WORD	  
	     case(addr_lsb)
	       2'b00:
		 begin
		    mask = 4'b1111;
		    data_align = data;
		 end
	       default:
		 align_except = 1'b1;
	     endcase // case (addr[1:0])
	   default:
	     align_except = 1'b0;
	 endcase // case (size)
      end // if (en)      
   end   
endmodule // mem_align


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:
