`include "mips_defines.vh"
`include "jpu_defines.vh"
`include "mmap_defines.vh"
`include "bus.vh"

import bus::*;


module jpu_core(/*AUTOARG*/
   // Outputs
   halted, bus_master_inst_out, bus_master_data_out, ila_probe,
   // Inputs
   clk, rst_b, bus_master_inst_in, bus_master_data_in
   );
   
   // Core Interface
   input         clk, rst_b;
   output        halted;

   // bus interfaces
   input 	 bus::s2m_s bus_master_inst_in, bus_master_data_in;
   output 	 bus::m2s_s bus_master_inst_out, bus_master_data_out;

   //ila_probes
   output [31:0] ila_probe[5:0];
   
   logic 	 rst, en0, en;

   logic 	 bus_inst_valid, bus_inst_stall, inst_excpt;
   logic [31:0]  inst;
   logic [29:0]  fetch_addr;
   
   logic 	 mem_read_valid, bus_data_stall, mem_excpt, mem_req;
   logic [29:0]  mem_addr;
   logic [31:0]  mem_read_word, mem_write_word;
   
   logic 	 rd_write, mem_read,mem_se;
   logic [31:0]  reg_data;  
   
   // Internal signals
   logic [31:0]  pc, nextpc, nextpc_flow;
   logic [31:0]  addr_jump, addr_branch;
   logic 	 branch_en;
   logic 	 exception_halt, syscall_halt, internal_halt;
   logic 	 write_align_except, read_align_except;
   logic 	 load_epc, load_bva, load_bva_sel;
   logic [31:0]  rt_data, rs_data, rd_data;
   logic [31:0]  epc, cause, bad_v_addr;
   logic [4:0] 	 cause_code;
   logic [3:0] 	 mem_mask;
   logic [31:0]  mem_read_data;
   logic [31:0]  mem_read_data_se;
   logic [1:0] 	 read_lsb;
   logic [1:0] 	 read_size;
   
   
   // Decode signals
   logic [31:0]  dcd_se_imm, dcd_e_imm, dcd_se_mem_offset, dcd_se_offset;
   logic [5:0] 	 dcd_op, dcd_funct2;
   logic [4:0] 	 dcd_rs, dcd_funct1, dcd_rt, dcd_rd, dcd_shamt;
   logic [4:0] 	 rs_num, rd_num;
   logic [15:0]  dcd_offset, dcd_imm;
   logic [25:0]  dcd_target;
   logic [19:0]  dcd_code;
   logic 	 dcd_bczft;

   logic 	 load_ex_regs, ctrl_RI;

   logic [31:0]  alu_in1, alu_in2;
   logic 	 alu_alt;		// From Decoder of mips_decode.v
   logic [2:0] 	 alu_cmp;		// From ALU of mips_alu.v
   logic [3:0] 	 alu_op;			// From Decoder of mips_decode.v
   logic [31:0]  alu_out;		// From ALU of mips_alu.v
   logic 	 ctrl_ALUSrc1;		// From Decoder of mips_decode.v
   logic [1:0] 	 ctrl_ALUSrc2;		// From Decoder of mips_decode.v
   logic 	 ctrl_Branch;		// From Decoder of mips_decode.v
   logic [2:0] 	 ctrl_BranchCond;	// From Decoder of mips_decode.v
   logic 	 ctrl_InstException;	// From Decoder of mips_decode.v
   logic 	 ctrl_Jump;		// From Decoder of mips_decode.v
   logic 	 ctrl_Link;		// From Decoder of mips_decode.v
   logic 	 ctrl_MemRead;		// From Decoder of mips_decode.v
   logic 	 ctrl_MemSE;		// From Decoder of mips_decode.v
   logic [1:0] 	 ctrl_MemSize;		// From Decoder of mips_decode.v
   logic 	 ctrl_MemWrite;		// From Decoder of mips_decode.v
   logic [1:0] 	 ctrl_RegDst;		// From Decoder of mips_decode.v
   logic 	 ctrl_RegSrc;		// From Decoder of mips_decode.v
   logic 	 ctrl_RegWrite;		// From Decoder of mips_decode.v
   logic 	 ctrl_SysException;	// From Decoder of mips_decode.v


   
   //reset and enables...
   always @(posedge clk) begin
      rst <= ~rst_b;
      en0 <= rst_b;;			  // pre-enable (arms fetch on 1st inst)
      en <= en0;			  // cpu enable
   end
   
   // PC Management
   register #(32, `TEXT_SEG_BASE) PCReg(pc, nextpc_flow, clk, (en & ~internal_halt), rst_b);
   add_const #(4) NextPCAdder(nextpc, pc);
   assign addr_jump = (dcd_op == 6'h0) ? rs_data : {pc[31:28], dcd_target, 2'b0};
//   assign addr_branch = pc + dcd_se_offset;

   //True MIPS calculates branch relative to pc+4
   assign addr_branch = nextpc + dcd_se_offset;

