`include "jpu.svh"

import jpu::*;

module cp0(/*AUTOARG*/
   // Outputs
   cp0_data_out, raise_exception, eret,
   // Inputs
   clk, rst, en, stalled, epc, vaddr, ints_in, excepts, cp0_op,
   cp0_data_in, cp0_reg
   );
   
   input logic clk, rst, en, stalled;
   input logic [31:0] epc;
   input logic [31:0] vaddr;
   input logic [7:0]  ints_in;
   input 	      exceptions_s excepts;
   input 	      cp0op_s cp0_op;
   input logic [31:0] cp0_data_in;
   input logic [4:0] cp0_reg;
   output logic [31:0] cp0_data_out;   
   output logic        raise_exception, eret;
   
   logic [31:0] [31:0] cp0reg;
  
   logic [15:0]	timer_inner;
   logic	inc_count;
   logic        timer_int;

   logic [7:0] 	interrupts, int_mask;
   logic 	int_enable, except_enable, except_level, user_mode;

   logic [4:0]  except_code;
   
   assign int_mask = cp0reg[`CR_STATUS][15:8];
   assign int_enable = cp0reg[`CR_STATUS][0];
   assign except_level = cp0reg[`CR_STATUS][1];
   assign user_mode = cp0reg[`CR_STATUS][4];

   assign cp0_data_out = (en && cp0_op==ERET) ? cp0reg[`CR_EPC] :
			  (en && cp0_op==MFC0) ? cp0reg[cp0_reg] :
			  '0;
   assign eret = (en && cp0_op==ERET) ?  1'b1: 1'b0;

   assign interrupts = cp0reg[`CR_CAUSE][15:8];

   //registers
   always @(posedge clk) begin
      if(rst) begin
	 cp0reg <= '0;
      end
      else begin
	 cp0reg <= cp0reg;

	 //timer
	 if(inc_count) begin
	   cp0reg[`CR_COUNT] <= cp0reg[`CR_COUNT]+1;
	 end
	 
	 //interrupts
	 cp0reg[`CR_CAUSE][15] <= cp0reg[`CR_CAUSE][15] | ints_in[7] | timer_int;
	 cp0reg[`CR_CAUSE][14:8] <= cp0reg[`CR_CAUSE][14:8] | ints_in[6:0];

	 if (en & ~ stalled) begin
	    if(cp0_op==ERET) begin
	       cp0reg[`CR_STATUS][1] <= 1'b0; //reset exception level
	    end
	    if(raise_exception) begin
	       cp0reg[`CR_EPC] <= epc;
	       cp0reg[`CR_CAUSE][6:2] <= except_code;
	       cp0reg[`CR_STATUS][1] <= 1'b1; //set exception level
	       if(except_code==`EX_ADEL || 
		  except_code==`EX_ADES ||
		  except_code==`EX_IBE  ||
		  except_code==`EX_DBE ) begin
		  cp0reg[`CR_BADVADDR ] <= vaddr;
	       end
	    end

	    //this should come last since external write should override internal updates
	    if(cp0_op == MTC0) begin
	       cp0reg[cp0_reg] <= cp0_data_in;
	       if(cp0_reg == `CR_COMPARE) begin
		  cp0reg[`CR_CAUSE][15] <= 0; // writing to compare clears timer interrupt
	       end	    
	    end
	 end
      end
   end

   // raise timer interrupt if time = compare, unless compare=0
   assign timer_int = ((cp0reg[`CR_COMPARE] != 32'b0) && (cp0reg[`CR_COUNT] == cp0reg[`CR_COMPARE]))? 1'b1 : 1'b0;
   
   //Exception Handler
   always @(*) begin
      raise_exception <= 1'b0;
      except_code <= '0;
      if (except_level == 1'b0 && ~stalled) begin
	 if (int_enable & (|(interrupts & int_mask))) begin
	    // interrupt
	    except_code <= `EX_INT;
	    raise_exception <= 1'b1;
	 end
	 if (|excepts) begin
	    //exception
	    if(excepts.AdEL)
	      except_code <= `EX_ADEL;
	    if(excepts.AdES)
	      except_code <= `EX_ADES;
	    if(excepts.IBE)
	      except_code <= `EX_IBE;
	    if(excepts.DBE)
	      except_code <= `EX_DBE;
	    if(excepts.Sys)
	      except_code <= `EX_SYS;
	    if(excepts.Bp)
	      except_code <= `EX_BP;
	    if(excepts.RI)
	      except_code <= `EX_RI;
	    if(excepts.CpU)
	      except_code <= `EX_CPU;
	    if(excepts.Ov)
	      except_code <= `EX_OV;
	    if(excepts.Tr)
	      except_code <= `EX_TR;
	    if(excepts.FPE)
	      except_code <= `EX_FPE;
	    raise_exception <= 1'b1;
	 end // if (|excepts)
      end // if (except_level == 1'b0)
   end // always @ (posedge clk)
   

   // Timer
   always @(posedge clk) begin
      if(rst) begin
	 timer_inner <= '0;
	 inc_count <= 1'b0;
      end
      else begin
	 if( timer_inner == `TIMER_PERIOD-1 ) begin
	    timer_inner <= 16'd1;
	    inc_count <= 1'b1;
	 end
	 else begin
	    timer_inner <= timer_inner+1;
	    inc_count <= 1'b0;
	 end
      end // else: !if(rst)
   end // always @ (posedge clk)
   
endmodule // cp0

   
      

   
// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:("." "../447rtl")
// verilog-library-extensions:(".sv" ".vh")
// End:
