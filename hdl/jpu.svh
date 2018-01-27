//data types for wishbone bus signals
`ifndef JPU_SVH
`define JPU_SVH

package jpu;

   typedef enum logic {REG1, SHAMT} alusrc1_s;
   typedef enum logic [1:0] {REG2, IMM, IMM_SE} alusrc2_s;
   typedef enum logic [1:0] {BYTE, HALF, WORD} memsize_s;
   
   typedef struct packed {      
      logic       reg_write;	// reg write enable
      logic [4:0] reg_dst;		// Destination Reg - rd, rt, ra
      alusrc1_s   alu_src1;	//alu 1 source: reg or shamt
      alusrc2_s   alu_src2;	// alu 2 src: reg, imm, imm_se
      logic [3:0] alu_op;	// ALU Opcode (alt)
      logic       mem_read;	//Read from Mem
      logic       mem_write;	//Write to Mem
      memsize_s   mem_size;	//Size of mem operation (B,H,W)
      logic       mem_se;		//memory sign-extend
      logic       j;		//jump
      logic       br;		//branch
      logic       link;		// If 1, then write PC+4 to reg
      logic [2:0] br_cond; //Branch Condition (bit 2:gt, bit 1:lt, bit 0:eq) [conditions are or-ed together]
      logic       sys_except;
      logic       inst_except;
      } ctrl_s;		     

   typedef struct packed {
      logic [5:0] op;
      logic [4:0] rs, rt, rd;
      logic [4:0] shamt;
      logic [31:0] br_offset, imm_ze, imm_se;
      logic [25:0] target;
   } dcd_s;
      
endpackage: jpu

`define COND_EQZ 3'b100
`define COND_LTZ 3'b010
`define COND_GTZ 3'b001

`define WORD_SIZE 32
`define CLK_FREQ 10e6

// ALU
`define ALU_NOP      4'h0
`define ALU_SYSCALL      4'h1
`define ALU_SLL      4'h2
`define ALU_SRL      4'h3
`define ALU_SRA      4'h3
`define ALU_ADD      4'h4
`define ALU_SUB      4'h5
`define ALU_ADDU      4'h4
`define ALU_SUBU      4'h5
`define ALU_AND      4'h6
`define ALU_OR       4'h7
`define ALU_XOR      4'h8
`define ALU_NOR      4'h9
`define ALU_SLT      4'ha
`define ALU_SLTU      4'ha
`define ALU_LUI      4'hb

   
`endif

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:

