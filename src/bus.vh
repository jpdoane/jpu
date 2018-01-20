//data types for wishbone bus signals
`ifndef BUS_VH
`define BUS_VH

package bus;

typedef struct packed {
		  logic   [29:0] addr;
		  logic [31:0] data;
		  logic        cyc,stb,we;
		  logic [3:0]  sel;
	       } m2s_s;

typedef struct packed {
		  logic [31:0] data;
		  logic        ack,err,stall;
	       } s2m_s;

typedef struct packed {
		  logic [29:0] start;
		  logic [29:0] top;
		  logic [29:0] words;
	       } slave_info_s;

function slave_info_s slave_info(logic [31:0] addr_base, logic [29:0] num_words);
   slave_info.start = addr_base >> 2;
   slave_info.top = slave_info.start + num_words;
   slave_info.words = num_words;
endfunction // addr_info
   
endpackage: bus

`endif

// Local Variables:
// verilog-typedef-regexp: "_[sS]$" 
// End:

