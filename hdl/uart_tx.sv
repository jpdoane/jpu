// JPD
// 12/9/17
// UART module
// asynchronous RS-232
// for FTDI <-> Arty 7
`include "uart_defines.vh"

module uart_tx(/*AUTOARG*/
   // Outputs
   active, uart_tx_ready, txd,
   // Inputs
   clk, rst, uart_divide, uart_tx_data, uart_tx_valid
   );
   localparam IDLE=0, START=1, DATA=2, STOP=3, ERROR=4, RESET=5;
   
   input clk, rst;
   input [`WORD_SIZE-1:0] uart_divide;  //baud rate = clk/clk_divide
   input [`UART_DATA_WIDTH-1:0] uart_tx_data;
   input 		  uart_tx_valid;
   output 		  active; 		  
   output reg 		  uart_tx_ready;

   output reg 		  txd;
 		       
   reg [2:0] 		       state;
   reg [2:0] 		       nextState;

   reg [`WORD_SIZE:0] clk_count;
   reg [$clog2(`UART_DATA_WIDTH):0]      bit_count;

   reg [`UART_DATA_WIDTH-1:0] 	 data;
   wire [`WORD_SIZE-1:0] 	      period;

   `ifdef JPU_SIM
   assign period = `UART_DIVIDE_OVERRIDE_SIM;
   `else
   assign period = uart_divide;
   `endif
   
   // data register
   always @(posedge clk) begin
      if(rst) begin	 
	 data <= 0;
	 bit_count <= 0;
      end
      else begin
	 data <= data;
	 bit_count <= 0;
	 if (state==IDLE && uart_tx_valid)
	   data <= uart_tx_data;
	 else if (state==DATA) begin
	    if(clk_count == period-1) begin
	       bit_count <= bit_count + 1;
	       data <= data >> 1;
	    end
	    else begin
	       bit_count <= bit_count;
	    end	    
	 end
      end // else: !if(rst)      
   end

   assign uart_tx_ready = (state == IDLE)?1:0;
   assign active = ~(state == IDLE && nextState==IDLE);   
         
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
	IDLE: nextState = uart_tx_valid?START:IDLE;
	START: nextState = (clk_count==period-1)?DATA:START;
	DATA: nextState = (bit_count == `UART_DATA_WIDTH-1 && clk_count==period-1)?STOP:DATA;
	STOP: nextState = (clk_count==period-1)?IDLE:STOP;
	ERROR: nextState = IDLE; //not yet sure what might cause error...
      endcase // case (state)
   end // always @ (*)


   //update counters
   always @(posedge clk)
     begin
	if (rst) begin
	   clk_count <= 0;
	end
	else begin
	   clk_count <= 0;
	   if ((state==START || state==DATA || state==STOP) && clk_count != period-1)
	     clk_count <= clk_count + 1;
	end
     end // always @ (posedge clk)
      
   
   //set txd
   always @(posedge clk)
     begin
	if (rst) begin
	   txd <= 1;
	end
	else begin
	   txd <= 1;
	   if (state == START)
	     txd <= 0;
	   else if (state == DATA)
	     txd <= data[0];
	end // else: !if(rst)
     end // always @ (posedge clk)
      
endmodule // uart

