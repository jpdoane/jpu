// JPD
// 12/9/17
// UART testbench 
// asynchronous RS-232
// for FTDI <-> Arty 7

// based on pipelined wishbone bus
// https://cdn.opencores.org/downloads/wbspec_b3.pdf
`include "bus_if.sv"
`include "uart_defines.vh"
`include "mmap_defines.vh"

module uart_bus(  bus_if.slave bus, 
   /*AUTOARG*/
   // Outputs
   uart_rxd_out, uart_rx_int, uart_tx_int, ila_probe,
   // Inputs
   uart_txd_in
   );

   output      uart_rxd_out;
   input       uart_txd_in;

   output      uart_rx_int;
   output      uart_tx_int;

   //ila_probes
   output [31:0] ila_probe[1:0];
   
   logic 	     clk, rst;
   logic 		 req, en;
   logic [`BUS_SELWIDTH-1:0] 		 wea;

   wire        tx_fifo_empty, tx_fifo_full, tx_fifo_overflow;
   wire        rx_fifo_empty, rx_fifo_full, rx_fifo_overflow, rx_fifo_underflow;
   wire        rx_valid, tx_ready;

   wire [`WORD_SIZE-1:0] write_mask;
   reg [`WORD_SIZE-1:0]  uart_rx_control, uart_tx_control, uart_divide;
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


   assign clk = bus.clk;
   assign rst = bus.rst;   

   assign en = bus.localSelect & bus.stb;
   assign wea = {`BUS_SELWIDTH{bus.we}} & bus.sel;
   assign bus.stall = 0; // we can always respond on next clock

   assign rxd = uart_txd_in; //our rx input is output from fdti tx
   assign uart_rxd_out = txd;  //fdti rx is output from our tx

   assign write_mask = {bus.sel[3], bus.sel[3], bus.sel[3], bus.sel[3],
			bus.sel[3], bus.sel[3], bus.sel[3], bus.sel[3],
			bus.sel[2], bus.sel[2], bus.sel[2], bus.sel[2],
			bus.sel[2], bus.sel[2], bus.sel[2], bus.sel[2],
			bus.sel[1], bus.sel[1], bus.sel[1], bus.sel[1],
			bus.sel[1], bus.sel[1], bus.sel[1], bus.sel[1],
			bus.sel[0], bus.sel[0], bus.sel[0], bus.sel[0],
			bus.sel[0], bus.sel[0], bus.sel[0], bus.sel[0]};


   assign addr = bus.addr << 2;
   assign uart_rx_int = rx_valid & uart_rx_control[`UART_INT_ENABLE_BIT];
   assign uart_tx_int = tx_ready & uart_tx_control[`UART_INT_ENABLE_BIT];
      
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

   assign uart_tx_err = 0; //no way to get tx err (yet)
      
   //update status and control regs
   //writes
   always @(posedge clk) begin
      if (rst) begin
	 uart_tx_control <= 32'b0;
	 uart_rx_control <= 32'b0;
	 uart_divide <= `UART_CLK_FREQ/`UART_DEFAULT_BAUDRATE;
//	 tx_data <= 0;
//	 we <= 0;
      end
      else begin
//	 tx_data <= 0;
//	 we <= 0;

	 uart_tx_control <= uart_tx_control;
	 uart_tx_control[`UART_ERROR_BIT] <= uart_tx_control[`UART_ERROR_BIT] | uart_tx_err;
	 uart_tx_control[`UART_FIFO_OVERFLOW_BIT] <= uart_tx_control[`UART_FIFO_OVERFLOW_BIT] | tx_fifo_overflow;
	 uart_tx_control[`UART_FIFO_FULL_BIT] <= tx_fifo_full;
	 uart_tx_control[`UART_FIFO_EMPTY_BIT] <= tx_fifo_empty;    
	 uart_tx_control[`UART_ACTIVE_BIT] <= tx_active;    
	 uart_tx_control[`UART_READY_BIT] <= tx_ready;

	 uart_rx_control[`UART_ERROR_BIT] <= uart_rx_control[`UART_ERROR_BIT] | uart_rx_err;
	 uart_rx_control[`UART_FIFO_OVERFLOW_BIT] <= uart_rx_control[`UART_FIFO_OVERFLOW_BIT] | rx_fifo_overflow;
	 uart_rx_control[`UART_FIFO_FULL_BIT] <= rx_fifo_full;
	 uart_rx_control[`UART_FIFO_EMPTY_BIT] <= rx_fifo_empty;    
	 uart_rx_control[`UART_ACTIVE_BIT] <= rx_active;    
	 uart_rx_control[`UART_READY_BIT] <= rx_valid;
	 
	 uart_divide <= uart_divide;

	 if (bus.cyc && bus.stb && bus.we) begin
	    case(addr)
	      `UART_RX_CTRL: uart_rx_control
		<= ( write_mask & bus.data_m2s) |
		   (~write_mask & uart_rx_control);
	      `UART_TX_CTRL: uart_tx_control
		<= ( write_mask & bus.data_m2s) |
		   (~write_mask & uart_tx_control);
	      `UART_DIV: uart_divide
		<= ( write_mask & bus.data_m2s) |
		   (~write_mask & uart_divide);
	      /*
	       * `UART_TX_PORT_WORD:
		begin
		   if(bus.sel[0]) begin
		      //trigger write to fifo
		      tx_data <= bus.data_m2s[7:0];
		      we <= 1;
		   end
		end
	       */
	    endcase // case (uart_addr)
	 end // if (bus.cyc && bus.stb && bus.we)
      end
   end

   assign we = ~addr_err && req && bus.we && (addr == `UART_TX_DATA);
   assign tx_data = bus.data_m2s[7:0];
   assign re = ~addr_err && req && ~bus.we && (addr == `UART_RX_DATA);
   
   
   //read regs
   always @(posedge clk)
     begin
	if(rst) begin
	   bus.data_s2m <= `WORD_SIZE'h0;
	   bus.ack <= 0;
	   bus.err <= 0;
	end
	else begin
	   bus.data_s2m <= `WORD_SIZE'h0;
	   bus.ack <= 0;
	   bus.err <= 0;
	   if (req) begin
	      if(addr_err)
		bus.err <= 1;
	      else begin
		 bus.ack <= 1;
		 // wrtites handled in other process
		 if (~bus.we) begin // read cmd
		    case(addr)
		      `UART_RX_CTRL: bus.data_s2m <= uart_rx_control;
		      `UART_TX_CTRL: bus.data_s2m <= uart_tx_control;
		      `UART_DIV: bus.data_s2m <= uart_divide;
		      `UART_RX_DATA:
			begin
			   //trigger read from fifo
			   //this actually reads off existing fifo output and then pops fifo
			   //this uses first word fall through feature of fifo
			   bus.data_s2m[7:0] <= rx_data;
			   bus.data_s2m[`UART_RX_VALID_BIT] <= rx_valid;
			end
		    endcase // case (uart_addr)
		 end
	      end // else: !if(addr_err)
	   end
	end // else: !if(rst)
     end // always @ (posedge clk)

   assign tx_ready = ~tx_fifo_full;
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

   assign ila_probe[0] = uart_rx_control;
   assign ila_probe[1] = uart_tx_control;
   
endmodule // uart_loopback

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
