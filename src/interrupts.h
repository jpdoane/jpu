#define INT_TMR  0x80 //int 8
#define INT_UART 0x40 //int 7
#define INT_BTN  0x20 //int 6

#define INT_TMR_SHIFT 16 //sll status reg by this amount puts tmr int in sign bit
#define INT_UART_SHIFT 17  //sll status reg by this amount puts uart int in sign bit
#define INT_BTN_SHIFT 18  //sll status reg by this amount puts btn int in sign bit

#define INT_TMR_MASK 0x00008000
#define INT_UART_MASK 0x00004000
#define INT_BTN_MASK 0x00002000


#define ENABLE_ALL_INTS  0xff01


