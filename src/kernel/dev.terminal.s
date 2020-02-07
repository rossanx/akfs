.global init_terminal
.global deal_with_key	

init_terminal:
	/***   VRAM  ***/
	movl $0xb8000, VRAM

set_initial_cursor_position:
	movl $(80 * 15 - 2), cursor_offset
	movl $(160 * 15 - 4), char_offset
	
deal_with_key:
	pushl   %ebp
        movl    %esp, %ebp
	movl    8(%esp), %eax

	/**** WHERE TO PRINT ****/
	mov	VRAM, %edi


/**** ASSOCIATE KEY VALUES TO ACTIONS ****/
	
	/**** IF KEY IS "DEL", INVOKE AN APPROPRIATE ACTION ****/
	cmp	$0x0e, %al
	je	.delkey

	/**** IF KEY IS "ENTER", INVOKE AN APPROPRIATE ACTION ****/
	cmp	$0x1c, %al
	je	.enterkey

/**** PRINT CHAR IF NO ACTION DEFINED FOR THE KEY ****/	

	/**** "INSTALL" KEYMAP ****/
	xorl %ebx, %ebx
	movl	$keymap, %esi	
	xor     %ecx, %ecx
	movb	%al, %bl
	movb	(%esi, %ebx, 1), %cl

	/**** PRINT CHAR ON THE SCREEN ****/
	movl    (char_offset), %ebx
	movb	%cl, %es:(%edi, %ebx, 1)
	addl    $2, char_offset
	
	/**** MOVE CURSOR ON THE SCREEN ****/
	addl    $1, cursor_offset
	call    move_cursor

	jmp 	.out

/**** ACTIONS *****/
	
	/**** ACTION FOR DEL KEY ****/
.delkey:
	/** "DELETE" CHAR **/
	movl	char_offset, %ebx
	subl    $2, %ebx
	movl    %ebx, char_offset
	movb	$' ', %es:(%edi, %ebx, 1)
	
	/** MOVE CURSOR **/
	subl $1, cursor_offset
	call move_cursor

	jmp 	.out

	/**** ACTION FOR ENTER KEY ****/
.enterkey:
	/** DEAL WITH char_offset **/
	movl char_offset, %eax
	addl char_line_size, %eax
	xorl %edx, %edx
	divl char_line_size
	mull char_line_size
	movl %eax, char_offset # NOW WE ARE AT THE BEGINNING OF THE NEXT LINE

	/** DEAL WITH cursor_offset **/
	movl cursor_offset, %eax
	addl cursor_line_size, %eax
	xorl %edx, %edx
	divl cursor_line_size
	mull cursor_line_size
	movl %eax, cursor_offset # NOW WE ARE AT THE BEGINNING OF THE NEXT LINE
	call move_cursor

	/* YEAH, REDUNDANT FOR NOW, BUT WE INTEND TO ADD MORE ACTIONS */
	jmp	.out

.out:
	
	pop %ebp
	ret
	

move_cursor:	
	/* SET CURSOR POSITION
	 *  - BX HOLDS THE POSITION
	 *  - YOU HAVE TO TRANSFER BX TO PORT 0x03D5 IN 2 STEPS
	 *    -- TRANSFER LOW PART TO 'LOW' REGISTER 0xF
	 *    -- TRANSFER HIGH PART TO 'HIGH' REGISTER 0xE
	 *       
	*/
	
	/* INFORM DESIRED CURSOR POSITION */
	movl (cursor_offset), %ebx
	
	/* INFORM YOU WANT TO TRANSFER TO LOW REGISTER */
	mov $0x03D4, %dx
	mov $0x0F, %al
	out %al, %dx   #->>>
	/* TRANSFER LOW VALUE TO LOW REGISTER */
	mov $0x03D5, %dx
	mov %bl, %al
	out %al, %dx   #->>>

	/* INFORM YOU WANT TO TRANSFER TO HIGH REGISTER */
	mov $0x03D4, %dx
	mov $0x0E, %al
	out %al, %dx   #->>>
	/* TRANSFER HIGH VALUE TO HIGH REGISTER */
	mov $0x03D5, %dx
	shr $8, %bx
	mov %bl, %al
	out %al, %dx   #->>>

	ret

/**** WELL, THAT'S OUR KEYMAP ****/	
#---------------------------------------------------------------------
keymap:
	.ascii " [1234567890-=[[qwertyuiop[][[asdfghjkl;'`["
	.byte	92 # value for backslash
	.ascii	"zxcvbnm,./[*[ [FFFFFFFFFF[[756-1230.[[C"
#---------------------------------------------------------------------

	
.section .data

/* THIS IS USED TO KEEP TRACK OF WHERE TO PUT THE CHAR */
VRAM:	.int 0

/* THIS IS USED TO KEEP TRACK OF WHERE TO PUT THE CURSOR AND CHAR */	

cursor_line_size:	.int 80	
cursor_offset:		.int 0

char_line_size:		.int 160
char_offset:		.int 0
	