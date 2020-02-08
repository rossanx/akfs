/*	
 * File: dev.clock.s
 * This code is part of the kalimera system project.
 * Author: Rossano Pablo Pinto (rossano at gmail dot com)
 * Date: Tue Mar 24 17:52:46 BRT 2015	
 */
	
.global init_clock_device_driver
	
clock:
	.long 0
	
init_clock_device_driver:
	pusha
	call install_clock_int_handler
	popa
	ret

install_clock_int_handler:
	pusha
	# IRQ 0 - TIMER
        /**** INFORM KEYBOARD INTERRUPT HANDLER ****/
	movl	$clock_int_handler, %eax
        /**** WRITE IDT ENTRY 32 ****/
	movw	%ax, (32*8)
	movw	$0x08, (32*8+2)
	movw	$0x8e00, (32*8+4)
	shr	$16, %eax
	movw	%ax, (32*8+6)
	popa
	ret

#------------------------------------------------------------------
# CLOCK INTERRUPT HANDLER
#------------------------------------------------------------------

clock_int_handler:

	/** UPDATE CLOCK **/
	addl	$1, clock
	/** Print char at the top left corner (to show passage of time).*/

	mov	$0xA,	%ah   
	mov	clock,   %al
	movw 	%ax, 0xb8000
	
	/** TEL PIC1 THAT WE FINISHED SERVICING Int **/
        mov $0x20, %al  
        out %al, $0x20    
	
	/** RETURN FROM INTERRUPT (RESTORES EFLAGS, CS and EIP) **/
        iret            

