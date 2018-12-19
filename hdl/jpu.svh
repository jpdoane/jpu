//data types for wishbone bus signals
`ifndef JPU_SVH
`define JPU_SVH

package jpu;

   typedef struct packed {
      logic [4:0] rd, rs1, rs2;
      logic [3:0] alu_op;
      logic [2:0] f3;
      logic 	  alu_pc, alu_imm, alu_we;
      logic 	  j, br, ld, st;
      logic [31:0] imm;
      logic [1:0]  mem_w;	    	  
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

`define WORD_SIZE 32
`define CLK_FREQ 10e6

`define TIMER_PERIOD 16'd100	// 10ms period for 10MHz clock
   
`endif

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:

