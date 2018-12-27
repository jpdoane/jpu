`include "risc-v.svh"

// Purely combinatorial
module decode(decode_if dif);
   		
   //instruction fields
   logic [4:0] opcode;
   logic [6:0] funct7;

   //// Instruction Types
   enum        logic[2:0]  {RTYPE, ITYPE, STYPE, BTYPE, UTYPE, JTYPE} insttype;
     
   // inst[1:0] = 2b'11 for valid RISC-V
   assign opcode = dif.inst[6:2];
   assign dif.rd = dif.inst[11:7];
   assign dif.f3 = dif.inst[14:12];
   assign dif.rs1 = dif.inst[19:15];
   assign dif.rs2 = dif.inst[24:20];
   assign funct7 = dif.inst[31:25];

   //
   // construct immediate field based on instruction type
   //
   assign dif.imm[0] = (insttype == ITYPE) ? dif.inst[20] :
		   (insttype == STYPE) ? dif.inst[7] :
		   1'b0;

   assign dif.imm[4:1] = (insttype == ITYPE || insttype == JTYPE) ? dif.inst[24:21] :
		     (insttype == STYPE || insttype == BTYPE) ? dif.inst[11:8] :
		     4'b0;

   assign dif.imm[10:5] = (insttype == UTYPE) ? 6'b0 :
		      dif.inst[30:25];
   
   assign dif.imm[11] = (insttype == UTYPE) ? 1'b0 :
 		    (insttype == BTYPE) ? dif.inst[7] :
 		    (insttype == JTYPE) ? dif.inst[20] :
		    dif.inst[31];

   assign dif.imm[19:12] = (insttype == UTYPE || insttype == JTYPE) ? dif.inst[19:12] :
		       {8{dif.inst[31]}};

   assign dif.imm[30:20] = (insttype == UTYPE) ? dif.inst[30:20] :
		       {11{dif.inst[31]}};
   
   assign dif.imm[31] = dif.inst[31];


   // decode based on opcodes
   always @(*) begin
      dif.j <= 1'b0;
      dif.br <= 1'b0;
      dif.ld <= 1'b0;
      dif.st <= 1'b0;
      dif.alu_we <= 1'b0;
      dif.alu_imm <= 1'b0;
      dif.alu_pc <= 1'b0;
      case(opcode)
	`RV_LUI:
	  begin
	     insttype <= UTYPE;
	     dif.alu_op <= `ALU_LUI;
	     dif.alu_imm <= 1'b1;
	     dif.alu_we <= 1'b1;
	  end
	`RV_AUIPC:
	  begin
	     insttype <= UTYPE;
	     dif.alu_op <= `ALU_ADD;
	     dif.alu_pc <= 1'b1;
	     dif.alu_imm <= 1'b1;
	     dif.alu_we <= 1'b1;
	  end
	`RV_JAL:
	  begin
	     insttype <= JTYPE;
	     dif.alu_op <= `ALU_ADD;
	     dif.alu_pc <= 1'b1;
	     dif.alu_imm <= 1'b1;
	     dif.j <= 1'b1;
	  end
	`RV_JALR:
	  begin
	     insttype <= ITYPE;
	     dif.alu_op <= `ALU_ADD;
	     dif.alu_imm <= 1'b1;
	     dif.j <= 1'b1;
	  end
	`RV_BRANCH:
	  begin
	     insttype <= BTYPE;
	     dif.alu_op <= `ALU_ADD;
	     dif.alu_pc <= 1'b1;
	     dif.alu_imm <= 1'b1;
	     dif.br <= 1'b1;
	  end
	`RV_LOAD:
	  begin
	     insttype <= ITYPE;
	     dif.alu_op <= `ALU_ADD;
	     dif.alu_imm <= 1'b1;
	     dif.ld <= 1'b1;
	  end
	`RV_STORE:
	  begin
	     insttype <= STYPE;
	     dif.alu_op <= `ALU_ADD;
	     dif.alu_imm <= 1'b1;
	     dif.st <= 1'b1;
	  end
	`RV_OP_IMM:
	  begin
	     insttype <= ITYPE;
	     dif.alu_op <= {funct7[5], dif.f3};
	     dif.alu_imm <= 1'b1;
	     dif.alu_we <= 1'b1;
	  end
	`RV_OP:
	  begin
	     insttype <= RTYPE;
	     dif.alu_op <= {funct7[5], dif.f3};
	     dif.alu_we <= 1'b1;
	  end	
      endcase // case (opcode)
   end // always @ (*)

endmodule // decode

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
