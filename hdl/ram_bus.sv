// jpdoane
// 12/22/2017
// based on pipelined wishbone bus
// https://cdn.opencores.org/downloads/wbspec_b3.pdf
`include "bus_if.sv"

module ram_bus( bus );

   parameter initfile="";

   bus_slave_if bus;

   //ram addressed by word
   localparam ramDepth = 1 << $bits(bus.localWordAddr);
	   
   logic 		      clk,rst,en, req, validReq, err;
   logic [`BUS_SELWIDTH-1:0]  wea;

   assign clk = bus.clk;
   assign rst = bus.rst;
   

   assign req = bus.localSelect & bus.stb;  //localSelect == master.cyc if address matches, 0 otherwise
   assign validReq = req && bus.wordAligned; //invalid if not word aligned
   assign err = req && ~validReq;
   assign en = validReq || bus.ack; // hold ram enable through ack
   assign wea = {`BUS_SELWIDTH{bus.we && req}} & bus.sel;

   assign bus.stall = 0; // we can always respond on next clock
   
   always @(posedge clk)
     begin
	bus.ack <= validReq;
	bus.err <= err;
	if(rst) begin
	   bus.ack <= 0;
	   bus.err <= 0;
	end
     end // always @ (posedge clk)

   //  Xilinx Single Port Byte-Write Read First RAM
   xilinx_single_port_byte_write_ram_read_first
     #(
       .NB_COL(`BUS_SELWIDTH),               // Specify number of columns (number of bytes)
       .COL_WIDTH(`BUS_BYTEWIDTH),           // Specify column width (byte width, typically 8 or 9)
       .RAM_DEPTH(ramDepth),                 // Specify RAM depth (number of entries)
       .RAM_PERFORMANCE("LOW_LATENCY"),      // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
       .INIT_FILE(initfile)                  // Specify name/location of RAM initialization file if using one (leave blank if not)
       ) ram_single (
		     .addra(bus.localWordAddr),        // Address bus, width determined from RAM_DEPTH
		     .dina(bus.data_m2s),    // RAM input data, width determined from NB_COL*COL_WIDTH
		     .clka(clk),       // Clock
		     .wea(wea ),         // Byte-write enable, width determined from NB_COL
		     .ena(en),         // RAM Enable, for additional power savings, disable port when not in use
		     .rsta(rst),       // Output reset (does not affect memory contents)
		     .regcea('0),   // Output register enable
		     .douta(bus.data_s2m)      // RAM output data, width determined from NB_COL*COL_WIDTH
		     );


   
endmodule

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
