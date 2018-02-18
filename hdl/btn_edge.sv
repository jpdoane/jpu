// Top module for the MIPS processor core
module btn_edge(/*AUTOARG*/
   // Outputs
   btn_re, btn_fe,
   // Inputs
   btn, clk, rst
   );
   parameter NUM_BTN=4;

   input logic [NUM_BTN-1:0] btn;
   input logic      clk,rst;   
   output logic btn_re, btn_fe;

   logic [NUM_BTN-1:0] btn_reg;

   assign btn_re = | (btn & ~btn_reg); // detect btn rising edge
   assign btn_fe = | (~btn & btn_reg); // detect btn falling edge
   
   always @(posedge clk) begin
      if(rst) begin
	btn_reg <= '0;
      end
      else begin
	 btn_reg <= btn;
      end      
   end
   
   
endmodule // btn
