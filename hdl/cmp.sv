//`include "risc-v.svh"

module cmp(/*AUTOARG*/
   // Outputs
   cmp_result,
   // Inputs
   cmp_r1, cmp_r2, cmp_op
   );

   input logic [31:0]      cmp_r1, cmp_r2;
   input logic [2:0]	   cmp_op;
   output logic 	   cmp_result;

   logic 		   eq,lt,ltu,result;
   
   assign eq = (cmp_r1 == cmp_r2);
   assign lt = ($signed(cmp_r1) < $signed(cmp_r2));
   assign ltu = (cmp_r1 < cmp_r2);

   //from risc-v.svh
   // `define F3_BEQ      3'b000
   // `define F3_BNE      3'b001
   // `define F3_BLT      3'b100
   // `define F3_BGE      3'b101
   // `define F3_BLTU     3'b110
   // `define F3_BGEU     3'b111

   //top two bits define eq, lt, ltu...
   assign result = (cmp_op[2:1] == 2'b00) ? eq : // F3_BEQ[2:1]
		   (cmp_op[2:1] == 2'b10) ? lt : // F3_BLT[2:1]
		   (cmp_op[2:1] == 2'b11) ? ltu : // F3_BLTU[2:1]
		   1'b0; //undefined...

		   
   assign cmp_result = cmp_op[0] ^ result; //lsb negates the meaning
                                           // i.e. eq->ne, lt->ge, ltu->geu
   
endmodule

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
