`include "bus.vh"
import bus::*;

module tb_uart;

   wire        clk;
   reg 	       rst;
   wire         mem_excpt, halted;

   // The clock
   clock CLK(clk);

   
   localparam numMasters = 1;
   localparam numSlaves = 1;

   //note that order for initialization is N-1 -> 0
   localparam bus::slave_info_s slaveInfo = bus::slave_info('h100<<2, 'hF);
   

   wire        bus::s2m_s bus_master_in;
   wire        bus::m2s_s bus_master_out;

   wire        bus::m2s_s bus_slave_in;
   wire        bus::s2m_s bus_slave_out;

   wire        uart_rxd_out, uart_txd_in;

   reg [29:0] addr;
   reg [31:0] data;
   reg        cyc,stb,we;
   reg [3:0] 	sel;

   parameter numbytes = 32;   
   reg [7:0] 	data_wr [numbytes-1:0];
   reg [7:0] 	data_re;
 	


   parameter uartdivide = 32;
   parameter waitclocks = numbytes*uartdivide*(8+2);
   
   assign bus_master_out.addr = addr;
   assign bus_master_out.data = data;
   assign bus_master_out.cyc = cyc;
   assign bus_master_out.stb = stb;
   assign bus_master_out.we = we;
   assign bus_master_out.sel = sel;
   

   assign uart_txd_in = uart_rxd_out;  //loopback uart ports
      
   uart_bus  #(.slaveInfo(slaveInfo)) uart(// Outputs
	.uart_rxd_out		(uart_rxd_out),
	.bus_o			(bus_slave_out),
	// Inputs
	.clk			(clk),
	.rst			(rst),
	.uart_txd_in		(uart_txd_in),
	.bus_i			(bus_slave_in));   

   // set up data bus      
   bus_intercon #(.numMasters(numMasters), .numSlaves(numSlaves), .slaveInfo(slaveInfo))
   databus( // Outputs
	    .bus_master_in_o	(bus_master_in),
	    .bus_slave_in_o	(bus_slave_in),
	    .addr_excpt	(mem_excpt),
	    // Inputs
	    .clk		(clk),
	    .rst		(rst),
	    .bus_master_out_i	(bus_master_out),
	    .bus_slave_out_i	(bus_slave_out));
   
   initial
     begin
	rst = 1;
	addr = '0;
	cyc = 0;
	stb = 0;
	we = 0;	
	sel = '1;	
	data = '0;

	for(int i=0;i<numbytes;i++) begin
	   //init random  data
	    data_wr[i] = $urandom;
	end

	#100;
	rst <= 0;
	@(negedge clk)
	  //set divider
	addr = 'h102; //divide
	cyc = 1;
	stb = 1;
	we = 1;	
	data = uartdivide;
	@(negedge clk)
	assert (bus_master_in.ack == 1);
	addr = 'h104; //tx port

	for(int i=0;i<numbytes;i++) begin
	   //write data
	   data[7:0] = data_wr[i];
	   $display("Writing byte[%d]: %h", i, data[7:0]) ;
	   @(negedge clk)
	     assert (bus_master_in.ack == 1);
	end
	
	stb = 0;
	we = 0;	
	cyc = 0;

	//wait for uart 
	for(int i=0;i<waitclocks;i++) begin
	   @(negedge clk);
	end
	
	  //read data
	addr = 'h103; //rx port
	cyc = 1;
	stb = 1;
	we = 0;

	for(int i=0;i<numbytes;i++) begin
	   //read data
	   @(negedge clk)
	     data_re = bus_master_in.data[7:0];
	     $display("Reading byte[%d]: %h", i, data_re) ;
	     assert (bus_master_in.ack == 1);
	   assert (bus_master_in.data[31] == 1);
	   assert (data_re == data_wr[i]);
	end

	cyc = 0;
	stb = 0;
	
	$finish;
	
     end

   

   
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
