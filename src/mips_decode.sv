/*
 *
 * Redistributions of any form whatsoever must retain and/or include the
 * following acknowledgment, notices and disclaimer:
 *
 * This product includes software developed by Carnegie Mellon University. 
 *
 * Copyright (c) 2004 by Babak Falsafi and James Hoe,
 * Computer Architecture Lab at Carnegie Mellon (CALCM), 
 * Carnegie Mellon University.
 *
 * This source file was written and maintained by Jared Smolens 
 * as part of the Two-Way In-Order Superscalar project for Carnegie Mellon's 
 * Introduction to Computer Architecture course, 18-447. The source file
 * is in part derived from code originally written by Herman Schmit and 
 * Diana Marculescu.
 *
 * You may not use the name "Carnegie Mellon University" or derivations 
 * thereof to endorse or promote products derived from this software.
 *
 * If you modify the software you must place a notice on or within any 
 * modified version provided or made available to any third party stating 
 * that you have modified the software.  The notice shall include at least 
 * your name, address, phone number, email address and the date and purpose 
 * of the modification.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY WARRANTY OF ANY KIND, EITHER 
 * EXPRESS, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANYWARRANTY 
 * THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS OR BE ERROR-FREE AND ANY 
 * IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
 * TITLE, OR NON-INFRINGEMENT.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY 
 * BE LIABLE FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, 
 * SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING OUT OF, RESULTING FROM, OR IN 
 * ANY WAY CONNECTED WITH THIS SOFTWARE (WHETHER OR NOT BASED UPON WARRANTY, 
 * CONTRACT, TORT OR OTHERWISE).
 *
 */

// Include the MIPS constants
`include "mips_defines.vh"
`include "jpu_defines.vh"

////
//// mips_decode: Decode MIPS instructions
////
//// op      (input)  - Instruction opcode
//// funct1  (input)  - Instruction minor opcode
//// funct2  (input)  - Instruction minor opcode
//// ctrl_RegDst (output) - Destination Reg - rd, rt, ra
//// ctrl_ALUSrc1 (output) - Source of 1nd ALU operand: Reg,Shift    
//// ctrl_ALUSrc2 (output) - Source of 2nd ALU operand: Reg, Imm 
//// ctrl_RegSrc (output) - Source of Reg Write, 0:ALU, 1: Mem
//// ctrl_Link (output)   -  If 1, then write PC+4 to reg
//// ctrl_RegWrite (output) - reg write enable
//// ctrl_MemRead (output) -Read from Mem
//// ctrl_MemWrite (output) Write to Mem
//// ctrl_MemSize (output) Size of mem operation (B,H,W)
//// ctrl_Jump (output)
//// ctrl_Branch (output)
//// ctrl_BranchCond (output) Branch Condition (bit 2:gt, bit 1:lt, bit 0:eq) [conditions are or-ed together]
//// alu_op (output) ALU Opcode
//// alu_alt (output) ALU alt function
//// ctrl_SysException (output)
//// ctrl_InstException (output)
////
module mips_decode(/*AUTOARG*/
   // Outputs
   ctrl_RegDst, ctrl_ALUSrc1, ctrl_ALUSrc2, ctrl_RegSrc, ctrl_Link,
   ctrl_RegWrite, ctrl_MemRead, ctrl_MemWrite, ctrl_MemSize,
   ctrl_MemSE, ctrl_Jump, ctrl_Branch, ctrl_BranchCond, alu_op,
   alu_alt, ctrl_SysException, ctrl_InstException,
   // Inputs
   dcd_op, dcd_funct2, dcd_rt
   );

   input [5:0] 	     dcd_op, dcd_funct2;
   input       [4:0] dcd_rt;
   output reg [1:0]  ctrl_RegDst; // Destination Reg - rd, rt, ra
   output reg 	     ctrl_ALUSrc1;
   output reg [1:0]  ctrl_ALUSrc2; // Source of ALU operands: 0:Reg, 1:Imm/shamt
   output reg 	     ctrl_RegSrc; // Source of Reg Write, 0:ALU, 1: Mem
   output reg 	     ctrl_Link; // If 1, then write PC+4 to reg
   output reg 	     ctrl_RegWrite; // reg write enable
   output reg 	     ctrl_MemRead; //Read from Mem
   output reg 	     ctrl_MemWrite; //Write to Mem
   output reg [1:0]  ctrl_MemSize; //Size of mem operation (B,H,W)
   output reg 	     ctrl_MemSE;
   output reg 	     ctrl_Jump;
   output reg 	     ctrl_Branch;
   output reg [2:0]  ctrl_BranchCond; //Branch Condition (bit 2:gt, bit 1:lt, bit 0:eq) [conditions are or-ed together]
   output reg [3:0]  alu_op; // ALU Opcode (alt)
   output reg 	     alu_alt; // ALU alt function
   output reg 	     ctrl_SysException, ctrl_InstException;

   always @(*) begin
      ctrl_SysException = 1'b0; 	// system exception
      ctrl_InstException = 1'b0; 	// reserved instruction execption

      ctrl_MemRead = ({dcd_op[5],dcd_op[3]}  == 2'b10) ? 1'b1 : 1'b0;
      ctrl_MemWrite = ({dcd_op[5],dcd_op[3]}  == 2'b11) ? 1'b1 : 1'b0;
      ctrl_MemSize = dcd_op[1:0];
      ctrl_MemSE = !dcd_op[2];

      alu_op = `ALU_NOP;
      
      case(dcd_op)
	6'b000000:
	  begin
	     ctrl_RegDst = `CTRL_REGDST_RD;
	     ctrl_ALUSrc1 = (dcd_funct2[5:2] == 4'b0000) ? `ALU_SRC1_SHAMT : `ALU_SRC1_REG;
	     ctrl_ALUSrc2 = `ALU_SRC2_REG;
	     ctrl_RegSrc = `CTRL_REGSRC_ALU;
	     ctrl_Link = (dcd_funct2 == 6'b001001) ? 1'b1 : 1'b0;
	     ctrl_Branch = 1'b0;
	     ctrl_BranchCond = 3'b000;
	     ctrl_Jump = (dcd_funct2[5:1] == 5'b00100) ? 1'b1 : 1'b0;
	     ctrl_RegWrite = (dcd_funct2 == 5'b001X0) ? 1'b0 : 1'b1;
	     alu_alt = dcd_funct2[0];

            casez(dcd_funct2)
	      6'b000?00: alu_op = `ALU_SHIFT_LEFT;
	      6'b000?1?: alu_op = `ALU_SHIFT_RIGHT;
	      6'b001100: ctrl_SysException = 1'b1;
	      6'b10000?: alu_op = `ALU_ADD;
	      6'b10001?: alu_op = `ALU_SUB;
	      6'b100100: alu_op = `ALU_AND;
	      6'b100101: alu_op = `ALU_OR;
	      6'b100110: alu_op = `ALU_XOR;
	      6'b100111: alu_op = `ALU_NOR;
	      6'b10101?: alu_op = `ALU_SLT;
	      default: alu_op = `ALU_NOP;
	    endcase // casez (dcd_funct)
	  end // case: 6'b000000
	6'b000001:
	  begin
	     ctrl_ALUSrc1 = `ALU_SRC1_REG;
	     ctrl_ALUSrc2 = `ALU_SRC2_REG;
	     ctrl_RegSrc = `CTRL_REGSRC_ALU;
	     ctrl_Link = dcd_rt[4];
//	     ctrl_RegDst = (ctrl_Link == 1'b1) ? `CTRL_REGDST_RA : `CTRL_REGDST_RT;
	     ctrl_RegDst = (dcd_rt[4] == 1'b1) ? `CTRL_REGDST_RA : `CTRL_REGDST_RT;
	     ctrl_Branch = 1'b1;
	     ctrl_BranchCond = 3'b010 ^ {3{dcd_rt[0]}};
	     ctrl_Jump = 1'b0;
	     alu_op = `ALU_NOP;
	     alu_alt = 1'b0;
	     ctrl_RegWrite = dcd_funct2[4];
	  end // case: 6'b000001
	default:
	  begin
	     ctrl_Link = (dcd_op == 6'b000011) ? 1'b1 : 1'b0;
	     ctrl_RegDst = (dcd_op == 6'b000011) ? `CTRL_REGDST_RA : `CTRL_REGDST_RT;
//	     ctrl_RegDst = (ctrl_Link == 1'b1) ? `CTRL_REGDST_RA : `CTRL_REGDST_RT;
	     ctrl_ALUSrc1 = `ALU_SRC1_REG;
	     ctrl_ALUSrc2 = (dcd_op[5:2] == 4'b0001) ? `ALU_SRC2_REG :
			    (dcd_op[5:2] == 4'b0011) ? `ALU_SRC2_IMM :
			    `ALU_SRC2_IMM_SE;
	     ctrl_RegSrc = (dcd_op[5] == 1'b1) ? `CTRL_REGSRC_MEM : `CTRL_REGSRC_ALU;
	     ctrl_Branch = (dcd_op[5:2] == 4'b0001) ? 1'b1 : 1'b0;
	     ctrl_BranchCond = {!dcd_op[0], dcd_op[1] ^ dcd_op[0], dcd_op[0]};
	     ctrl_Jump = (dcd_op[5:1] == 5'b00001) ? 1'b1 : 1'b0;
	     alu_alt = dcd_op[0] & !dcd_op[5];
	     ctrl_RegWrite = (dcd_op == 6'b000011) ? 1'b1 : dcd_op[5]^dcd_op[3];

            casez(dcd_op)
	      6'b1?????: alu_op = `ALU_ADD;
	      6'b00100?: alu_op = `ALU_ADD;
	      6'b00010?: alu_op = `ALU_SUB;
	      6'b001100: alu_op = `ALU_AND;
	      6'b001101: alu_op = `ALU_OR;
	      6'b001110: alu_op = `ALU_XOR;
	      6'b00101?: alu_op = `ALU_SLT;
	      6'b001111: alu_op = `ALU_LUI;
	      default: alu_op = `ALU_NOP;
	    endcase // casez (dcd_op)
	  end // case: default
      endcase // case (dcd_op)

//      ctrl_RegWrite = (alu_op == `ALU_NOP) ? 0 :
//		      ctrl_Link | !(ctrl_Jump | ctrl_Branch | ctrl_MemWrite);

   end // always @ (*)
   
endmodule
