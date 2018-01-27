#include "uart.h"

static int* uart_base = (int*) UART_ADDR;

void uart_init(void)
{
  // set uart divide for 9600 baud
  uart_base[2] = UART_DIV;
}

void uart_txflush(void)
{
  while(uart_base[1] & TX_STATUS_MASK != 0) {}
}

char uart_rx(void)
{
  int rx_word;
  do
  {
    rx_word = uart_base[3];
  } while(rx_word >= 0); // sign bit is valid data

  return (char) rx_word & 0xFF; // rx data is lowest byte
}

int uart_rx_nonblock(void)
{
  return uart_base[3];
}

void uart_tx(char tx)
{
  uart_base[4] = (int) tx;
}
