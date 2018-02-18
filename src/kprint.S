	#Printing Subroutines for Exception Handling
	#no stack, register safe

	#include "kprint.h"
	
	.globl	uart_init
	.globl	print_hex
	.globl	print_str
	.globl	print_char
	.globl	receive_char
		
	.section .ktext, "ax"

	#uart_init
	## uart clock passed in $a0
	#load uart config data into mem and set uart divider 
uart_init:
	sw	$a0, UART_DIV		#set uart divider register
	li	$a0, UART_INT_ENABLE	#
	sw	$a0, UART_RX_CTRL	#enable rx interrupts
	j	$ra

	#print_hex
	#print hex word in "0xFFFFFFFF" format
print_hex:
	sw	$ra, saveprinthex	#save $ra
	sw	$s0, saveprinthex+4	#save $s0
	sw	$s1, saveprinthex+8	#save $s1
	sw	$s2, saveprinthex+12	#save $s2
	sw	$s3, saveprinthex+16	#save $s3
	addi 	$s0, $a0, 0		#argument to print
	la	$a0, hex_prefix		#print prefix 0x
	jal	print_str
	
	addi	$s1, $zero, 8		#hex digit counter: print 8 digits
	la	$s2, hex_digits		#string of hex digits 0-F
	li	$s3, UART_TX_DATA	#load uart addr 
print_hex_loop:	
	srl	$a0, $s0, 28		#most significant nibble
	add	$a0, $s2, $a0		#addr of ascii hex digit
	lb	$a0, 0($a0)		#load ascii hex digit
	sb	$a0, 0($s3)		#send char to uart 
	addi 	$s1, $s1, -1 		#decrement counter
	sll	$s0, $s0, 4		#(bd) shift to next nibble
	bgtz	$s1, print_hex_loop	#loop through each nibble	
	lw	$ra, saveprinthex	#restore $ra
	lw	$s0, saveprinthex+4	#restore $s0
	lw	$s1, saveprinthex+8	#restore $s1
	lw	$s2, saveprinthex+12	#restore $s2
	lw	$s3, saveprinthex+16	#(bd) restore $s3
	j	$ra			#return

	#print_str
	#prints asciiz string (passed in $a0) to uart	
print_str:	
	sw	$s0, saveprintstr	#save $s0
	sw	$s1, saveprintstr+4	#save $s1
	li	$s0, UART_TX_DATA	#load uart addr
printstr_loop:	
	lb	$s1, 0($a0)		#load character
	beq	$s1, $0, printstr_exit	#jump to exit if end of string
	sb	$s1, 0($s0)		#send char to uart
	addi	$a0, $a0, 1		#(bd) increment address
 	j	printstr_loop		#loop back to printloop	
printstr_exit:	
	lw	$s0, saveprintstr	#restore $s0
	lw	$s1, saveprintstr+4	#restore $s1
	j	$ra


	#print_char
	#prints ascii char (passed in $a0) to uart
print_char:				
	sb	$a0, UART_TX_DATA	#send char to uart
	j	$ra

	#receive_char
	#receive ascii char, return in v0
receive_char:				
	lb	$v0, UART_RX_DATA	#send char to uart
	j	$ra

	
	.section .kdata, "aw"
	.align 2
saveuartinit:
	.space 4*2
saveprinthex:
	.space 4*5
saveprintstr:
	.space 4*2
hex_digits:
	.asciiz "0123456789abcdef"
hex_prefix:
	.asciiz "0x"
