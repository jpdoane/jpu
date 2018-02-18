#define UART_BASE 0xffff0000

#define UART_DIV 0x411
#define TX_STATUS_MASK 0x100000	

void uart_init(void);
void uart_txflush(void);
char uart_rx(void);
int uart_rx_nonblock(void);
void uart_tx(char tx);
