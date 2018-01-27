// JPD
// 12/9/17
// UART module
// asynchronous RS-232
// for FTDI <-> Arty 7
// currently assumes no parity, one stop bit
`include "uart_defines.vh"

module uart_rx(/*AUTOARG*/
   // Outputs
   uart_rx_data, uart_rx_valid, uart_rx_err, active,
   // Inputs
   clk, rst, rxd, uart_divide
   );
   
   input 	  clk, rst;
   input 	  rxd;
   input [`WORD_SIZE-1:0] uart_divide;  //baud rate = clk/clk_divide
   output reg [`UART_DATA_WIDTH-1:0] uart_rx_data;
   output reg 			     uart_rx_valid, uart_rx_err;
   output 			     active;
   

   localparam IDLE=0, START=1, DATA=2, STOP=3, ERROR=4, RESET=5;
   
   reg [2:0] 		       state;
   reg [2:0] 		       nextState;

   reg [`WORD_SIZE:0] clk_count;
   reg [$clog2(`UART_DATA_WIDTH):0]      bit_count;

   reg 				     rxd_last;
   reg 				     rxd_fe;
   reg [`UART_DATA_WIDTH-1:0] 	     data;

   wire [`WORD_SIZE-1:0] 	      period, half_period;
   
   `ifdef JPU_SIM
   assign period = `UART_DIVIDE_OVERRIDE_SIM;
   `else
   assign period = uart_divide;
   `endif

   assign half_period = period>>2;
   assign active = ~(state == IDLE && nextState==IDLE);   
      
   //output data
   always @(posedge clk) begin
      if(rst) begin
	 uart_rx_data <= 0;
	 uart_rx_valid <= 0;
	 uart_rx_err <= 0;
      end
      else begin
	 uart_rx_data <= 0;
	 uart_rx_valid <= 0;
	 uart_rx_err <= 0;
	 if(state==STOP && clk_count==half_period) begin
	    uart_rx_data <= data;
	    uart_rx_valid <= 1;
	 end
	 if(state == ERROR)
	   uart_rx_err <= 1;
      end // else: !if(rst)
   end
   
   
   //detect falling edge
   always @(posedge clk)
     begin
	if(rst)
	  begin
	     rxd_last <= 1;
	     rxd_fe <= 0;
	  end
	else
	  begin
	     rxd_last <= rxd;
	     rxd_fe <= ~rxd & rxd_last;
	  end
     end // always @ (posedge clk)

      
   //state machine
   always @(posedge clk)
     begin
	if (rst)
	  state <= RESET;
	else
	  state <= nextState;
     end

   always @(*) begin
      nextState = state;
      case (state)
	RESET: nextState = IDLE;
	IDLE: nextState = rxd_fe?START:IDLE;
	START: nextState = (clk_count==half_period-1 && rxd==1)?ERROR:  //framing error...
			   (clk_count==period-1)?DATA:START;
	DATA: nextState = (bit_count == `UART_DATA_WIDTH-1 && clk_count==period-1)?STOP:DATA;
	STOP: nextState = (clk_count==half_period && rxd==0)?ERROR:  //framing error...
			  (clk_count==half_period)?IDLE:STOP; //jump to idle early, so we don't miss next start bit
	ERROR: nextState = (clk_count==period<<2)?IDLE:ERROR; // wait for break then retun to idle
      endcase // case (state)
   end // always @ (*)

   //update counter
   always @(posedge clk)
     begin
	if (rst) begin
	   clk_count <= 0;
	end
	else begin
	   clk_count <= 0;
	   if ((state==START || state==DATA || state==STOP) && clk_count != period-1)
	     clk_count <= clk_count + 1;
	   else if (state == ERROR && rxd==1)
	     clk_count <= clk_count + 1;	   
	end // else: !if(rst)
     end // always @ (posedge clk)
   
   //update data bits
   //data never gets erased except on rst, just overwritten with new data...
   always @(posedge clk)
     begin
	if (rst) begin
	   data <= 0;
	   bit_count <= 0;	   
	end
	else begin
	   bit_count <= 0;
	   data <= data;
	   if (state==DATA) begin
	      bit_count <= bit_count;
	      data <= data;
	      if(clk_count == 0) begin
		 data <= data >> 1;
	      end      
	      else if (clk_count==half_period-1) begin
		 data[`UART_DATA_WIDTH-1] <= rxd;
	      end
	      else if(clk_count == period-1) begin
		 bit_count <= bit_count + 1;
	      end
	   end
	end // else: !if(rst)
     end // always @ (posedge clk)
   
   

endmodule // uart

