#JPU Hello world with function calls
	
.text 0x00400000
main:
        addiu   $s0, $zero, 'p'		#store letter 'p'
        addiu   $s1, $zero, 'q'		#store letter 'q'
        addiu   $s2, $zero, '\r'	#store cr

	jal	inituart		#initialize uart

helloworld:	
	la	$a0, hw_string		#load address of hello world message
	jal	printstr		#print to uart

waitloop:	
	jal	uart_rx_block		#wait for data on uart
	add	$t0, $zero, $v0		#copy rx byte to $t0

	#check if char is a 'p'	
	beq	$t0, $s0, helloworld	#if p, print hello world again

	#check if char is a 'q'	
	beq	$t0, $s1, quit		#if q, exit

	#print character back to uart
	add	$a0, $zero, $t0		#copy rx byte to $a0
	jal	printchar		#print char to uart
	
	bne	$t0, $s2, uart_echo	#if char is cr, add a nl before echoing cr
        addiu   $a0, $zero, '\n'	#new line char
	jal	printchar		#print nl to uart

uart_echo:	
	add	$a0, $zero, $t0		#copy rx byte to $a0
	jal	printchar		#echo char to uart
	j	waitloop		#go back, wait for more

quit:	
	la	$a0, gb_string		#load address of goodbye message
	jal	printstr		#print to uart

	#Quit JPU
        addiu $v0, $zero, 0xa
        syscall

##########################
#Subroutines
#
	
inituart:
	#load uart config data into mem and set uart divider
	la	$t0, uart_config
	lw	$t1, 0($t0)		#uart base addr
	sw	$t1, 0($gp)		#store uart base in $gp+0
	lw	$t2, 4($t0)		#clk divide (9600baud)
	sw	$t2, 4($gp)		#store clk divide in $gp+4
	sw	$t2, 8($t1)		#set uart divider register
	lw	$t1, 8($t0)		#polling loop const
	sw	$t1, 8($gp)		#store polling loop in $gp+8
	j	$ra


uart_rx_block:
	#return uart rx byte ($v0)
	#function is blocking: does not return until data is received
	lw	$t0, 0($gp)		#load uart addr
uart_check:
	lw	$t1, 12($t0)		#load uart rx port data
	bltz	$t1, uart_exit		#rx valid is sign bit, check if valid					
					#no data yet, loop a while, let uart run...
	lw	$t2, 8($gp)		#load counter for polling loop
uart_loop:
	addi 	$t2, $t2, -1 		#decrement counter
	bgtz	$t2, uart_loop		#loop til zero
	j	uart_check		#recheck for uart data
uart_exit:	
	andi	$v0, $t1, 0xFF		#only LS byte is valid - mask off rest of word
	j	$ra
	
printchar:
	#prints ascii char (passed in $a0) to uart
	lw	$t0, 0($gp)		#load uart addr
	sb	$a0, 16($t0)		#send char to uart
	j	$ra
	
printstr:
	#prints asciiz string (passed in $a0) to uart
	lw	$t0, 0($gp)		#load uart addr
printstr_loop:	
	lb	$t1, 0($a0)		#load character
	beq	$t1, $zero, printstr_exit	#jump to exit if end of string
	sb	$t1, 16($t0)		#send char to uart
	addi	$a0, $a0, 1		#increment address
 	j	printstr_loop		#loop back to printloop
printstr_exit:	
	j	$ra
	
.data 0x10000000
uart_config:
        .word	0x1000	#uart base mem
	.word	0x411	#uart clk divide for 9600 baud
	.word	0x2800	#number of loops in polling loop
	
hw_string:
	.asciiz "\r\nHello, World!\r\nWelcome to the JPU\r\nAnything is possible in the JPU!\r\n"
gb_str:
	.asciiz "Goodbye!\r\n"
	

	
