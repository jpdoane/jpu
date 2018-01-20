// jpdoane
// 12/22/2017
// based on pipelined wishbone bus
// https://cdn.opencores.org/downloads/wbspec_b3.pdf
`include "jpu_debug.vh"
`include "mmap_defines.vh"
`include "bus.vh"

import bus::*;

module ram_dualport_bus(/*AUTOARG*/
   // Outputs
   bus1_o, bus2_o,
   // Inputs
   clk, rst, ram_rst, bus1_i, bus2_i
   );

   parameter initfile="mem.dat";
   parameter bus::slave_info_s slaveInfo = bus::slave_info('0,'h1000);
   
   localparam addr_width = $clog2(slaveInfo.words);
//   localparam addr_width = $clog2('h1000);
           
   input  clk, rst, ram_rst;   
   input  bus::m2s_s bus1_i, bus2_i;
   output bus::s2m_s bus1_o, bus2_o;
   bus::s2m_s bus1_o_reg,bus2_o_reg;
   assign bus1_o = bus1_o_reg;
   assign bus2_o = bus2_o_reg;

   wire [`WORD_SIZE-3:0] addr_wide1, addr_wide2;
   wire [addr_width-1:0] ram_addr1, ram_addr2;
   wire 		 addr_err1, addr_err2;
   wire 		 req1, req2;
   wire [3:0]		 we1, we2;
   
   assign req1 = bus1_i.cyc & bus1_i.stb;
   assign req2 = bus2_i.cyc & bus2_i.stb;
   assign we1 = {4{bus1_i.we}} & bus1_i.sel;
   assign we2 = {4{bus2_i.we}} & bus2_i.sel;
      
   //port 1

   assign addr_err1 = (bus1_i.addr >= slaveInfo.start && bus1_i.addr < slaveInfo.top)?0:1;
   assign addr_wide1 = bus1_i.addr - slaveInfo.start;
   assign ram_addr1 = addr_wide1[addr_width-1:0];
   assign bus1_o_reg.stall = 0; // we can always respond on next clock

   always @(posedge clk)
     begin
	if(rst) begin
	   bus1_o_reg.ack <= 0;
	   bus1_o_reg.err <= 0;
	end
	else begin
	   bus1_o_reg.ack <= 0;
	   bus1_o_reg.err <= 0;
	   if (req1 & ~addr_err1) begin
	      if(addr_err1)
		bus1_o_reg.err <= 1;
	      else
		 bus1_o_reg.ack <= 1;
	   end
	end // else: !if(rst)
     end // always @ (posedge clk)

   //port 2

   assign addr_err2 = (bus2_i.addr >= slaveInfo.start && bus2_i.addr < slaveInfo.top)?0:1;
   assign addr_wide2 = bus2_i.addr - slaveInfo.start;
   assign ram_addr2 = addr_wide2[addr_width-1:0];
   assign bus2_o_reg.stall = 0; // we can always respond on next clock
   
   always @(posedge clk)
     begin
	if(rst) begin
	   bus2_o_reg.ack <= 0;
	   bus2_o_reg.err <= 0;
	end
	else begin
	   bus2_o_reg.ack <= 0;
	   bus2_o_reg.err <= 0;
	   if (req2 & ~addr_err2) begin
	      if(addr_err2)
		bus2_o_reg.err <= 1;
	      else
		 bus2_o_reg.ack <= 1;
	   end // if (bus2.cyc & bus2_i.stb & ~addr_err2)
	end // else: !if(rst)
     end // always @ (posedge clk)

  //  Xilinx True Dual Port RAM Byte Write Read First Single Clock RAM
   xilinx_true_dual_port_read_first_byte_write_1_clock_ram
     #(
       .NB_COL(4),                           // Specify number of columns (number of bytes)
       .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
       .RAM_DEPTH(slaveInfo.words),                     // Specify RAM depth (number of entries)
       .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
       .INIT_FILE(initfile)                        // Specify name/location of RAM initialization file if using one (leave blank if not)
       ) ram_dual (
		     .addra(ram_addr1),     // Address bus, width determined from RAM_DEPTH
		     .dina(bus1_i.data),       // RAM input data, width determined from NB_COL*COL_WIDTH
		     .clka(clk),       // Clock
		     .wea(we1 ),         // Byte-write enable, width determined from NB_COL
		     .ena(req1),         // RAM Enable, for additional power savings, disable port when not in use
		     .rsta(ram_rst),       // Output reset (does not affect memory contents)
		     .regcea('0),   // Output register enable
		     .douta(bus1_o_reg.data),      // RAM output data, width determined from NB_COL*COL_WIDTH
		     .addrb(ram_addr2),     // Address bus, width determined from RAM_DEPTH
		     .dinb(bus2_i.data),       // RAM input data, width determined from NB_COL*COL_WIDTH
		     .web(we2 ),         // Byte-write enable, width determined from NB_COL
		     .enb(req2),         // RAM Enable, for additional power savings, disable port when not in use
		     .rstb(ram_rst),       // Output reset (does not affect memory contents)
		     .regceb('0),   // Output register enable
		     .doutb(bus2_o_reg.data)      // RAM output data, width determined from NB_COL*COL_WIDTH
		   );

   
endmodule



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
