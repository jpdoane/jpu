interface decode_if (
   input logic [31:0]    inst,
   output logic [4:0] rd, rs1, rs2,
   output logic [3:0] alu_op,
   output logic [2:0] f3,
   output logic       alu_pc, alu_imm, alu_we,
   output logic       j, br, ld, st,
   output logic [31:0] imm
		     );
endinterface


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("..")
// End:
