`include "bus_if.sv"
`include "mmap_defines.vh"

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
      
   logic        halted;
   logic [7:0] 	interrupts;
   logic 	uart_rx_int, uart_tx_int;

   logic [31:0]  ila_core[5:0];
   logic [31:0]  ila_uart[1:0];   

   logic 	 btn_re, btn_fe, sw_re, sw_fe; //rising and falling edge signals
         
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
   
   // instantiate bus interfaces and devices
   bus_master_if bus_master_text();
   bus_master_if bus_master_data();

   bus_slave_if #(`TEXT_SEG_BASE, `TEXT_SEG_WIDTH) bus_text();
   bus_slave_if #(`KTEXT_SEG_BASE, `KTEXT_SEG_WIDTH) bus_ktext();
   bus_slave_if #(`DATA_SEG_BASE, `DATA_SEG_WIDTH) bus_data();
   bus_slave_if #(`HEAP_SEG_BASE, `HEAP_SEG_WIDTH) bus_heap();
   bus_slave_if #(`STACK_SEG_BASE, `STACK_SEG_WIDTH) bus_stack();
   bus_slave_if #(`KDATA_SEG_BASE, `KDATA_SEG_WIDTH) bus_kdata();
//   bus_slave_if #(`UART_SEG_BASE, `UART_SEG_WIDTH) bus_uart();

   ram_bus  #(`TEXT_INIT_FILE) ram_text( .bus(bus_text) );
   ram_bus  #(`KTEXT_INIT_FILE) ram_ktext( .bus(bus_ktext) );
   ram_bus  #(`DATA_INIT_FILE) ram_data( .bus(bus_data) );
   ram_bus  #(`HEAP_INIT_FILE) ram_heap( .bus(bus_heap) );
   ram_bus  #(`STACK_INIT_FILE) ram_stack( .bus(bus_stack) );
   ram_bus  #(`KDATA_INIT_FILE) ram_kdata( .bus(bus_kdata) );
   
   // uart_bus uart(.bus           (bus_uart), 
   // 		 .uart_rxd_out	(uart_rxd_out),
   // 		 .uart_txd_in	(uart_txd_in),
   // 		 .uart_rx_int   (uart_rx_int),
   // 		 .uart_tx_int   (uart_tx_int),
   // 		 .ila_probe     (ila_uart));


   bus_intercon #(.numSlaves(2)) instbus(.bus_master(bus_master_text),
					 .bus_slaves('{bus_text, bus_ktext}),
					 .clk(clk),
					 .rst(rst));
   
   bus_intercon #(.numSlaves(5)) databus(.bus_master(bus_master_data),
					 .bus_slaves('{bus_data, bus_heap, bus_stack, bus_kdata}),
					 .clk(clk),
					 .rst(rst));
   
   // cpu core
   core jpu_core( .bus_inst(bus_master_text),
		  .bus_data(bus_master_data),
		 // Outputs
		 .halted		(halted),
		 // Inputs
		 .clk			(clk),
		 .rst			(rst),
		 .interrupts            (interrupts),
		 .ila_probe             (ila_core));


   // physical buttens and switches
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
