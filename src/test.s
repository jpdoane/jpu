	.section .boot

bootstrap:
	li a0, 0x0
loop:
	addi a0, a0, 0x1
	j loop
	
