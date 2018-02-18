`include "bus.vh"
`include "mmap_defines.vh"

import bus::*;


// Top module for the MIPS processor core
module jpu_impl(/*AUTOARG*/
   // Outputs
   status_led, uart_rxd_out, ila_probe,
   // Inputs
   clk, rst, user_btn, user_sw, uart_txd_in
   );
           
   input clk, rst;
   input [3:0] user_btn;
   input [3:0] user_sw;
   output logic [7:0] status_led;
   output logic      uart_rxd_out;
   output logic [7:0] [31:0]ila_probe;
   input 	uart_txd_in;
      
   logic        halted, ram_rst, rst_b;
   logic [7:0] 	interrupts;
   logic 	uart_rx_int, uart_tx_int;

   logic [31:0]  ila_core[5:0];
   logic [31:0]  ila_uart[1:0];   

   logic 	 btn_re, btn_fe, sw_re, sw_fe; //rising and falling edge signals
   
   localparam numTextMasters = 1;
   localparam numTextSlaves = 2;
   localparam bus::slave_info_s [numTextSlaves-1:0]    //note that order for initialization is N-1 -> 0
     textSlaveInfo = '{bus::slave_info(`KTEXT_SEG_BASE, `KTEXT_SEG_WORDS),
		       bus::slave_info(`TEXT_SEG_BASE, `TEXT_SEG_WORDS)};

   localparam numDataMasters = 1;
   localparam numDataSlaves = 5;
   localparam bus::slave_info_s [numDataSlaves-1:0]     //note that order for initialization is N-1 -> 0
     dataSlaveInfo = '{bus::slave_info(`UART_SEG_BASE, `UART_SEG_WORDS),
		   bus::slave_info(`KDATA_SEG_BASE, `KDATA_SEG_WORDS),
		   bus::slave_info(`STACK_SEG_BASE, `STACK_SEG_WORDS),
		   bus::slave_info(`HEAP_SEG_BASE, `HEAP_SEG_WORDS),
		   bus::slave_info(`DATA_SEG_BASE, `DATA_SEG_WORDS)};
   
   bus::s2m_s bus_mastertext_in, bus_masterdata_in;
   bus::m2s_s bus_mastertext_out, bus_masterdata_out;

   bus::m2s_s [numDataSlaves-1:0] bus_dataslave_in;
   bus::s2m_s [numDataSlaves-1:0] bus_dataslave_out;
   bus::m2s_s [numTextSlaves-1:0] bus_textslave_in;
   bus::s2m_s [numTextSlaves-1:0] bus_textslave_out;
   
   assign ram_rst = rst;
   assign rst_b = ~rst;

   assign status_led[0] = !rst;
   assign status_led[1] = halted;
   assign status_led[7:2] = '0;

   assign interrupts[7] = 0; //timer
   assign interrupts[6] = uart_rx_int | uart_tx_int;
   assign interrupts[5] = btn_re | sw_re | sw_fe;
   assign interrupts[4:0] = 0;      

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
   
   // The MIPS core
   jpu_core core(// Outputs
		 .bus_master_inst_out	(bus_mastertext_out),
		 .bus_master_data_out	(bus_masterdata_out),
		 .halted		(halted),
		 // Inputs
		 .clk			(clk),
		 .rst_b			(rst_b),
		 .bus_master_inst_in	(bus_mastertext_in),
		 .bus_master_data_in	(bus_masterdata_in),
		 .interrupts            (interrupts),
		 .ila_probe             (ila_core));
   
   // instantiate devices on the bus
   ram_bus  #(.initfile(`TEXT_INIT_FILE), .slaveInfo(textSlaveInfo[0]))
   ram_text( // Outputs
	     .bus_o		(bus_textslave_out[0]),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_textslave_in[0]));

   ram_bus  #(.initfile(`KTEXT_INIT_FILE), .slaveInfo(textSlaveInfo[1]))
   ram_ktext( // Outputs
	     .bus_o		(bus_textslave_out[1]),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_textslave_in[1]));

   
   ram_bus  #(.initfile(`DATA_INIT_FILE), .slaveInfo(dataSlaveInfo[0]))
   ram_data (// Outputs
	     .bus_o		(bus_dataslave_out[0]),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_dataslave_in[0]));

   ram_bus  #(.initfile(`HEAP_INIT_FILE), .slaveInfo(dataSlaveInfo[1]))
   ram_heap (// Outputs
	     .bus_o		(bus_dataslave_out[1]),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_dataslave_in[1]));

   ram_bus  #(.initfile(`STACK_INIT_FILE), .slaveInfo(dataSlaveInfo[2]))
   ram_stack (// Outputs
	     .bus_o		(bus_dataslave_out[2]),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_dataslave_in[2]));

   ram_bus  #(.initfile(`KDATA_INIT_FILE), .slaveInfo(dataSlaveInfo[3]))
   ram_kdata (// Outputs
	     .bus_o		(bus_dataslave_out[3]),
	     // Inputs
	     .clk		(clk),
	     .rst		(rst),
	     .ram_rst		(ram_rst),
	     .bus_i		(bus_dataslave_in[3]));
   
   uart_bus #(.slaveInfo(dataSlaveInfo[4]))
     uart(// Outputs
	.uart_rxd_out		(uart_rxd_out),
	.bus_o			(bus_dataslave_out[4]),
	// Inputs
	.clk			(clk),
	.rst			(rst),
	.uart_txd_in		(uart_txd_in),
	.bus_i			(bus_dataslave_in[4]),
	.uart_rx_int               (uart_rx_int),
	.uart_tx_int               (uart_tx_int),
        .ila_probe              (ila_uart));

   // set up data bus      
   bus_intercon #(.numMasters(numDataMasters), .numSlaves(numDataSlaves), .slaveInfo(dataSlaveInfo))
   databus( // Outputs
	    .bus_master_in_o	(bus_masterdata_in),
	    .bus_slave_in_o	(bus_dataslave_in),
	    // Inputs
	    .clk		(clk),
	    .rst		(rst),
	    .bus_master_out_i	(bus_masterdata_out),
	    .bus_slave_out_i	(bus_dataslave_out));

   // set up instruction bus
   bus_intercon #(.numMasters(numTextMasters), .numSlaves(numTextSlaves), .slaveInfo(textSlaveInfo))
   instbus( // Outputs
	    .bus_master_in_o	(bus_mastertext_in),
	    .bus_slave_in_o	(bus_textslave_in),
	    // Inputs
	    .clk		(clk),
	    .rst		(rst),
	    .bus_master_out_i	(bus_mastertext_out),
	    .bus_slave_out_i	(bus_textslave_out));

   btn_edge #(4) arty_btns( // Outputs
		      .btn_re		(btn_re),
		      .btn_fe		(btn_fe),
		      // Inputs
		      .btn		(user_btn),
		      .clk		(clk),
		      .rst		(rst));

   btn_edge #(4) arty_sw( // Outputs
		    .btn_re		(sw_re),
		    .btn_fe		(sw_fe),
		    // Inputs
		    .btn		(user_sw),
		    .clk		(clk),
		    .rst		(rst));

      
endmodule // mips_top



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
