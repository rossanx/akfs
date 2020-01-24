/*    File: exceptions0to31.s
 *    This code is part of the kalimera system project.
 *    Author: Rossano Pablo Pinto (rossano at gmail dot com)
 *    Date: Wed Apr 22 14:25:13 BRT 2015
*/


/* MAKE THIS "FUNCTION" VISIBLE TO OTHER FILES */
.global register_exceptions
	
.code32
.section .text

.macro deal_with_it

	pushl   $0x0E       # FG: YELLOW
	pushl   $0x00       # BG: BLACK	
	pushl	$action_msg # MSG
	pushl	$24         # COLUMN
	pushl	$1          # LINE
	call print	
1:	
	jmp 1b   # JUST FOR TESTING PURPOSES: Every exception puts the system
	         # into an infinite loop. You should reboot!!!
	iret
.endm	

/*----------------------------------------------------------------------------
 * EXCEPTION HANDLERS
 *---------------------------------------------------------------------------*/
	
register_exceptions:
	pusha

	# Exception 0
	movl	$_exception00, %eax
	movw	%ax, (0*8)
	movw	$0x08, (0*8+2)
	movw	$0x8e00, (0*8+4)
	shr	$16, %eax
	movw	%ax, (0*8+6)

	# Exception 1
	movl	$_exception01, %eax
	movw	%ax, (1*8)
	movw	$0x08, (1*8+2)
	movw	$0x8e00, (1*8+4)
	shr	$16, %eax
	movw	%ax, (1*8+6)

	# Exception 2
	movl	$_exception02, %eax
	movw	%ax, (2*8)
	movw	$0x08, (2*8+2)
	movw	$0x8e00, (2*8+4)
	shr	$16, %eax
	movw	%ax, (2*8+6)

	# Exception 3
	movl	$_exception03, %eax
	movw	%ax, (3*8)
	movw	$0x08, (3*8+2)
	movw	$0x8e00, (3*8+4)
	shr	$16, %eax
	movw	%ax, (3*8+6)

	# Exception 4
	movl	$_exception04, %eax
	movw	%ax, (4*8)
	movw	$0x08, (4*8+2)
	movw	$0x8e00, (4*8+4)
	shr	$16, %eax
	movw	%ax, (4*8+6)

	# Exception 5
	movl	$_exception05, %eax
	movw	%ax, (5*8)
	movw	$0x08, (5*8+2)
	movw	$0x8e00, (5*8+4)
	shr	$16, %eax
	movw	%ax, (5*8+6)

	# Exception 6
	movl	$_exception06, %eax
	movw	%ax, (6*8)
	movw	$0x08, (6*8+2)
	movw	$0x8e00, (6*8+4)
	shr	$16, %eax
	movw	%ax, (6*8+6)

	# Exception 7
	movl	$_exception07, %eax
	movw	%ax, (7*8)
	movw	$0x08, (7*8+2)
	movw	$0x8e00, (7*8+4)
	shr	$16, %eax
	movw	%ax, (7*8+6)

	# Exception 8
	movl	$_exception08, %eax
	movw	%ax, (8*8)
	movw	$0x08, (8*8+2)
	movw	$0x8e00, (8*8+4)
	shr	$16, %eax
	movw	%ax, (8*8+6)

	# Exception 9
	movl	$_exception09, %eax
	movw	%ax, (9*8)
	movw	$0x08, (9*8+2)
	movw	$0x8e00, (9*8+4)
	shr	$16, %eax
	movw	%ax, (9*8+6)

	# Exception 10
	movl	$_exception10, %eax
	movw	%ax, (10*8)
	movw	$0x08, (10*8+2)
	movw	$0x8e00, (10*8+4)
	shr	$16, %eax
	movw	%ax, (10*8+6)

	# Exception 11
	movl	$_exception11, %eax
	movw	%ax, (11*8)
	movw	$0x08, (11*8+2)
	movw	$0x8e00, (11*8+4)
	shr	$16, %eax
	movw	%ax, (11*8+6)

	# Exception 12
	movl	$_exception12, %eax
	movw	%ax, (12*8)
	movw	$0x08, (12*8+2)
	movw	$0x8e00, (12*8+4)
	shr	$16, %eax
	movw	%ax, (12*8+6)

	# Exception 13
	movl	$_exception13, %eax
	movw	%ax, (13*8)
	movw	$0x08, (13*8+2)
	movw	$0x8e00, (13*8+4)
	shr	$16, %eax
	movw	%ax, (13*8+6)

	# Exception 14
	movl	$_exception14, %eax
	movw	%ax, (14*8)
	movw	$0x08, (14*8+2)
	movw	$0x8e00, (14*8+4)
	shr	$16, %eax
	movw	%ax, (14*8+6)

	# Exception 15
	movl	$_exception15, %eax
	movw	%ax, (15*8)
	movw	$0x08, (15*8+2)
	movw	$0x8e00, (15*8+4)
	shr	$16, %eax
	movw	%ax, (15*8+6)

	# Exception 16
	movl	$_exception16, %eax
	movw	%ax, (16*8)
	movw	$0x08, (16*8+2)
	movw	$0x8e00, (16*8+4)
	shr	$16, %eax
	movw	%ax, (16*8+6)

	# Exception 17
	movl	$_exception17, %eax
	movw	%ax, (17*8)
	movw	$0x08, (17*8+2)
	movw	$0x8e00, (17*8+4)
	shr	$16, %eax
	movw	%ax, (17*8+6)

	# Exception 18
	movl	$_exception18, %eax
	movw	%ax, (18*8)
	movw	$0x08, (18*8+2)
	movw	$0x8e00, (18*8+4)
	shr	$16, %eax
	movw	%ax, (18*8+6)

	# Exception 19
	movl	$_exception19to31, %eax
	movw	%ax, (19*8)
	movw	$0x08, (19*8+2)
	movw	$0x8e00, (19*8+4)
	shr	$16, %eax
	movw	%ax, (19*8+6)


	
	popa
	ret
	
/*----------------------------------------------------------------------------
 * EXCEPTION HANDLERS
 *---------------------------------------------------------------------------*/
	
/* Devide by zero exception */
_exception00:
	cli
	pushl $0   # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $0   # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_00
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Debug exception */
_exception01:
	cli
	pushl $0   # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $1   # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_01
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp

	deal_with_it
	

/* NMI exception */
_exception02:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $2    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_02
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it



/* Breakpoint exception */
_exception03:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $3    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_03
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	deal_with_it


	
/* Overflow exception */
_exception04:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $4    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_04
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	deal_with_it

/* Out of Bounds exception */
_exception05:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $5    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_05
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it
	
/* Invalid OpCode exception */
_exception06:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $6    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_06
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* No coprocessor exception */
_exception07:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $7    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_07
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Double Fault exception */
_exception08:  # ERROR CODE PUSHED BY PROCESSOR
	cli
	pushl $8    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_08
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Coprocessor Segment exception */
_exception09:
	cli
	pushl $0    # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $9    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_09
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Bad TSS exception */
_exception10:  # ERROR CODE PUSHED BY PROCESSOR
	cli
	pushl $10    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_10
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it


/* Segment not present exception */
_exception11:  # ERROR CODE PUSHED BY PROCESSOR
	cli
	pushl $11    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_11
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Stack Fault exception */
_exception12:  # ERROR CODE PUSHED BY PROCESSOR
	cli
	pushl $12    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_12
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* General Protection Fault exception */
_exception13:  # ERROR CODE PUSHED BY PROCESSOR
	cli
	pushl $13    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK		
	pushl	$ex_msg_13
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it


/* Page fault exception */
_exception14:  # ERROR CODE PUSHED BY PROCESSOR
	cli
	pushl $14    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK	
	pushl	$ex_msg_14
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp

	deal_with_it


/* Unknown Interrupt exception */
_exception15:
	cli
	pushl $0     # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $15    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK	
	pushl	$ex_msg_15
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Coprocessor Fault exception */
_exception16:
	cli
	pushl $0     # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $16    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK	
	pushl	$ex_msg_16
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it

/* Alignment Check exception */
_exception17:
	cli
	pushl $0     # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $17    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK	
	pushl	$ex_msg_17
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp
	
	deal_with_it


/* Machine Check exception */
_exception18:
	cli
	pushl $0     # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $18    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)
	
	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK
	pushl	$ex_msg_18
	pushl	$24
	pushl	$0
	call print	
	addl	$20, %esp
	
	deal_with_it

/* Reserved exception */
_exception19to31:
	cli
	pushl $0       # TO BE USED BY deal_with_it (ERROR CODE)
	pushl $1931    # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

	pushl   $0x07       # FG: GREY
	pushl   $0x00       # BG: BLACK
	pushl	$ex_msg_19
	pushl	$24
	pushl	$0
	call print
	addl	$20, %esp # POINT STACK POINTER 5 POSITIONS BACK
	
	deal_with_it

	
.section .data
ex_msg_00:
	.asciz	"Divide by zero exception                        "
ex_msg_01:
	.asciz	"Debug exception                                 "
ex_msg_02:
	.asciz	"NMI exception                                   "
ex_msg_03:
	.asciz	"Breakpoint exception                            "
ex_msg_04:
	.asciz	"Overflow exception                              "
ex_msg_05:
	.asciz	"Out of Bounds exception                         "
ex_msg_06:
	.asciz	"Invalid OpCode exception                        "
ex_msg_07:
	.asciz	"No coprocessor exception                        "
ex_msg_08:
	.asciz	"Double Fault exception                          "
ex_msg_09:
	.asciz	"Coprocessor Segment exception                   "
ex_msg_10:
	.asciz	"Bad TSS exception                               "
ex_msg_11:
	.asciz	"Segment not present exception                   "
ex_msg_12:
	.asciz	"Stack Fault exception                           "
ex_msg_13:
	.asciz	"General Protection Fault exception              "
ex_msg_14:
	.asciz	"Page fault exception                            "
ex_msg_15:
	.asciz	"Unknown Interrupt exception                     "
ex_msg_16:
	.asciz	"Coprocessor Fault exception                     "
ex_msg_17:
	.asciz	"Alignment Check exception                       "
ex_msg_18:
	.asciz	"Machine Check exception                         "
ex_msg_19:
	.asciz	"Reserved exception                              "

action_msg:	
	.asciz  "You should reboot the machine !"
	


