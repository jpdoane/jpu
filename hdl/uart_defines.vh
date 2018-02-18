//uart

`include "mmap_defines.vh"

`define UART_PARITY 1
`define UART_DATA_WIDTH 8
`define UART_STOP_BITS 1
`define UART_DEFAULT_BAUDRATE  9600
`define UART_CLK_FREQ `CLK_FREQ  

`define UART_DIVIDE_OVERRIDE_SIM 8

`define UART_RX_CTRL    `UART_SEG_BASE
`define UART_RX_DATA    `UART_SEG_BASE + 'h4
`define UART_TX_CTRL    `UART_SEG_BASE + 'h8
`define UART_TX_DATA    `UART_SEG_BASE + 'hc
`define UART_DIV        `UART_SEG_BASE + 'h10

//uart control register bits
`define UART_ERROR_BIT 31
`define UART_FIFO_OVERFLOW_BIT 30
`define UART_FIFO_FULL_BIT  29
`define UART_FIFO_EMPTY_BIT  28
`define UART_ACTIVE_BIT  27
`define UART_INT_ENABLE_BIT   1
`define UART_READY_BIT  0

//uart rx data bits:
`define UART_RX_VALID_BIT 31

