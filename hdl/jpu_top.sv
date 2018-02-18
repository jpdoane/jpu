// Top module for the JPU processor core
module jpu_top(/*AUTOARG*/
   // Outputs
   led, ledred, uart_rxd_out,
   // Inputs
   clk100MHz, btn, sw, uart_txd_in
   );
           
   input clk100MHz;
   input [3:0] btn, sw;
   output [3:0] led;
   output [3:0] ledred;
   output       uart_rxd_out;
   input 	uart_txd_in;


   logic        rst, rst_clk, clk, locked;
   logic [7:0] 	status_led;
   logic [7:0] [31:0]ila_probe;
   
   assign rst_clk = btn[0];
   assign rst = btn[1];
   assign led = status_led[3:0];
   assign ledred = status_led[7:4];

      
   jpu_impl jpu(// Outputs
		.status_led		(status_led),
		.uart_rxd_out		(uart_rxd_out),
		.ila_probe              (ila_probe),
		// Inputs
		.clk			(clk),
		.rst			(rst),
		.user_btn		(btn),
		.user_sw		(sw),
		.uart_txd_in		(uart_txd_in));

   ila_0 my_ila (
		 .clk(clk100MHz), // input wire clk
		 .probe0(ila_probe[0]), // input wire [31:0]  probe0  
		 .probe1(ila_probe[1]), // input wire [31:0]  probe1 
		 .probe2(ila_probe[2]), // input wire [31:0]  probe2 
		 .probe3(ila_probe[3]), // input wire [31:0]  probe3 
		 .probe4(ila_probe[4]), // input wire [31:0]  probe4 
		 .probe5(ila_probe[5]), // input wire [31:0]  probe5 
		 .probe6(ila_probe[6]), // input wire [31:0]  probe6 
		 .probe7(ila_probe[7]) // input wire [31:0]  probe7 
		 );

         
  clk_wiz_0 clk_top
     (
      // Clock out ports
      .clk(clk),     // output clk
      // Status and control signals
      .reset(rst_clk), // input reset
      .locked(locked),       // output locked
     // Clock in ports
      .clk100MHz(clk100MHz));      // input clk100MHz   
         
endmodule // jpu_top



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
