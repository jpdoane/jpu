`include "bus_if.sv"

module bus_tb;
           
   localparam [29:0] ram1_addr = 32'h12340000;
   localparam [29:0] ram2_addr = 32'habcd0000;

   localparam ram1_width = 5;
   localparam ram2_width = 6;
   
   logic clk, rst;

   //master signals
   logic en, we;
   logic [31:0] data_i;
   logic [31:0] addr;
   logic [3:0]  byte_mask;   
   logic [31:0] data_o;
   logic        valid, stall, err;

   
   clock #(0, 10) myclk(.clk);
   
   // instantiate bus interfaces and devices
   bus_master_if bus_master();

   bus_master master(.bus(bus_master),
		     // Outputs
		     .data_o		(data_o[31:0]),
		     .valid_o		(valid),
		     .stall_o		(stall),
		     .err_o		(err),
		     // Inputs
		     .en_i		(en),
		     .we_i		(we),
		     .data_i		(data_i[31:0]),
		     .addr_i		(addr[31:0]),
		     .byte_mask_i	(byte_mask[3:0]));
      
   bus_slave_if #(ram1_addr, ram1_width) bus_ram1();
   bus_slave_if #(ram2_addr, ram2_width) bus_ram2();

   ram_bus  ram1( .bus(bus_ram1) );
   ram_bus  ram2( .bus(bus_ram2) );
   

   bus_intercon #(.numSlaves(2)) bus(.bus_master(bus_master),
					 .bus_slaves('{bus_ram1, bus_ram2}),
					 .clk(clk),
					 .rst(rst));


   initial
     begin
	rst = 1;
	#15;
	rst = 0;
	byte_mask = 4'b1111;
	addr = 0;
	en = 0;
	we = 0;
	@(posedge clk);

	@(posedge clk);
	//#1
	//write to ram1[0]
	addr <= ram1_addr;
	data_i <= 32'hdeadbeef;
	en <= 1;
	we <= 1;
	

	@(posedge clk);
	//write to ram1[1]
	addr <= ram1_addr+4;
	data_i <= 32'h12345678;

	@(posedge clk);
	//write to msb of ram1[1]
	byte_mask = 4'b1000;
	addr <= ram1_addr+4;
	data_i <= 32'haa000000;
	@(posedge clk);

	//write to lsb of ram1[1]
	byte_mask = 4'b0001;
	addr <= ram1_addr+4;
	data_i <= 32'h000000bb;

	@(posedge clk);
	//#1
	//write to ram2[0]
	byte_mask = 4'b1111;
	addr <= ram2_addr;
	data_i <= 32'h87654321;

	@(posedge clk);
	//#1
	//write to ram2[1]
	addr <= ram2_addr+4;
	data_i <= 32'habcd1234;
	
	@(posedge clk);
	//#1
	//read from ram1[0]
	addr <= ram1_addr;
	data_i <= '0;
	we <= 0;

	@(posedge clk);
	//#1
	//read from ram1[1]
	addr <= ram1_addr+4;
	
	@(negedge clk);
	assert(valid && data_o == 32'hdeadbeef); //check ram1[0] data
			
	@(posedge clk);
	//#1
	//read from ram2[0]
	addr <= ram2_addr;

	@(negedge clk);
	assert(valid && data_o == 32'haa3456bb); //check ram1[1] data
	
	@(posedge clk);
	//read from ram2[1]
	addr <= ram2_addr+4;

	@(negedge clk);
	assert(valid && data_o == 32'h87654321); //check ram2[0] data

	@(posedge clk);

	@(negedge clk);
	assert(valid && data_o == 32'habcd1234); //check ram2[1] data

	@(posedge clk);
	//try address not word aligned
	addr <= ram1_addr+1;

	@(posedge clk);
	@(negedge clk);
	assert(~valid && err); //confirm addr err

	@(posedge clk);
	//try address out of range of slaves
	addr <= '0;

	@(posedge clk);
	@(negedge clk);
	assert(~valid && err); //confirm addr err


	
	$finish;
	  
     end
      
endmodule // mips_top


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "..")
// End:
