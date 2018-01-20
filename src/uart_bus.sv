// JPD
// 12/9/17
// UART testbench 
// asynchronous RS-232
// for FTDI <-> Arty 7

`include "jpu_defines.vh"
`include "uart_defines.vh"
`include "mmap_defines.vh"
`include "bus.vh"

import bus::*;

module uart_bus(/*AUTOARG*/
   // Outputs
   uart_rxd_out, bus_o, ila_probe,
   // Inputs
   clk, rst, uart_txd_in, bus_i
   );

   parameter bus::slave_info_s slaveInfo = bus::slave_info('0,'0);
   localparam addr_width = $clog2(slaveInfo.words);
//   localparam addr_width = $clog2('hF);
   
   input       clk;
   input       rst;   
   output      uart_rxd_out;
   input       uart_txd_in;

   input       bus::m2s_s bus_i;
   output      bus::s2m_s bus_o;

   //ila_probes
   output [31:0] ila_probe[1:0];

   bus::s2m_s bus_o_reg;
   assign bus_o = bus_o_reg;

   wire        tx_fifo_empty, tx_fifo_full, tx_fifo_overflow;
   wire        rx_fifo_empty, rx_fifo_full, rx_fifo_overflow, rx_fifo_underflow;
   wire        rx_valid;
   wire        req,wea;
           
   wire [`WORD_SIZE-3:0] addr_wide;
   wire [addr_width-1:0] uart_addr;
   wire        addr_err;       
   wire        re, we;

   wire [`WORD_SIZE-1:0] write_mask;
   reg [`WORD_SIZE-1:0] uart_control, uart_divide, uart_status;
   wire [7:0] 		tx_data, rx_data;
   
   
   wire 		txd; // From tx of uart_tx.v
   wire 		rxd;
   wire [`UART_DATA_WIDTH-1:0] uart_rx_data;		// From rx of uart_rx.v
   wire 		       uart_tx_err;		// From rx of uart_rx.v
   wire 		       uart_rx_err;		// From rx of uart_rx.v
   wire 		       uart_rx_valid;		// From rx of uart_rx.v
   wire 		       uart_tx_ready;		// From tx of uart_tx.v

   wire 		       tx_active,rx_active;
   

   reg [`UART_DATA_WIDTH-1:0]  uart_tx_data;
   reg 			       uart_tx_valid;
   
   assign rxd = uart_txd_in; //our rx input is output from fdti tx
   assign uart_rxd_out = txd;  //fdti rx is output from our tx


   assign write_mask = {bus_i.sel[3], bus_i.sel[3], bus_i.sel[3], bus_i.sel[3],
			bus_i.sel[3], bus_i.sel[3], bus_i.sel[3], bus_i.sel[3],
			bus_i.sel[2], bus_i.sel[2], bus_i.sel[2], bus_i.sel[2],
			bus_i.sel[2], bus_i.sel[2], bus_i.sel[2], bus_i.sel[2],
			bus_i.sel[1], bus_i.sel[1], bus_i.sel[1], bus_i.sel[1],
			bus_i.sel[1], bus_i.sel[1], bus_i.sel[1], bus_i.sel[1],
			bus_i.sel[0], bus_i.sel[0], bus_i.sel[0], bus_i.sel[0],
			bus_i.sel[0], bus_i.sel[0], bus_i.sel[0], bus_i.sel[0]};


   
   uart_tx tx( // Outputs
	      .active			(tx_active),
	      .uart_tx_ready		(uart_tx_ready),
	      .txd			(txd),
	      // Inputs
	      .clk			(clk),
	      .rst			(rst),
	      .uart_divide		(uart_divide[`WORD_SIZE-1:0]),
	      .uart_tx_data		(uart_tx_data[`UART_DATA_WIDTH-1:0]),
	      .uart_tx_valid		(uart_tx_valid));
   
   uart_rx   rx(// Outputs
		.uart_rx_data		(uart_rx_data[`UART_DATA_WIDTH-1:0]),
		.uart_rx_valid		(uart_rx_valid),
		.uart_rx_err		(uart_rx_err),
		.active			(rx_active),
		// Inputs
		.clk			(clk),
		.rst			(rst),
		.rxd			(rxd),
		.uart_divide		(uart_divide[`WORD_SIZE-1:0]));

   assign bus_o_reg.stall = 0; // we can always respond on next clock
   assign uart_tx_err = 0; //no way to get tx err (yet)
   

   assign req = bus_i.cyc & bus_i.stb;
   assign wea = {4{bus_i.we}} & bus_i.sel;
   assign addr_err = (bus_i.addr >= slaveInfo.start && bus_i.addr < slaveInfo.top)?0:1;
   assign addr_wide = bus_i.addr - slaveInfo.start;
   assign uart_addr = addr_wide[addr_width-1:0];


   
   //update status and control regs
   //writes
   always @(posedge clk) begin
      if (rst) begin
	 uart_status <= 32'b0;
	 uart_control <= 32'b0;
	 uart_divide <= `UART_CLK_FREQ/`UART_DEFAULT_BAUDRATE;
//	 tx_data <= 0;
//	 we <= 0;
      end
      else begin
//	 tx_data <= 0;
//	 we <= 0;

	 uart_status <= uart_status;	 
	 uart_status[`UART_RX_ERROR_BIT] <= uart_status[`UART_RX_ERROR_BIT] | uart_rx_err;    
	 uart_status[`UART_RX_FIFO_OVERFLOW_BIT] <= uart_status[`UART_RX_FIFO_OVERFLOW_BIT] | rx_fifo_overflow;
	 uart_status[`UART_RX_FIFO_FULL_BIT] <= rx_fifo_full;
	 uart_status[`UART_RX_FIFO_EMPTY_BIT] <= rx_fifo_empty;
	 uart_status[`UART_TX_ERROR_BIT] <= uart_status[`UART_TX_ERROR_BIT] | uart_tx_err;    
	 uart_status[`UART_TX_FIFO_OVERFLOW_BIT] <= uart_status[`UART_TX_FIFO_OVERFLOW_BIT] | tx_fifo_overflow;
	 uart_status[`UART_TX_FIFO_FULL_BIT] <= tx_fifo_full;
	 uart_status[`UART_TX_FIFO_EMPTY_BIT] <= tx_fifo_empty;
	 uart_status[`UART_TX_ACTIVE_BIT] <= tx_active;
	 uart_status[`UART_RX_ACTIVE_BIT] <= rx_active;

	 uart_control <= uart_control;
	 uart_divide <= uart_divide;
	 if (bus_i.cyc && bus_i.stb && bus_i.we) begin
	    case(uart_addr)
	      `UART_STATUS_REG_WORD: uart_status
		<= ( write_mask & bus_i.data) |
		   (~write_mask & uart_status);
	      `UART_CTRL_REG_WORD: uart_control
		<= ( write_mask & bus_i.data) |
		   (~write_mask & uart_control);
	      `UART_DIVIDE_REG_WORD: uart_divide
		<= ( write_mask & bus_i.data) |
		   (~write_mask & uart_divide);
	      /*
	       * `UART_TX_PORT_WORD:
		begin
		   if(bus_i.sel[0]) begin
		      //trigger write to fifo
		      tx_data <= bus_i.data[7:0];
		      we <= 1;
		   end
		end
	       */
	    endcase // case (uart_addr)
	 end // if (bus_i.cyc && bus_i.stb && bus_i.we)
      end
   end

   assign we = ~addr_err && req && bus_i.we && (uart_addr == `UART_TX_PORT_WORD);
   assign tx_data = bus_i.data[7:0];
   assign re = ~addr_err && req && ~bus_i.we && (uart_addr == `UART_RX_PORT_WORD);
   
   
   //read regs
   always @(posedge clk)
     begin
	if(rst) begin
	   bus_o_reg.data <= `WORD_SIZE'h0;
	   bus_o_reg.ack <= 0;
	   bus_o_reg.err <= 0;
	end
	else begin
	   bus_o_reg.data <= `WORD_SIZE'h0;
	   bus_o_reg.ack <= 0;
	   bus_o_reg.err <= 0;
	   if (req) begin
	      if(addr_err)
		bus_o_reg.err <= 1;
	      else begin
		 bus_o_reg.ack <= 1;
		 // wrtites handled in other process
		 if (~bus_i.we) begin // read cmd
		    case(uart_addr)
		      `UART_STATUS_REG_WORD: bus_o_reg.data <= uart_status;
		      `UART_CTRL_REG_WORD: bus_o_reg.data <= uart_control;
		      `UART_DIVIDE_REG_WORD: bus_o_reg.data <= uart_divide;
		      `UART_RX_PORT_WORD:
			begin
			   //trigger read from fifo
			   //this actually reads off existing fifo output and then pops fifo
			   //this uses first word fall through feature of fifo
			   bus_o_reg.data[7:0] <= rx_data;
			   bus_o_reg.data[`UART_RX_VALID_BIT] <= rx_valid;
			end
		    endcase // case (uart_addr)
		 end
	      end // else: !if(addr_err)
	   end
	end // else: !if(rst)
     end // always @ (posedge clk)


   uart_fifo tx_fifo (
		      .clk(clk),              // input wire clk
		      .srst(rst),            // input wire srst
		      .din(tx_data),              // input wire [7 : 0] din
		      .wr_en(we),           // input wire wr_en
		      .rd_en(uart_tx_ready & ~tx_fifo_empty),          // input wire rd_en
		      .dout(uart_tx_data),            // output wire [7 : 0] dout
		      .full(tx_fifo_full),            // output wire full
		      .wr_ack(),        // output wire wr_ack
		      .overflow(tx_fifo_overflow),    // output wire overflow
		      .empty(tx_fifo_empty),          // output wire empty
		      .valid(uart_tx_valid),          // output wire valid
		      .underflow()  // output wire underflow
		      );

   uart_fifo rx_fifo (
		      .clk(clk),            // input wire clk
		      .srst(rst),          // input wire srst
		      .din(uart_rx_data),            // input wire [7 : 0] din
		      .wr_en(uart_rx_valid),        // input wire wr_en
		      .rd_en(re && ~rx_fifo_empty),        // input wire rd_en
		      .dout(rx_data),          // output wire [7 : 0] dout
		      .full(rx_fifo_full),          // output wire full
		      .wr_ack(),      // output wire wr_ack
		      .overflow(rx_fifo_overflow),  // output wire overflow
		      .empty(rx_fifo_empty),        // output wire empty
		      .valid(rx_valid),        // output wire valid
		      .underflow(rx_fifo_underflow)  // output wire underflow
		      );

   //from uart_rxk
   assign ila_probe[0][31] = rxd;
   assign ila_probe[0][30] = uart_rx_valid;
   assign ila_probe[0][29] = uart_rx_err;
   assign ila_probe[0][28:24] = '0;
   assign ila_probe[0][23:16] = uart_rx_data;
   //uart rx fifo
   assign ila_probe[0][15] = re;
   assign ila_probe[0][14] = rx_fifo_empty;
   assign ila_probe[0][13] = rx_fifo_full;
   assign ila_probe[0][12] = rx_fifo_overflow;
   assign ila_probe[0][11] = rx_fifo_underflow;
   assign ila_probe[0][10] = rx_valid;
   assign ila_probe[0][9:8] = '0;
   assign ila_probe[0][7:0] = rx_data;

   
   //to uart_tx
   assign ila_probe[1][31] = txd;
   assign ila_probe[1][29] = uart_tx_valid;
   assign ila_probe[1][30] = uart_tx_ready;
   assign ila_probe[1][28:24] = '0;
   assign ila_probe[1][23:16] = uart_tx_data;
   //uart tx fifo
   assign ila_probe[1][15] = we;
   assign ila_probe[1][14] = tx_fifo_empty;
   assign ila_probe[1][13] = tx_fifo_full;
   assign ila_probe[1][12] = tx_fifo_overflow;
   assign ila_probe[1][11:8] = '0;
   assign ila_probe[1][7:0] = tx_data;

   
endmodule // uart_loopback

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
