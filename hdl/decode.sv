`include "mips_defines.vh"
`include "jpu.svh"

import jpu::*;

module decode(/*AUTOARG*/
   // Outputs
   ctrl, dcd,
   // Inputs
   inst, en
   );

   input [31:0]      inst;
   input 	     en;
//   input usermode_s  user_mode;
   output 	     ctrl_s ctrl;
   output 	     dcd_s dcd;

   //internal decode signals
   logic [5:0] 	     opcode, funct; 
   logic [15:0]      imm;   
   assign opcode = inst[31:26];
   assign funct = inst[5:0];
   assign imm = inst[15:0];

   //decode signals for core   
   assign dcd.op = opcode;
   assign dcd.rs = inst[25:21];   
   assign dcd.rt = inst[20:16];   
   assign dcd.rd = inst[15:11];   
   assign dcd.rt = inst[20:16];   
   assign dcd.shamt = inst[10:6];
   assign dcd.target = inst[25:0];
   assign dcd.imm_ze = { 16'h0, imm }; //zero extended immediate
   assign dcd.imm_se = { {16{imm[15]}}, imm }; //sign extended immediate
   assign dcd.br_offset =  { {14{imm[15]}}, imm, 2'b0}; //se offset for branch
   
   always @(*) begin
      //defaults...
      ctrl.sys_except <= 1'b0;
      ctrl.inst_except <= 1'b0;
      ctrl.alu_src1 <= REG1;
      ctrl.alu_src2 <= REG2;
      ctrl.reg_src <= ALU;
      ctrl.reg_dst <= RD;
      ctrl.reg_write <= 1'b0;
      ctrl.j <= 1'b0;
      ctrl.br <= 1'b0;
      ctrl.br_cond = '0;
//      ctrl.link <= 1'b0;
      ctrl.mem_read <= 1'b0;
      ctrl.mem_write <= 1'b0;
      ctrl.mem_size <= WORD;
//      ctrl.mem_se <= 1'b0;
      ctrl.alu_op <= NOP;
      ctrl.cp0_op <= CP0NOP;
           
      // ctrl.mem_read <= ({dcd_op[5],dcd_op[3]}  == 2'b10) ? 1'b1 : 1'b0;
      // ctrl.mem_write <= ({dcd_op[5],dcd_op[3]}  == 2'b11) ? 1'b1 : 1'b0;
      // ctrl.mem_size <= dcd_op[1:0];
      // ctrl.mem_se <= !dcd_op[2];
      if(en) begin
	 case(opcode)
	   `OP_OTHER0:
	     begin
		ctrl.alu_src2 <= REG2;
		ctrl.reg_src <= (funct == `OP0_JALR) ? LINK : ALU;
		ctrl.reg_dst <= RD;
		ctrl.br <= 1'b0;
		ctrl.br_cond = '0;
		ctrl.sys_except <= (funct == `OP0_SYSCALL) ? 1'b1 : 1'b0;

		if (funct == `OP0_SLL || funct == `OP0_SRL || funct == `OP0_SRA)
		  ctrl.alu_src1 <= SHAMT;
		else
		  ctrl.alu_src1 <= REG1;

		if (funct == `OP0_JR || funct == `OP0_JALR)
		  ctrl.j <= 1'b1;

		if (funct == `OP0_JR || funct == `OP0_SYSCALL)
		  ctrl.reg_write <= 1'b0;
		else
		  ctrl.reg_write <= 1'b1;

		case(funct)
		  `OP0_SLL, `OP0_SLLV: ctrl.alu_op <= SLL;
		  `OP0_SRA, `OP0_SRAV: ctrl.alu_op <= SRA;
		  `OP0_SRL, `OP0_SRLV: ctrl.alu_op <= SRL;
		  `OP0_ADD: ctrl.alu_op <= ADD;
		  `OP0_ADDU: ctrl.alu_op <= ADDU;
		  `OP0_SUB: ctrl.alu_op <= SUB;
		  `OP0_SUBU: ctrl.alu_op <= SUBU;
		  `OP0_AND: ctrl.alu_op <= AND;
		  `OP0_OR: ctrl.alu_op <= OR;
		  `OP0_XOR: ctrl.alu_op <= XOR;
		  `OP0_NOR: ctrl.alu_op <= NOR;
		  `OP0_SLT: ctrl.alu_op <= SLT;
		  `OP0_SLTU: ctrl.alu_op <= SLTU;
		  `OP0_JR, `OP0_JALR, `OP0_SYSCALL: ctrl.alu_op <= NOP;
		  default: begin
		     //unsupported instruction
		     ctrl.alu_op <= NOP;
		     ctrl.inst_except <= 1'b1; 
		  end
		endcase
	     end // case: 6'b000000

	   `OP_OTHER1:
	     begin
		ctrl.j <= 1'b0;
		ctrl.br <= 1'b1;
		ctrl.reg_src <= LINK;
		ctrl.reg_dst <= RA;

		case(dcd.rt)
		  `OP1_BLTZAL,`OP1_BLTZALL:
		    begin
		       ctrl.reg_write <= 1'b1;
		       ctrl.br_cond <= `COND_LTZ;
		    end	     
		  `OP1_BGEZAL, `OP1_BGEZALL:
		    begin
		       ctrl.reg_write <= 1'b1;
		       ctrl.br_cond <= `COND_GTZ | `COND_EQZ;
		    end	     
		  `OP1_BLTZ,`OP1_BLTZL:
		    begin
		       ctrl.reg_write <= 1'b0;
		       ctrl.br_cond <= `COND_LTZ;
		    end
		  `OP1_BGEZ, `OP1_BGEZL:
		    begin
		       ctrl.reg_write <= 1'b0;
		       ctrl.br_cond <= `COND_GTZ | `COND_EQZ;
		    end
		  default: //unsupported instruction
		    begin
		       ctrl.reg_write <= 1'b0;
		       ctrl.inst_except <= 1'b1;		    
		    end
		endcase; // case (rt)
	     end // case: 6'b000001
	   `OP_Z0: //coproc 0
	     begin
		case(dcd.rs)
		  `OPZ_MFCZ:
		    begin
		       ctrl.cp0_op <= MFC0;
		       ctrl.reg_src <= CP0;
		       ctrl.reg_write <= 1'b1;
		       ctrl.reg_dst <= RT;
		    end
		  `OPZ_MTCZ:
		    ctrl.cp0_op <= MTC0;
		  `OPZ_COPZS:
		    if(funct==`OPC_ERET)
		      ctrl.cp0_op <= ERET;
		    else
		      ctrl.inst_except <= 1'b1;
		  default:
		    //unsupported instruction
		    ctrl.inst_except <= 1'b1; 
		endcase; // case (dcd.rs)
	     end // case: `OP_Z0
	   `OP_J:
	     ctrl.j <= 1'b1;
	   `OP_JAL:
	     begin
		ctrl.j <= 1'b1;
		ctrl.reg_write <= 1'b1;
		ctrl.reg_dst <= RA;
		ctrl.reg_src <= LINK;
	     end
	   `OP_BEQ, `OP_BNE:
	     begin
		ctrl.br <= 1'b1;
		ctrl.br_cond <= (opcode == `OP_BEQ)? `COND_EQZ: 
				`COND_LTZ | `COND_GTZ;
		ctrl.alu_src1 <= REG1;
		ctrl.alu_src2 <= REG2;
		ctrl.alu_op <= SUB;
	     end
	   `OP_BLEZ, `OP_BGTZ:
	     begin
		ctrl.alu_op <= NOP;
		ctrl.br <= 1'b1;
		ctrl.br_cond <= (opcode == `OP_BLEZ) ? `COND_LTZ | `COND_EQZ:
				`COND_GTZ;
	     end
	   `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU:
	     begin
		ctrl.alu_src1 <= REG1;
		ctrl.alu_src2 <= IMM_SE;
		ctrl.reg_write <= 1'b1;
		ctrl.reg_src <= ALU;
		ctrl.reg_dst <= RT;
		ctrl.alu_op <= (opcode == `OP_ADDI) ? ADD:
			       (opcode == `OP_ADDIU) ? ADDU:
			       (opcode == `OP_SLTI) ? SLT:
			       SLTU;
	     end
	   `OP_ANDI, `OP_ORI, `OP_XORI:
	     begin
		ctrl.alu_src1 <= REG1;
		ctrl.alu_src2 <= IMM;
		ctrl.reg_write <= 1'b1;
		ctrl.reg_src <= ALU;
		ctrl.reg_dst <= RT;
		ctrl.alu_op <= (opcode == `OP_ANDI) ? AND:
			       (opcode == `OP_ORI) ? OR:
			       XOR;
	     end
	   `OP_LUI:
	     begin
		ctrl.alu_src2 <= IMM;
		ctrl.reg_write <= 1'b1;
		ctrl.reg_src <= ALU;
		ctrl.reg_dst <= RT;
		ctrl.alu_op <= LUI;
	     end
	   `OP_LB,`OP_LH, `OP_LW, `OP_LBU, `OP_LHU:
	     begin
		ctrl.alu_src1 <= REG1;
		ctrl.alu_src2 <= IMM_SE;
		ctrl.reg_write <= 1'b1;
		ctrl.reg_dst <= RT;
		ctrl.alu_op <= ADD;
		ctrl.mem_read <= 1'b1;
		ctrl.reg_src <= (opcode == `OP_LBU || opcode == `OP_LHU) ? MEM : MEM_SE;
		ctrl.mem_size <= (opcode == `OP_LB || opcode == `OP_LBU) ? BYTE :
				 (opcode == `OP_LH || opcode == `OP_LHU) ? HALF :
				 WORD;
	     end
	   `OP_SB,`OP_SH, `OP_SW:
	     begin
		ctrl.alu_src1 <= REG1;
		ctrl.alu_src2 <= IMM_SE;
		ctrl.alu_op <= ADD;
		ctrl.mem_write <= 1'b1;
		ctrl.mem_size = (opcode == `OP_SB)? BYTE :
				(opcode == `OP_SH)? HALF :
				WORD;
	     end
	   default:
	     begin
		// opcode not implemented
		ctrl.inst_except <= 1'b1;
	     end
	 endcase // case (opcode)
      end // if (en)
   end // always @ endmodule
endmodule

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
