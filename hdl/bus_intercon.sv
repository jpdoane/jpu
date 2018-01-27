// jpdoane
// 12/22/2017
// based on pipelined wishbone bus
// https://cdn.opencores.org/downloads/wbspec_b3.pdf
`include "jpu.svh"
`include "mmap_defines.vh"
`include "bus.vh"

import bus::*;

module bus_intercon(/*AUTOARG*/
   // Outputs
   bus_master_in_o, bus_slave_in_o,
   // Inputs
   clk, rst, bus_master_out_i, bus_slave_out_i
   );

   parameter integer numMasters = 1;
   parameter integer numSlaves = 1;
   parameter bus::slave_info_s [numSlaves-1:0] slaveInfo = {bus::slave_info('0,'0)};

   //not sure why we need this, but using slaveInfo[i] returns an error...
   wire 	     bus::slave_info_s [numSlaves-1:0] slaveInfo2;
   assign slaveInfo2 = slaveInfo;
   
   
// localparam   wb_slave2master_s bus_busy = {32'b0, 0,0,1};   //send to master when blocked
   localparam   bus::s2m_s bus_error = '{data:'0, ack:0,err:1,stall:0};  //send to master on bad address
   localparam   bus::m2s_s null_slave = '{addr:'0, data:'0,cyc:0,stb:0,we:0,sel:'0}; // send to inactive slaves
   localparam   bus::s2m_s stall_master = '{data:'0, ack:0,err:0,stall:1};  //send to inactive masters
   localparam   bus::s2m_s null_master = '{data:'0, ack:0,err:0,stall:0};  //send to inactive masters
   
   input 	     clk,rst;
   
   // master signals
   output 	     bus::s2m_s [numMasters-1:0] bus_master_in_o;
   input 	     bus::m2s_s [numMasters-1:0] bus_master_out_i;
   bus::s2m_s [numMasters-1:0] bus_master_in_reg;
   assign bus_master_in_o=bus_master_in_reg;

   // slave signals
   input 	     bus::s2m_s [numSlaves-1:0] bus_slave_out_i;
   output 	     bus::m2s_s [numSlaves-1:0] bus_slave_in_o;
   bus::m2s_s [numSlaves-1:0] bus_slave_in_reg;
   assign bus_slave_in_o=bus_slave_in_reg;

   reg 	     addr_excpt;      

   reg [$clog2(numMasters):0] grantMaster;
   reg [$clog2(numSlaves):0]  activeSlave;
   reg [$clog2(numSlaves):0] 	activeSlave_pipe;
   wire 			activeCycle, activeReq;
   reg 				activeReq_pipe, addr_valid_pipe;
   
   reg  			addr_valid;   
   wire [`WORD_SIZE-3:0] 	bus_addr;
   
   reg [numMasters-1:0] 	request;
   wire [numMasters-1:0] 	mask_request;
   reg [numMasters-1:0] 	mask;
   
   //master arbitration

   //form request vector from masters that have cyc high
   always @(*)
     begin
	for(int i = 0; i < numMasters; i++) 
          request[i] = bus_master_out_i[i].cyc;
     end

   assign activeCycle = bus_master_out_i[grantMaster].cyc;   
   assign activeReq = activeCycle && bus_master_out_i[grantMaster].stb;   
   assign mask_request = mask & request;
   
   // round robin arbiter
   always @(posedge clk) begin
      if(rst) begin
	 grantMaster <= 0;
	 mask <= '1;
      end
      else begin
	 grantMaster <= grantMaster;  //assume stay with current master and mask
	 mask <= mask;
	 
	 if(~activeCycle) begin //bus is free, look for new requests
	    if (mask_request == '0) begin //no unmasked requests remain, reset mask
	       for(int i=numMasters; i>0; i--)  begin //count down, so lowest num is prioritiezed
		  if (request[i-1]) begin
		     grantMaster <= i-1;
		     mask <= '1; // reset mask
		  end
	       end
	    end
	    else begin
	       for(int i=numMasters; i>0; i--)  begin //count down, so lowest num is prioritiezed
		  if (mask_request[i-1]) begin
		     grantMaster <= i-1;
		  end
	       end
	       for(int i=0; i<=numMasters-1; i++)  begin //mask off lower masters
    		  mask[i]=(i<=grantMaster)?0:1;
	       end
	    end // else: !if(mask_request == '0)	    
	 end // if (~activeCycle)
      end // else: !if(rst)
   end

   assign bus_addr = bus_master_out_i[grantMaster].addr;
   
   //determine active slave
   always @(*) begin
      activeSlave = 0;
      addr_valid = 0;
      for(int i=0; i<numSlaves; i++)  begin
	 if (activeCycle && (bus_addr>=slaveInfo2[i].start ) && (bus_addr < slaveInfo2[i].top)) begin
	    addr_valid = 1;
	    activeSlave = i;
	 end
      end
   end

   //connect master->slave signals
   always @(*) begin
      for(int i=0; i<numSlaves; i++)  begin
	 if(activeCycle && (activeSlave==i) && addr_valid)
	    bus_slave_in_reg[i] = bus_master_out_i[grantMaster];
	 else
	    bus_slave_in_reg[i] = null_slave;
      end
   end
   
   //connect slave->master signals
   //return bus signals to master from slave that was addressed *last clock*
   always @(*) begin
      for(int i=0; i<numMasters; i++)  begin
	 if(grantMaster==i)
	   if(activeReq_pipe)
	     if(addr_valid_pipe)
	       bus_master_in_reg[i] =  bus_slave_out_i[activeSlave_pipe];
	     else
	       bus_master_in_reg[i] =  bus_error;	       
	   else
	     bus_master_in_reg[i] =  null_master;
	 else
	   bus_master_in_reg[i] = stall_master;
      end
   end
   
   //register the segment to track for the pipelined ack
   always @(posedge clk) begin
      if (rst) begin
	 activeSlave_pipe <= 0;
	 activeReq_pipe <= 0;
	 addr_valid_pipe <= 0;
      end
      else begin
	 activeSlave_pipe <= activeSlave;
	 activeReq_pipe <= activeReq;
	 addr_valid_pipe <= addr_valid;
      end
   end // always @ (posedge clk)
   
endmodule



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
