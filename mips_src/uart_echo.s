#JPU echo uart with function calls

UART_ADDR	= 0x1000
UART_DIV	= 0x411
POLL_DLY	= 0x2000
TX_STATUS_MASK  = 0x100000
	
.text 0x00400000
main:
        addiu   $s1, $zero, 'q'		#store letter 'q'
        addiu   $s2, $zero, '\r'	#store cr
	jal	inituart		#initialize uart

waitloop:	
	jal	uart_rx_block		#wait for data on uart
	add	$s0, $zero, $v0		#copy rx byte to $t0
	beq	$s0, $s1, quit		#if q, exit
	bne	$s0, $s2, echo		#if not \r, jump to simple echo
	addi	$a0, $zero, '\n'	#if we rx \r, echo additional \n
	jal	printchar			
echo:	add	$a0, $zero, $s0		#echo character back
	jal	printchar
	j	waitloop		#go back, wait for more

quit:	
	la	$a0, gb_str		#load address of goodbye message
	jal	printstr		#print to uart
	jal	uart_tx_complete	#wait for tx to complete

	#Quit JPU
        addiu $v0, $zero, 0xa
        syscall

##########################
#Subroutines
#
	
inituart:
	#load uart config data into mem and set uart divider
	li	$t0, UART_ADDR
	li	$t1, UART_DIV
	sw	$t1, 8($t0)		#set uart divider register
	j	$ra

uart_tx_complete:
	#return once all uart transmissions are complete
	li	$t0, UART_ADDR		#load uart addr
txchk_lp:
	lw	$t1, 4($t0)		#load uart status
	li	$t2, TX_STATUS_MASK	#mask for tx_active bit
	and	$t1, $t1, $t2		#select tx_active bit
	bnez	$t1, txchk_lp		#still transmitting if set, keep looping
	j	$ra
	
uart_rx_block:
	#return uart rx byte ($v0)
	#function is blocking: does not return until data is received
	li	$t0, UART_ADDR		#load uart addr
uart_check:
	lw	$t1, 12($t0)		#load uart rx port data
	bltz	$t1, uart_exit		#rx valid is sign bit, check if valid					
					#no data yet, loop a while, let uart run...
	li	$t2, POLL_DLY		#load counter for polling loop
uart_loop:
	addi 	$t2, $t2, -1 		#decrement counter
	bgtz	$t2, uart_loop		#loop til zero
	j	uart_check		#recheck for uart data
uart_exit:	
	andi	$v0, $t1, 0xFF		#only LS byte is valid - mask off rest of word
	j	$ra

	
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
	
printchar:
	#prints ascii char (passed in $a0) to uart
	li	$t0, UART_ADDR		#load uart addr
	sb	$a0, 16($t0)		#send char to uart
	j	$ra
	
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
	
.data 0x10000000
gb_str:
	.asciiz "Goodbye!\r\n"
hex_str:
	.asciiz "0123456789abcdef"
hex_prefix:
	.asciiz "0x"
