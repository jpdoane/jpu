`include "risc-v.svh"
`include "jpu.svh"

import jpu::*;
  
module tb_decode;
           
   logic [31:0]      inst;
   jpu::dcd_s dcd;
   
   decode decoder(/*AUTOINST*/
		  // Outputs
		  .dcd			(dcd),
		  // Inputs
		  .inst			(inst[31:0]));

   initial
     begin


/*
00000000 <link-0x8>:
   0:   00008133                add     x2,x1,x0
   4:   0de08113                addi    x2,x1,222
00000008 <link>:
   8:   f8209e23                sh      x2,-100(x1)
   c:   ffdff0ef                jal     x1,8 <link>
  10:   00209463                bne     x1,x2,18 <link+0x10>
  14:   fedff06f                j       0 <link-0x8>
  18:   0beef0b7                lui     x1,0xbeef
*/

	
	// R-format
	inst = 32'h00008133;  //add     x2,x1,x0
	#1;
	assert(dcd.rd == 5'h2);
	assert(dcd.rs1 == 5'h1);
	assert(dcd.rs2 == 5'h0);
	assert(dcd.alu_op == `ALU_ADD);
	assert(dcd.f3 == `F3_ADD);
	assert(dcd.alu_pc == 1'b0);
	assert(dcd.alu_imm == 1'b0);
	assert(dcd.j == 1'b0);
	assert(dcd.br == 1'b0);
	assert(dcd.ld == 1'b0);
	assert(dcd.st == 1'b0);

	// I-format
	inst = 32'h0de08113;  //addi x2, x1, 0xde
	#1;
	assert(dcd.rd == 5'h2);
	assert(dcd.rs1 == 5'h1);
	assert(dcd.imm == 32'hde);
	assert(dcd.alu_op == `ALU_ADD);
	assert(dcd.f3 == `F3_ADD);
	assert(dcd.alu_pc == 1'b0);
	assert(dcd.alu_imm == 1'b0);
	assert(dcd.j == 1'b0);
	assert(dcd.br == 1'b0);
	assert(dcd.ld == 1'b0);
	assert(dcd.st == 1'b0);
	
	// S-format
	inst = 32'hf8209e23;     // sh      x2,-100(x1)
	#1;
	assert(dcd.rs2 == 5'h2);
	assert(dcd.rs1 == 5'h1);
	assert(dcd.imm == -32'd100);
	assert(dcd.alu_op == `ALU_ADD);
	assert(dcd.f3 == `F3_LSH);
	assert(dcd.alu_pc == 1'b0);
	assert(dcd.alu_imm == 1'b1);
	assert(dcd.j == 1'b0);
	assert(dcd.br == 1'b0);
	assert(dcd.ld == 1'b0);
	assert(dcd.st == 1'b1);

        $display("Test Complete");
     end

endmodule // tb_decode

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("..")
// End:
