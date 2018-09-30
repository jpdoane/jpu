module mmu(/*AUTOARG*/
   // Inputs
   inst_addr_log, data_addr_log, inst_en, data_en, user_mode,
   inst_addr_phy, data_addr_phy
   );
   input logic [31:0] inst_addr_log, data_addr_log;
   input logic inst_en, data_en, data_we;

//   input logic [7:0] proc_id;
   input usermode_s user_mode;   
   output logic [31:0] inst_addr_phy, data_addr_phy;
   output logic        AdEL, AdES;

   
 
endmodule // mmu


// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// verilog-library-directories:(".")
// verilog-library-extensions:(".sv" ".vh")
// End:
  
