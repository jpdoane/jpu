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


   logic        rst, clk, locked;
   logic [7:0] 	status_led;
   
   assign rst = btn[0];
   assign led = status_led[3:0];
   assign ledred = status_led[7:4];

      
   jpu_impl jpu(// Outputs
		.status_led		(status_led),
		.uart_rxd_out		(uart_rxd_out),
		// Inputs
		.clk			(clk),
		.rst			(rst),
		.user_btn		(btn),
		.user_sw		(sw),
		.uart_txd_in		(uart_txd_in));
         
  clk_wiz_0 clk_top
     (
      // Clock out ports
      .clk(clk),     // output clk
      // Status and control signals
      .reset(rst), // input reset
      .locked(locked),       // output locked
     // Clock in ports
      .clk100MHz(clk100MHz));      // input clk100MHz   
         
endmodule // jpu_top



// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
