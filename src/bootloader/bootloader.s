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

	/* FAKEKERNEL ADDRESSES
	 * THIS IS USED TO KEEP BOTH bootloader AND fakekernel
	 * IN THE SAME SEGMENT
	 */
	.set KADDR, 0x800       
	.set TOTAL_RAM, 0x7ee8  

	
	/* REAL KERNEL ADDRESSES */
	#.set KADDR, 0x1000
	#.set TOTAL_RAM, 0xf0f0
	
#--------------------------------------------------------------------------
EDDPACKET:
	.byte  16, 0, 122, 0  # packet-size, always 0, sectors-max127, always 0
        .short 0x0000, KADDR  # BUFFER MEMORY ADDRESS
	                      # When using KADDR = 0x1000, it will result in
	                      # address 0x10000 (64k)
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

	/* WARNING: THIS INSTRUCTION MUST BE PLACED HERE.
	 *          IF YOU PLACE THIS AT THE printmsg BLOCK YOU END UP
	 *          WITH AN INFINITE LOOP THAT ONLY PRINTS THE FIRST
	 *          CHARACTER OF THE msg
	 */
	leaw msg, %si      # COPY ADDRESS OF msg TO REGISTER $si
	                   # - msg IS DEFINED AT THE END OF THIS FILE

	/* CLEAR SCREEN */
	call cls

	/* DETECT THE MOUNT OF RAM */
	call detect_memory
	
/* PRINT MSG TO SCREEN! */
printmsg:
	lodsb              
	orb %al,%al
	jz loadkernel	
	movb $0x0e, %ah
	mov $0x0007, %bx
	int $0x10
	jmp printmsg

/* LOAD KERNEL INTO MEMORY */	
loadkernel: # kernel is located at disk sectors 2, 3, 4, ...	
	lea EDDPACKET, %si #  
	mov $0x80, %dl     # READ FROM DISK HDA
	mov $0x42, %ah     # EDD Service
	int $0x13          # DISK SERVICE

/* WAIT FOR A KEY PRESS */	
waitkey:
	mov	$0x0, %ah  # WAIT FOR A KEY PRESS
	int	$0x16
	/* CLEAR SCREEN */
	call cls

/* JUMP TO THE KERNEL CODE */	
dispatch:
	/*
	*# ljmp $0x1000, $0x0 
	* FAR JUMP to 0x10000 (64K) [0x1000:0x0 -> 0x10000]
        * - THIS PASSES CONTROL TO THE KERNEL.
	*   IF SUCEEDED, NO MORE CODE FROM THE BOOTLOADER
	*   IS EXECUTED
	*/
	ljmp $KADDR, $0x0 # FAR JUMP to 0x10000 (64K) [0x1000:0x0 -> 0x10000]	
	
/* CLEAR SCREEN */
cls:
	pusha
	mov	$0x0, %ah
	mov	$0x03, %al
	int	$0x10
	popa
	ret
	
/*
 * THANKS TO GRUB, OSDEV, AND BROWN (INTERRUPT LIST) FOR THE VALUABLE
 * INFORMATION ON DETECTING MEMORY WITH 0xE820 !!!
 *
 * BROWN LIST ENTRY FOR 0XE820 -> http://www.ctyme.com/intr/rb-1741.htm:
    "AX = E820h
     EAX = 0000E820h
     EDX = 534D4150h ('SMAP')
     EBX = continuation value or 00000000h to start at beginning of map
     ECX = size of buffer for result, in bytes (should be >= 20 bytes)
     ES:DI -> buffer for result (see #00581)

     Return:
     CF clear if successful
     EAX = 534D4150h ('SMAP')
     ES:DI buffer filled
     EBX = next offset from which to copy or 00000000h if all done
     ECX = actual length returned in bytes
     CF set on error
     AH = error code (86h) (see #00496 at INT 15/AH=80h)
	
   Notes: ... A maximum of 20 bytes will be transferred at one time,
	even if ECX is higher; some BIOSes ... ignore the value of ECX
	on entry, and always copy 20 bytes. Some BIOSes expect the
	high word of EAX to be clear on entry, i.e. EAX=0000E820h...
	The BIOS is permitted to return a nonzero continuation value
	in EBX and indicate that the end of the list has already been
	reached by returning with CF set on the next iteration. This
	function will return base memory and ISA/PCI memory contiguous
	with base memory as normal memory ranges; it will indicate
	chipset-defined address holes which are not in use and
	motherboard memory-mapped devices, and all occurrences of the
	system BIOS as reserved; standard PC address ranges will not
	be reported "
 */
	
