`include "risc-v.svh"


module alu_tb_top;

    logic [31:0] alu_in1, alu_in2;
    logic [31:0] alu_out;
    logic [3:0] alu_op; 

   alu ALU( // Outputs
	    .alu_out			(alu_out),
	    // Inputs
	    .alu_in1			(alu_in1),
	    .alu_in2			(alu_in2),
	    .alu_op			     (alu_op));

/* ALU_OPs
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
*/
   initial
     begin

        alu_in1 = 32'h12345678;
        alu_in2 = 32'hbeefdead;

        $display("Testing add");
        alu_op = `ALU_ADD;
        #1
        if(alu_out != alu_in1 + alu_in2)  $display("Add error: %h", alu_out);

        $display("Testing sub");
        alu_op = `ALU_SUB;
        #1
        if(alu_out != alu_in1 - alu_in2)  $display("sub error: %h", alu_out);

        $display("Testing sll");
        alu_in1 = 32'b0101;
        alu_in2 = 32'd1;
        alu_op = `ALU_SLL;
        #1
        if(alu_out != alu_in1 << alu_in2)  $display("sll error: %h", alu_out);

        alu_in1 = 32'b0101;
        alu_in2 = 32'd31;
        #1
        if(alu_out != alu_in1 << alu_in2)  $display("sll error: %h", alu_out);

        $display("Testing slt");
        alu_in1 = 0;
        alu_in2 = 1;
        alu_op = `ALU_SLT;
        #1
        if(alu_out != 32'h1)  $display("slt error: %h", alu_out);
        alu_op = `ALU_SLTU;
        #1
        if(alu_out != 32'h1)  $display("sltu error: %h", alu_out);

        alu_in1 = 1;
        alu_in2 = 0;
        alu_op = `ALU_SLT;
        #1
        if(alu_out != 32'h0)  $display("slt error: %h", alu_out);
        alu_op = `ALU_SLTU;
        #1
        if(alu_out != 32'h0)  $display("sltu error: %h", alu_out);

        alu_in1 = -1;
        alu_in2 = 1;
        alu_op = `ALU_SLT;
        #1
        if(alu_out != 32'h1)  $display("slt error: %h", alu_out);
        alu_op = `ALU_SLTU;
        #1
        if(alu_out != 32'h0)  $display("sltu error: %h", alu_out);

        $display("Testing srl");
        alu_in1 = 32'hffffffff;
        alu_in2 = 32'd5;
        alu_op = `ALU_SRL;
        #1
        if(alu_out != alu_in1 >> alu_in2)  $display("srl error: %h", alu_out);

        $display("Testing sra");
        alu_in1 = 32'hffffffff;
        alu_in2 = 32'd5;
        alu_op = `ALU_SRA;
        #1
        if(alu_out != $unsigned($signed(alu_in1) >>> $signed(alu_in2)))  $display("sra error: %h != %h", alu_out, $unsigned($signed(alu_in1) >>> $signed(alu_in2)));

        $display("Testing lui");
        alu_in2 = 32'hdeadbeef;
        alu_op = `ALU_LUI;
        #1
        if(alu_out != alu_in2)  $display("lui error: %h", alu_out);

        $display("Testing and");
        alu_in1 = 32'haaaaaaaa;
        alu_in2 = 32'hdeadbeef;
        alu_op = `ALU_AND;
        #1
        if(alu_out != (alu_in1 & alu_in2))  $display("and error: %h != %h", alu_out, alu_in1 & alu_in2);

        $display("Testing or");
        alu_in1 = 32'haaaaaaaa;
        alu_in2 = 32'hdeadbeef;
        alu_op = `ALU_OR;
        #1
        if(alu_out != (alu_in1 | alu_in2))  $display("or error: %h != %h", alu_out, alu_in1 | alu_in2);

        $display("Testing and");
        alu_in1 = 32'haaaaaaaa;
        alu_in2 = 32'hdeadbeef;
        alu_op = `ALU_XOR;
        #1
        if(alu_out != (alu_in1 ^ alu_in2))  $display("xor error: %h != %h", alu_out, alu_in1 ^ alu_in2);

        $display("Test Complete");
     end

endmodule // tb_decode

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("..")
// End:
