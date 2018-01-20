`include "mips_defines.vh"
`include "jpu_defines.vh"


////
//// mips_ALU: Performs all arithmetic and logical operations
////
//// alu_out (output) - Final result
//// alu_in1 (input)  - Operand modified by the operation
//// alu_in2 (input)  - Operand used (in arithmetic ops) to modify alu_in1
//// alu_op (input)  - Selects which operation is to be performed
//// alu_alt (input)  - alternate alu_op functionality (e.g. unsigned, sra, ...)
////
module mips_alu(/*AUTOARG*/
   // Outputs
   alu_out, alu_cmp,
   // Inputs
   alu_in1, alu_in2, alu_op, alu_alt
   );

   input [31:0]  alu_in1, alu_in2;
   input [3:0]   alu_op;
   input 	 alu_alt;

   output reg [31:0] alu_out;
   output reg [2:0] alu_cmp;

   wire [31:0] 	    alu_add, alu_sl, alu_sr;
   wire       sub;
   reg [31:0] 	    alu_and, alu_or, alu_xor;
   
   assign sub = (alu_op == `ALU_SUB || alu_op == `ALU_SLT) ? 1'b1 : 1'b0; 
     
   always @(*) begin   
      alu_and = alu_in1 & alu_in2;
      alu_or = alu_in1 | alu_in2;
      alu_xor = alu_in1 ^ alu_in2;
   end
   adder AdderUnit(alu_add, alu_in1, alu_in2, sub);
   shift_left shiftLeftUnit(alu_sl, alu_in2, alu_in1[4:0]);
   shift_right shiftRightUnit(alu_sr, alu_in2, alu_in1[4:0],alu_alt);
   
   always @(*) begin
      case(alu_op)
	`ALU_NOP: alu_out = alu_in1;
	`ALU_SYSCALL: alu_out = 32'b0;
	`ALU_SHIFT_RIGHT: alu_out = alu_sr;
	`ALU_SHIFT_LEFT: alu_out = alu_sl;
	`ALU_ADD: alu_out = alu_add;
	`ALU_SUB: alu_out = alu_add;
	`ALU_AND: alu_out = alu_and;
	`ALU_OR: alu_out = alu_or;
	`ALU_XOR: alu_out = alu_xor;
	`ALU_NOR: alu_out = !alu_or;
	`ALU_SLT: alu_out = {31'b0, alu_add[31]}; //set on sign bit of op1-op2
	`ALU_LUI: alu_out = {alu_in2[15:0], 16'b0};
	default: alu_out = 32'b0;
      endcase // case (alu_op)
      
      alu_cmp[2] = (alu_out==32'b0) ? 1'b1 : 1'b0; //result == 0
      alu_cmp[1] = alu_out[31]; //result < 0
      alu_cmp[0] = !(alu_cmp[2] | alu_cmp[1]); //result > 0
      
   end // always @ begin

endmodule

module shift_left(/*AUTOARG*/
   // Outputs
   x_shift,
   // Inputs
   x, shamt
   );
   input [31:0]  x;
   input [4:0]   shamt;
   output reg [31:0] 	 x_shift;
   
   always @(*) begin
      case(shamt)
	5'd0: x_shift = x;
	5'd1: x_shift = x << 1;
	5'd2: x_shift = x << 2;
	5'd3: x_shift = x << 3;
	5'd4: x_shift = x << 4;
	5'd5: x_shift = x << 5;
	5'd6: x_shift = x << 6;
	5'd7: x_shift = x << 7;
	5'd8: x_shift = x << 8;
	5'd9: x_shift = x << 9;
	5'd10: x_shift = x << 10;
	5'd11: x_shift = x << 11;
	5'd12: x_shift = x << 12;
	5'd13: x_shift = x << 13;
	5'd14: x_shift = x << 14;
	5'd15: x_shift = x << 15;
	5'd16: x_shift = x << 16;
	5'd17: x_shift = x << 17;
	5'd18: x_shift = x << 18;
	5'd19: x_shift = x << 19;
	5'd20: x_shift = x << 20;
	5'd21: x_shift = x << 21;
	5'd22: x_shift = x << 22;
	5'd23: x_shift = x << 23;
	5'd24: x_shift = x << 24;
	5'd25: x_shift = x << 25;
	5'd26: x_shift = x << 26;
	5'd27: x_shift = x << 27;
	5'd28: x_shift = x << 28;
	5'd29: x_shift = x << 29;
	5'd30: x_shift = x << 30;
	5'd31: x_shift = x << 31;
      endcase // case (shamt)
   end // always @ begin
endmodule
   
module shift_right(/*AUTOARG*/
   // Outputs
   x_shift,
   // Inputs
   x, shamt, arith
   );
   input [31:0]  x;
   input [4:0]   shamt;
   input 	 arith;
   wire 	 shval;   
   output reg [31:0] 	 x_shift;

   assign shval = (arith == 1) ? x[31] : 1'b0;
   
   always @(*) begin
      case(shamt)
	5'd0: x_shift = x;
	5'd1: x_shift = {shval, x[31:1]};
	5'd2: x_shift = {{2{shval}}, x[31:2]};
	5'd3: x_shift = {{3{shval}}, x[31:3]};
	5'd4: x_shift = {{4{shval}}, x[31:4]};
	5'd5: x_shift = {{5{shval}}, x[31:5]};
	5'd6: x_shift = {{6{shval}}, x[31:6]};
	5'd7: x_shift = {{7{shval}}, x[31:7]};
	5'd8: x_shift = {{8{shval}}, x[31:8]};
	5'd9: x_shift = {{9{shval}}, x[31:9]};
	5'd10: x_shift = {{10{shval}}, x[31:10]};
	5'd11: x_shift = {{11{shval}}, x[31:11]};
	5'd12: x_shift = {{12{shval}}, x[31:12]};
	5'd13: x_shift = {{13{shval}}, x[31:13]};
	5'd14: x_shift = {{14{shval}}, x[31:14]};
	5'd15: x_shift = {{15{shval}}, x[31:15]};
	5'd16: x_shift = {{16{shval}}, x[31:16]};
	5'd17: x_shift = {{17{shval}}, x[31:17]};
	5'd18: x_shift = {{18{shval}}, x[31:18]};
	5'd19: x_shift = {{19{shval}}, x[31:19]};
	5'd20: x_shift = {{20{shval}}, x[31:20]};
	5'd21: x_shift = {{21{shval}}, x[31:21]};
	5'd22: x_shift = {{22{shval}}, x[31:22]};
	5'd23: x_shift = {{23{shval}}, x[31:23]};
	5'd24: x_shift = {{24{shval}}, x[31:24]};
	5'd25: x_shift = {{25{shval}}, x[31:25]};
	5'd26: x_shift = {{26{shval}}, x[31:26]};
	5'd27: x_shift = {{27{shval}}, x[31:27]};
	5'd28: x_shift = {{28{shval}}, x[31:28]};
	5'd29: x_shift = {{29{shval}}, x[31:29]};
	5'd30: x_shift = {{30{shval}}, x[31:30]};
	5'd31: x_shift = {{31{shval}}, x[31]};
      endcase // case (shamt)
   end // always @ begin
endmodule
     
////
//// adder
////
//// out (output) - adder result
//// in1 (input)  - Operand1
//// in2 (input)  - Operand2
//// sub (input)  - Subtract?
////
module adder(out, in1, in2, sub);
   output [31:0] out;
   input [31:0]  in1, in2;
   input         sub;

   assign        out = sub?(in1 - in2):(in1 + in2);

endmodule // adder


