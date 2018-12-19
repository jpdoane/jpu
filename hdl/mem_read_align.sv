module mem_read_align(/*AUTOARG*/
   // Outputs
   data, align_except,
   // Inputs
   data_align, addr_lsb, format
   );

   input logic [31:0] data_align;
   input logic [1:0] 	addr_lsb;
   input [2:0] format; //per risc-v funct3 def for store opcodes
   
   output logic [31:0] data;
   output logic align_except;

   logic 	se_bit;

// memory format given by funct3 code:
// `define F3_LSB      3'b000
// `define F3_LSH      3'b001
// `define F3_LSW      3'b010
// `define F3_LBU      3'b100 //LOAD only
// `define F3_LHU      3'b101 //LOAD only
  
   always @(*) begin
      data = 32'h0;
      align_except = 1'b0;
      se_bit = 1'b0;
      case(format[1:0]) // lowest two bits define size, msb defines signed/unsigned
	2'b00: //`F3_LSB[1:0]: //BYTE
	  begin
	     se_bit = ~format[2] && data[7]; //if format[2] then unsigned
	     case(addr_lsb)
	       2'b00: data = {{24{se_bit}}, data_align[7:0]};
	       2'b01: data = {{24{se_bit}}, data_align[15:8]};
	       2'b10: data = {{24{se_bit}}, data_align[23:16]};
	       2'b11: data = {{24{se_bit}}, data_align[31:24]};
	     endcase // case (addr[1:0])
	  end
	2'b01: //`F3_LSH[1:0]: //HALFWORD
	  begin
	     se_bit = ~format[2] && data[15]; //if format[2] then unsigned
	     case(addr_lsb)
	       2'b00: data = {{16{se_bit}}, data_align[15:0]};
	       2'b10: data = {{16{se_bit}}, data_align[31:16]};
	       default:
		 align_except = 1'b1;
	     endcase // case (addr[1:0])
	  end
	2'b10: //`F3_LSW[1:0]: //WORD
	  begin
	     case(addr_lsb)
	       2'b00: data = data_align;
	       default:
		 align_except = 1'b1;
	     endcase // case (addr[1:0])
	  end
	default:
	  align_except = 1'b1;
      endcase // case (size)
   end   
endmodule // mem_align


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:
