// Simulated clock module
module clock(clk);
   parameter start = 0, halfPeriod = 50;
   output    clk;
   reg 	     clk;
   
   initial
     clk = start;
   
   always
     #halfPeriod clk= ~clk;
   
endmodule

