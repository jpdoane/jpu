//data types for wishbone bus signals
`ifndef JPU_SVH
`define JPU_SVH

package jpu;

   typedef enum logic {REG1, SHAMT} alusrc1_s;
   typedef enum logic [1:0] {REG2, IMM, IMM_SE} alusrc2_s;
   typedef enum logic [1:0] {BYTE, HALF, WORD} memsize_s;
   typedef enum logic [1:0] {MFC0, MTC0, ERET, CP0NOP} cp0op_s;
   typedef enum logic [3:0] { SYSCALL, SLL, SRL, SRA, ADD,SUB,
			      ADDU, SUBU, AND, OR, XOR, NOR,
			      SLT, SLTU, LUI, NOP} aluop_s;
   typedef enum logic [2:0] {MEM, MEM_SE, ALU, LINK, CP0} regsrc_s;
   typedef enum logic [1:0] {RD, RT, RA} regdst_s;
   
   typedef struct packed {      
      logic       reg_write;	// reg write enable
      regsrc_s    reg_src;	// Source for reg write 
      regdst_s    reg_dst;	// Destination for reg write
      alusrc1_s   alu_src1;	//alu 1 source: reg or shamt
      alusrc2_s   alu_src2;	// alu 2 src: reg, imm, imm_se
      aluop_s     alu_op;	// ALU Opcode (alt)
      logic       mem_read;	//Read from Mem
      logic       mem_write;	//Write to Mem
      memsize_s   mem_size;	//Size of mem operation (B,H,W)
      logic       j;		//jump
      logic       br;		//branch
//      logic       link;		// If 1, then write PC+4 to reg
      logic [2:0] br_cond; //Branch Condition (bit 2:gt, bit 1:lt, bit 0:eq) [conditions are or-ed together]
      logic       sys_except;
      logic       inst_except;
      cp0op_s 	  cp0_op;
      } ctrl_s;		     

   typedef struct packed {
      logic [5:0] op;
      logic [4:0] rs, rt, rd;
      logic [4:0] shamt;
      logic [31:0] br_offset, imm_ze, imm_se;
      logic [25:0] target;
  } dcd_s;

   typedef struct packed {      
      logic 	  AdEL;
      logic 	  AdES;
      logic 	  IBE;
      logic 	  DBE;
      logic 	  Sys;
      logic 	  Bp;
      logic 	  RI;
      logic 	  CpU;
      logic 	  Ov;
      logic 	  Tr;
      logic 	  FPE;
   } exceptions_s;
      
endpackage: jpu

`define COND_EQZ 3'b100
`define COND_LTZ 3'b010
`define COND_GTZ 3'b001

`define WORD_SIZE 32
`define CLK_FREQ 10e6

`define TIMER_PERIOD 16'd100	// 10ms period for 10MHz clock
   
`endif

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:

