////
//// 
////
`define KTEXT_SEG_BASE 32'h80000000
`define KTEXT_SEG_WORDS 'h1000
`define KTEXT_INIT_FILE "ktext.mem"

`define KDATA_SEG_BASE 32'h90000000
`define KDATA_SEG_WORDS 'h1000
`define KDATA_INIT_FILE "kdata.mem"

`define TEXT_SEG_BASE 32'h00400000
`define TEXT_SEG_WORDS 'h1000
`define TEXT_INIT_FILE "text.mem"

`define DATA_SEG_BASE 32'h10000000
`define DATA_SEG_WORDS 'h1000
`define DATA_INIT_FILE "data.mem"

`define HEAP_SEG_BASE 32'h10008000
`define HEAP_SEG_WORDS 'h1000
`define HEAP_INIT_FILE ""

`define STACK_SEG_BASE 32'h7ffff000
`define STACK_SEG_TOP 'h7ffffffc
`define STACK_SEG_WORDS 'h1000
`define STACK_INIT_FILE ""

// uart memory map
`define UART_SEG_BASE 32'hffff0000
`define UART_SEG_WORDS 'hF


//special addresses
`define BOOTSTRAP_START `KTEXT_SEG_BASE
`define EXCEPT_HANDLER 'h80000180


