////
//// Internal signal constants
////

`define WORD_SIZE 32
`define CLK_FREQ 10e6


// ALU
`define ALU_NOP      4'h0
`define ALU_SYSCALL      4'h1
`define ALU_SHIFT_LEFT      4'h2
`define ALU_SHIFT_RIGHT      4'h3
`define ALU_ADD      4'h4
`define ALU_SUB      4'h5
`define ALU_AND      4'h6
`define ALU_OR       4'h7
`define ALU_XOR      4'h8
`define ALU_NOR      4'h9
`define ALU_SLT      4'ha
`define ALU_LUI      4'hb

// ALU Source Mux
`define ALU_SRC1_REG 1'b0 //register -> ALU
`define ALU_SRC1_SHAMT 1'b1 //shamt -> ALU

`define ALU_SRC2_REG 2'b00 //register -> ALU
`define ALU_SRC2_IMM 2'b01 //immediate zero extended -> ALU
`define ALU_SRC2_IMM_SE 2'b10 //immediate sign extended -> ALU



// Desitation Reg
`define CTRL_REGDST_RD 2'h0
`define CTRL_REGDST_RT 2'h1
`define CTRL_REGDST_RA 2'h2

`define CTRL_REGSRC_ALU 1'b0
`define CTRL_REGSRC_MEM 1'b1

