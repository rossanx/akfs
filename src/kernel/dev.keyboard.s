/*      
 * File: dev.keyboard.s
 * This code is part of the kalimera system project.
 * Author: Rossano Pablo Pinto (rossano at gmail dot com)
 * Date: Tue Feb 10 17:52:46 BRT 2015
*/
	
//.set __DEBUG_KEYBOARD__

.global init_keyboard_device_driver
	
init_keyboard_device_driver:
	pusha

	/*
        * INITIALIZE PS/2 CONTROLLER - 	## 2020-01-23
	*  >>> THIS IS A SIMPLIFIED VERSION - IT DOEN'T DEAL WITH
	*  >>> EVERY POSSIBLE SITUATION
	* THIS INITIALIZATION DEALS WITH A PS/2 CONTROLLER WITH SINGLE CHANNEL
	*/
	
	/**** Start by disabling PS/2 devices ****/
	movb   $0xAD, %al    # COMMAND TO DISABLE PS/2 DEVICE 1
	outb   %al, $0x64    # SEND COMMAND TO CONTROLLER
	movb   $0xA7, %al    # COMMAND TO DISABLE PS/2 DEVICE 2
	outb   %al, $0x64    # SEND COMMAND TO CONTROLLER
	/**** Flush output buffer ****/
	inb    $0x60, %al    # READ PENDING BUFFER VALUE AND DISCARD IT (FLUSH)
	/*** Set configuration byte ****/
	movb   $0x20, %al    # ENABLE COMMAND REGISTER READ (READ CONFIG BYTE)
	outb   %al, $0x64    # SEND COMMAND TO CONTROLLER
	xor %eax, %eax       # ZERO OUT EAX
	inb    $0x64, %al    # READ CONTROLLER CONFIGURATION BYTE
	orb  $0b00000100, %al # SET CONFIGURATION BYTE VALUES
        #       ||||||||
        #       |||||||+->  1st PS/2 port interrupt (0 = disable)
        #       ||||||+-->  2nd PS/2 port interrupt (0 = disable)
        #       |||||+--->  DID POST SUCCEED ? ( 1 = SUCCESS)
        #       ||||+---->  ALWAYS ZERO
	#       |||+----->  1st PS/2 por clock (0 = enabled)
	#       ||+------>  2nd PS/2 por clock (0 = enabled)
	#       |+------->  1st PS/2 port translation (0 = disabled)
	#       +-------->  ALWAYS ZERO
	mov %eax, %ebx       # save EAX to EBX
	movb   $0x60, %al    # ENABLE COMMAND REGISTER WRITE (CONFIG BYTE)
	outb   %al, $0x64    # SEND CONFIGURATION BYTE TO THE CONTROLLER
	mov %ebx, %eax       # READ EBX TO EAX
	outb %al, $0x64      # WRITE CONFIGURATION BYTE BACK TO PS/2 CONTROLLER
	/**** Enable PS/2 devices ****/
	movb   $0xae, %al    # COMMAND TO ENABLE 1ST PORT OF PS/2 CONTROLLER
	outb   %al, $0x64    # SEND COMMAND TO CONTROLLER
	/**** Reset PS/2 devices ****/
	movb $0xff, %al
	outb %al, $0x64
	/* END OF PS/2 INITIALIZATION */

	
	/* INSTALL KEYBOARD INTERRUPT HANDLER */
	call install_keyboard_int_handler

	
	popa
	ret

install_keyboard_int_handler:
	pusha
	# IRQ 1 - KEYBOARD
	/**** INFORM KEYBOARD INTERRUPT HANDLER ****/
	movl	$readkeyboard, %eax    
	/**** WRITE IDT ENTRY 33 ****/
	movw	%ax, (33*8)
	movw	$0x08, (33*8+2)
	movw	$0x8e00, (33*8+4)
	shr	$16, %eax
	movw	%ax, (33*8+6)
	
	popa
	ret

/**** THIS IS THE INTERRUPT HANDLER FOR THE KEYBOARD ****/	
readkeyboard:    
	nop
	/**** SAVE REGISTERS ****/
	pusha

	#### PORT 0x64 	WHEN READING STATUS REGISTER
	# 7 6 5 4 3 2 1 0
	# | | | | | | | |
	# | | | | | | | +--> Output buffer status(1=full, 0=empty)
	# | | | | | | +----> Input buffer status (1=full, 0=empty)
	# | | | | | +------> System Flag (1=self test passed, 0=failed)
	# | | | | +--------> Command/Data available (0 = data available in
	# | | | |            at port 0x60, 1 = command available at port 0x64)
	# | | | +----------> Keyboard active (1=enabled, 0=disabled)
	# | | +------------> Error detected (1=error in trans., 0=no error)
	# | +--------------> Timeout error (1=keyboard timeout, 0=no error)
	# +----------------> Parity error (1=error, 0=no error)


	xorl %eax, %eax
	/**** READ KEY PRESSED ****/
	inb	$0x60, %al

	/**** IGNORE KEY RELEASE FOR NOW ****/
	cmp	$0, %al
	jng	.out
	
	push %eax
	call deal_with_key   /* dev.terminal.s */
	add $4, %esp


.out:
	
	/**** RESTORE REGISTERS ****/
	popa


	/**** THIS IS VERY IMPORTANT. WHEN FINISHED SERVING AN
	 **** INTERRUPT, YOU MUST INFORM PICs ABOUT IT (CLEAR INTERRUPT)
	 **** OTHERWISE PICs WILL CONTINUE RAISING AN INTERRUPT
	 **** >>>> IT LOOPS FOREVER !!!!
	 ****/
	movb	$0x20, %al      # TEL PIC1 THAT WE FINISHED SERVICING Int
	outb	%al, $0x20      #

	
	/**** RETURN FROM INTERRUPT ****/
	iret

