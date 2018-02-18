#include "kprint.h"
#include "interrupts.h"

	.section .boot, "ax"	
	.globl bootstrap
bootstrap:

	# init uart
	li	$a0, UART_9600	#uart clock div for 9600 baud
	jal	uart_init

	## enable interrupts
	mfc0	$k0, $12	#status reg
	ori	$k0, ENABLE_ALL_INTS	#enable ints
	mtc0	$k0, $12	#update status reg

	## jump to user code
	## j	0x00400000		#
forever:
	j forever
