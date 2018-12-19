`include "risc-v.svh"
`include "jpu.svh"

import jpu::*
  
module tb_decode;
           
   logic [31:0]      inst;
   jpu::dcd_s dcd;
   
   decode decoder(/*AUTOINST*/
		  // Outputs
		  .dcd			(dcd),
		  // Inputs
		  .inst			(inst[31:0]));

   
   
   initial
     begin
	rst = 1;
	uart_tx_data = '0;
	uart_tx_valid = 1'b0;
	user_btn <= '0;
	#150;
	rst <= 0;

	@(posedge clk);
	@(posedge clk);

	for(int i=0;i<tx_string.len();i=i+1) begin	  
	   #100;
	   wait(uart_tx_ready);
	   @(posedge clk);
	   uart_tx_data[7:0] = tx_string[i];
	   $display("Sending: %c", tx_string[i]);
	   uart_tx_valid = 1'b1;
	   @(posedge clk);
	   uart_tx_valid = 1'b0;
	end

	// #1000	
	// //push button
	// @(posedge clk);
	// user_btn[3] <= 1'b1;
	// @(posedge clk);
	// user_btn[3] <= 1'b0;
	
     end

    always @(posedge clk) begin
	   if (!rst & uart_rx_valid)
    	   $display("Receiving: %c (%h)", uart_rx_data, uart_rx_data);	   
     end


//    reg tb_err;

//   initial
//     begin
//     tb_err = 0;
//	#500;
//	wait(uart_rx_valid);
//      assert (uart_rx_data=="A")
//          else tb_err = 1;
//	#500;
//	wait(uart_rx_valid);
//    assert(uart_rx_data=="B")
//          else tb_err = 1;
//	#500;
//	wait(uart_rx_valid);
//    assert(uart_rx_data=="p")
//          else tb_err = 1;
//	#500;
//	wait(uart_rx_valid);
//    assert(uart_rx_data=="q")
//          else tb_err = 1;
//    #500    

//    if(tb_err)    
//        $display("Error: Data Not Received Successfully");
//    else
//        $display("Data Transmitted Successfully!");

//    $finish;
//     end
     

   always @(halted)
     begin
	#0;
	if(halted === 1'b1)
	  $finish;
     end

   clock myclk(clk);

   
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
// verilog-library-directories:("..")
// End:
