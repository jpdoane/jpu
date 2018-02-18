// jpdoane
// 12/22/2017
// based on pipelined wishbone bus
// https://cdn.opencores.org/downloads/wbspec_b3.pdf
`include "jpu_debug.vh"
`include "mmap_defines.vh"
`include "bus.vh"

import bus::*;

module ram_bus(/*AUTOARG*/
   // Outputs
   bus_o,
   // Inputs
   clk, rst, ram_rst, bus_i
   );

   parameter initfile="";
   parameter bus::slave_info_s slaveInfo = bus::slave_info('0,'h1000);
   
   localparam addr_width = $clog2(slaveInfo.words);
//   localparam addr_width = $clog2('h1000);

   input  clk, rst, ram_rst;   
   input  bus::m2s_s bus_i;
   output  bus::s2m_s bus_o;
   bus::s2m_s bus_o_reg;
   assign bus_o = bus_o_reg;
   
   wire [29:0] addr_wide;
   wire [addr_width-1:0] ram_addr;
   wire 		 addr_err;
   wire 		 req;
   wire [3:0] 		 wea;
      

   assign req = bus_i.cyc & bus_i.stb;
   assign wea = {4{bus_i.we}} & bus_i.sel;
   assign addr_err = (bus_i.addr >= slaveInfo.start && bus_i.addr < slaveInfo.top)?0:1;
   assign addr_wide = bus_i.addr - slaveInfo.start;
   assign ram_addr = addr_wide[addr_width-1:0];
   assign bus_o_reg.stall = 0; // we can always respond on next clock

   always @(posedge clk)
     begin
	if(rst) begin
	   bus_o_reg.ack <= 0;
	   bus_o_reg.err <= 0;
	end
	else begin
	   bus_o_reg.ack <= 0;
	   bus_o_reg.err <= 0;
	   if (req) begin
	      if(addr_err)
		bus_o_reg.err <= 1;
	      else begin
		 bus_o_reg.ack <= 1;
	      end // else: !if(addr_err)
	   end
	end // else: !if(rst)
     end // always @ (posedge clk)


   //  Xilinx Single Port Byte-Write Read First RAM
   xilinx_single_port_byte_write_ram_read_first
     #(
       .NB_COL(4),                           // Specify number of columns (number of bytes)
       .COL_WIDTH(8),                        // Specify column width (byte width, typically 8 or 9)
       .RAM_DEPTH(slaveInfo.words),                     // Specify RAM depth (number of entries)
       .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
       .INIT_FILE(initfile)                        // Specify name/location of RAM initialization file if using one (leave blank if not)
       ) ram_single (
		     .addra(ram_addr),     // Address bus, width determined from RAM_DEPTH
		     .dina(bus_i.data),       // RAM input data, width determined from NB_COL*COL_WIDTH
		     .clka(clk),       // Clock
		     .wea(wea ),         // Byte-write enable, width determined from NB_COL
		     .ena(req),         // RAM Enable, for additional power savings, disable port when not in use
		     .rsta(rst),       // Output reset (does not affect memory contents)
		     .regcea('0),   // Output register enable
		     .douta(bus_o_reg.data)      // RAM output data, width determined from NB_COL*COL_WIDTH
		     );


   
endmodule

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
