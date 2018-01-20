`include "jpu_debug.vh"
`include "bus.vh"
`include "mmap_defines.vh"

import bus::*;


// Top module for the MIPS processor core
module jpu_impl(/*AUTOARG*/
   // Outputs
   status_led, uart_rxd_out,
   // Inputs
   clk, rst, user_btn, user_sw, uart_txd_in
   );
           
   input clk, rst;
   input [3:0] user_btn;
   input [3:0] user_sw;
   output [7:0] status_led;
   output       uart_rxd_out;
   input 	uart_txd_in;
      
   logic        halted, rst_clk, ram_rst, rst_b;

   logic [31:0]  ila_core[5:0];
   logic [31:0]  ila_uart[1:0];   
   
   localparam numMasters = 1;
   localparam numSlaves = 5;
   
   //note that order for initialization is N-1 -> 0
   localparam bus::slave_info_s [numSlaves-1:0]
     slaveInfo = '{bus::slave_info(`UART_SEG_BASE, `UART_SEG_WORDS),
	//	   bus::slave_info(`KDATA_SEG_BASE, `KDATA_SEG_WORDS),
	//	   bus::slave_info(`KTEXT_SEG_BASE, `KTEXT_SEG_WORDS),
		   bus::slave_info(`STACK_SEG_BASE, `STACK_SEG_WORDS),
		   bus::slave_info(`HEAP_SEG_BASE, `HEAP_SEG_WORDS),
		   bus::slave_info(`DATA_SEG_BASE, `DATA_SEG_WORDS),
		   bus::slave_info(`TEXT_SEG_BASE, `TEXT_SEG_WORDS)};


   bus::s2m_s bus_master_inst_in, bus_master_data_in;
   bus::m2s_s bus_master_inst_out, bus_master_data_out;

   bus::s2m_s bus_text_out, bus_data_out, bus_heap_out, bus_stack_out, bus_uart_out;
   bus::m2s_s bus_text_in, bus_data_in, bus_heap_in, bus_stack_in, bus_uart_in;
   //bus::s2m_s bus_ktext_out, bus_kdata_out;
   //bus::m2s_s bus_ktext_in, bus_kdata_in;

   bus::m2s_s bus_inst_in;
   bus::s2m_s bus_inst_out;
   
   bus::m2s_s [numSlaves-1:0] bus_slave_in;
   bus::s2m_s [numSlaves-1:0] bus_slave_out;

   
   assign bus_slave_out[0] = bus_text_out;
   assign bus_slave_out[1] = bus_data_out;
   assign bus_slave_out[2] = bus_heap_out;
   assign bus_slave_out[3] = bus_stack_out;
//   assign bus_slave_out[4] = bus_ktext_out;
//   assign bus_slave_out[5] = bus_kdata_out;
   assign bus_slave_out[4] = bus_uart_out;
   
   assign bus_text_in = bus_slave_in[0];
   assign bus_data_in = bus_slave_in[1];
   assign bus_heap_in = bus_slave_in[2];
   assign bus_stack_in = bus_slave_in[3];
  // assign bus_ktext_in = bus_slave_in[4];
  // assign bus_kdata_in = bus_slave_in[5];
   assign bus_uart_in = bus_slave_in[4];


   assign rst_clk = !user_btn[1];
   assign ram_rst = rst;
   assign rst_b = ~rst;

   assign status_led[0] = !rst;
   assign status_led[1] = halted;
   assign status_led[7:2] = '0;

   

`ifndef JPU_SIM
  `TOP_DEBUG logic [31:0] ila_probe[7:0];

   always @(posedge clk) begin
      ila_probe[0] <= ila_core[0];
      ila_probe[1] <= ila_core[1];
      ila_probe[2] <= ila_core[2];
      ila_probe[3] <= ila_core[3];
      ila_probe[4] <= ila_core[4];
      ila_probe[5] <= ila_core[5];
      ila_probe[6] <= ila_uart[0];
      ila_probe[7] <= ila_uart[1];
   end // always @ (posedge clk)
`endif

   
   // The MIPS core
   jpu_core core(// Outputs
		 .bus_master_inst_out	(bus_master_inst_out),
		 .bus_master_data_out	(bus_master_data_out),
		 .halted		(halted),
		 // Inputs
		 .clk			(clk),
		 .rst_b			(rst_b),
		 .bus_master_inst_in	(bus_master_inst_in),
		 .bus_master_data_in	(bus_master_data_in),
		 .ila_probe             (ila_core));

   // instantiate devices on the bus
   ram_dualport_bus #(.initfile(`TEXT_INIT_FILE), .slaveInfo(slaveInfo[0]))
   ram_text( // Outputs
	     .bus1_o		(bus_inst_out),
	     .bus2_o		(bus_text_out),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus1_i		(bus_inst_in),
	     .bus2_i		(bus_text_in));

   ram_bus  #(.initfile(`DATA_INIT_FILE), .slaveInfo(slaveInfo[1]))
   ram_data (// Outputs
	     .bus_o		(bus_data_out),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_data_in));

   ram_bus  #(.initfile(`HEAP_INIT_FILE), .slaveInfo(slaveInfo[2]))
   ram_heap (// Outputs
	     .bus_o		(bus_heap_out),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_heap_in));

   ram_bus  #(.initfile(`STACK_INIT_FILE), .slaveInfo(slaveInfo[3]))
   ram_stack (// Outputs
	     .bus_o		(bus_stack_out),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_stack_in));
   
   uart_bus  #(.slaveInfo(slaveInfo[4])) uart(// Outputs
	.uart_rxd_out		(uart_rxd_out),
	.bus_o			(bus_uart_out),
	// Inputs
	.clk			(clk),
	.rst			(rst),
	.uart_txd_in		(uart_txd_in),
	.bus_i			(bus_uart_in),   
        .ila_probe             (ila_uart));

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

            

      
endmodule // mips_top



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
