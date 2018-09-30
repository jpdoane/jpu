`include "bus.vh"

import bus::*;

module bus_master(/*AUTOARG*/
   // Outputs
   data_o, valid_o, stall_o, err_o, bus_o,
   // Inputs
   clk, rst, en_i, we_i, data_i, addr_i, byte_mask_i, user_mode,
   bus_i
   );
   
   input logic clk, rst;
   input logic en_i, we_i;
   input logic [31:0] data_i;
   input logic [29:0] addr_i;
   input logic [3:0]  byte_mask_i;   
   input 	      usermode_s user_mode; 	       
   output logic [31:0] data_o;
   output logic        valid_o, stall_o, err_o;
   input 	       bus::s2m_s bus_i;
   output 	       bus::m2s_s bus_o;
      
   logic 	       active_req, active_read;
   
   always @(posedge clk) begin
      if(rst) begin
	 active_req <= 0;
	 active_read <= 0;
      end
      else begin
	 active_req <= en_i | (active_req & bus_i.stall);
	 active_read <= (en_i & ~we_i) | (active_read & bus_i.stall);
      end
   end
     
   assign bus_o.cyc = en_i | active_req;
   assign bus_o.stb = en_i;
   assign bus_o.we = en_i & we_i;
   assign bus_o.sel = byte_mask_i;
   assign bus_o.data = data_i;
   assign bus_o.addr = addr_i;
         
   assign data_o = bus_i.data;
   assign valid_o = active_read && bus_i.ack && ~bus_i.err;
   assign stall_o = bus_i.stall;
   assign err_o = bus_i.err || (active_req & ~(bus_i.stall | bus_i.ack));

endmodule // bus_master

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:
