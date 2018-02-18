
##########################
# Printing Subroutines
#

#include "uart.s"	

	.globl	printhex
	.globl	printstr
	
	
	.text
printhex:
	#print hex word in "0xFFFFFFFF" format
	addi	$sp, $sp, -12		#allocate 3 words on stack
	sw	$ra, 0($sp)		#save $ra
	sw	$s0, 4($sp)		#save $s0
	sw	$s1, 8($sp)		#save $s1
	add	$s0, $zero, $a0		#argument to print
	la	$a0, hex_prefix		#print prefix 0x
	jal	printstr
	addi	$s1, $zero, 8		#hex digit counter: print 8 digits
print_hex_loop:	
	srl	$a0, $s0, 28		#print most significant nibble
	jal	hexdigit		#returns digit in hex ascii
	add	$a0, $zero, $v0		#hex digit in ascii
	jal	printchar		#print to uart
	sll	$s0, $s0, 4		#shift to next nibble
	addi 	$s1, $s1, -1 		#decrement counter
	bgtz	$s1, print_hex_loop	#loop through each nibble
	lw	$ra, 0($sp)		#restore $ra
	lw	$s0, 4($sp)		#restore $s0
	lw	$s1, 8($sp)		#restore $s1
	addi	$sp, $sp, 12		#restore stack
	j	$ra			#return
	
hexdigit:
	#$v0 returns ascii hex digit of first nibble in $a0
	andi	$t0, $a0, 0xF		#mask lowest nibble
	la	$t1, hex_str		#string of hex digits 0-F
	add	$t1, $t0, $t1		#addr of hex digit
	lb	$v0, 0($t1)		#load ascii hex digit
	j	$ra			#return
	
printstr:
	#prints asciiz string (passed in $a0) to uart
	li	$t0, UART_ADDR		#load uart addr
printstr_loop:	
	lb	$t1, 0($a0)		#load character
	beq	$t1, $zero, printstr_exit	#jump to exit if end of string
	sb	$t1, 16($t0)		#send char to uart
	addi	$a0, $a0, 1		#increment address
 	j	printstr_loop		#loop back to printloop
printstr_exit:	
	j	$ra
	
.data
hex_str:
	.asciiz "0123456789abcdef"
hex_prefix:
	.asciiz "0x"
