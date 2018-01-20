`include "jpu_debug.vh"
`include "bus.vh"
`include "mmap_defines.vh"

import bus::*;


// Top testbench module for the MIPS processor core
module tb_jpu_top;
           
   logic       uart_rxd_out;
   logic       uart_txd_in;
      
   logic        rst, rst_b, ram_rst;
   logic        clk;
   logic        halted;

   localparam numMasters = 1;
   localparam numSlaves = 3;

   assign uart_txd_in = uart_rxd_out;
      
   //note that order for initialization is N-1 -> 0
   localparam bus::slave_info_s [numSlaves-1:0]
     slaveInfo = '{bus::slave_info(`UART_SEG_BASE, `UART_SEG_WORDS),
		   bus::slave_info(`DATA_SEG_BASE, `DATA_SEG_WORDS),
		   bus::slave_info(`TEXT_SEG_BASE, `TEXT_SEG_WORDS)};


   bus::s2m_s bus_master_inst_in, bus_master_data_in;
   bus::m2s_s bus_master_inst_out, bus_master_data_out;

   bus::s2m_s bus_text_out, bus_data_out, bus_uart_out;
   bus::m2s_s bus_text_in, bus_data_in, bus_uart_in;

   bus::m2s_s bus_inst_in;
   bus::s2m_s bus_inst_out;
   
   bus::m2s_s [numSlaves-1:0] bus_slave_in;
   bus::s2m_s [numSlaves-1:0] bus_slave_out;

   assign bus_slave_out[0] = bus_text_out;
   assign bus_slave_out[1] = bus_data_out;
   assign bus_slave_out[2] = bus_uart_out;
   
   assign bus_text_in = bus_slave_in[0];
   assign bus_data_in = bus_slave_in[1];
   assign bus_uart_in = bus_slave_in[2];

   assign rst_b = ~rst;
   assign ram_rst = rst;

   // The MIPS core
   jpu_core core(// Outputs
		 .bus_master_inst_out	(bus_master_inst_out),
		 .bus_master_data_out	(bus_master_data_out),
		 .halted		(halted),
		 // Inputs
		 .clk			(clk),
		 .rst_b			(rst_b),
		 .bus_master_inst_in	(bus_master_inst_in),
		 .bus_master_data_in	(bus_master_data_in));

   // instantiate devices on the bus
   ram_dualport_bus #(.initfile("text.mem"), .slaveInfo(slaveInfo[0]))
   ram_text( // Outputs
	     .bus1_o		(bus_inst_out),
	     .bus2_o		(bus_text_out),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus1_i		(bus_inst_in),
	     .bus2_i		(bus_text_in));

   ram_bus  #(.initfile("data.mem"), .slaveInfo(slaveInfo[1]))
   ram_data (// Outputs
	     .bus_o		(bus_data_out),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_data_in));

   uart_bus  #(.slaveInfo(slaveInfo[2])) uart(// Outputs
	.uart_rxd_out		(uart_rxd_out),
	.bus_o			(bus_uart_out),
	// Inputs
	.clk			(clk),
	.rst			(rst),
	.uart_txd_in		(uart_txd_in),
	.bus_i			(bus_uart_in));   

   // set up data bus      
   bus_intercon #(.numMasters(numMasters), .numSlaves(numSlaves), .slaveInfo(slaveInfo))
   databus( // Outputs
	    .bus_master_in_o	(bus_master_data_in),
	    .bus_slave_in_o	(bus_slave_in),
	    // Inputs
	    .clk		(clk),
	    .rst		(rst),
	    .bus_master_out_i	(bus_master_data_out),
	    .bus_slave_out_i	(bus_slave_out));

   // set up instruction bus
   bus_intercon #(.numMasters(1), .numSlaves(1), .slaveInfo(slaveInfo[0]))
   instbus( // Outputs
	    .bus_master_in_o	(bus_master_inst_in),
	    .bus_slave_in_o	(bus_inst_in),
	    // Inputs
	    .clk		(clk),
	    .rst		(rst),
	    .bus_master_out_i	(bus_master_inst_out),
	    .bus_slave_out_i	(bus_inst_out));
         
   clock myclk(clk);

   initial
     begin
	rst = 1;
	#75;
	rst <= 0;
     end

   always @(halted)
     begin
	#0;
	if(halted === 1'b1)
	  $finish;
     end

   
endmodule


// Clock module for the MIPS core.  You may increase the clock period
// if your design requires it.
module clock(clockSignal);
   parameter start = 0, halfPeriod = 50;
   output    clockSignal;
   reg 	     clockSignal;
   
   initial
     clockSignal = start;
   
   always
     #halfPeriod clockSignal = ~clockSignal;
   
endmodule



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
