module regfile (/*AUTOARG*/
   // Outputs
   rs1_data, rs2_data,
   // Inputs
   clk, rst, rs1, rs2, rd, rd_data, rd_we
   );
   input 		   clk, rst;
   input [4:0]             rs1, rs2, rd; 
   input [31:0] 	   rd_data;
   input 		   rd_we;
   output logic [31:0] 	   rs1_data, rs2_data;

   logic [31:0] 	   mem[0:31];
   int 			   i; 			   

   always @(posedge clk) begin
      // initialize regfile
      if (!rst) begin
	 for (i = 0; i < 32; i = i+1)
           mem[i] <= 32'b0;
      end
      else if (rd_we && (rd != 0)) begin
	 //write reg
	 mem[rd] <= rd_data; 
      end 
   end 

   
   // reg writes are pipelined, so feed forward data for read after write   
   assign rs1_data = (rs1 == 0) ? 32'h0 :
		     ((rs1==rd) && rd_we) ? rd_data:
		     mem[rs1];
   assign rs2_data = (rs2 == 0) ? 32'h0 :
		     ((rs2==rd) && rd_we) ? rd_data:
		     mem[rs2];

endmodule

