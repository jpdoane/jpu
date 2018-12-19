`include "risc-v.svh"
`include "jpu.svh"


// Purely combinatorial
module decode(/*AUTOARG*/
   // Outputs
   dcd,
   // Inputs
   inst
   );

   input logic [31:0]      inst;
   output 		   jpu::dcd_s dcd;
   		
   //instruction fields
   logic [4:0] 		   opcode;
   logic [6:0] 		   funct7;

   //// Instruction Types
   typedef enum 	   logic[2:0]  {RV_RTYPE, RV_ITYPE, RV_STYPE, RV_BTYPE, RV_UTYPE, RV_JTYPE} rv_insttype_s;
   rv_insttype_s insttype;
     
   // inst[1:0] = 2b'11 for valid RISC-V
   assign opcode = inst[6:2];
   assign dcd.rd = inst[11:7];
   assign dcd.f3 = inst[14:12];
   assign dcd.rs1 = inst[19:15];
   assign dcd.rs2 = inst[24:20];
   assign funct7 = inst[31:25];

   //
   // construct immediate field based on instruction type
   //
   assign dcd.imm[0] = (insttype == RV_ITYPE) ? inst[20] :
		   (insttype == RV_STYPE) ? inst[7] :
		   1'b0;

   assign dcd.imm[4:1] = (insttype == RV_ITYPE || insttype == RV_JTYPE) ? inst[24:21] :
		     (insttype == RV_STYPE || insttype == RV_BTYPE) ? inst[24:21] :
		     4'b0;

   assign dcd.imm[10:5] = (insttype == RV_UTYPE) ? 6'b0 :
		      inst[30:25];
   
   assign dcd.imm[11] = (insttype == RV_UTYPE) ? 1'b0 :
 		    (insttype == RV_BTYPE) ? inst[7] :
 		    (insttype == RV_JTYPE) ? inst[20] :
		    inst[31];

   assign dcd.imm[19:12] = (insttype == RV_UTYPE || insttype == RV_JTYPE) ? inst[19:12] :
		       {8{inst[31]}};

   assign dcd.imm[30:20] = (insttype == RV_UTYPE) ? inst[30:20] :
		       {11{inst[31]}};
   
   assign dcd.imm[31] = inst[31];


   // decode based on opcodes
   always @(*) begin
      dcd.j <= 1'b0;
      dcd.br <= 1'b0;
      dcd.ld <= 1'b0;
      dcd.st <= 1'b0;
      dcd.alu_we <= 1'b0;
      dcd.alu_imm <= 1'b0;
      dcd.alu_pc <= 1'b0;
      case(opcode)
	`RV_LUI:
	  begin
	     insttype <= RV_UTYPE;
	     dcd.alu_op <= `ALU_LUI;
	     dcd.alu_imm <= 1'b1;
	     dcd.alu_we <= 1'b1;
	  end
	`RV_AUIPC:
	  begin
	     insttype <= RV_UTYPE;
	     dcd.alu_op <= `ALU_ADD;
	     dcd.alu_pc <= 1'b1;
	     dcd.alu_imm <= 1'b1;
	     dcd.alu_we <= 1'b1;
	  end
	`RV_JAL:
	  begin
	     insttype <= RV_JTYPE;
	     dcd.alu_op <= `ALU_ADD;
	     dcd.alu_pc <= 1'b1;
	     dcd.alu_imm <= 1'b1;
	     dcd.j <= 1'b1;
	  end
	`RV_JALR:
	  begin
	     insttype <= RV_ITYPE;
	     dcd.alu_op <= `ALU_ADD;
	     dcd.alu_imm <= 1'b1;
	     dcd.j <= 1'b1;
	  end
	`RV_BRANCH:
	  begin
	     insttype <= RV_BTYPE;
	     dcd.alu_op <= `ALU_ADD;
	     dcd.alu_pc <= 1'b1;
	     dcd.alu_imm <= 1'b1;
	     dcd.br <= 1'b1;
	  end
	`RV_LOAD:
	  begin
	     insttype <= RV_ITYPE;
	     dcd.alu_op <= `ALU_ADD;
	     dcd.alu_imm <= 1'b1;
	     dcd.ld <= 1'b1;
	  end
	`RV_STORE:
	  begin
	     insttype <= RV_STYPE;
	     dcd.alu_op <= `ALU_ADD;
	     dcd.alu_imm <= 1'b1;
	     dcd.st <= 1'b1;
	  end
	`RV_OP_IMM:
	  begin
	     insttype <= RV_ITYPE;
	     dcd.alu_op <= {funct7[5], dcd.f3};
	     dcd.alu_imm <= 1'b1;
	     dcd.alu_we <= 1'b1;
	  end
	`RV_OP:
	  begin
	     insttype <= RV_RTYPE;
	     dcd.alu_op <= {funct7[5], dcd.f3};
	     dcd.alu_we <= 1'b1;
	  end	
      endcase // case (opcode)
   end // always @ (*)

endmodule // decode

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
