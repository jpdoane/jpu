`include "risc-v.svh"


module decode_tb_top;

   //import uvm_pkg::*;

   logic [31:0]  inst;

   decode_if dcd(.inst(inst));
   decode decoder(.dif(dcd));

   initial
     begin


/* decode_test.s
        add x2, x1, x3		#R - type
        addi x2, x1, 0xde   #I - type
 link:  sh  x2, -100(x1)    #S - type
        jal x1, link        #J - type
        beq x1, x2, link    #B - type
        lui x1, 0xdbeef     #U - type
*/

	// R-format
	$display("Test R-format instruction");
	inst = 32'h00008133;  //add     x2,x1,x0
	#1;
	if(dcd.rd != 5'h2)  $display("Bad rd: %h", dcd.rd);
	if(dcd.rs2 != 5'h0)  $display("Bad rs2: %h", dcd.rs2);
	if(dcd.rs1 != 5'h1)  $display("Bad rs1: %h", dcd.rs1);
	//if(dcd.imm != 32'hde)  $display("Bad imm: %h", dcd.imm);
	if(dcd.alu_op != `ALU_ADD)  $display("Bad alu_op: %h", dcd.alu_op);
	if(dcd.f3 != `F3_ADD)  $display("Bad f3: %h", dcd.f3);	
	if(dcd.alu_pc != 1'b0)  $display("Bad alu_pc: %h", dcd.alu_pc);
	if(dcd.alu_imm != 1'b0)  $display("Bad alu_imm: %h", dcd.alu_imm);
    if(dcd.alu_we != 1'b1)  $display("Bad alu_we: %h", dcd.alu_we);
	if(dcd.j != 1'b0)  $display("Bad j: %h", dcd.j);
	if(dcd.br != 1'b0)  $display("Bad br: %h", dcd.br);
	if(dcd.ld != 1'b0)  $display("Bad ld: %h", dcd.ld);
	if(dcd.st != 1'b0)  $display("Bad st: %h", dcd.st);

	// I-format
	$display("Test I-format instruction");
	inst = 32'h0de08113;  //addi x2, x1, 0xde
	#1;
	if(dcd.rd != 5'h2)  $display("Bad rd: %h", dcd.rd);
	if(dcd.rs1 != 5'h1)  $display("Bad rs1: %h", dcd.rs1);
	if(dcd.imm != 32'hde)  $display("Bad imm: %h", dcd.imm);
	if(dcd.alu_op != `ALU_ADD)  $display("Bad alu_op: %h", dcd.alu_op);
	if(dcd.f3 != `F3_ADD)  $display("Bad f3: %h", dcd.f3);	
	if(dcd.alu_pc != 1'b0)  $display("Bad alu_pc: %h", dcd.alu_pc);
	if(dcd.alu_imm != 1'b1)  $display("Bad alu_imm: %h", dcd.alu_imm);
    if(dcd.alu_we != 1'b1)  $display("Bad alu_we: %h", dcd.alu_we);
	if(dcd.j != 1'b0)  $display("Bad j: %h", dcd.j);
	if(dcd.br != 1'b0)  $display("Bad br: %h", dcd.br);
	if(dcd.ld != 1'b0)  $display("Bad ld: %h", dcd.ld);
	if(dcd.st != 1'b0)  $display("Bad st: %h", dcd.st);
	
	// S-format
	$display("Test S-format instruction");
	inst = 32'hf8209e23;     // sh      x2,-100(x1)
	#1;
	if(dcd.rs2 != 5'h2)  $display("Bad rs2: %h", dcd.rs2);
	if(dcd.rs1 != 5'h1)  $display("Bad rs1: %h", dcd.rs1);
	if(dcd.imm != -32'd100)  $display("Bad imm: %d", dcd.imm);
	if(dcd.alu_op != `ALU_ADD)  $display("Bad alu_op: %h", dcd.alu_op);
	if(dcd.f3 != `F3_LSH)  $display("Bad f3: %h", dcd.f3);	
	if(dcd.alu_pc != 1'b0)  $display("Bad alu_pc: %h", dcd.alu_pc);
	if(dcd.alu_imm != 1'b1)  $display("Bad alu_imm: %h", dcd.alu_imm);
    if(dcd.alu_we != 1'b0)  $display("Bad alu_we: %h", dcd.alu_we);
	if(dcd.j != 1'b0)  $display("Bad j: %h", dcd.j);
	if(dcd.br != 1'b0)  $display("Bad br: %h", dcd.br);
	if(dcd.ld != 1'b0)  $display("Bad ld: %h", dcd.ld);
	if(dcd.st != 1'b1)  $display("Bad st: %h", dcd.st);

	$display("Test J-format instruction");
    //ffdff0ef                jal     x1,8 <link> (prev line)
	inst = 32'hffdff0ef;
	#1;
	if(dcd.rd != 5'h1)  $display("Bad rd: %h", dcd.rd);
	if(dcd.imm != -32'h4)  $display("Bad imm: %d", dcd.imm);
	if(dcd.alu_op != `ALU_ADD)  $display("Bad alu_op: %h", dcd.alu_op);
