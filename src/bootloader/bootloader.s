/*
* File: bootloader.s
* This code is part of the kalimera system project.
* Author: Rossano Pablo Pinto (rossano at gmail dot com)
* Date: Tue Feb 10 17:52:46 BRT 2015
*/
	
	.code16               # Generate 16-bit code
	.text                 # Executable code location
	.globl _start;        # INFORMS CODE ENTRY POINT
	
#--------------------------------------------------------------------------
	/* SOME USEFUL VARIABLES */

	.set KADDR, 0x7f0   # THIS IS USED TO KEEP BOTH bootloader
		  	    # AND fakekernel IN THE SAME SEGMENT
	
	#.set KADDR, 0x1000 # REAL KERNEL ADDRESS


	
#--------------------------------------------------------------------------
EDDPACKET:
	.byte  16, 0, 122, 0  # packet-size, always 0, sectors-max127, always 0
        .short 0x0000, KADDR  # BUFFER MEMORY ADDRESS	
       #.short 0x0000, 0x1000 # BUFFER MEMORY ADDRESS
	                      # - it will result in address 0x10000 (64k)
	                      # - Yeah, Intel 16 bit mode addressing nonsense
	                      #   (Kidding!! But explanation not important here,
	                      #    check x86 memory segmentation and addresses
	                      #    with 20 bits)
	.quad  0x00000001     # LBA Sector Number to start reading
#---------------------------------------------------------------------------	

_start:                    # THIS IS THE CODE ENTRY POINT
	
	mov %cs, %ax       # MAKE DATA SEGMENT SAME AS CODE SEGMENT!
	mov %ax, %ds       # - YOU CAN'T COPY %cs TO %ds OR %es, BUT YOU
	mov %ax, %es       #   CAN COPY %cs TO %ax, AND YOU CAN COPY
	                   #   %ax to BOTH %ds AND %es, SO USE %ax TO
	                   #   DO THAT.

	# WARNING: THIS INSTRUCTION MUST BE DONE HERE.
	#          IF YOU DO THIS AT THE printmsg BLOCK YOU END UP
	#          WITH AN INFINITE LOOP THAT ONLY PRINTS THS FIRST
	#          CHARACTER OF THE msg
	leaw msg, %si      # COPY ADDRESS OF msg TO REGISTER $si
	                   # - msg IS DEFINED AT THE END OF THIS FILE
	                   
	# CLEAR SCREEN
	mov $0x00, %ah
	mov $0x03, %al
	int $0x10
	
# PRINT MSG TO SCREEN!
printmsg:
	lodsb              
	orb %al,%al
	jz loadkernel
	movb $0x0e, %ah
	mov $0x0007, %bx
	int $0x10
	jmp printmsg



loadkernel: # kernel is located at disk sectors 2, 3, 4, ...	
	lea EDDPACKET, %si #  
	mov $0x80, %dl     # READ FROM DISK HDA
	mov $0x42, %ah     # EDD Service
	int $0x13          # DISK SERVICE


waitkey:
	mov	$0x0, %ah  # WAIT FOR A KEY PRESS
	int	$0x16
	
	mov	$0x0, %ah  # CLEAR SCREEN
	mov	$0x03, %al
	int	$0x10
	
	
dispatch:

	ljmp $KADDR, $0x0 # FAR JUMP to 0x10000 (64K) [0x1000:0x0 -> 0x10000]	
	#ljmp $0x1000, $0x0 # FAR JUMP to 0x10000 (64K) [0x1000:0x0 -> 0x10000]
                           # - THIS PASSES CONTROL TO THE KERNEL.
	                   #   IF SUCEEDED, NO MORE CODE FROM THE BOOTLOADER
	                   #   IS EXECUTED


# THIS CODE SHOULD NEVER BE REACHED, IF EVERYTHING IS OK
# WE JUMP TO KERNEL AND NEVER COME BACK
end:	
	cli
	hlt
	jmp end


# IT'S COMMON PRACTICE TO DECLARE ALL MESSAGE "VARIABLES"
# AT THE END OF THE FILE
msg:	.asciz ">KALIMERA BOOT LOADER --- Press enter to run kernel\n\r"

	
# THIS IS THE BOOT SIGNATURE. x86 FIRMWARE EXPECTS THIS	
bootsignature:			
     .org 510          # "GO TO" byte 510 byte
     .byte 0x55, 0xaa  # WRITE BOOT SIGNATURE
