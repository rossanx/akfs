/*
* File: fakekernel.s
* This code is part of the kalimera system project.
* Author: Rossano Pablo Pinto (rossano at gmail dot com)
* Date: Tue Jan 07 14:17:32 BRT 2020
*/
	
	.code16               # Generate 16-bit code
	.text                 # Executable code location
	.globl _start;        # INFORMS CODE ENTRY POINT
	
#---------------------------------------------------------------------------	
	.set TOTAL_RAM, 0x7ee8 # TOTAL RAM INSTALLED
	.set MEMORY_SUFFIX, 'M'   # ACCEPT B OR M
	.set VIDEO, 0xb8000
	.set LINE_SIZE, 160
#---------------------------------------------------------------------------
	
# THIS IS THE CODE ENTRY POINT
_start: 

	# WARNING: THIS INSTRUCTION MUST BE DONE HERE.
	#          IF YOU DO THIS AT THE printmsg BLOCK YOU END UP
	#          WITH AN INFINITE LOOP THAT ONLY PRINTS THS FIRST
	#          CHARACTER OF THE msg
	leaw msg, %si      # COPY ADDRESS OF msg TO REGISTER $si
	                   # - msg IS DEFINED AT THE END OF THIS FILE
	                   
/* PRINT MSG TO SCREEN */
printmsg:
	lodsb              
	orb %al,%al
	jz print_total_memory_dec
	movb $0x0e, %ah
	mov $0x0007, %bx
	int $0x10
	jmp printmsg

/* PRINT MEMORY SIZE IN DECIMAL
 *
 * THIS FUNCTION READS THE VALUE STORED BY THE BOOTLOADER AT POSITION
 * "MEMORY_SIZE_AREA", CONVERTS THE HEXADECIMAL NUMBER TO DECIMAL, AND
 * PRINTS IT TO SCREEN. 
*/
print_total_memory_dec:
	movl $hexnumbers, %esi    # SET HEX NUMBERS TABLE ADDRESS	
	mov  $(VIDEO+(LINE_SIZE*3)+1), %edi # LOAD VIDEO MEMORY ADDRESS	
	xorl %ecx, %ecx           # USED AS HEX VALUE HOLDER IN EACH ITERATION
.divisor:
	.int 10
	
	movl TOTAL_RAM, %eax      # READ TOTAL TO EAX REGISTER
	xorl %edx, %edx           # HIGH DWORD - WE ARE DEALING WITH 32BITS
	                          #              SO ALWAYS 0
	
.check_memory_suffix:
	movl $MEMORY_SUFFIX, %ebx
	cmpl $'M', %ebx
	jne .exit_check_memory_suffix
	shrl $20, %eax            # DIVIDE TOTAL_RAM BY 1M
.exit_check_memory_suffix:

	
	movl $18, %ebx            # INITIALIZE LOOP COUNTER
.print_total_memory_dec_loop:
	xorl %edx, %edx        # RESET EDX TO ZERO (
	divl .divisor         # DIVIDE TOTAL BY 10. AX->QUOTIENT, DX->REMAINDER
	movb $0x37, 7(%esi)       # TEMPORARY WORKAROUND FOR MEMORY TRASHING
	movb (%esi,%edx,1), %ch   # READ NUMBER FROM TABLE TO CH REGISTER
	movb $0x7, %cl            # FG:LIGHTGREY, BG:BLACK
	#---- PUSH TO THE STACK INSTEAD OF PRINTING RIGHT AWAY
	#movw %cx, (%ebx,%edi)     # WRITE NUMBER TO SCREEN: OFFSET EBX
	pushw %cx
	#-----------------------------------------------------
	subl $2, %ebx              # DECREMENT 2 FROM EBX (BACKWARD 1 CHAR)
	cmp $0, %ebx              # IF EBX IS GREATER THAN 0, LOOP
	jge .print_total_memory_dec_loop


	movl $10, %ebx   # INITIALIZE LOOP TO PRINT TO SCREEN
	movl $0, %eax    # SCREEN OFFSET
.read_stack:
	cmp $0, %ebx
	je .write_memory_suffix
	sub $1, %ebx     # DECREMENT 1 FROM LOOP
	popw %cx         # READ STACK
	cmpb $'0', %ch   # IF LEFT MOST NIBBLE IS ZERO, DON'T PRINT IT
	je .read_stack
.print_to_screen:	
	movw %cx, (%eax,%edi)     # WRITE NUMBER TO SCREEN: OFFSET EBX
	addl $2, %eax
	jmp .read_stack_without_zero_omitting

.read_stack_without_zero_omitting:
	cmp $0, %ebx
	je .write_memory_suffix
	sub $1, %ebx     # DECREMENT 1 FROM LOOP
	popw %cx         # READ STACK
	jmp .print_to_screen
.write_memory_suffix:
	
	movl $MEMORY_SUFFIX, %ebx
	cmpl $'M', %ebx
	jne .write_B
.write_MB:
	movb $0x7, %cl            # FG:LIGHTGREY, BG:BLACK
	movb $'M', %ch            # M CHARACTER
	addl $2, %eax             # INCREMENT SCREEN POSITION		
        movw %cx, (%eax,%edi)     # WRITE CHAR TO SCREEN: OFFSET EBX
        movb $'B', %ch            # M CHARACTER
	add $2, %eax
        movw %cx, (%eax,%edi)     # WRITE CHAR TO SCREEN: OFFSET EBX
	jmp .exit_write_memory_suffix
.write_B:
	movb $0x7, %cl            # FG:LIGHTGREY, BG:BLACK
	movb $'B', %ch            # M CHARACTER
	addl $2, %eax             # INCREMENT SCREEN POSITION		
        movw %cx, (%eax,%edi)     # WRITE CHAR TO SCREEN: OFFSET EBX	
.exit_write_memory_suffix:



	
/* END OF PROGRAM (AND SYSTEM, :)) */	
end:
	cli
	hlt
	jmp end


# IT'S COMMON PRACTICE TO DECLARE ALL MESSAGE "VARIABLES"
# AT THE END OF THE FILE
msg:	.asciz " >>FAKE KERNEL LOADED --- IT SEEMS THE BOOTLOADER WORKED. Yey!!\n\r"
	.align 8	
hexnumbers: .ascii  "0123456789ABCDEF"
