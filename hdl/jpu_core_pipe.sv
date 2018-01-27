`include "mips_defines.vh"
`include "jpu_defines.vh"
`include "mmap_defines.vh"
`include "bus.vh"
`include "jpu.svh"

import bus::*;
import jpu::*;

module jpu_core(/*AUTOARG*/
   // Outputs
   halted, bus_master_inst_out, bus_master_data_out, ila_probe,
   // Inputs
   clk, rst_b, bus_master_inst_in, bus_master_data_in
   );
   
   // Core Interface
   input         clk, rst_b;
   output        halted;
   input 	 bus::s2m_s bus_master_inst_in, bus_master_data_in;
   output 	 bus::m2s_s bus_master_inst_out, bus_master_data_out;
   output [31:0] ila_probe[5:0];

   // decode and control signals and their registers
   ctrl_s ctrl_ID, crtl_EX, ctrl_MEM, ctrl_WB;
   dcd_s dcd_ID, dcd_EX, dcd_MEM, dcd_WB;
   
   // pc and flow signals
   logic 	 rst, en0, en;
   logic 	 bus_inst_valid, bus_inst_stall, inst_excpt;
   logic [31:0]  inst;
   logic [31:0]  pc, nextpc, nextpcplus4;
   logic [29:0]  addr_fetch;
   logic [31:0]  addr_jump, addr_branch, addr_link;
   logic 	 branch_en;
   logic 	 pipeline_stall; 	 
   logic 	 internal_halt, halted;

   // register data
   logic [31:0]  rt_data, rs_data;
   logic [31:0]  reg_write_data;  

   // memory signals
   logic 	 mem_read_valid, mem_excpt, bus_data_stall, mem_req;
   logic [29:0]  mem_addr;
   logic 	 write_align_except, read_align_except;
   logic [31:0]  mem_read_word, mem_write_word;
   logic [3:0] 	 mem_mask;
   logic [31:0]  mem_read_data;
   logic [31:0]  mem_read_data_se;

   // alu signals
   logic [31:0]  alu_out, alu_out_r1;
   logic [31:0]  alu_in1, alu_in2;
   logic [2:0] 	 alu_cmp;		// From ALU of mips_alu.v
   logic [3:0] 	 alu_op;			// From Decoder of mips_decode.v
   logic [31:0]  alu_out;		// From ALU of mips_alu.v


   //reset and enables...
   always @(posedge clk) begin
      rst <= ~rst_b;
      en0 <= rst_b;;			  // pre-enable (arms fetch on 1st inst)
      en <= en0;			  // cpu enable
   end

   logic pipeline_stall;
   assign pipeline_stall = bus_inst_stall | bus_data_stall;  //temporary stall due to bus latency
   assign internal_halt = ctrl.sys_except | ctrl.inst_except; //interrupt or exception

   
   ///////////////////////
   // Fetch/WB cycle
   
   // ********************************************
   // PC Management
   // ********************************************
   // program flow example: jump and link instruction at pc=8
   //
   // clk 0: pc = 0, nextpc = 4, nextpc+4 = 8, addr_link = 4, ra = ?
   //    inst(0) being executed, inst(4) being fetched
   //    not j/br command so nextpc <= nextpc+4
   //
   // clk 1: pc = 4, nextpc = 8, nextpc+4 = 12, addr_link = 8, ra = ?
   //    inst(4) being executed, inst(8) being fetched
   //    not j/br command so nextpc <= nextpc+4
   //
   // clk 2: pc = 8, nextpc = 12, nextpc+4 = 16, addr_link = 12, ra = ?
   //    inst(8) being executed, inst(12) being fetched
   //    inst(8) is jal 0xF0, so nextpc <= 0xF0
   //    register writes are pipelined, so ra remains unset
   //
   // clk 3: pc = 12, nextpc = F0, nextpc+4 = F4, addr_link = 16, ra = ?
   //    inst(12) being executed, inst(F0) being fetched
   //    we are now in branch delay slot, nextpc is jump target
   //    pipelined reg write of addr_link occurs: ra <= addr_link
   //    2nd j/br in branch delay slot is not legal, so nextpc <= nextpc+4
   //
   // clk 4: pc = F0, nextpc = F4, nextpc+4 = F8, addr_link = F4, ra = 16
   //    inst(F0) being executed, inst(F4) being fetched
   //    we have jumped and are now executing target code, with properly linked return address
   //  

   always @(posedge clk) begin
      if (rst) begin
	 pc <= '0;
	 nextpc <= `TEXT_SEG_BASE;
	 addr_link <= '0;
	 halted <= 1'b0;
      end
      else begin
	 if (en & ~internal_halt & ~pipeline_stall) begin
	    pc <= nextpc;
	    nextpc <= (ctrl.j == 1'b1) ? addr_jump :
		      (branch_en == 1'b1) ? addr_branch :
		      nextpcplus4;
	    addr_link <= nextpcplus4;
	    halted <= 1'b0;
	 end
	 else begin
	    pc <= pc;
	    nextpc <= nextpc;
	    addr_link <= addr_link;
	    halted <= internal_halt;
	 end
      end // else: !if(rst)
   end // always @ (posedge clk)

   assign addr_fetch = nextpc[31:2]; //always fetch word aligned nextpc
   assign nextpcplus4 = nextpc + 4;
   assign addr_jump = (dcd.op == 6'h0) ? rs_data : {pc[31:28], dcd.target, 2'b0};
   assign addr_branch = nextpc + dcd.br_offset; //branch offset is relative to branch delay slot
   assign branch_en = ctrl.br && ( | (ctrl.br_cond & alu_cmp) );

   // *******************************
   // Instruction bus
   // bus reads have latencty 1, so this represents the Fetch->ID register
   //
   bus_master bus_inst_master(// Outputs
			      .data_o		(inst),
			      .valid_o		(bus_inst_valid),
			      .stall_o		(bus_inst_stall),
			      .err_o		(inst_excpt),
			      .bus_o		(bus_master_inst_out),
			      // Inputs
			      .clk		(clk),
			      .rst		(rst),
			      .en_i		(en0), // enable early to prefetch instruction
			      .we_i		('0),
			      .data_i		('0),
			      .addr_i		(nextpc),
			      .byte_mask_i	('1),
			      .bus_i		(bus_master_inst_in));

   
   //***********************************
   // Instruction Decode cycle
   // 

   // Decode module is combinatorial
   decode Decoder(/*AUTOINST*/
		  // Outputs
		  .ctrl			(ctrl_ID),
		  .dcd			(dcd_ID),
		  // Inputs
		  .inst			(inst[31:0]));

   // Reg module is combinatorial
   // reg reads occur on ID cycle
   // reg writes occur on WB (Fetch) cycle
   regfile Registers(//Outputs
		     .rs_data(rs_data_ID),
		     .rt_data(rt_data_ID),
		     //Inputs
		     .rs_num(dcd_ID.rs),
		     .rt_num(dcd_ID.rt),
		     .rd_num(ctrl_WB.reg_dst),
		     .rd_data(data_WB),
		     .rd_we(ctrl_WB.reg_write),
		     .clk(clk),
		     .rst_b(rst_b),
		     .halted(halted));
   
   
   // register decode and control signals for pipelined ops
   always @(posedge clk) begin
      if (rst) begin
	 dcd_r1 <= '0;
	 ctrl_r1 <= '0;
	 alu_r1 <= '0;
      end
      else begin
	 if (internal_halt) begin
	    dcd_r1 <= dcd_r1;
	    ctrl_r1 <= ctrl_r1;
	    alu_out_r1 <= alu_out_r1;
	 end	 
	 else begin
	    dcd_r1 <= dcd;
	    ctrl_r1 <= ctrl;
	    alu_out_r1 <= alu_out;
	 end // else: !ifinternal_halt
      end // else: !if(rst)
   end // always @ (posedge clk)



   // ****************************
   // ALU
   //   
   assign alu_in1 = (ctrl.alu_src1 == REG) ? rs_data : {26'b0, dcd.shamt};
   assign alu_in2 = (ctrl.alu_src2 == REG) ? rt_data :
		    (ctrl.alu_src2 == IMM) ? dcd.imm_ze :
		    dcd.imm_se;   		    
   // Execute
   mips_alu ALU(/*AUTOINST*/
		// Outputs
		.alu_out		(alu_out[31:0]),
		.alu_cmp		(alu_cmp[2:0]),
		// Inputs
		.alu_in1		(alu_in1[31:0]),
		.alu_in2		(alu_in2[31:0]),
		.alu_op			(alu_op[3:0]));


   // ****************************
   // Memory cycle
   //
   assign mem_req = en & (ctrl.mem_write | ctrl.mem_read);
   assign mem_addr = alu_out[31:2];

   mem_write_align MEM_WRITE_ALIGN(// Inputs
				   .data(rt_data), //data to write
				   .addr_lsb(alu_out[1:0]),
				   .size(ctrl_MemSize),
				   .en(ctrl_MemWrite),
				   //Outputs
				   .data_align(mem_write_word), // full word with properly aligned data
				   .mask(mem_mask),
				   .align_except(write_align_except));

   
   bus_master bus_data_master( // Outputs
			      .data_o		(mem_read_word),
			      .valid_o		(mem_read_valid),
			      .stall_o		(bus_data_stall),
			      .err_o		(mem_excpt),
			      .bus_o		(bus_master_data_out),
			      // Inputs
			      .clk		(clk),
			      .rst		(rst),
			      .en_i		(mem_req),
			      .we_i		(ctrl.mem_write),
			      .data_i		(mem_write_word),
			      .addr_i		(mem_addr),
			      .byte_mask_i	(mem_mask),
			      .bus_i		(bus_master_data_in));
   
   
   mem_read_align MEM_READ_ALIGN(// Inputs
				 .data_align(mem_read_word), //full word from mem
				 .addr_lsb(alu_out_r1[1:0]),
				 .size(ctrl_r1.mem_size),
				 .en(ctrl_r1.mem_read),
				 //Outputs
				 .data(mem_read_data), //data shifted to lsb
				 .data_se(mem_read_data_se), //data shifted to lsb, sign extened
				 .align_except(read_align_except));

   // data to write back to register
   // piplelined to accomodate mem read delay
   assign data_WB = (ctrl_WB.link == 1'b1) ? addr_link_WB :
			   ~ctrl_WB.mem_read ? alu_out_WB :
			   ctrl_WB.mem_se ? mem_read_data_se_WB :
			   mem_read_data_WB;
     

   //ila probes
   assign  ila_probe[0] = pc;
   assign  ila_probe[1] = inst;
   assign  ila_probe[2] = mem_read_word;
   assign  ila_probe[3] = mem_write_word;
   assign  ila_probe[4] = mem_addr;
   assign  ila_probe[5][0] = alu_alt;        // From Decoder of mips_decode.v
   assign  ila_probe[5][4:1] = alu_op;            // From Decoder of mips_decode.v
   assign  ila_probe[5][5] = ctrl_ALUSrc1;        // From Decoder of mips_decode.v
   assign  ila_probe[5][7:6] = ctrl_ALUSrc2;        // From Decoder of mips_decode.v
   assign  ila_probe[5][8] = ctrl_Branch;        // From Decoder of mips_decode.v
   assign  ila_probe[5][11:9] = ctrl_BranchCond;    // From Decoder of mips_decode.v
   assign  ila_probe[5][12] = ctrl_InstException;    // From Decoder of mips_decode.v
   assign  ila_probe[5][13] = ctrl_Jump;        // From Decoder of mips_decode.v
   assign  ila_probe[5][14] = ctrl_Link;        // From Decoder of mips_decode.v
   assign  ila_probe[5][15] = ctrl_MemRead;        // From Decoder of mips_decode.v
   assign  ila_probe[5][16] = ctrl_MemSE;        // From Decoder of mips_decode.v
   assign  ila_probe[5][18:17] = ctrl_MemSize;        // From Decoder of mips_decode.v
   assign  ila_probe[5][19] = ctrl_MemWrite;        // From Decoder of mips_decode.v
   assign  ila_probe[5][21:20] = ctrl_RegDst;        // From Decoder of mips_decode.v
   assign  ila_probe[5][22] = ctrl_RegSrc;        // From Decoder of mips_decode.v
   assign  ila_probe[5][23] = ctrl_RegWrite;        // From Decoder of mips_decode.v
   assign  ila_probe[5][24] = ctrl_SysException;    // From Decoder of mips_decode.v
   assign  ila_probe[5][25] = branch_en;
   assign  ila_probe[5][26] = exception_halt;
   assign  ila_probe[5][27] = syscall_halt;
   assign  ila_probe[5][28] = syscall_halt;
   assign  ila_probe[5][30:29] = 2'b0;
   assign  ila_probe[5][31] = rst_b;

endmodule // mips_core


//// register: A register which may be reset to an arbirary value
////
//// q      (output) - Current value of register
//// d      (input)  - Next value of register
//// clk    (input)  - Clock (positive edge-sensitive)
//// enable (input)  - Load new value?
//// reset  (input)  - System reset
////
module register(q, d, clk, enable, rst_b);

   parameter
            width = 32,
            reset_value = 0;

   output [(width-1):0] q;
   reg [(width-1):0]    q;
   input [(width-1):0]  d;
   input                 clk, enable, rst_b;

//   always @(posedge clk or negedge rst_b)
   always @(posedge clk)
     if (~rst_b)
       q <= reset_value;
     else if (enable)
       q <= d;

endmodule // register


////
//// add_const: An adder that adds a fixed constant value
////
//// out (output) - adder result
//// in  (input)  - Operand
////
module add_const(out, in);

   parameter add_value = 1;

   output   [31:0] out;
   input    [31:0] in;

   assign   out = in + add_value;

endmodule // adder
 

module mem_write_align(/*AUTOARG*/
   // Outputs
   data_align, mask, align_except,
   // Inputs
   data, addr_lsb, size, en
   );

   input [31:0] data;
   input [1:0] addr_lsb, size;
   input       en;   
   output reg [31:0] data_align;
   output reg [3:0]  mask;
   output reg align_except;

   always @(*) begin
      mask = 4'h0;
      data_align = 32'h0;
      align_except = 1'b0;
      if(en) begin
	 case(size)
	   2'b00: //BYTE (these come from the lest sig bits of mips opcode)
	     case(addr_lsb)
	       2'b00:
		 begin
		    mask = 4'b0001;
		    data_align = data;
		 end
	       2'b01:
		 begin
		    mask = 4'b0010;
		    data_align = data << 8;
		 end
	       2'b10:
		 begin
		    mask = 4'b0100;
		    data_align = data << 16;
		 end
	       2'b11:
		 begin
		    mask = 4'b1000;
		    data_align = data << 24;
		 end
	     endcase // case (addr[1:0])	
	   2'b01: //HALFWORD
	     case(addr_lsb)
	       2'b00:
		 begin
		    mask = 4'b0011;
		    data_align = data;
		 end
	       2'b10:
		 begin
		    mask = 4'b1100;
		    data_align = data << 16;
		 end
	       default:
		 align_except = 1'b1;
	     endcase // case (addr[1:0])
	   2'b11: //WORD	  
	     case(addr_lsb)
	       2'b00:
		 begin
		    mask = 4'b1111;
		    data_align = data;
		 end
	       default:
		 align_except = 1'b1;
	     endcase // case (addr[1:0])
	   default:
	     align_except = 1'b0;
	 endcase // case (size)
      end // if (en)      
   end   
endmodule // mem_align

module mem_read_align(/*AUTOARG*/
   // Outputs
   data, data_se, align_except,
   // Inputs
   data_align, addr_lsb, size, en
   );

   input [31:0] data_align;
   input [1:0] addr_lsb, size;
   input       en;
   
   output reg [31:0] data;
   output reg [31:0] data_se;
   output reg align_except;

   always @(*) begin
      data = 32'h0;
      data_se = 32'h0;
      align_except = 1'b0;
      if (en) begin
	 case(size)
	   2'b00: //BYTE (these come from the lest sig bits of mips opcode)
	     begin
		case(addr_lsb)
		  2'b00: data = {24'h0, data_align[7:0]};
		  2'b01: data = {24'h0, data_align[15:8]};
		  2'b10: data = {24'h0, data_align[23:16]};
		  2'b11: data = {24'h0, data_align[31:24]};
		endcase // case (addr[1:0])
		data_se[7:0] = data[7:0];
		data_se[31:8] = {24{data[7]}};
	     end
	   2'b01: //HALFWORD
	     begin
		case(addr_lsb)
		  2'b00: data = {16'h0, data_align[15:0]};
		  2'b10: data = {16'h0, data_align[31:16]};
		  default:
		    align_except = 1'b1;
		endcase // case (addr[1:0])
		data_se[15:0] = data[15:0];
		data_se[31:16] = {16{data[15]}};
	     end
	   2'b11: //WORD
	     begin
		case(addr_lsb)
		  2'b00: data = data_align;
		  default:
		    align_except = 1'b1;
		endcase // case (addr[1:0])
		data_se = data;
	     end
	   default:
	     align_except = 1'b0;
	 endcase // case (size)
      end // if (en)      
   end   
endmodule // mem_align

   

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:

