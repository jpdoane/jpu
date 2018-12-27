`include "mmap_defines.vh"
`include "decode_if.sv"
`include "bus_if.sv"

module core(
   bus_if.master bus_inst,
   bus_if.master bus_data,
   
   /*AUTOARG*/
   // Outputs
   halted, ila_probe,
   // Inputs
   clk, rst, interrupts
   );
   
   // Core Interface
   input         clk, rst;
   output        halted;
   input 	 [7:0] interrupts;
   output [31:0] ila_probe[5:0];


   
   // instruction
   logic [31:0] inst;

   // pc and flow signals
   logic 	en, boot, fetch, jump;
   logic [31:0] pc, nextpc, pcplus4;
   //logic 	stall, stalled; 

   // register signals
   logic [31:0] rs1_data, rs2_data, rd_data, wb_data; 	 
   logic [31:0] alu_in1, alu_in2, alu_out;
   logic [4:0]  rd;

   // other control signals
   logic 	ld, rd_we, cmp_result;
   
   // bus signals
   logic 	bus_inst_valid, bus_inst_stall, bus_inst_err;
   logic 	bus_data_valid, bus_data_stall, bus_data_err;

   // memory signals
   logic 	mem_en;
   logic 	mem_read_valid;
   logic [3:0] 	mem_write_mask;
   logic [31:0] mem_read_word, mem_write_word;
   logic [31:0] mem_data_rd;
   logic [2:0] 	mem_format;
   logic [1:0] 	mem_addr_lsb;
   logic 	write_align_err, read_align_err;

   logic [1:0]  priv_level;   
   assign priv_level = `RV_MODE_M; //hardwire as machine mode for now (full access)
 
   // control flow from reset
   // this assumes that we can fetch instruction and have it ready next cycle
   // will need more complex control flow if we add pipelining...   
   //
   // cycle   0    1    2    3    4
   // rst     1    0    0    0    0
   // fetch   0    0    1    1    1
   // en      0    0    0    1    1
   // boot    0    0    1    0    0
   // pc      0    0    0    BS   BS+4
   // nextpc  0    0    BS   BS+4 BS+8
   
   always @(posedge clk) begin      
      if (rst) begin
	 fetch <= 1'b0;
	 en <= 1'b0;
	 pc <= '0;
      end
      else begin
	 fetch <= 1'b1;
	 en <= fetch;
	 pc <= nextpc;
      end // else: !if(rst)
   end // always @ (posedge clk)

   assign boot = fetch & ~en;                     // first fetch after reset is boot
   assign pcplus4 = pc + 4;                       // subsequent instruction
   assign jump = dcd.j || (dcd.br && cmp_result);

   assign nextpc = ~fetch ? '0:                   
		   boot ? `BOOTSTRAP_ADDR :       
		   jump ? {alu_out[31:1], 1'b0} : // LSB of jump/branch calls is set to 0
		   pcplus4;                       

   decode_if dcd(.inst(inst));
   decode Decoder(.dif(dcd));

   // store reg data for write back rd on following cycle.  This allows cycle for memory read  
   always @(posedge clk) begin      
      if (~en) begin
	 wb_data <= '0;
	 rd <= '0;
	 ld <= 0;
	 rd_we <= '0;
	 mem_addr_lsb <= '0;
	 mem_format <= '0;
      end
      else begin
	 rd <= dcd.rd;
	 ld <= dcd.ld; // remember if we are doing a load...
	 rd_we <= dcd.alu_we || dcd.ld;
	 mem_format <= dcd.f3;
	 mem_addr_lsb <= alu_out[1:0];
	 if(dcd.j)
	   wb_data <= pcplus4; //all jumps are links, store pc+4
	 else
	   wb_data <= alu_out;
      end // else: !if(~en)
   end // always @ (posedge clk)

   // if last cycle is a load, write back data from mem, otherwise write back saved reg_data
   assign rd_data = ld ? mem_data_rd : wb_data;

   regfile Registers(// Outputs
		     .rs1_data		(rs1_data),
		     .rs2_data		(rs2_data),
		     // Inputs
		     .clk		(clk),
		     .rst		(rst),
		     .rs1		(dcd.rs1),
		     .rs2		(dcd.rs2),
		     .rd		(dcd.rd),
		     .rd_data		(rd_data),
		     .rd_we		(rd_we));
   
   cmp Comparitor(// Outputs
		  .cmp_result		(cmp_result),
		  // Inputs
		  .cmp_r1		(rs1_data),
		  .cmp_r2		(rs2_data),
		  .cmp_op               (dcd.f3));
   
   assign alu_in1 = dcd.alu_pc ? pc : rs1_data;
   assign alu_in2 = dcd.alu_imm ? dcd.imm : rs2_data;
   alu ALU( // Outputs
	    .alu_out			(alu_out),
	    // Inputs
	    .alu_in1			(alu_in1),
	    .alu_in2			(alu_in2),
	    .alu_op			(dcd.alu_op));
   

   // ****************************
   // Memory Management
   //
   assign mem_en = en & (dcd.ld | dcd.st);

   bus_master bus_inst_master( .bus(bus_inst),
			      // Outputs
			      .data_o		(inst),
			      .valid_o		(bus_inst_valid),
			      .stall_o		(bus_inst_stall),
			      .err_o		(bus_inst_err),
			      // Inputs
			      .en_i		(fetch),
			      .we_i		('0),
			      .data_i		('0),
			      .addr_i		(nextpc[31:2]),
			      .byte_mask_i	('1));

   bus_master bus_data_master( .bus(bus_data),
			      // Outputs
			       .data_o		(mem_read_word),
			       .valid_o		(bus_data_valid),
			       .stall_o		(bus_data_stall),
			       .err_o		(bus_data_err),
			       // Inputs
			       .en_i		(mem_en),
			       .we_i		(dcd.st),
			       .data_i		(mem_write_word),
			       .addr_i		(alu_out[31:2]),
			       .byte_mask_i	(mem_write_mask));

   
   //write align operates on same clock as decode, use dcd/alu signals
   mem_write_align MEM_WRITE_ALIGN(// Inputs
				   .data(rs2_data), //data to write
				   .addr_lsb(alu_out[1:0]),
				   .format(dcd.f3),
				   //Outputs
				   .data_align(mem_write_word), // full word with properly aligned data
				   .mask(mem_write_mask),
				   .align_except(write_align_err));
   
   
   //read align operates on next clock after decode, use registered signals
   mem_read_align MEM_READ_ALIGN(// Inputs
				 .data_align(mem_read_word), //full word from mem
				 .addr_lsb(mem_addr_lsb),
				 .format(mem_format),
				 //Outputs
				 .data(mem_data_rd), //byte/halfword shifted down
				 .align_except(read_align_err));

   // //coproc 0 interrupts and exceptions
   // always @(*) begin
   //    excepts 	    = '0; // set unimplemented excepts to zero
   //    excepts.RI    = ctrl.inst_except;
   //    excepts.Sys   = ctrl.sys_except;
   //    excepts.IBE   = inst_bus_err;
   //    excepts.DBE   = data_bus_err;
   //    excepts.AdEL  = read_align_err;
   //    excepts.AdES  = write_align_err;
   //    excepts.CpU   = ((user_mode==USER) && (ctrl.cp0_op != CP0NOP)) ? 1'b1 : 1'b0;
   //    vaddr 	    = inst_bus_err ? pc :
   // 		      write_align_err ? alu_out :
   // 		      read_align_err | data_bus_err ? alu_out_r1 :
   // 		      '0;
   // end // always @ (*)
   
   // //ila probes
   // assign  ila_probe[0] = pc;
   // assign  ila_probe[1] = nextpc;
   // assign  ila_probe[2] = cp0_data_out;   
   // assign  ila_probe[3][0] = ctrl.j;   
   // assign  ila_probe[3][1] = ctrl.br;   
   // assign  ila_probe[3][2] = branch_en;   
   // assign  ila_probe[3][3] = stall;
   // assign  ila_probe[3][31:4] = '0;   
   // assign  ila_probe[4][10:0] = excepts;
   // assign  ila_probe[4][18:11] = interrupts;
   // assign  ila_probe[5][25:0] = ctrl;   
   // assign  ila_probe[5][26] = stall;
   // assign  ila_probe[5][27] = branch_en;
   // assign  ila_probe[5][28] = eret;
   // assign  ila_probe[5][29] = raise_exception;
   // assign  ila_probe[5][30] = en;
   // assign  ila_probe[5][31] = rst;
   
endmodule // jpu_core


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:

