#include "interrupts.h"

	.section .except, "ax"	
	.globl except_hdl
	
except_hdl:
	la	$k0, space_except
	.set noat
	sw	$at, 0($k0)
	.set at
	sw	$ra, space_except+4
	jal	except_save_regs

	mfc0  	$t0, $13	#load cause reg
	srl	$t0, $t0, 2
	andi	$a0, $t0, 0x1f	#exception code (=0 for interrupt, >0 for trap)
	bgtz	$a0, trap	  #Branch if trap (non interrupt)
	
interrupt:
	mfc0	$a0, $13			#cause reg
	sll	$a0, $a0, INT_TMR_SHIFT		#timer int flag in sign bit
	bltzal	$a0, timer_hdl			#timer int handler
	mfc0	$a0, $13			#cause reg
	sll	$a0, $a0, INT_UART_SHIFT	#uart int flag in sign bit
	bltzal	$a0, uart_hdl			#uart int handler
	mfc0	$a0, $13			#cause reg
	sll	$a0, $a0, INT_BTN_SHIFT		#btn int flag in sign bit
	bltzal	$a0, btn_hdl			#btn int handler
	j	done

timer_hdl: #not implemented yet
	li	$t0, INT_TMR_MASK	#clear interrupt bit
	xor	$t0, $t0, -1		#invert mask
	mfc0	$t1, $13		#load cause
	and	$t1, $t1, $t0		#clear bit
	mtc0	$t1, $13		#save cause
	jr	$ra

uart_hdl: #echo character
	sw	$ra, space_uarthdl	#save ra
	jal 	receive_char		#get character from uart
	move	$a0, $v0		#copy char to arg of print_char
	jal 	print_char		#print character
	li	$t0, INT_UART_MASK	#clear interrupt bit
	xor	$t0, $t0, -1		#invert mask
	mfc0	$t1, $13		#load cause
	and	$t1, $t1, $t0		#clear bit
	mtc0	$t1, $13		#save cause
	lw	$ra, space_uarthdl	#restore ra
	jr	$ra			#return
	
btn_hdl: #print simple message
	sw	$ra, space_btnhdl
	la	$a0, btn_msg
	jal	print_str
	li	$t0, INT_BTN_MASK	#clear interrupt bit
	xor	$t0, $t0, -1		#invert mask
	mfc0	$t1, $13		#load cause
	and	$t1, $t1, $t0		#clear bit
	mtc0	$t1, $13		#save cause
	lw	$ra, space_btnhdl
	jr	$ra
	
	#threw a trap
	#just print the error for now and keep going at next instruction
trap:		
	## $a0 contains excpetion ID
	mfc0	$a1, $14	#EPC
	jal	print_exception
	
	#restore system state and return to user code	
done:	
	jal	except_load_regs	#restore saved registers

	lw	$ra, space_except+4	#restore ra
	la	$k0, space_except
	.set noat
	lw	$at, 0($k0)		#restore at
	.set at

	eret			#return from exception
	nop
	
print_inter:
	sw	$ra, saveprintint	#save $ra
	sw	$s0, saveprintint+4	#save $s0
	addi	$s0, $a0,0
	la	$a0, interrupt_msg
	jal	print_str		#print interrupt msg
	addi	$a0, $s0,0		#(bd) print interrupt
	jal	print_hex
	la	$a0, nl
	jal	print_str		#print newline
	lw	$ra, saveprintint	#restore $ra
	lw	$s0, saveprintint+4	#restore $s0
	j	$ra
	
	
print_exception:
	## $a0 is exception ID, $a1 is EPC
	sw	$ra, saveprintexcept	#save $ra
	sw	$s0, saveprintexcept+4	#save $s0
	addi	$s0, $a0, 0
	la	$a0, except_msg1
	jal	print_str		#print interrupt msg
	addi	$a0, $s0,0		#(bd) print interrupt
	jal	print_hex

	la	$a0, except_msg2
	jal	print_str		#print interrupt msg
	addi	$a0, $a1,0		#(bd) print EPC
	jal	print_hex

	la	$a0, nl
	jal	print_str		#print newline
	lw	$ra, saveprintexcept	#restore $ra
	lw	$s0, saveprintexcept+4	#restore $s0
	jr	$ra


	# save regs for exception handler
	# multiple calls will overwrite! exception handler must not be reentrant
	# not saved: at (must be saved immediately)
	# not saved: ra (must be saved by caller)
	# not saved: gp,sp,fp (not safe to use stack during exception hdl)
except_save_regs:
	sw	$v0, space_regs
	sw	$v1, space_regs + 0x4
	sw	$a0, space_regs + 0x8
	sw	$a1, space_regs + 0xc
	sw	$a2, space_regs + 0x10
	sw	$a3, space_regs + 0x14
	sw	$t0, space_regs + 0x18
	sw	$t1, space_regs + 0x1c
	sw	$t2, space_regs + 0x20
	sw	$t3, space_regs + 0x24
	sw	$t4, space_regs + 0x28
	sw	$t5, space_regs + 0x2c
	sw	$t6, space_regs + 0x30
	sw	$t7, space_regs + 0x34
	sw	$t8, space_regs + 0x38
	sw	$t9, space_regs + 0x3c
	sw	$s0, space_regs + 0x40
	sw	$s1, space_regs + 0x44
	sw	$s2, space_regs + 0x48
	sw	$s3, space_regs + 0x4c
	sw	$s4, space_regs + 0x50
	sw	$s5, space_regs + 0x54
	sw	$s6, space_regs + 0x58
	sw	$s7, space_regs + 0x5c
	sw	$k0, space_regs + 0x60
	sw	$k1, space_regs + 0x64
	jr	$ra

	# restore regs after exception handler
except_load_regs:
	lw	$v0, space_regs
	lw	$v1, space_regs + 0x4
	lw	$a0, space_regs + 0x8
	lw	$a1, space_regs + 0xc
	lw	$a2, space_regs + 0x10
	lw	$a3, space_regs + 0x14
	lw	$t0, space_regs + 0x18
	lw	$t1, space_regs + 0x1c
	lw	$t2, space_regs + 0x20
	lw	$t3, space_regs + 0x24
	lw	$t4, space_regs + 0x28
	lw	$t5, space_regs + 0x2c
	lw	$t6, space_regs + 0x30
	lw	$t7, space_regs + 0x34
	lw	$t8, space_regs + 0x38
	lw	$t9, space_regs + 0x3c
	lw	$s0, space_regs + 0x40
	lw	$s1, space_regs + 0x44
	lw	$s2, space_regs + 0x48
	lw	$s3, space_regs + 0x4c
	lw	$s4, space_regs + 0x50
	lw	$s5, space_regs + 0x54
	lw	$s6, space_regs + 0x58
	lw	$s7, space_regs + 0x5c
	lw	$k0, space_regs + 0x60
	lw	$k1, space_regs + 0x64
	jr	$ra
	
	.section .kdata, "aw"
	.align 2
space_regs:
	.space 4*32			#temp space for 32 regs
space_except:
	.space 4*5			#temp space
btn_msg:
	.asciiz "Button Pressed!\n"
btn_time:
	.word 0
space_btnhdl:
	.word 0
space_uarthdl:
	.word 0

saveprintint:
	.space 4*2
	.align 2
saveprintexcept:
	.space 4*2
	.align 2
hexchars:
	.asciiz "0123456789abcdef"
	.align 2
except_msg1:
	.asciiz "Ex: "
	.align 2
except_msg2:
	.asciiz " at: "
	.align 2
interrupt_msg:
	.asciiz "Int: "
	.align 2
nl:
	.asciiz "\n"
	
	
