/*
 * File: dev.pic.s
 * This code is part of the kalimera system project.
 * Author: Rossano Pablo Pinto (rossano at gmail dot com)
 * Date: Tue Feb 10 17:52:46 BRT 2015
 */

.global init_pic_device_driver
	
init_pic_device_driver:
	pusha

.remapIRQController:

	movb	$0x11, %al
	outb	%al, $0x20
	outb	%al, $0xA0

	/**** PIC1 IRQ0 now emits value 32 (0x20) ****/
	movb	$0x20, %al     
	outb	%al, $0x21
	/**** PIC2 IRQ8 now emits value 40 (0x28) ****/
	movb	$0x28, %al     
	outb	%al, $0xA1

	/**** Connect the two PICs ****/
	movb	$0x04, %al     
	outb	%al, $0x21
	movb	$0x02, %al
	outb	%al, $0xA1

	/**** Automatically perform EOI (End-of-Interrupt) ****/
	movb	$0x01, %al     
	outb	%al, $0x21     ####### NOT WORKING - I have to explicitly
	outb	%al, $0xA1     ####### write $0x20 to PICs

	
	popa
	ret
	