detect_memory:
	pusha	
	.set MAGICNUMBER, 0x534D4150
	.set BUFFER, 0x7ef0
	movl $0, TOTAL_RAM       # INITIALIZE TOTAL MEMORY TO ZERO
        movl $MAGICNUMBER, %edx  # MAGIC NUMBER
	movw $BUFFER, %di        # BUFFER - several bytes away from bootloader
	xorl %ebx, %ebx          # ZERO OUT EBX
.read_1st_entry:	
        movl $0x0000e820, %eax   # BIOS FUNCTION NUMBER
        movl $1, %es:20(%di)     # MAKE ACPI HAPPY !!!
        movl $24, %ecx           # EACH ENTRY SIZE (BROWN SAYS IT ONLY READS 20)
        int $0x15
.test_validity:	
	jc .error_detect_memory  # ERROR IF CARRY IS SET ON THE 1ST CALL
	movl $MAGICNUMBER, %edx  # MAGIC NUMBER
	cmpl %edx, %eax          # ON SUCCESSS, EAX MUST HOLD MAGIC NUMBER	
	jne .error_detect_memory
	testl %ebx, %ebx         # IF ZERO, "ERROR" (list with 1 entry only)
	je  .error_detect_memory #
	jmp .test_return_size    # OTHERWISE
.read_next:
	movl $0x0000e820, %eax   # BIOS FUNCTION NUMBER
	movl $1, %es:20(%di)     # MAKE ACPI HAPPY !!!
	movl $24, %ecx           # SIZE OF EACH ENTRY
	int $0x15
	jc .exit_detect_memory   # IF CF IS 1, END OF LIST - EXIT
	movl $MAGICNUMBER, %edx  # MAGIC NUMBER
.test_return_size:	
	jcxz .skip               # TEST IF ECX is 0
	cmpb $24, %cl            # DID I HAVE A 24byte RESPONSE FROM ACPI?
	jbe .increment
.increment:
	call add_to_total        # ADD MEMORY BLOCK SIZE TO TOTAL
	addw $24, %di            # INCREMENT BUFFER POINTER
.skip:
	testl %ebx, %ebx         # IF EBX IS ZERO, REACHED END OF LIST
	jne .read_next
.exit_detect_memory:
	popa
	ret	
.error_detect_memory:
	popa
	ret
	
/* ADD MEMORY SIZE TO TOTAL MEMORY SIZE!
 * BUT ONLY THE LOWER 32 BITS
 * SO, IF YOU HAVE MORE THAN 4GB OF MEMORY, IT WON'T DETECT
 */
add_to_total:
	pusha
	movl TOTAL_RAM, %eax
	addl %es:8(%di), %eax
	movl %eax, TOTAL_RAM
	popa
	ret

/* THIS CODE SHOULD NEVER BE REACHED, IF EVERYTHING IS OK
 * WE JUMP TO KERNEL AND NEVER COME BACK
 */	
end:	
	cli
	hlt
	jmp end


/* IT'S COMMON PRACTICE TO DECLARE ALL MESSAGE "VARIABLES"
 * AT THE END OF THE FILE
 */ 
msg:	    .asciz ">KALIMERA BOOT LOADER --- Press enter to run kernel\n\r"

	
/* THIS IS THE BOOT SIGNATURE. x86 FIRMWARE EXPECTS THIS */
bootsignature:			
     .org 510          # "GO TO" byte 510 byte
     .byte 0x55, 0xaa  # WRITE BOOT SIGNATURE
