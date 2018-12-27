`include "bus_if.sv"

module bus_master(bus,
   /*AUTOARG*/
   // Outputs
   data_o, valid_o, stall_o, err_o,
   // Inputs
   en_i, we_i, data_i, addr_i, byte_mask_i
   );
   
   bus_master_if bus;
   
   input logic en_i, we_i;
   input logic [31:0] data_i;
   input logic [29:0] addr_i;
   input logic [3:0]  byte_mask_i;   
   output logic [31:0] data_o;
   output logic        valid_o, stall_o, err_o;
      
   logic 	       active_req, active_read;

   logic clk, rst;

   assign clk = bus.clk;
   assign rst = bus.rst;
      
   always @(posedge clk) begin
      if(rst) begin
	 active_req <= 0;
	 active_read <= 0;
      end
      else begin
	 active_req <= en_i | (active_req & bus.stall);
	 active_read <= (en_i & ~we_i) | (active_read & bus.stall);
      end
   end
     
   assign bus.cyc = en_i | active_req;
   assign bus.stb = en_i;
   assign bus.we = en_i & we_i;
   assign bus.sel = byte_mask_i;
   assign bus.data_m2s = data_i;
   assign bus.addr = addr_i;
         
   assign data_o = bus.data_s2m;
   assign valid_o = active_read && bus.ack && ~bus.err;
   assign stall_o = bus.stall;
   assign err_o = bus.err || (active_req & ~(bus.stall | bus.ack));

endmodule // bus_master

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:
