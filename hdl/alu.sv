`include "risc-v.svh"

module alu(/*AUTOARG*/
   // Outputs
   alu_out,
   // Inputs
   alu_in1, alu_in2, alu_op
   );

   input [31:0]  alu_in1, alu_in2;
   input [3:0]   alu_op;

   output logic [31:0] alu_out;

   logic [31:0] 	    alu_add, alu_sub, alu_sl, alu_sr;
   logic [31:0] 	    alu_and, alu_or, alu_xor;
   logic 		    alu_slt,alu_sltu;

   always @(*) begin      
      alu_add = alu_in1 + alu_in2;
      alu_sub = alu_in1 - alu_in2;
      alu_and = alu_in1 & alu_in2;
      alu_or = alu_in1 | alu_in2;
      alu_xor = alu_in1 ^ alu_in2;

      //would be nice to use the existing comparitor block for this, but would require some rewiring & muxes
      alu_slt = ($signed(alu_in1) < $signed(alu_in2));
      alu_sltu = (alu_in1 < alu_in2);      
   end

   shift_left shiftLeftUnit(alu_sl, alu_in1, alu_in2[4:0]);
   shift_right shiftRightUnit(alu_sr, alu_in1, alu_in2[4:0],alu_op[3]);
   
   always @(*) begin
      case(alu_op)
	`ALU_ADD: alu_out = alu_add;
	`ALU_SUB: alu_out = alu_sub;
	`ALU_SLL: alu_out = alu_sl;
	`ALU_SLT: alu_out = {31'b0, alu_slt};
	`ALU_SLTU: alu_out = {31'b0, alu_sltu};
	`ALU_XOR: alu_out = alu_xor;
	`ALU_SRL, `ALU_SRA: alu_out = alu_sr; //determined by alu_op[3]
	`ALU_OR: alu_out = alu_or;
	`ALU_LUI: alu_out = alu_in2;
	`ALU_AND: alu_out = alu_and;
	default: alu_out = 32'b0;
      endcase // case (alu_op)            
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
     
// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
