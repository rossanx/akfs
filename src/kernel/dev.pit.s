/*	
 * File: dev.pit.s
 * This code is part of the kalimera system project.
 * Author: Rossano Pablo Pinto (rossano at gmail dot com)
 * Date: Tue Mar 24 17:52:46 BRT 2015	
 */
	

.global configure_pit
.set    TICRATE, 1193182
.set	HZ, 100    # About 10ms resolution

	
configure_pit:
	pusha

	# SET MODE TO BINARY
	mov	$0x34, %al
	outb	%al, $0x40

	movl	$0, %edx        # CLEAR DIVIDEND (it crashes otherwise)
	movl	$TICRATE, %eax  # DIVIDEND
	movl	$HZ, %ecx       # DIVISOR
	div 	%ecx            # RESULT IN %eax (and %edx when 64 bits)
	
	outb	%al, $0x40    # LSB
	shr	$8, %ax
	outb	%al, $0x40    # MSB
	
	popa
	ret
	