//	if(dcd.f3 != `F3_LSH)  $display("Bad f3: %h", dcd.f3);	
	if(dcd.alu_pc != 1'b1)  $display("Bad alu_pc: %h", dcd.alu_pc);
	if(dcd.alu_imm != 1'b1)  $display("Bad alu_imm: %h", dcd.alu_imm);
    if(dcd.alu_we != 1'b0)  $display("Bad alu_we: %h", dcd.alu_we);
	if(dcd.j != 1'b1)  $display("Bad j: %h", dcd.j);
	if(dcd.br != 1'b0)  $display("Bad br: %h", dcd.br);
	if(dcd.ld != 1'b0)  $display("Bad ld: %h", dcd.ld);
	if(dcd.st != 1'b0)  $display("Bad st: %h", dcd.st);

	$display("Test B-format instruction");
    // fe208ce3                beq     x1,x2,8 <link>
	inst = 32'hfe208ce3;
	#1;
	if(dcd.rs1 != 5'h1)  $display("Bad rs1: %h", dcd.rs1);
	if(dcd.rs2 != 5'h2)  $display("Bad rs2: %h", dcd.rs2);
	if(dcd.imm != -32'h8)  $display("Bad imm: %d", dcd.imm);
	if(dcd.alu_op != `ALU_ADD)  $display("Bad alu_op: %h", dcd.alu_op);
	if(dcd.f3 != `F3_BEQ)  $display("Bad f3: %h", dcd.f3);	
	if(dcd.alu_pc != 1'b1)  $display("Bad alu_pc: %h", dcd.alu_pc);
	if(dcd.alu_imm != 1'b1)  $display("Bad alu_imm: %h", dcd.alu_imm);
    if(dcd.alu_we != 1'b0)  $display("Bad alu_we: %h", dcd.alu_we);
	if(dcd.j != 1'b0)  $display("Bad j: %h", dcd.j);
	if(dcd.br != 1'b1)  $display("Bad br: %h", dcd.br);
	if(dcd.ld != 1'b0)  $display("Bad ld: %h", dcd.ld);
	if(dcd.st != 1'b0)  $display("Bad st: %h", dcd.st);

	$display("Test U-format instruction");
    //0beef0b7                lui     x1,0xbeef
	inst = 32'hdbeef0b7;
    #1;
    if(dcd.rd != 5'h1)  $display("Bad rd: %h", dcd.rd);
    if(dcd.imm != 32'hdbeef000)  $display("Bad imm: %d", dcd.imm);
    if(dcd.alu_op != `ALU_LUI)  $display("Bad alu_op: %h", dcd.alu_op);
    //if(dcd.f3 != `F3_BEQ)  $display("Bad f3: %h", dcd.f3);    
    if(dcd.alu_pc != 1'b0)  $display("Bad alu_pc: %h", dcd.alu_pc);
    if(dcd.alu_imm != 1'b1)  $display("Bad alu_imm: %h", dcd.alu_imm);
    if(dcd.alu_we != 1'b1)  $display("Bad alu_we: %h", dcd.alu_we);
    if(dcd.j != 1'b0)  $display("Bad j: %h", dcd.j);
    if(dcd.br != 1'b0)  $display("Bad br: %h", dcd.br);
    if(dcd.ld != 1'b0)  $display("Bad ld: %h", dcd.ld);
    if(dcd.st != 1'b0)  $display("Bad st: %h", dcd.st);

    $display("Test Complete");
 end

endmodule // tb_decode

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("..")
// End:
