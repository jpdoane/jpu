// jpdoane
// 12/22/2017
// based on pipelined wishbone bus
// https://cdn.opencores.org/downloads/wbspec_b3.pdf

`include "bus_if.sv"

module bus_intercon(bus_master, bus_slaves,
		    /*AUTOARG*/
		    // Inputs
		    clk, rst
		    );

   parameter integer numSlaves = 1;

   // bus interfaces
   bus_master_if bus_master;
   bus_slave_if bus_slaves [numSlaves-1:0];

   input 	     clk,rst; 
   
   assign bus_master.clk = clk;
   assign bus_master.rst = rst;

   //need to define arrays to use in mux because systemverilog is an idiotic language
   // that doesn't let you index an array of interfaces in a mux for some reason
   logic [numSlaves-1:0] slave_onehot;
   logic [numSlaves-1:0] [`BUS_DATAWIDTH-1:0] data_s2m;
   logic [numSlaves-1:0] 		      slave_ack;
   logic [numSlaves-1:0] 		      slave_err;
   logic [numSlaves-1:0] 		      slave_stall;

   
   // register the master.cyc
   logic 		 cyc_reg;
   
   //connect master to all slaves, let slaves figure out if they are being addressed...
   genvar 		 i;
   for(i=0; i<numSlaves; i++)  begin
      assign bus_slaves[i].clk = clk;
      assign bus_slaves[i].rst = rst;
      assign bus_slaves[i].data_m2s = bus_master.data_m2s;
      assign bus_slaves[i].addr = bus_master.addr;
      assign bus_slaves[i].cyc = bus_master.cyc;
      assign bus_slaves[i].stb = bus_master.stb;
      assign bus_slaves[i].we = bus_master.we;
      assign bus_slaves[i].sel = bus_master.sel;

      // aggregate slave signals in array
      assign data_s2m[i] = bus_slaves[i].data_s2m;
      assign slave_ack[i] = bus_slaves[i].ack;
      assign slave_err[i] = bus_slaves[i].err;
      assign slave_stall[i] = bus_slaves[i].stall;
   end

   //populate array of slaves to drive mux
   //array is registered to allow for pipelined bus
   for(i=0; i<numSlaves; i++)  begin
      always @(posedge clk) begin
	 slave_onehot[i] <= bus_slaves[i].localSelect;
      end
	end
   
   
   // connect master to active slave
   // set error if addr does not match one (and only one) slave
   always @(*) begin
      bus_master.data_s2m = '0;
      bus_master.ack = 0;
      bus_master.err = cyc_reg; //if cyc was high, then error if no match to slave
      bus_master.stall = 0;

      for(int j=0; j<numSlaves; j++) begin
       	 if (slave_onehot == (1 << j)) begin
	    bus_master.data_s2m = data_s2m[j];
       	    bus_master.ack = slave_ack[j];
       	    bus_master.err = slave_err[j];
       	    bus_master.stall = slave_stall[j];
       	 end
      end
   end
   
   //register the slave for the pipelined ack
   always @(posedge clk) begin
      cyc_reg <= bus_master.cyc;
      if (rst) begin
	 cyc_reg <= 0;
      end
   end // always @ (posedge clk)
   
endmodule



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
