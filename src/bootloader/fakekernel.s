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

# THIS IS THE CODE ENTRY POINT
_start: 

	# WARNING: THIS INSTRUCTION MUST BE DONE HERE.
	#          IF YOU DO THIS AT THE printmsg BLOCK YOU END UP
	#          WITH AN INFINITE LOOP THAT ONLY PRINTS THS FIRST
	#          CHARACTER OF THE msg
	leaw msg, %si      # COPY ADDRESS OF msg TO REGISTER $si
	                   # - msg IS DEFINED AT THE END OF THIS FILE
	                   
# PRINT MSG TO SCREEN!
printmsg:
	lodsb              
	orb %al,%al
	jz waitkey
	movb $0x0e, %ah
	mov $0x0007, %bx
	int $0x10
	jmp printmsg


waitkey:
        mov     $0x0, %ah  # WAIT FOR A KEY PRESS
        int     $0x16
	
end:	
	#cli
	#hlt
	jmp end


# IT'S COMMON PRACTICE TO DECLARE ALL MESSAGE "VARIABLES"
# AT THE END OF THE FILE
msg:	.asciz " >>FAKE KERNEL LOADED --- IT SEEMS THE BOOTLOADER WORKED. Yay!!\n\r"
