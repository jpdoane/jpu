`include "../uart_defines.vh"

// Top testbench module for the JPU processor
module tb_jpu_uart;
           
   logic        clk, rst;
   logic       uart_rxd_out, uart_txd_in;

   logic [`UART_DATA_WIDTH-1:0] uart_rx_data, uart_tx_data;	// From uart_recv of uart_rx.v
   logic			uart_rx_err;		// From uart_recv of uart_rx.v
   logic			uart_rx_valid;		// From uart_recv of uart_rx.v
   logic			uart_tx_ready;		// From uart_send of uart_tx.v
   logic			uart_tx_valid;		// From uart_send of uart_tx.v
   logic [`WORD_SIZE-1:0] uart_divide;		// From uart_send of uart_tx.v

   logic 		  halted;
   logic [7:0]		  status;
   logic [3:0]		  user_btn;
   logic [7:0] [31:0] 	  ila_probe;

   assign halted=status[1];
    		  
   jpu_impl jpu(// Outputs
		.status_led		(status),
		.uart_rxd_out		(uart_rxd_out),
		.ila_probe              (ila_probe),
		// Inputs
		.clk			(clk),
		.rst			(rst),
		.user_btn		(user_btn),
		.user_sw		('0),
		.uart_txd_in		(uart_txd_in));

   
   assign uart_divide = `UART_DIVIDE_OVERRIDE_SIM;
   
   uart_tx tb_uart_tx( // Outputs
		     .uart_tx_ready	(uart_tx_ready),
		     .txd		(uart_txd_in),
		     // Inputs
		     .clk		(clk),
		     .rst		(rst),
		     .uart_divide	(uart_divide[`WORD_SIZE-1:0]),
		     .uart_tx_data	(uart_tx_data[`UART_DATA_WIDTH-1:0]),
		     .uart_tx_valid	(uart_tx_valid));
   
   uart_rx tb_uart_rx( // Outputs
		     .uart_rx_data	(uart_rx_data[`UART_DATA_WIDTH-1:0]),
		     .uart_rx_valid	(uart_rx_valid),
		     .uart_rx_err	(uart_rx_err),
		     // Inputs
		     .clk		(clk),
		     .rst		(rst),
		     .rxd		(uart_rxd_out),
		     .uart_divide	(uart_divide[`WORD_SIZE-1:0]));


   string 		  tx_string = "abcdefg";
   initial
     begin
	rst = 1;
	uart_tx_data = '0;
	uart_tx_valid = 1'b0;
	user_btn <= '0;
	#75;
	rst <= 0;


	#1000	
	//push button
	@(posedge clk);
	user_btn[3] <= 1'b1;
	#100000	
	@(posedge clk);
	user_btn[3] <= 1'b0;

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
// End:
