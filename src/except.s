	.ktext 0x80000000
bootstrap:
	j	0x0040000
	
	.ktext 0x80000180
except_hdl:
	sw	$at, save	;save $at reg
	sw	$a0, save+4
	sw	$a1, save+8
	sw	$a2, save+12
	sw	$ra, save+16
	mfc0  	$k0, $13	;load cause reg
	mfc0  	$k1, $12	;load status reg
	srl	$a0, $k0, 2
	andi	$a0, $a0, 0x1f	;exception code
	bgtz	$a0, $0, exception ;Branch unless interupt
	nop

	;; interrupt
	srl	$a0, $k0, 8	    
	andi	$a0, $a0, 0xff	;pending interrupts
	srl	$a1, $k1, 8	    
	andi	$a1, $a1, 0xff	;interrupt enable mask
	and	$a0, $a0, $a1	;pending enabled interrrupts
	lw	$a1, int_hdl_enable ;inter handlers
	andi	$a1, $a1, 0xff	;interrupt enable mask
	and	$a0, $a0, $a1	;pending enabled interrrupts that have handlers

	li	$a1, 8		;count variable for looping
find_int_hdl:			;loop through and check each interrupt
	addi	$a1, $a1, -1	;decrement loop counter
	srlv	$a2, $a0, $a1	;shift relevant bit to lsb
	andi	$a2, $a2, 1
	bgtz	$a2, int_jump	;branch if we have a handler
	nop
	bgtz	$a1, find_int_hdl
	nop
	j	done
	nop

int_jump:	;found a registered handler for interrupt number $a1
	la	$a0,int_hdl	;array of pointers to interrupt handlers
	sll	$a1, 2
	add	$a0, $a0, $a1	;addr of pointer to int handler
	lw	$a0, $a0	;addr of int handler
	jalr	$a0		;jump to interrupt handler
	nop
	j	done
	nop

exception:			;threw an exception
	mfc0	$a1, $14	;EPC
	jal	print_exception
	mov	$a0, $k0	;(BD) cause reg

halt:	j	halt		;just halt for now
	nop

done:				;restore system state and return to user code
	mtc0	$0, $13		;clear cause reg
	mfc0	$k0, $12	;status reg
	andi	$k0, 0xfffd	;clear exl
	ori	$k0, 0x1	;enable int
	mtc0	$k0, $12	;update status reg
	
	lw	$at, save	;restore registers
	lw	$a0, save+4
	lw	$a1, save+8
	lw	$a2, save+12
	lw	$ra, save+16
	eret			;return
	

	.kdata
save:
	.word 5			;temp space for registers
int_hdl_enable:
	.word			;bits [7:0] indicate is interrupt handlers are enabled
int_hdl:
	.word 8			;function pointers to interrupt handlers
	
	
