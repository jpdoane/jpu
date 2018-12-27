	.text

	add x2, x1, x3		#R - type
	addi x2, x1, 0xde	#I - type
link:	sh  x2, -100(x1)	#S - type
	jal x1, link		#J - type
	beq x1, x2, link	#B - type
	lui x1, 0xdbeef		#U - type
	
	
