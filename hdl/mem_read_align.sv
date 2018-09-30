module mem_read_align(/*AUTOARG*/
   // Outputs
   data, data_se, align_except,
   // Inputs
   data_align, addr_lsb, size, en
   );

   input [31:0] data_align;
   input [1:0] 	addr_lsb;
   input memsize_s size;
   input       en;
   
   output reg [31:0] data;
   output reg [31:0] data_se;
   output reg align_except;

   always @(*) begin
      data = 32'h0;
      data_se = 32'h0;
      align_except = 1'b0;
      if (en) begin
	 case(size)
	   BYTE: //BYTE (these come from the lest sig bits of mips opcode)
	     begin
		case(addr_lsb)
		  2'b00: data = {24'h0, data_align[7:0]};
		  2'b01: data = {24'h0, data_align[15:8]};
		  2'b10: data = {24'h0, data_align[23:16]};
		  2'b11: data = {24'h0, data_align[31:24]};
		endcase // case (addr[1:0])
		data_se[7:0] = data[7:0];
		data_se[31:8] = {24{data[7]}};
	     end
	   HALF: //HALFWORD
	     begin
		case(addr_lsb)
		  2'b00: data = {16'h0, data_align[15:0]};
		  2'b10: data = {16'h0, data_align[31:16]};
		  default:
		    align_except = 1'b1;
		endcase // case (addr[1:0])
		data_se[15:0] = data[15:0];
		data_se[31:16] = {16{data[15]}};
	     end
	   WORD: //WORD
	     begin
		case(addr_lsb)
		  2'b00: data = data_align;
		  default:
		    align_except = 1'b1;
		endcase // case (addr[1:0])
		data_se = data;
	     end
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
