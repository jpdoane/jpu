//////
////// RISC-V ISA Defines
//////

//// Priviledge modes
`define RV_MODE_U 2'b00
`define RV_MODE_S 2'b01
`define RV_MODE_M 2'b11

////
//// RV32I OPCODES
////

`define RV_LOAD      5'b00000
`define RV_MISC_MEM  5'b00011
`define RV_OP_IMM    5'b00100
`define RV_AUIPC     5'b00101
`define RV_STORE     5'b01000
`define RV_OP        5'b01100
`define RV_LUI       5'b01101
`define RV_BRANCH    5'b11000
`define RV_JALR      5'b11001
`define RV_JAL       5'b11011
`define RV_SYSTEM    5'b11100

//following opcodes are not implemented by RV32I
/* -----\/----- EXCLUDED -----\/-----
//
`define RV_LOAD_FP   5'b00001
`define RV_CUSTOM_0  5'b00010
`define RV_OP_IMM_32 5'b00110
// xx111 reserved for >32b instructions
`define RV_STORE_FP  5'b01001
`define RV_CUSTOM_1  5'b01010
`define RV_AMO       5'b01011
`define RV_OP_32     5'b01110
`define RV_MADD      5'b10000
`define RV_MSUB      5'b10001
`define RV_NMSUB     5'b10010
`define RV_NMADD     5'b10011
`define RV_OP_FP     5'b10100
//10101 reserved
`define RV_CUSTOM_2  5'b10110
//11010 reserved
//11101 reserved
`define RV_CUSTOM_3  5'b11110
 -----/\----- EXCLUDED -----/\----- */

////
//// Funct3 Codes
////

// opcode=RV_BRANCH
`define F3_BEQ      3'b000
`define F3_BNE      3'b001
`define F3_BLT      3'b100
`define F3_BGE      3'b101
`define F3_BLTU     3'b110
`define F3_BGEU     3'b111

// opcode=RV_LOAD or RV_STORE
`define F3_LSB      3'b000
`define F3_LSH      3'b001
`define F3_LSW      3'b010
`define F3_LBU      3'b100 //LOAD only
`define F3_LHU      3'b101 //LOAD only

// opcode=RV_OP or RV_OP_IMM
`define F3_ADD      3'b000 //funct7[5] ? SUB : ADD,  no SUBI
`define F3_SLL      3'b001
`define F3_SLT      3'b010
`define F3_SLTU     3'b011
`define F3_XOR      3'b100
`define F3_SRX      3'b101  //funct7[5] ? SRA : SRL
`define F3_OR       3'b110
`define F3_AND      3'b111

// opcode=RV_MISC_MEM
`define F3_FENCE    3'b000
`define F3_FENCE_I  3'b001

// opcode=RV_SYSTEM
`define F3_ECALL    3'b000  //csr[0] ? EBREAK : ECALL
`define F3_CSRRW    3'b001
`define F3_CSRRS    3'b010
`define F3_CSRRC    3'b011
`define F3_CSRRWI   3'b101
`define F3_CSRRSI   3'b110
`define F3_CSRRCI   3'b111


////
//// ALU Opcodes
//// for RV_OP, RV_OP_IMM, funct3 defines the ALU operation
//// with funct7 providing alternate flags for add/sub or srl/sra
//// the 3 LSB in ALU code map to funct3, with MSB the alt flag.
//// so ALU codes can be constructed as:  {funct7[5], funct3}
//// We will also define a few needed alu functions, e.g. LUI

`define ALU_ADD     4'b0000
`define ALU_SUB     4'b1000
`define ALU_SLL     4'b0001
`define ALU_SLT     4'b0010
`define ALU_SLTU    4'b0011
`define ALU_XOR     4'b0100
`define ALU_SRL     4'b0101
`define ALU_SRA     4'b1101
`define ALU_OR      4'b0110
`define ALU_LUI     4'b1110 // essentially an 'or' with rs1=0
`define ALU_AND     4'b0111


// cmp bits: {LT, LTU, EQ}
