// Top jpu testbench 
module tb_jpu_top;
           
   logic clk, rst;
   logic [3:0] user_btn;
   logic [3:0] user_sw;
   logic [7:0] status_led;
   logic       uart_rxd_out;
   logic       uart_txd_in;
 
   assign       user_btn = '0;
   assign       ussr_sw = '0;   
   assign       uart_txd_in = '0;
      
   clock #(0, 10) myclk(.clk);

   jpu_impl jpu(.ila_probe(), .*);

   initial
     begin
	rst = 1;
	#15;
	rst <= 0;
     end
   
endmodule


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:
