`include "mips_defines.vh"
`include "mmap_defines.vh"
`include "bus.vh"
`include "jpu.svh"

import bus::*;
import jpu::*;

module jpu_core(/*AUTOARG*/
   // Outputs
   halted, bus_master_inst_out, bus_master_data_out, ila_probe,
   // Inputs
   clk, rst_b, interrupts, bus_master_inst_in, bus_master_data_in
   );
   
   // Core Interface
   input         clk, rst_b;
   output        halted;
   input 	 [7:0] interrupts;
   input 	 bus::s2m_s bus_master_inst_in, bus_master_data_in;
   output 	 bus::m2s_s bus_master_inst_out, bus_master_data_out;
   output [31:0] ila_probe[5:0];

   // decode and control signals
   jpu::ctrl_s ctrl, ctrl_r1;
   jpu::dcd_s dcd, dcd_r1;
   
   // pc and flow signals
   logic 	rst, en0, en;
   logic 	bus_inst_valid, bus_inst_stall;
   logic [31:0] inst;
   logic [31:0] pc, pc_r1, nextpc, nextpcplus4;
   logic [29:0] addr_fetch;
   logic [31:0] addr_jump, addr_branch, addr_link;
   logic 	branch_en;
   logic 	stall, stalled; 

   // register data
   logic [31:0] rt_data, rs_data;
   logic [4:0] 	rd_num;
   logic [31:0] reg_write_data; 

   // memory signals
   logic 	mem_read_valid, bus_data_stall, mem_req;
   logic [29:0] mem_addr;
   logic [31:0] mem_read_word, mem_write_word;
   logic [3:0] 	mem_mask;
   logic [31:0] mem_read_data;
   logic [31:0] mem_read_data_se;

   // alu signals
   logic [31:0] alu_out, alu_out_r1;
   logic [31:0] alu_in1, alu_in2;
   logic [2:0] 	alu_cmp;		// From ALU of mips_alu.v
   aluop_s 	 alu_op;			// From Decoder of mips_decode.v

   //cp0 
   exceptions_s excepts;
   logic 	 inst_bus_err, data_bus_err;
   logic         addr_load_err, addr_store_err; 	 
   logic 	 write_align_err, read_align_err;
   logic 	 raise_exception, eret;
   usermode_s 	 user_mode; 	 
   logic [31:0]  cp0_data_out, cp0_data_r1;   
   logic [31:0]  epc, vaddr;   
   
   //reset and enables...
   always @(posedge clk) begin
      rst <= ~rst_b;
      en0 <= rst_b;			  // pre-enable (arms fetch on 1st inst)
      en <= en0;			  // cpu enable
   end

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

   assign stall = bus_inst_stall | bus_data_stall | raise_exception | eret;  //temporary stall due to bus latency

   always @(posedge clk) begin
      if (rst) begin
	 pc <= '0;
	 nextpc <= `BOOTSTRAP_START;
	 addr_link <= '0;
	 stalled <= 1'b0;
      end
      else begin
	 if( en0 & ~en) begin
	    //about to go live...
	    pc <= nextpc;
	    nextpc <= nextpcplus4;
	    addr_link <= nextpcplus4;
	    stalled <= 1'b0;
	 end
	 else if (stall | ~en) begin
	    pc <= pc;
	    nextpc <= (eret) ? cp0_data_out :
		      (raise_exception) ? `EXCEPT_HANDLER :
		       nextpc;
	    addr_link <= addr_link;
	    stalled <= 1'b1;
	 end
	 else begin
	    pc <= nextpc;
	    nextpc <= (ctrl.j == 1'b1) ? addr_jump :
		      (branch_en == 1'b1) ? addr_branch :
		      nextpcplus4;
	    addr_link <= nextpcplus4;
	    stalled <= 1'b0;
	 end
      end // else: !if(rst)
   end // always @ (posedge clk)

   assign addr_fetch = nextpc[31:2]; //always fetch word aligned nextpc
   assign nextpcplus4 = nextpc + 4;
   assign addr_jump = (dcd.op == 6'h0) ? rs_data : {pc[31:28], dcd.target, 2'b0};
   assign addr_branch = nextpc + dcd.br_offset; //branch offset is relative to branch delay slot
   assign branch_en = ctrl.br && ( | (ctrl.br_cond & alu_cmp) );
   assign epc = (ctrl_r1.j | ctrl_r1.br) ? pc_r1 : pc;
   
   decode Decoder(/*AUTOINST*/
		  // Outputs
		  .ctrl			(ctrl),
		  .dcd			(dcd),
		  // Inputs
		  .inst			(inst[31:0]),
		  .en			(en));
   
   // data to write to register
   // piplelined to accomodate mem read delay
   assign reg_write_data = (ctrl_r1.reg_src == LINK) ? addr_link :
			   (ctrl_r1.reg_src == ALU) ? alu_out_r1 :
			   (ctrl_r1.reg_src == CP0) ? cp0_data_r1 :
			   (ctrl_r1.reg_src == MEM) ? mem_read_data :
			   (ctrl_r1.reg_src == MEM_SE) ? mem_read_data_se : '0;

   assign rd_num = (ctrl_r1.reg_dst==RD) ? dcd_r1.rd :
		   (ctrl_r1.reg_dst==RT) ? dcd_r1.rt :
		   (ctrl_r1.reg_dst==RA) ? `R_RA : '0;

   regfile Registers(//Outputs
		     .rs_data(rs_data),
		     .rt_data(rt_data),
		     //Inputs
		     .rs_num(dcd.rs),
		     .rt_num(dcd.rt),
		     .rd_num(rd_num),
		     .rd_data(reg_write_data),
		     .rd_we(en & ctrl_r1.reg_write),
//		     .rd_we(en & ctrl_r1.reg_write & ~stall),
		     .clk(clk),
		     .rst_b(rst_b),
		     .halted());

   // register decode and control signals for pipelined ops
   always @(posedge clk) begin
      if (rst) begin
	 cp0_data_r1 <= '0;
	 ctrl_r1 <= '0;
	 dcd_r1 <= '0;
	 alu_out_r1 <= '0;
	 pc_r1 <= '0;
      end
      else begin
	 if (stall) begin
	    cp0_data_r1 <= cp0_data_r1;
	    ctrl_r1 <= ctrl_r1;
	    dcd_r1 <= dcd_r1;
	    alu_out_r1 <= alu_out_r1;
	    pc_r1 <= pc_r1;
	 end	 
	 else begin
	    cp0_data_r1 <= cp0_data_out;
	    ctrl_r1 <= ctrl;
	    dcd_r1 <= dcd;
	    alu_out_r1 <= alu_out;
	    pc_r1 <= pc;
	 end // else: !ifinternal_halt
      end // else: !if(rst)
   end // always @ (posedge clk)

   // ****************************
   // ALU
   //   
   assign alu_in1 = (ctrl.alu_src1 == REG1) ? rs_data : {26'b0, dcd.shamt};
   assign alu_in2 = (ctrl.alu_src2 == REG2) ? rt_data :
		    (ctrl.alu_src2 == IMM) ? dcd.imm_ze :
		    dcd.imm_se;   		    
   // Execute
   mips_alu ALU(// Outputs
		.alu_out		(alu_out[31:0]),
		.alu_cmp		(alu_cmp[2:0]),
		// Inputs
		.alu_in1		(alu_in1[31:0]),
		.alu_in2		(alu_in2[31:0]),
		.alu_op			(ctrl.alu_op));


   // ****************************
   // Memory Management
   //
   assign mem_req = en & (ctrl.mem_write | ctrl.mem_read);
   assign mem_addr = alu_out[31:2];

   bus_master bus_inst_master(// Outputs
			      .data_o		(inst),
			      .valid_o		(bus_inst_valid),
			      .stall_o		(bus_inst_stall),
			      .err_o		(inst_bus_err),
			      .bus_o		(bus_master_inst_out),
			      // Inputs
			      .clk		(clk),
			      .rst		(rst),
			      .en_i		(en0), // enable early to prefetch instruction
			      .we_i		('0),
			      .data_i		('0),
			      .addr_i		(addr_fetch),
			      .byte_mask_i	('1),
			      .user_mode        (user_mode),
			      .bus_i		(bus_master_inst_in));


   mem_write_align MEM_WRITE_ALIGN(// Inputs
				   .data(rt_data), //data to write
				   .addr_lsb(alu_out[1:0]),
				   .size(ctrl.mem_size),
				   .en(ctrl.mem_write),
				   //Outputs
				   .data_align(mem_write_word), // full word with properly aligned data
				   .mask(mem_mask),
				   .align_except(write_align_err));

   
   bus_master bus_data_master( // Outputs
			       .data_o		(mem_read_word),
			       .valid_o		(mem_read_valid),
			       .stall_o		(bus_data_stall),
			       .err_o		(data_bus_err),
			       .bus_o		(bus_master_data_out),
			       // Inputs
			       .clk		(clk),
			       .rst		(rst),
			       .en_i		(en & mem_req),
			       .we_i		(ctrl.mem_write),
			       .data_i		(mem_write_word),
			       .addr_i		(mem_addr),
			       .byte_mask_i	(mem_mask),
 			       .user_mode        (user_mode),
			       .bus_i		(bus_master_data_in));
   
   
   mem_read_align MEM_READ_ALIGN(// Inputs
				 .data_align(mem_read_word), //full word from mem
				 .addr_lsb(alu_out_r1[1:0]),
				 .size(ctrl_r1.mem_size),
				 .en(ctrl_r1.mem_read),
				 //Outputs
				 .data(mem_read_data), //data shifted to lsb
				 .data_se(mem_read_data_se), //data shifted to lsb, sign extened
				 .align_except(read_align_err));

   //coproc 0 interrupts and exceptions
   always @(*) begin
      excepts 	    = '0; // set unimplemented excepts to zero
      excepts.RI    = ctrl.inst_except;
      excepts.Sys   = ctrl.sys_except;
      excepts.IBE   = inst_bus_err;
      excepts.DBE   = data_bus_err;
      excepts.AdEL  = read_align_err;
      excepts.AdES  = write_align_err;
      excepts.CpU   = ((user_mode==USER) && (ctrl.cp0_op != CP0NOP)) ? 1'b1 : 1'b0;
      vaddr 	    = inst_bus_err ? pc :
		      write_align_err ? alu_out :
		      read_align_err | data_bus_err ? alu_out_r1 :
		      '0;
   end // always @ (*)
   
   cp0 CP0(// Outputs
	   .cp0_data_out		(cp0_data_out),
	   .raise_exception		(raise_exception),
	   .eret                        (eret),
	   .user_mode (user_mode),
	   // Inputs
	   .clk				(clk),
	   .rst				(rst),
	   .en                          (en),
	   .stalled                     (stalled),
	   .epc				(epc[31:0]),
	   .vaddr			(vaddr[31:0]),
	   .ints_in			(interrupts[7:0]),
	   .excepts			(excepts),
	   .cp0_op			(ctrl.cp0_op),
	   .cp0_data_in			(rt_data),
	   .cp0_reg			(dcd.rd));

   //ila probes
   assign  ila_probe[0] = pc;
   assign  ila_probe[1] = nextpc;
   assign  ila_probe[2] = cp0_data_out;   
   assign  ila_probe[3][0] = ctrl.j;   
   assign  ila_probe[3][1] = ctrl.br;   
   assign  ila_probe[3][2] = branch_en;   
   assign  ila_probe[3][3] = stall;
   assign  ila_probe[3][31:4] = '0;   
   assign  ila_probe[4][10:0] = excepts;
   assign  ila_probe[4][18:11] = interrupts;
   assign  ila_probe[5][25:0] = ctrl;   
   assign  ila_probe[5][26] = stall;
   assign  ila_probe[5][27] = branch_en;
   assign  ila_probe[5][28] = eret;
   assign  ila_probe[5][29] = raise_exception;
   assign  ila_probe[5][30] = en;
   assign  ila_probe[5][31] = rst;
   
endmodule // jpu_core


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:

