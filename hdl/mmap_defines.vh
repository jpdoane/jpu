////
//// 
////
`define UART_SEG_BASE 32'h00001000
`define UART_SEG_WORDS 'hF

`define KTEXT_SEG_BASE 32'h00200000
`define KTEXT_SEG_WORDS 'h1000
`define KTEXT_INIT_FILE "ktext.mem"

`define KDATA_SEG_BASE 32'h00300000
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
`define HEAP_INIT_FILE 'h1000

`define STACK_SEG_BASE 32'h7ffff000
`define STACK_SEG_TOP 'h7ffffffc
`define STACK_SEG_WORDS 'h1000
`define STACK_INIT_FILE "data.mem"

// uart register map

`define UART_CTRL_REG_WORD 0
`define UART_STATUS_REG_WORD 1
`define UART_DIVIDE_REG_WORD 2
`define UART_RX_PORT_WORD  3
`define UART_TX_PORT_WORD  4

//uart status bits
`define UART_RX_ERROR_BIT 0
`define UART_RX_FIFO_OVERFLOW_BIT 1
`define UART_RX_FIFO_FULL_BIT  2
`define UART_RX_FIFO_EMPTY_BIT  3
`define UART_RX_ACTIVE_BIT  4
`define UART_TX_ERROR_BIT  16
`define UART_TX_FIFO_OVERFLOW_BIT 17
`define UART_TX_FIFO_FULL_BIT  18
`define UART_TX_FIFO_EMPTY_BIT  19
`define UART_TX_ACTIVE_BIT  20

//uart rx bits
`define UART_RX_VALID_BIT 31