//   assign nextpc_flow = pc; //dont ever advance

   assign nextpc_flow = (ctrl_Jump == 1'b1) ? addr_jump :
            (branch_en == 1'b1) ? addr_branch :
            nextpc;
   assign fetch_addr = en ? nextpc_flow[31:2] : pc[31:2];

   assign branch_en = ctrl_Branch && ( | (ctrl_BranchCond & alu_cmp) );
   
        
   // Instruction decoding
   assign        dcd_op = inst[31:26];    // Opcode
   assign        dcd_rs = inst[25:21];    // rs field
   assign        dcd_rt = inst[20:16];    // rt field
   assign        dcd_rd = inst[15:11];    // rd field
   assign        dcd_shamt = inst[10:6];  // Shift amount
   assign        dcd_bczft = inst[16];    // bczt or bczf?
   assign        dcd_funct1 = inst[4:0];  // Coprocessor 0 function field
   assign        dcd_funct2 = inst[5:0];  // funct field; secondary opcode
   assign        dcd_offset = inst[15:0]; // offset field
        // Sign-extended offset for branches
   assign        dcd_se_offset = { {14{dcd_offset[15]}}, dcd_offset, 2'b0};
        // Sign-extended offset for load/store
   assign        dcd_se_mem_offset = { {16{dcd_offset[15]}}, dcd_offset};
   assign        dcd_imm = inst[15:0];        // immediate field
   assign        dcd_e_imm = { 16'h0, dcd_imm };  // zero-extended immediate
        // Sign-extended immediate
   assign        dcd_se_imm = { {16{dcd_imm[15]}}, dcd_imm };
   assign        dcd_target = inst[25:0];     // target field
   assign        dcd_code = inst[25:6];       // Breakpoint code


   assign ctrl_RI = 1'b0;
   
   // // synthesis translate_off
   // always @(posedge clk) begin
   //   // useful for debugging, you will want to comment this out for long programs
   //   if (rst_b) begin
   //     $display ( "=== Simulation Cycle %d ===", $time );
   //     $display ( "[pc=%x, inst=%x] [op=%x, rs=%d, rt=%d, rd=%d, imm=%x, f2=%x] [reset=%d, halted=%d]",
   //                 pc, inst, dcd_op, dcd_rs, dcd_rt, dcd_rd, dcd_imm, dcd_funct2, ~rst_b, halted);
   //   end
   // end
   // // synthesis translate_on


   assign mem_req = en & (ctrl_MemWrite | ctrl_MemRead);
   assign mem_addr = alu_out[31:2];


   
   //Reg Writes are delayed due to mem/bus latency
   //store  relevant control signals for subsequent cycle(s)
   always @(posedge clk) begin
      if (rst) begin
	 rd_write <= 0;
	 reg_data <= '0;
	 rd_num <= '0;
	 mem_read <= 0;
	 mem_se <= 0;
	 read_lsb <= '0;   
	 read_size <= '0;
      end
      else begin
	 if (internal_halt) begin
	   rd_write <= rd_write;
	   reg_data <= reg_data;
	   rd_num <= rd_num;
	    mem_read <= mem_read;
	    mem_se <= mem_se;
	    read_lsb <= read_lsb;   
	    read_size <= read_size;
	 end	 
	 else begin
	    rd_write <= ctrl_RegWrite;
	    rd_num <= (ctrl_RegDst == `CTRL_REGDST_RD) ? dcd_rd
		      : (ctrl_RegDst == `CTRL_REGDST_RT) ? dcd_rt
		      : `R_RA;	 
	    reg_data <= (ctrl_Link == 1'b1) ? nextpc : alu_out;
	    // reg_data <= (ctrl_Link == 1'b1) ? nextpc :
	    // 	       (ctrl_RegSrc == `CTRL_REGSRC_ALU) ? alu_out;
	    mem_read <= ctrl_MemRead;
	    mem_se <= ctrl_MemSE;
	    read_lsb <= alu_out[1:0];   
	    read_size <= ctrl_MemSize;
	 end // else: !ifinternal_halt
      end // else: !if(rst)
   end // always @ (posedge clk)

   assign rd_data = ~mem_read ? reg_data :                      // internal write (alu,pc)
		    mem_se ? mem_read_data_se :			// write from mem (sign extend)
		    mem_read_data;				// write from mem (no sign extend)
      
   logic pipeline_stall;
   assign pipeline_stall = bus_inst_stall | bus_data_stall;

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
			      .addr_i		(fetch_addr),
			      .byte_mask_i	('1),
			      .bus_i		(bus_master_inst_in));

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
			      .we_i		(ctrl_MemWrite),
			      .data_i		(mem_write_word),
			      .addr_i		(mem_addr),
			      .byte_mask_i	(mem_mask),
			      .bus_i		(bus_master_data_in));

   
   // Generate control signals
   mips_decode Decoder(/*AUTOINST*/
		       // Outputs
		       .ctrl_RegDst	(ctrl_RegDst[1:0]),
		       .ctrl_ALUSrc1	(ctrl_ALUSrc1),
		       .ctrl_ALUSrc2	(ctrl_ALUSrc2[1:0]),
		       .ctrl_RegSrc	(ctrl_RegSrc),
		       .ctrl_Link	(ctrl_Link),
		       .ctrl_RegWrite	(ctrl_RegWrite),
		       .ctrl_MemRead	(ctrl_MemRead),
		       .ctrl_MemWrite	(ctrl_MemWrite),
		       .ctrl_MemSize	(ctrl_MemSize[1:0]),
		       .ctrl_MemSE	(ctrl_MemSE),
		       .ctrl_Jump	(ctrl_Jump),
		       .ctrl_Branch	(ctrl_Branch),
		       .ctrl_BranchCond	(ctrl_BranchCond[2:0]),
		       .alu_op		(alu_op[3:0]),
		       .alu_alt		(alu_alt),
		       .ctrl_SysException(ctrl_SysException),
		       .ctrl_InstException(ctrl_InstException),
		       // Inputs
		       .dcd_op		(dcd_op[5:0]),
		       .dcd_funct2	(dcd_funct2[5:0]),
		       .dcd_rt		(dcd_rt[4:0]));

   assign rs_num = (ctrl_SysException == 1'b1) ? `R_V0
		   : dcd_rs;

   // assign rd_num = (ctrl_RegDst == `CTRL_REGDST_RD) ? dcd_rd
   // 		   : (ctrl_RegDst == `CTRL_REGDST_RT) ? dcd_rt
   // 		   : `R_RA;

   // assign rd_data = (ctrl_Link == 1'b1) ? nextpc :
   // 		    (ctrl_RegSrc == `CTRL_REGSRC_ALU) ? alu_out :
   // 		    (ctrl_MemSE == 1'b1) ? mem_read_data_se :
   // 		    mem_read_data;
   
   regfile Registers(//Outputs
		     .rs_data(rs_data),
		     .rt_data(rt_data),
		     //Inputs
		     .rs_num(rs_num),
		     .rt_num(dcd_rt),
		     .rd_num(rd_num),
		     .rd_data(rd_data),
		     .rd_we(rd_write),
		     .clk(clk),
		     .rst_b(rst_b),
		     .halted(halted));

   assign alu_in1 = (ctrl_ALUSrc1 == `ALU_SRC1_REG) ? rs_data : {26'b0, dcd_shamt};
   assign alu_in2 = (ctrl_ALUSrc2 == `ALU_SRC2_REG) ? rt_data :
		    (ctrl_ALUSrc2 == `ALU_SRC2_IMM) ? dcd_e_imm :
		    dcd_se_imm;
   		    
   // Execute
   mips_alu ALU(/*AUTOINST*/
		// Outputs
		.alu_out		(alu_out[31:0]),
		.alu_cmp		(alu_cmp[2:0]),
		// Inputs
		.alu_in1		(alu_in1[31:0]),
		.alu_in2		(alu_in2[31:0]),
		.alu_op			(alu_op[3:0]),
		.alu_alt		(alu_alt));


   mem_write_align MEM_WRITE_ALIGN(// Inputs
				   .data(rt_data), //data to write
				   .addr_lsb(alu_out[1:0]),
				   .size(ctrl_MemSize),
				   .en(ctrl_MemWrite),
				   //Outputs
				   .data_align(mem_write_word), // full word with properly aligned data
				   .mask(mem_mask),
				   .align_except(write_align_except));
	 
     
   mem_read_align MEM_READ_ALIGN(// Inputs
				 .data_align(mem_read_word), //full word from mem
				 .addr_lsb(read_lsb),
				 .size(read_size),
				 .en(mem_read),
				 //Outputs
				 .data(mem_read_data), //data shifted to lsb
				 .data_se(mem_read_data_se), //data shifted to lsb, sign extened
				 .align_except(read_align_except));
   
   
   // Miscellaneous stuff (Exceptions, syscalls, and halt)
   exception_unit EU(.exception_halt(exception_halt), .pc(pc), .rst_b(rst_b),
                     .clk(clk), .load_ex_regs(load_ex_regs),
                     .load_bva(load_bva), .load_bva_sel(load_bva_sel),
                     .cause(cause_code),
                     .IBE(inst_excpt),
                     .DBE(1'b0),
                     .RI(ctrl_RI),
                     .Ov(1'b0),
                     .BP(1'b0),
                     .AdEL_inst(pc[1:0]?1'b1:1'b0),
                     .AdEL_data(1'b0),
                     .AdES(1'b0),
                     .CpU(1'b0));

   syscall_unit SU(.syscall_halt(syscall_halt), .pc(pc), .clk(clk),
		   .Sys(ctrl_SysException), .r_v0(rs_data), .rst_b(rst_b));
   assign        internal_halt = exception_halt | syscall_halt | pipeline_stall;
   register #(1, 0) Halt(halted, internal_halt, clk, en, rst_b);
   register #(32, 0) EPCReg(epc, pc, clk, load_ex_regs, rst_b);
   register #(32, 0) CauseReg(cause,
                              {25'b0, cause_code, 2'b0}, 
                              clk, load_ex_regs, rst_b);
   register #(32, 0) BadVAddrReg(bad_v_addr, pc, clk, load_bva, rst_b);


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

