/*
 * File: kalimera.s
 * This code is part of the kalimera system project.
 * Author: Rossano Pablo Pinto (rossano at gmail dot com)
 * Date: Tue Feb 10 17:52:46 BRT 2015
 */

/***********************************************************************
 * MEMORY MAP AFTER KERNEL BOOT
 *      
 *   0x00000000-0x000007ff - IDT
 *   0x00000800-0x00000817 - GDT
 *   0x0000f0f0-0x0000ffff - CONFIG_AREA
 *   ......
 *   0x00010000-0x.....    - kernel
 *   ......
 *             -0x04000000 - kernel stack (GROWS DOWNWARDS)
*************************************************************************/

.section .text

	.set TOTAL_RAM, 0xf0f0
	.set MEMORY_SUFFIX, 'M'
	.set VIDEO, 0xb8000
	.set LINE_SIZE, 160
/*      
 * CREATE "POINTERS" TO TABLES GDT AND IDT
 *
 *  - IDT STARTS AT MEMORY ADDRESS 0x0
 *  - GDT COMES RIGHT AFTER IDT, SO ADDRESS 0x800
 */

idt_ptr:
	.word 0x800         # SIZE
	.long 0x0           # ADDRESS - YEAH, FIRST BYTE OF MEMORY

gdt_ptr:
	.word 0x818-0x800-1 # SIZE
	.long 0x800         # ADDRESS
	
.code16
.globl _start;
_start:	

	/* ENABLE A20 - ENABLES ADDRES LINE 20 */
        in      $0x92,  %al    # THIS ENABLES ACCESS TO ALL MEMORY AVAILABLE
        or      $0x02,  %al    # TO REAL MODE. LOOK FOR "A20 LINE x86" ON THE 
        out     %al,    $0x92  # WEB IF YOU WANT TO KNOW THE DETAILS
	
	/* SET STACK SEGMENT AND STACK POINTER */
        xorw    %ax, %ax       # SET %ax REGISTER TO ZERO
        movw    %ax, %ss       # SET ADDRESS OF STACK SEGMENT TO ZERO
        movw    $8192, %sp     # POINT %sp TO 8K (TOP OF THE STACK)

        /* DISABLE INTERRUPTS - VERY, VERY IMPORTANT */
        cli
	
/*
 * INSERT VALUES INTO THE GDT - CREATE GDT
 * VALUES ARE DESCRIBED AT DOCUMENT my-kernel-gdt.ods AND docs/journal.md
 *                                               "PLEASE READ THE DOCS"
 *	- EACH ENTRY IS 8 BYTES LONG
 *      - WE DEFINE 3 ENTRIES
 *        -- A DUMMY ENTRY (0x0)
 *        -- AN ENTRY FOR THE CODE SEGMENT (0x8)
 *        -- AN ENTRY FOR THE DATA SEGMENT (0x10)
 */
buildgdt:	
	/* ENTRY 0x0 - RECOMMENDED BY INTEL (dummy) */
        movw    $0x0000, 0x800
        movw    $0x0000, 0x802
        movw    $0x0000, 0x804
        movw    $0x0000, 0x806

        /* ENTRY 0x8 - CODE SEGMENT */
        movw    $0xFFFF, 0x808
        movw    $0x0000, 0x80A
        movb    $0x00,   0x80C
        movb    $0x9A,   0x80D
        movb    $0xCF,   0x80E
        movb    $0x00,   0x80F
                
        /* ENTRY 0x10 -  DATA SEGMENT */
        movw    $0xFFFF, 0x810
        movw    $0x0000, 0x812
        movb    $0x00,   0x814
        movb    $0x92,   0x815
        movb    $0xCF,   0x816
        movb    $0x00,   0x817

	
/* INFORMS CPU THE ADDRESS OF GDT AND IDT */        
loadxDT:
        addr32 lgdtl    gdt_ptr
        addr32 lidtl    idt_ptr

	
/* ENABLES PROTECTED MODE (32 bits) */  
setPMbit:       
        mov     %cr0, %eax   # COPY CONTROL REGISTER 0 TO %eax
        bts     $0x0, %eax   # SET BIT 0 TO 1 (THIS ENABLES PROTECTED MODE)
        mov     %eax, %cr0   # WRITE NEW VALUE TO CONTROL REGISTER 0

        /* I HAD TO WRITE THE NEXT INSTRUCTION USING OPCODE INSTEAD OF
         * THE MNEMONIC (GAS doesn't generate THE OPCODE FOR THIS...)
         * - THE OPCODE REPRESENTS A "far jump"
         * - The format of the instruction is
         *   0x66,0xea  <TARGET ADDRESS> <GDT ENTRY>
         *
         *   IN THIS CASE, WE ARE JUMPING TO "FUNCTION" setData
         *   AND USING THE SECOND ENTRY OF GDT (0x8)
         */
        .byte   0x66, 0xea    
        .long   setDATA         # JUMPS TO setData
        .word   0x8


################################ 32 bit code ################################
.code32
setDATA:

        /* DATA DESCRIPTOR */
        mov     $0x10, %eax   # INFORMS GDT ENTRY RESPONSIBLE FOR DATA SEGMENT
        mov     %eax, %ss
        mov     %eax, %ds
        mov     %eax, %es
        mov     %eax, %fs
        mov     %eax, %gs


test_protected_mode:
        smsw    %ax            # LOAD lower 16 bit CR0 to %ax
        and     $0x1, %ax      # TEST IF PE IS ENEBLED
        jnz protected_mode_ok
        jz  halt

