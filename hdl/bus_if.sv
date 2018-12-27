//data types for wishbone bus signals
`ifndef BUSIF_SV
`define BUSIF_SV

`define BUS_DATAWIDTH 32
`define BUS_ADDRWIDTH 32

`define BUS_BYTEWIDTH 8
`define BUS_SELWIDTH `BUS_DATAWIDTH/`BUS_BYTEWIDTH

interface bus_master_if;

   logic clk, rst;

   // master->slave signals
   logic [`BUS_ADDRWIDTH-1:0]       addr;
   logic [`BUS_DATAWIDTH-1:0] 	    data_m2s;
   logic 			    cyc,stb,we;
   logic [`BUS_SELWIDTH-1:0] 	    sel;

   // slave->master signals
   logic [`BUS_DATAWIDTH-1:0] 	    data_s2m;
   logic   			    ack,err,stall;

endinterface


interface bus_slave_if;

   // global base address of local addresses, addrWidth-1:0 assumed to be zero
   parameter [`BUS_ADDRWIDTH-1:0] baseAddr = '0; 

   //width of local address space
   parameter integer addrWidth = 0;

   //inputs
   logic clk, rst;

   // master->slave signals
   logic [`BUS_ADDRWIDTH-1:0]       addr;
   logic [`BUS_DATAWIDTH-1:0] 	    data_m2s;
   logic 			    cyc,stb,we;
   logic [`BUS_SELWIDTH-1:0] 	    sel;

   // slave->master signals
   logic [`BUS_DATAWIDTH-1:0] 	    data_s2m;
   logic  			    ack,err,stall;

   // slave address translation
   logic [addrWidth-1:0]  localAddr;
   logic [addrWidth-3:0]  localWordAddr;
   logic 			      localSelect;
   logic 			      wordAligned;
   
   assign localSelect = cyc && (addr[`BUS_ADDRWIDTH-1:addrWidth] == baseAddr[`BUS_ADDRWIDTH-1:addrWidth]);
   assign localAddr = addr[addrWidth-1:0];
   assign localWordAddr = addr[addrWidth-1:2];
   assign wordAligned = (localAddr[1:0] == 2'b00);   
endinterface

			       
// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:


`endif
