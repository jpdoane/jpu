#include "uart.h"

// put _start in own section, so that linker knows to put it at top of .text seg
void _start (void) __attribute__ ((section ("entry"))); 

void printstr(const char* str);

void _start (void)
{
  int dataword;
  char data = 0;
  uart_init();

  while(1)
  {
    dataword = uart_rx_nonblock();
    if(dataword<0){
      data = (char) dataword & 0xFF;
      switch(data) {
      case 'p':
	printstr("Hello from the new and improved JPU!\r\n");
	break;
      case '\r':
	printstr("\r\n");
	break;
      default:
	uart_tx(data);
      }
    }    
  }
}

void printstr(const char* str)
{
  while(*str) {
    uart_tx(*str++);
  }
}
    

      