/* IF PROTECTED MODE IS "WORKING", YOU SHOULD SEE A YELLOW MESSAGE AT
 * THE TOP OF THE SCREEN THAT READS:
 *	
 *             KALIMERA KERNEL >> 32bits Protected Mode <<
 */        	
protected_mode_ok:
        xor     %eax, %eax
        mov     $0xE,   %ah   # FG:YELLOW, BG:BLACK
        cld
        mov     $msgkernel, %esi #$msgkernel, %esi
        mov     $VIDEO+32, %edi   # WRITE MESSAGE AT POSITION 16, FIRST LINE
        mov     $MSGLEN,    %ecx        
.loop0:
        lodsb
        stosw
        loop .loop0

/* LET'S CELEBRATE WITH AN "ENTERPRISE!!!!" ANIMATION */
jmp print_enterprise
	
#----------------------------------------------------------------------
msgkernel:
        .asciz "KALIMERA KERNEL >> 32bits Protected Mode <<"
        .equ    MSGLEN, . - msgkernel


	
/***************************************************************************
 * YOU CAN SIMPLY IGNORE THE CODE FROM THIS POINT ON.                      *
 * >>>>> IT'S JUST SOME ENTERPRISE ANIMATION TO CELEBRATE 32bit PM. <<<<<< *
 ***************************************************************************/

	
/* LET'S CELEBRATE WITH AN "ENTERPRISE!!!!" */	
print_enterprise:
	xorl %eax, %eax
	movl  $(VIDEO+(LINE_SIZE*7)), %edi # LOAD VIDEO MEMORY ADDRESS		
        movl $7, %ebx                      # INITIALIZE OUTER LOOP
	movl $line1, %esi                  # GET ADDRESS OF 1ST STRING
	jmp .after_read_line
.read_line:
	cmp $0, %ebx             # LOOP COUNTER REACH 0 ?
	je .end_print_enterprise
	addl $L1LEN, %esi        # GET ADDRESS OF NEXT LINE
	addl $LINE_SIZE, %edi
.after_read_line:	
	subl $1, %ebx     # DECREMENT OUTER LOOP
	xorl %edx, %edx   # ZERO OUT STRING INDEX
	movl $31, %eax
.put_char:
	movb (%esi,%edx,1), %ch # MOVE CHAR FROM STRING TO %ch
	cmpb $0, %ch            # CHECK IF IT'S THE END OF THE STRING
	je .read_line           # IF THIS IS THE END, READ NEXT LINE
	movb $0x2, %cl          # GREEN ON BLACK
        movw %cx, (%eax,%edi)   # WRITE NUMBER TO SCREEN: OFFSET EAX
        addl $2, %eax           # MOVE CURSOR TO THE RIGHT
	addl $1, %edx           # INCREMENT STRING INDEX
        jmp .put_char
.end_print_enterprise:	


/* ANIMATE ENTERPSISE */
.set ENGINE_POS, (VIDEO+(LINE_SIZE*12)+39)	
animate:
	xorl %ecx, %ecx
	movl $ENGINE_POS, %edi
.engine:		

/* PUT DASH */	
	xorl %ebx, %ebx	
	mov $8, %eax
.put_dash:	
	mov $0xE, %cl          
	mov $'-', %ch
        movw %cx, (%ebx, %edi)
	call sleep
	cmp $0, %eax
	je .initialize_put_space
	subl $1, %eax # DECREMENT OUTER LOOP
	subl $2, %ebx # MOVE SCREEN CURSOR
	jmp .put_dash
/* PUT SPACE */
.initialize_put_space:	
	xorl %ecx, %ecx
	xorl %ebx, %ebx	
	movl $8, %eax
	movl $ENGINE_POS, %edi	
.put_space:	
	mov $0xE, %cl          
	mov $' ', %ch
        movw %cx, (%ebx, %edi)
	call sleep
	cmp $0, %eax
	je .end_of_put_space
	subl $1, %eax # DECREMENT OUTER LOOP
	subl $2, %ebx # MOVE SCREEN CURSOR
	jmp .put_space	
.end_of_put_space:
/*-------------------*/	
	
	jmp animate


/* HALT */	
halt:
        hlt
        jmp halt

/* SLEEP - THE HARDCORE WAY - WITHOUT rdtscp :)) */
sleep:
	pusha
	movl $0x00FFFFFF, %eax
	xorl %ebx, %ebx
.count_down:
	subl $1, %eax
	cmp $0, %eax
	jne .count_down
	cmp $0x0000FFFF, %ebx
	jge .end_sleep
.count_up:
	addl $1, %ebx
.refill_eax:
	movl $0x00FFFFFF, %eax
.end_sleep:	
	popa
	ret
	

#-----------------------------------------------------------------
	
line1:
        .asciz "_________________            _-_               "
        .equ   L1LEN, . - line1
	
line2:                           
        .asciz "\\________________)  ____.---'---`-.______     "
        .equ   L2LEN, . - line2

line3:
	.asciz "             \\_ \\    \\-------+---+-------/  "
        .equ   L3LEN, . - line3
	
line4:
	.asciz "                  \\ \\   /  /    `-_-'        "
	.equ   L4LEN, . - line4
	
line5:
	.asciz "              .__,--`.`-'..'-_                 "
	.equ   L5LEN, . - line5
	
line6:
	.asciz "             /___RPPNCC1701 |[                 "
	.equ   L6LEN, . - line6
	
line7:
	.asciz "                  `--.____,-'                  "
	.equ   L7LEN, . - line7
