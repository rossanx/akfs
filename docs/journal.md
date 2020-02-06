Author: rossano at gmail dot com

This document is a narrative of the process involved in creating this
kernel (kalimera). It discusses the sequence of events and the rationale
related to the choices we are going to make along the development.

=======================================================================

1 - Getting the system to execute our code as the first thing after
the firmware.

We have chosen the x86/i386 (a.k.a. PC) to be the target architecture
of the kernel. x86 systems start by executing the firmware located at the
main board (we are considering the execution of the BIOS and not
EFI/UEFI). As the last step, the firmware tries to load the first
sector of a bootable device. The most common size of a sector is 512
bytes. This first sector, when valid, must have the signature 0xAA55
at the end of the sector (byte 510 stores 0x55 and byte 511 stores
0xAA - remember that the counting starts at 0). This first sector is
called MBR and has the following format:

 - first 446 bytes: bootloader
 - space for four partition entries
 - last 2 bytes: 0xAA55 (boot signature)

The firmware does not care about the first 510 bytes. It is happy with
the boot signature, so we are free to write the first 510 bytes as we
wish. So, we are going to use all the available 510 bytes as our
bootloader (funny, it's so small and we used the phrase "all the
available 510 bytes" as if we had a huge space :)) ). The firmware
copies this sector to memory position 0x7C00 and checks if the values
0xAA and 0x55 are present at positions 0x7DFF and 0x7E00. If true, the
firmware instructs the CPU to jump to 0x7C00. Now we are in control of
the system, yey!!! We intend to put our kernel in an area that starts
at 0x10000 (64k). In short, the boot sequence is (This only renders on
GITLAB because it uses mermaid MD. So, if you are reading this from
GITHUB and want to see this graph, check this same project at GITLAB):

```mermaid
graph LR;
firmware -- LOADS/<br/>JUMP TO --> id1["bootloader<br/>at 0x7C00"] -- LOADS/<br/>JUMP TO --> id2["kernel at<br/>0x10000"];
```

Ok, you know the theory. Now we must provide some code to be loaded by
the firmware. Considering we have a machine (real or virtual - qemu or
virtualbox) that has a hard disk, we must provide a code that fits in
512 bytes (actually 510).

   SEE FILE src/bootloader/bootloader.s

After programming and compiling this bootloader we need a way of
writing it to the "MBR". If the machine is virtual (qemu) it's
easy. Write the bootloader to the start of the virtual hard disk (it's
a file). If it's a real machine, you do have some more steps: I
accomplish this using a bootable dvd with a live linux distro. I boot
the real machine with the live linux, then I transfer the bootloader
using "wget" or "scp", and write it to the real hard disk using "dd"
(I wrote a script that accomplishes that! It works like a charm -- TO
BE UPLOADED).

The final layout of our disk is supposed to be as follows:

      1st sector   2nd sector   3rd sector   4th sector       Nth sector
    +------------+------------+------------+------------+   +------------+
    | Bootloader | kernel 1/N | kernel 2/N | kernel 3/N |...| kernel N/N |
    +------------+------------+------------+------------+   +------------+

Yep, no filesystem at all!!! Let's work with bare sectors. Once the
kernel is loaded into memory we don't need the disk anymore.

=======================================================================

2 - The boot loader (src/bootloader/bootloader.s)

We could use LILO, GRUB or any other bootloader to boot our kernel. So
why are we having the trouble to create our own? Well, why are we
having the trouble to create our very own kernel? We could use Linux or
any other kernel. We don't need kalimera - akfs (a(nother) kernel from
scratch). I hope you've got the point... We are creating the
bootloader 'cause we can :)) The objective is to create as much as we
can...

Our bootloader will execute 2 main tasks:

    - Load the kalimera kernel to memory
    - Detect the amount of RAM installed in the system and write it to
      a configuration area to be used by the kernel
    
The bootloader is going to copy our kernel from sectors 2, 3, 4, and
so on, to a memory space starting at position 0x10000 (64K). Yeah,
that's right. The disk is going to be used as a raw pool of
sectors. NO FILESYSTEM AT ALL! At least for now. When our bootloader
is put to run, BIOS services are still available to us. Let's use a
BIOS service to copy our kernel from disk to memory. We are going to
use EDD (Enhanced Disk Drive Services) and the BIOS DISK service. In
order to use the EDD service, we need to specify a Disk Address Packet
(DAP) structure. This structure is used to instruct BIOS "interrupt"
13h (invoked with the instruction "int $0x13") what to copy and where
to put it. Excerpt from our bootloader (showing our DAP):

    EDDPACKET:
            .byte  16, 0, 122, 0  # packet-size, always 0, sectors-max127, always 0
            .short 0x0000, KADDR  # BUFFER MEMORY ADDRESS	
                                  # - it will result in address 0x10000 (64k)
                                  # - Yeah, Intel 16 bit mode addressing nonsense
                                  #   (Kidding!! But explanation not important here,
                                  #    check x86 memory segmentation and addresses
                                  #    with 20 bits)
            .quad  0x00000001     # LBA Sector Number to start reading

Observe the variable KADDR. It holds the memory address to put the
kernel. The only purpose of KADDR is to make it easy to switch from
test routines to the real kernel. With the use of KADDR, It's easy to
copy a program to the position pointed by KADDR and jump to it
(explained later - testing the bootloader).

Returning to the main topic, this DAP tells the BIOS "interrupt" 13h,
service 0x42, to copy 122 sectors from disk. It also instructs the
service to start copying from sector 1 and to store the contents to
memory buffer at address 0x10000 (64k). Sector 0 hosts our bootloader
(it's the "MBR"), so skip it from the copy.

There are several ways to detect the amount of memory installed in a
system. The memory detection can be done by the kernel or by the
bootloader. By far, the method used the most is based on the service
0xE820 of the BIOS interrupt 0x15. GRUB uses it. Let's do the same.
Service 0xE820 fills in a buffer with a list of system memory regions.
Each entry of the list has the following structure:

       - BASE ADDRESS OF THE REGION (64 bits)
       - REGION AMOUNT OF MEMORY(64 bits)
       - TYPE OF THE REGION (32 bits)
       - ACPI 3.0 EXTENDED ATTRIBUTES (32 bits)

Our bootloader will get each lower part (least significant 32 bits) of
the "REGION AMOUNT OF MEMORY" and add them together to get the total
memory installed in the system (TOTAL RAM). We don't care, at least
for now, if the memory is available for use or not, we only need the
total RAM. This value will be stored at positon 0xf0f0 so the kernel
can access it latter to make use of this information.

Ok. So now you have written the bootloader and you want to test if
it's working as expected. To do so, I suggest writing a small program
that prints a message to the screen. Also, make this program read the
total RAM value obtained by the bootloader and print it to the screen
in decimal format. Let's go ahead and do it to test our
bootloader. Take a look at the file src/bootloader/fakekernel.s to see
what's going on.

   SEE FILE src/bootloader/fakekernel.s

Next, follow these steps to make the bootloader run fakekernel.s:

             I created a Makefile with recipes to execute the next steps:

             A - Change variable to indicate bootloader to load
                 fakekernel instead of kalimera
             B - Assemble and link bootloader.s
             C - Assemble and link fakekernel.s
             D - create a qemu disk
             E - write the bootloader.bin to first sector
             F - write fakekernel.bin to second sector
             G - run qemu with all the parameters

             So, just go to the main directory of kalimera installation
             (it's where you put the files of the repository you cloned)
             and type:

                make clean; make testbl

=======================================================================

3 - Kernel main file (src/kernel/kalimera.s)

+-- Timestamp: 2020-01-07-13:20 ---+

The idea is to create the bare bones functionality in one file, and
from that file call other functions present in other files. The source
code of this first file is written in x86 assembly language. I prefer
using the AT&T format. In this format, the structure of the mnemonic
is:

    opcode source destination

So, if you want to copy the value 0x10 to register EAX, you would
write the following code:

    mov $0x10, %eax

On the other hand, in Intel format you reverse source and destination
like this: "opcode destination source", and the same example would be
written like this: "mov eax, 10h". The assembler I use to assemble the
code is GAS (GNU Assembler).

Ok, so let's get started. Our kernel is supposed to run in 32 bits
protected mode. Things are a little bit easier in real-mode, as you
don't need some of the structures present in protected-mode. In
real-mode the position of the interrupt vector table (IVT) is fixed at
the very beginning of memory. On the other hand, in protected-mode the
IVT can be placed anywhere in memory. In protected-mode, the IVT is
called IDT (Interrupt Descriptor Table). In protected-mode you can
configure areas of the memory to be used as code or data placeholders
with rigid limits. In order to do that, you create a table that
informs how the memory should be used and where that memory starts and
ends. This table is called GDT (Global Descriptor Table). Any process
that is created can have it's own GDT entry (usually a pointer to an
LDT - Local Descriptor Table - We are not using LDTs in kalimera, at
least for now). In our case, we are going to create kernel threads to
run our tasks (always switched to ring 0) - kalimera kernel will not
run user-space code, i.e., CPU running in ring 3, at least for now. In
doing so, every thread shares the same GDT entries.

GDT is a complex beast where you can configure a bunch of things
related to the segment you are trying to use and protect. We're
getting back to the GDT structure latter. First, let's talk about how
to swith from real-mode to protected-mode.

In order to run the x86 CPU in protected-mode you should execute the
following steps:

     **** CODE IN 16 BITS WITH THE PROCESSOR IN REAL-MODE ****

     FIRST STEP: DISABLE INTERRUPTS. THIS IS IMPORTANT. IF YOU SWITCH
                 TO PROTECTED-MODE WITHOUT DEFINING AN IVT, YOU WILL
                 CRASH YOUR MACHINE. IF AN INTERRUPT IS RAISED AND YOU
                 DONT'T HAVE AN INTERRUPT HANDLER (ISR) FOR THAT, BEHAVIOR
		 IS UNDEFINED. YOU COULD END UP EXECUTING WHATEVER GARBAGE
                 THE PROCESSOR WOULD EVENTUALLY POINT TO!!!! SO:
		 
                     cli
     NEXT:
         ..some other stuff that you can check in the code... The important
	 stuff:
	 
     A - Create a GDT with at least 3 entries:
         -- Dummy entry (recommended by Intel)
         -- CODE SEGMENT entry
         -- DATA SEGMENT entry
     B - Create a pointer to the GDT with the following structure:
         GDT SIZE, ADDRESS OF THE FIRST BYTE OF THE TABLE
     C - Create a pointer to the IDT with the following structure:
         IDT SIZE, ADDRESS OF THE FIRST BYTE OF THE TABLE
     D - Tell the CPU where those tables are in memory. To do that
         you use the instructions:

           addr32 lgdtl	gdt_ptr
           addr32 lidtl	idt_ptr

         Here, gdt_ptr and idt_ptr are the structures holding the information
	 described at B and C.
     E - Set the first bit in the CR0 register to 1. This informs the CPU it is
         in the process of switching to protected-mode. This bit is called PE.
     F - Execute a FAR JUMP instruction landing in 32 bit code. To do that
         you should execute the following CODE:

             .byte	0x66, 0xea      # FAR JUMP OPCODE
             .long	setDATA         # 1st OPCODE PARAM - JUMPS TO setData
             .word	0x8             # 2nd OPCODE PARAM - GDT ENTRY

         This code tells the CPU to JUMP to memory location
	 represented by the "variable" setDATA. But what the frak! Why
	 are we using opcodes instead of mnemonics? Sometimes it's not
	 possible to use a mnemonic to execute the instruction you
	 want to execute. The FAR JUMP from 16bit code to 32bit code
	 is one example where the assembler I'm using had problems to
	 generate the correct OPCODE. The mnemonic would be something
	 like this:

              ljmp target_address, gdt_entry

         A FAR JUMP is any jump that goes from one segment to another.

     **** CODE IN 32 BITS WITH THE PROCESSOR IN PROTECTED-MODE ****

     G - Code executing in 32 bits protected-mode. This first part of
         the code in 32bits executes the "function" setDATA. This
         "function" initializes all data segment registers with the
         GDT entry 0x10, which is an entry for a DATA SEGMENT. The
         code for that is like this:
	 
         .code32
         setDATA:

             /* DATA DESCRIPTOR */
             mov     $0x10, %eax   # INFORMS GDT ENTRY RESPONSIBLE FOR DATA SEGMENT
             mov     %eax, %ss
             mov     %eax, %ds
             mov     %eax, %es
             mov     %eax, %fs
             mov     %eax, %gs

     H - Test if PM bit in CR0 is set to 1. If so, I just print the message
         "KALIMERA KERNEL >> 32bits Protected Mode <<" to the screen.
	 
     I - In order to make things safer, I moved kernel stack out of the way!
         I set it to be at the end of memory. It grows downwards, as always:

            move_kernel_stack_to_end_of_memory:	
                    ### STACK AT THE END OF CONFIGURED MEMORY
                    movl	TOTAL_RAM, %ebp
                    movl	TOTAL_RAM, %esp

     J - In order to have some fun. After the message, I put an ascii
         art of the USS Enterprise on the screen and animate it. Yey!!!

As you could see it's not as easy as we present it to students when
teaching Operating Systems. Well, you use any abstraction that suits
the audience.

3.1 - GDT

Now let's cut to the chase. Let's code this.

   SEE FILE src/kernel/kalimera.s

I decided to make the GDT with the following entries:

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

Putting it in simple words, both the CODE SEGMENT and the DATA SEGMENT are 4GB
long, goes from 0x0 and 0xFFFFFFFF. Now let me break a GDT entry down. THIS IS
GOLD, SAVE IT SOMEWHERE.

Entry 0x8 (CODE SEGMENT) will be put in memory like this:

<pre>
                  Address                      Address
                    0x80F---+             +--- 0x808
                            |             |
                            v             v
      Higher addresses  - 0x00CF9A000000FFFF -  Lower Addresses
                       
Now let's break it down:

   * SEGMENT LIMIT
                               .        ....
      Higher addresses  - 0x00CF9A000000FFFF -  Lower Addresses
                               |        ||||
                               |        vvvv
			       +------>FFFFF This represents the limit of the
			                     segment. I prefer thinking
					     about it in terms o the number
			                     of "pages" of this segment.
					     This is a 20 bit number, all set
					     to "1".  2^20 equals 1M.
   * GRANULARITY
                              .
      Higher addresses  - 0x00CF9A000000FFFF -  Lower Addresses
                              |
                           +--+---+       
                           |      |
       Bit representation:   1100
	                     ||||
                             |||+-> RESERVED
                             ||+--> RESERVED			     
                             |+---> "1" This is a 32bit segment (0 is a 16bit)
                             +----> "1" Means "the page size" is 4k.
	                             This a multiplication factor. But I prefer
                                     thinking about it as the "page size"


            **************************************************************
            ****** So if you multiply 1M by 4K you end up with 4G. *******
            **************************************************************

   * BASE ADDRESS
                            ..    ......   
      Higher addresses  - 0x00CF9A000000FFFF -  Lower Addresses
                            ||    ||||||
                            |+---+||||||
                            +---+|||||||
                                ||||||||
                                vvvvvvvv
                                00000000 -> This represents the base address.

            **************************************************************
            ******  SO THIS SEGMENT STARTS AT MEMORY ADDRESS 0x0.  *******
            **************************************************************


   * SEGMENT TYPE (CODE / DATA)
                                ..   
      Higher addresses  - 0x00CF9A000000FFFF -  Lower Addresses
                                ||
                       +--------++-------+
                    +--+--+           +--+--+
                    |     |           |     |
                     1001              1010
		     ||||              |||+----> WE ARE NOT USING IT
                     ||||              ||+-----> "1" READABLE/WRITABLE
                     ||||              |+------> WE ARE NOT USING IT
                     ||||              +-------> "1" CODE SEGMENT
                     |||+----------------------> "1" CODE DESCRIPTOR
                     ||+------------------+
                     |+------------------+|
                     v                   ||
               SEGMENT IN MEMORY         vv 
                                         00 --> "0" RING NUMBER (kernel mode)

               Other values for ring number are 01, 10, 11 (user mode)

            **************************************************************
            ****** SO THIS SEGMENT IS USED TO PUT INSTRUCTIONS AND *******
            ****** NOT DATA, AND IS TO BE USED BY THE CPU IN RING 0*******
            **************************************************************
</pre>

Phew!!!! That was a bunch of bits!!! I hope you could have understood
the break down.

I will save you from the explanation of the DATA SEGMENT, it's almost
the same. Humm, not really. Let's dig in. They are really look alike
IN OUR KERNEL (it could be really different in another project). Take
a look:


<pre>
                .
   CODE  0x00CF9A000000FFFF (We've just broke this one down)
   DATA  0x00CF92000000FFFF
                |
                |       Bit representation of "2":
		|
                +--------> 0010
                           ||||
                           |||+-> WE ARE NOT USING IT			   
                           ||+--> "1" READABLE/WRITABLE
                           |+---> WE ARE NOT USING IT
                           +----> DATA SEGMENT
</pre>


It states that it goes from memory address 0x0 to 0xFFFFFFFF (4GB of
memory), it's a data segment, you can't execute code, it's readable
and writable. That's it. Phew again !!!!

+-- Timestamp: 2020-01-19-16:25 ---+

Now we have a program that runs in 32bits protected-mode without any
help of any OS. This program discarded all the BIOS IVT. It's on it's
own now. Now what? How are we going to transform this program in an OS
kernel. Next steps:

     - Create ALL IVT(IDT) entries for hard/soft and exceptions
     - Create code for each IVT pointer (interrupt handler/Interrupt Service
       Routine)
     - Create a multitasking environment:
       -- Context switching logic
       -- Scheduler
     - Device drivers for some hardware we want to use
     - ...
	
Yeah! This is going to be fun. 	

+-- Timestamp: Wed Jan 22 22:36:02 -03 2020 --+

3.2 - IDT

Ok. Let's touch the IDT subject. What is it for? CPUs handle
stochastic (random) events, system service calls, and "internal
errors" (exceptions) with a mechanism called "INTERRUPTS". It does
what the word means: it interrupts the current flow of instructions of
the CPU and executes another one to handle the situation. The
situation can be classified into 3 categories: EXCEPTION, HARDWARE
INTERRUPT, and SOFTWARE INTERRUPT (system calls). All these categories
are treated using the same mechanism:

       A - CPU "receives/perceives" the event
       B - CPU saves context (copies the contents of almost all registers
           to memory).
       C - CPU uses the "number of the event" (interrupt/exception number)
           to index an IDT entry (aha moment!!! :)).
       D - CPU fetches the routine to handle the event and handle it
       E - When finished, CPU returns from the interrupt (it restores
           the previous context - copies all register values saved in memory
	   back to the CPU registers and resume previous "interrupted"
	   flow/task).

Intel CPUs uses "event" numbers 0 to 31 to represent EXCEPTIONS. So,
IDT entries from 0 to 31 must deal with the handling of these
exceptions. The defined Intel CPUs exceptions are:

          +---------Exception
          |  +------Meaning
          |  |
          v  v
         00: "Divide by zero exception          "
         01: "Debug exception                   "
         02: "NMI exception                     "
         03: "Breakpoint exception              "
         04: "Overflow exception                "
         05: "Out of Bounds exception           "
         06: "Invalid OpCode exception          "
         07: "No coprocessor exception          "
         08: "Double Fault exception            "
         09: "Coprocessor Segment exception     "
         10: "Bad TSS exception                 "
         11: "Segment not present exception     "
         12: "Stack Fault exception             "
         13: "General Protection Fault exception"
         14: "Page fault exception              "
         15: "Unknown Interrupt exception       "
         16: "Coprocessor Fault exception       "
         17: "Alignment Check exception         "
         18: "Machine Check exception           "
         19: "Reserved exception                "
         ...
         31: "Reserved exception                "

So, our IDT will have the first 32 entries filled-up with stuff to
deal with EXCEPTIONS. Most exceptions are the result of some
instruction executed or to be executed by the CPU. For instance, if
you try to divide a number by 0, the CPU will generate the exception
"Divide by zero exception".

Next entries are "reserved" to deal with HARDWARE INTERRUPTS. HARDWARE
INTERRUPTS are events generated by external devices connected to the
CPU (you may argue that some devices were embedded in the CPU, etc.. -
it doesn't matter here). Intel CPUs have one single PIN to be used as
a way to be informed a HARDWARE INTERRUPT happened. If a device wants
to be handled by the CPU, it generates a signal on that PIN (actually,
it's more complicated than that!!! To be able to connect several
devices to the CPU using one single interrupt PIN, a device called
Programmable Interrupt Controller - PIC - is used. I will get into the
details when discussing the code, so this simplified explanation is
enough for now). When the CPU receives this hardware interrupt, it
tries to discover which device were responsible for that. After that,
the CPU does the same A-E actions described before. Each device uses
an IRQ number in order to be identified. For instance, the clock
device uses IRQ 0.

We plan to deal with the following hardware in kalimera (listing with
IRQ number and device):

      IRQ0  - CLOCK
      IRQ1  - KEYBOARD
      IRQ4  - SERIAL PORT
      IRQ11 - ETHERNET NETWORK CARD

So, if the first 32 IDT entries were occupied by the exceptions stuff,
the next free entry is 32. So, IRQ0 will fire the loading of IDT entry
32. Our IDT entries for the HARDWARE INTERRUPTS will be the following:

      Entry 32 - IRQ0  - CLOCK
      Entry 33 - IRQ1  - KEYBOARD
      Entry 36 - IRQ4  - SERIAL PORT
      Entry 43 - IRQ11 - ETHERNET NEWORK CARD

Be patient, we are almost coding!!

We decided to put our IDT at block 0x0-0x7ff. Each IDT entry is 8
bytes (64 bits) long and has the following structure:

       - OFFSET - bits 0-15 (16 bits)
       - SELECTOR - it's 0x8 in kalimera - chooses 2nd GDT entry (16 bits)
       - NOT USED - set it to zero (8 bits)
       - TYPE AND ATTRIBUTES - (8 bits) - More details when presenting the code
       - OFFSET - bits 16-31 (16 bits)

OFFSET is the address of the routine (function) for that entry, so
when that entry is selected, that code gets to be executed. 

This is another view for the IDT entry structure. If you look at the code
you'll always see the SELECTOR and TYPE/ATTRIBUTES with the same values:

<pre>
       OFFSET       TYPE/      NOT       SELECTOR           OFFSET
    (HIGHER BITS)   ATTRIB     USED                      (LOWER BITS)

   3322222222211111 00000000 00000000 1111110000000000 1111110000000000 
   1098765432109876 76543210 76543210 5432109876543210 5432109876543210 
  +----------------+--------+--------+----------------+----------------+ bits
  |                |10001110|00000000|0000000000001000|                |
  +----------------+--------+--------+----------------+----------------+
                    ||||||||
		    ||||++++-> GATE TYPE (Interrupt Gate)
		    |||+-----> 0 FOR INT/TRAP GATES
		    |++------> DESCIPTOR PRIVILEDGE LEVEL (RING 0)
		    +--------> 1 FOR USED INTERRUPT, 0 OTHERWISE
</pre>

3.2.1 - EXCEPTIONS

Ok. Let's code the IDT entries. Let's start with the EXCEPTIONS.

      SEE FILE src/kernel/exceptions0to31.s

Let me break the first entry down. The code to register the handler (ISR)
for exception 0 is:

        movl    $_exception00, %eax     # LINE1
        movw    %ax, (0*8)              # LINE2
        movw    $0x08, (0*8+2)          # LINE3
        movw    $0x8e00, (0*8+4)        # LINE4
        shr     $16, %eax               # LINE5
        movw    %ax, (0*8+6)            # LINE6

I defined a function called _exception00 to deal with exception zero.
Let's call this function "handler". For now, It doesn't matter what it
does. All you have to grasp now is how to register an IDT entry. It
goes like this:

        - At LINE1 I load the address of _exception00 (handler)
          into register EAX
        - At LINE2 I write the first 16 bits of the handler address
          into the first 2 bytes of the 1st IDT entry
        - At LINE3 I write the GDT entry to be considered when executing
          this handler (kalimera will always use 0x8 - that's the
          second GDT entry)
        - At LINE4 I write the following: 0x8e00
          Let me break it into bits:
             TYPE/ATTRIBUTES      FIELD NOT USED (ALWAYS SET IT TI ZERO)
                     8E             00
                   10001110       00000000
                   ||||||||
                   ||||++++--> GATE TYPE : 1110 equal "Interrupt Gate"
                   |||+------> 0 - for Interrupt Gates
                   |++-------> Privilege Level - 00 - KERNEL MODE
                   +---------> 1 - Interrupt Present

+-- Timestamp: Thu Jan 23 22:30:12 -03 2020 --+

Now when exception "Divide by zero" is generated by the CPU, "function"
_exception00 is called. Let's take a look at the function:

         /* Devide by zero exception */
         _exception00:
                 pushl $0 # TO BE USED BY deal_with_it (ERROR CODE)
                 pushl $0 # TO BE USED BY deal_with_it (EXCEPTION NUMBER)

                 pushl  $0x07       # FG: GREY
                 pushl  $0x00       # BG: BLACK		
                 pushl  $ex_msg_00
                 pushl  $24
                 pushl  $0
                 call print
                 addl	$20, %esp
	
                 deal_with_it

This function puts the ERROR CODE and the EXCEPTION NUMBER on the
stack (first two "pushl"s). Then it prints a message informing the
exception (next "pushl"s and "call print"). After that, a macro called
deal_with_it is called. You can see the macro next:

          .macro deal_with_it
                  pushl   $0x0E     # FG: YELLOW
                  pushl   $0x00     # BG: BLACK	
                  pushl	$action_msg # MSG
                  pushl	$24         # COLUMN
                  pushl	$1          # LINE
                  call print	
          1:	
	          jmp 1b   # JUST FOR TESTING PURPOSES: Every exception puts
                           # the system into an infinite loop.
                           # You should reboot!!!
	          iret
          .endm	

This macro were supposed to "handle" the exception. In our kernel, at
least for now, it will only print a message informing you should
reboot and enter an infinite loop. That's it. It never returns/resumes
from an exception.

Phew !!!!

In order to make kalimera kernel install the IDT entries discussed so
far, file exceptions0to31.s defines a "function" called
register_exceptions. This function is called from kalimera.s just
after printing the yellow message at the top of the screen.

In order to test if our exception handlers are being called when an
exception occurs, I provided 3 more Makefile targets. To generate an
exception "Divide by zero" and test the handler, type:

         make clean; make zero

To generate an exception "Invalid OPCODE" and test the handler, type:

         make clean; make opcode

To generate an exception "General Protection Fault" and test the
handler, type:

         make clean; make gpf


So far, messages were print to the screen using assembly language. To
make things easier, I defined a C function called print (the one used
in the exception handlers and in the macro. This function is defined
at file src/kernel/utils.c. That's the first code in C in our kernel!!
Yey!!

      SEE FILE src/kernel/utils.c

We are going to program "high level" stuff, like the scheduler, the
taskloader, the TCP/IP stack, the ARP/RARP protocol, and several other
network stuff, in C. Even the code to deal with the PCI bus will be
written in C.

Next, I think I'll create a device driver for a PS/2 keyboard. Input
is an important thing in every computer system. An input device will
enable us to do some tricks and control our kernel with special
keys. It will also allow us to do some mundane stuff, like typing
text...
Stay tuned.


+-- Timestamp: Fri Jan 24 14:11:45 -03 2020 --+

3.2.2 - DEVICE DRIVERS AND HARDWARE INTERRUPTS

Ok, I'm back...

DEVIDE DRIVER FILE NAMING CONVENTION

In order to bring some file naming structure, I'll name every device
driver file with the prefix "dev.". So, for example, a file for a
keyboard device driver would be named dev.keyboard.s.

PIC "DEVICE DRIVER"

I consider PICs routers of interrupts, they are not supposed to
generate any interrupt by themselves, and you don't register an IDT
entry for thi device - that's why I "ed the title of this section. In
order to use any IRQ, you must configure the PICs. Usually PCs offer
two chips connected to each other. You have to "logically" connect
both together.

      SEE FILE src/kernel/dev.pic.s

      TODO: PUT SOME DIAGRAM EXPLAINNING THE PHYSICAL/LOGICAL
            CONNECTION BETWEEN PIC1 AND PIC2

KEYBOARD DEVICE DRIVER

Normally, I would start developing a clock device driver, followed by
a serial device driver (which is nice for debugging), and then a
keyboard device driver. That's what I did in a previous kernel I
developed. But for this kernel I want to organize the features in
"correlated blocks" for a better understanding. So, clock is closely
related to multitasking, which is a feature I intend to provide in a
near future. Also, it's nice to have some fun typing on a screen using
a device driver you created, with a keyboard map you invented, with
key press/release actions you developd.

So, let's start with a keyboard (PS/2) device driver. A device driver
knows how to "drive" a piece of hardware, for instance, a keyboard or
NIC, and it knows how to initialize it. Most of the time a device
driver is also responsible for dealing with HARDWARE INTERRUPTS
generated by the hardware it's supposed to control. Our keyboard
device driver will feature:

         - Keyboard initialization
         - keyboard interrupt handling
         - keymap/layout (translate scan code number to a key)
         - key press actions ("shortcuts")
           -- For instance, I could use F1 to F10 keys to select a
              terminal view, just like UNIX systems do.
           -- I could use a tab key to send a network ping packet
              (this is too soon, :)) - We will get there)
           -- We could program an action for the three-finger-salute
              (ctrl+alt+del)
         - UNBUFFERED OUTPUT (writes directly on the screen) - Version 1
         - BUFFERED OUTPUT (writes to a buffer that can be consumed by
           different tasks - threads). - Version 2

In order to make it simple, we are going to commit a sin: our keyboard
driver will write the key you typed (translated to a printable char
representing the key of your keyboard) directly on the screen! The
right way of doing it is to write the content you typed in a buffer
that will be consumed by some task. Well, version 2 of our device
driver will do just that.

A PS/2 keyboard controller, which is the chip you send/receive control
and data to/from your keyboard, is accessible through a mechanism
called "IO port". An IO port represents a register of a chip that can
be read/written, depending on the chip and purpose of it. Each IO port
is addressed using, normally, an hexadecimal number. Some IO port
numbers are fixed, others can be changed. The PS/2 controller offers
two ports to interact with it:

           0x60 - Data port (you can read a value that resulted from
	          the pressing of a keyboard key)
                     -- READ/WRITE

           0x64 - Command/Status port. This port is used for different
                  purposes depending on the direction of the use
                  (READ or WRITE), you access diferent parts of the chip.
                  So:
                     -- READ (Status Register) - You READ from the
                        STATUS REGISTER
                     -- WRITE (Command Register) - You WRITE to the
                        COMMAND REGISTER

Ok, this was a very simplified explanation. There are some other
aspects I will not cover here. I'll cover just the bare bones to allow
for a very simple keyboard device driver. Let's code it and grasp some
other details while we do it:

      SEE FILE src/kernel/dev.keyboard.s

File dev.keyboard.s starts with initialization code for the PS/2
Controller. It puts the controller in a known state. After that, the
device driver registers a handler for the IRQ1 in the IDT entry number
33. The code to execute that is:

<pre>
	/**** INFORM KEYBOARD INTERRUPT HANDLER ****/
	movl	$readkeyboard, %eax    #int_handler, %eax	
	/**** WRITE IDT ENTRY 33 ****/
	movw	%ax, (33*8)
	movw	$0x08, (33*8+2)
	movw	$0x8e00, (33*8+4)
	shr	$16, %eax
	movw	%ax, (33*8+6)
</pre>

Function "readkeyboard" is the interrupt handler for the keyboard. It
basically reads IO port 0x60 and extract the scan code for the
pressed/released key. One thing to notice is that the keyboard raises
an interrupt when the key is pressed and a second one when the key is
released.

+-- Timestamp: Sat Jan 25 14:10:20 -03 2020 --+

Just for fun, I also programmed two actions: one for the key BACKSPACE
and another for the key ENTER. They do what they are supposed to do in
an editor: 

         - BACKSPACE - delete previous character and move cursor to the left
         - ENTER - go to the next line

+-- Timestamp: Wed Feb  5 23:10:51 -03 2020 --+

Ok. In order to put our keyboard device driver to work, we need to
enable interrupts. \^o^/. If we just do that we will cause an
exception!!! It happens because several devices present in your
motherboard generates interrupts. If an interrupt is raised and we
don't have a proper IDT entry for it, some garbage code will
execute... It will end up raising an exception... So, we need to mask
all the interrupts we don't wnat to deal with at the moment. In order to do that
you execute the following code presentat file kalimera.s:

<pre>
      mask_some_interrupts:	
              /**** MASK ALL INTERRUPTS BUT keyboard ****/
              movb   $0b11111101, %al
                     #  ||||||||
                     #  |||||||+-> IRQ0	
                     #  ||||||+--> IRQ1 - OUR KEYBOARD (ONLY INTERRUPT ENABLED)
                     #  |||||+---> IRQ2 - ROUTER FOR IRQs 8 to 15
                     #  ||||+----> IRQ3
                     #  |||+-----> IRQ4
                     #  ||+------> IRQ5
                     #  |+-------> IRQ6
                     #  +--------> IRQ7
              outb   %al, $0x21
              outb   %al, $0xA1
</pre>

In the previous code we masked all interrupts but the keyboard
interrupt 1. After this we can FINALLY enable interrupts with
"sti". YeY!!!


AND WE ARE NOT DONE YET. MORE ARE TO COME...BE PATIENT... BUT FOR NOW
YOU CAN READ THE APPENDICES.


=======================================================================

Appendix A. Exploring qemu memory

Qemu offers a very handy monitor where you can type a set of commands.
You activate this monitor passing the parameter "-monitor stdio" when
executing the command qemu. In special, the command "x /format address"
shows the memory (Virtual Memory) at position "address" and beyond. You
can do the same for Physical memory with "xp /format address". So, for
example, if you type:

     (qemu) x /16b 0x7C00

The monitor shows 16 1-byte chuncks of memory starting at position
0x7C00. You would end up we this output:

     0000000000007c00: 0x10 0x00 0x7a 0x00 0x00 0x00 0xf0 0x07
     0000000000007c08: 0x01 0x00 0x00 0x00 0x00 0x00 0x00 0x00

If you want to inspect memory showing 4-byte chunks of memory, you
would type this: (qemu) x /16w 0x7C00

     0000000000007c00: 0x007a0010 0x07f00000 0x00000001 0x00000000
     0000000000007c10: 0xd88ec88c 0x368dc08e 0x00b47c4b 0x10cd03b0
     0000000000007c20: 0x74c008ac 0xbb0eb409 0x10cd0007 0x368df2eb
     0000000000007c30: 0x80b27c00 0x13cd42b4 0x16cd00b4 0x03b000b4

The modifiers ("/fmt") are:

    SIZE
    
       b - 1-byte ( 8 bits) chuncks
       h - 2-byte (16 bits) chuncks
       w - 4-byte (32 bits) chuncks
       g - 8-byte (64 bits) chuncks

    FORMAT OR BASE

       x - hexadecimal
       d OR u - decimal
       c - \x format
       o - octal

=======================================================================

Appendix B. Exploring qemu REGISTERS !!!!

This is amazing. You should definitely explore this.
Type: (qemu) info registers

You end up with:

     EAX=00000000 EBX=0000dc80 ECX=0000b60a EDX=00000000
     ESI=0000fdd8 EDI=00000000 EBP=00000040 ESP=00006efc
     EIP=0000b626 EFL=00000246 [---Z-P-] CPL=0 II=0 A20=1 SMM=0 HLT=1
     ES =0040 00000400 0000ffff 00009300
     CS =f000 000f0000 0000ffff 00009b00
     SS =0000 00000000 0000ffff 00009300
     DS =0000 00000000 0000ffff 00009300
     FS =0000 00000000 0000ffff 00009300
     GS =0000 00000000 0000ffff 00009300
     LDT=0000 00000000 0000ffff 00008200
     TR =0000 00000000 0000ffff 00008b00
     GDT=     00000000 00000000
     IDT=     00000000 000003ff
     CR0=00000010 CR2=00000000 CR3=00000000 CR4=00000000
     DR0=0000000000000000 DR1=0000000000000000 DR2=0000000000000000 DR3=0000000000000000 
     DR6=00000000ffff0ff0 DR7=0000000000000400
     EFER=0000000000000000
     FCW=037f FSW=0000 [ST=0] FTW=00 MXCSR=00001f80
     FPR0=0000000000000000 0000 FPR1=0000000000000000 0000
     FPR2=0000000000000000 0000 FPR3=0000000000000000 0000
     FPR4=0000000000000000 0000 FPR5=0000000000000000 0000
     FPR6=0000000000000000 0000 FPR7=0000000000000000 0000
     XMM00=00000000000000000000000000000000 XMM01=00000000000000000000000000000000
     XMM02=00000000000000000000000000000000 XMM03=00000000000000000000000000000000
     XMM04=00000000000000000000000000000000 XMM05=00000000000000000000000000000000
     XMM06=00000000000000000000000000000000 XMM07=00000000000000000000000000000000

This is very handy. For instance, this output shows CR0 with value 00000010.
The right-most bit (PE) is set to 0. This shows the CPU is running in REAL-MODE.
You can also see that GDT shows the value 00000000 00000000 (that's normal when
in REAL-MODE (GDT is non-existent in REAL-MODE). IDT shows the IVT starts at
position 0 e ends at position 000003ff.


The following output shows a CPU running in PROTECTED-MODE:

     EAX=000b8c1d EBX=000b8c1e ECX=00004107 EDX=0000000c
     ESI=00010218 EDI=000b8c81 EBP=017fffcc ESP=017fffc8
     EIP=00011d17 EFL=00000202 [-------] CPL=0 II=0 A20=1 SMM=0 HLT=0
     ES =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
     CS =0008 00000000 ffffffff 00cf9a00 DPL=0 CS32 [-R-]
     SS =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
     DS =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
     FS =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
     GS =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
     LDT=0000 00000000 0000ffff 00008200 DPL=0 LDT
     TR =0000 00000000 0000ffff 00008b00 DPL=0 TSS32-busy
     GDT=     00000800 00000017
     IDT=     00000000 00000800
     CR0=00000011 CR2=00000000 CR3=00000000 CR4=00000000
     DR0=0000000000000000 DR1=0000000000000000 DR2=0000000000000000 DR3=0000000000000000 
     DR6=00000000ffff0ff0 DR7=0000000000000400
     EFER=0000000000000000
     FCW=037f FSW=0000 [ST=0] FTW=00 MXCSR=00001f80
     FPR0=0000000000000000 0000 FPR1=0000000000000000 0000
     FPR2=0000000000000000 0000 FPR3=0000000000000000 0000
     FPR4=0000000000000000 0000 FPR5=0000000000000000 0000
     FPR6=0000000000000000 0000 FPR7=0000000000000000 0000
     XMM00=00000000000000000000000000000000 XMM01=00000000000000000000000000000000
     XMM02=00000000000000000000000000000000 XMM03=00000000000000000000000000000000
     XMM04=00000000000000000000000000000000 XMM05=00000000000000000000000000000000
     XMM06=00000000000000000000000000000000 XMM07=00000000000000000000000000000000

Observe CR0 value is 00000011. The right-most bit (PE) is set to 1.
You can also see that GDT shows the value 00000800 00000017. This means
the GDT goes from memory position 0x800 to 0x817. 

IDT shows the IVT starts at position 0 and ends at position 00000800.

So cool! I can't express my joy enough in being able to see this.

=======================================================================

Appendix C. Bootloader in memory

This is the memory occupied by our bootloader. This was obtained typing
this at the (qemu) prompt: (qemu) x /256h 0x7c00

     0000000000007c00: 0x0010 0x007a 0x0000 0x07f0 0x0001 0x0000 0x0000 0x0000
     0000000000007c10: 0xc88c 0xd88e 0xc08e 0x368d 0x7c4b 0x00b4 0x03b0 0x10cd
     0000000000007c20: 0x08ac 0x74c0 0xb409 0xbb0e 0x0007 0x10cd 0xf2eb 0x368d
     0000000000007c30: 0x7c00 0x80b2 0x42b4 0x13cd 0x00b4 0x16cd 0x00b4 0x03b0
     0000000000007c40: 0x10cd 0x00ea 0xf000 0xfa07 0xebf4 0x3efc 0x414b 0x494c
     0000000000007c50: 0x454d 0x4152 0x4220 0x4f4f 0x2054 0x4f4c 0x4441 0x5245
     0000000000007c60: 0x2d20 0x2d2d 0x5020 0x6572 0x7373 0x6520 0x746e 0x7265
     0000000000007c70: 0x7420 0x206f 0x7572 0x206e 0x656b 0x6e72 0x6c65 0x0d0a
     0000000000007c80: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007c90: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ca0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cb0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cc0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cd0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ce0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cf0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d00: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d10: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d20: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d30: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d40: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d50: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d60: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d70: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d80: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d90: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007da0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007db0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007dc0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007dd0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007de0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007df0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0xaa55


Observe the value 0xaa55 at the end.

=======================================================================

Appendix D. fakekernel in memory (now the address is 0x8000, instead of 0x7F00)

This is the memory occupied by our fakekernel. This was obtained typing
this at the (qemu) prompt: (qemu) x /48h 0x7F00

     0000000000007f00: 0x368d 0x7f18 0x08ac 0x74c0 0xb409 0xbb0e 0x0007 0x10cd
     0000000000007f10: 0xf2eb 0x00b4 0x16cd 0xfeeb 0x3e20 0x463e 0x4b41 0x2045
     0000000000007f20: 0x454b 0x4e52 0x4c45 0x4c20 0x414f 0x4544 0x2044 0x2d2d
     0000000000007f30: 0x202d 0x5449 0x5320 0x4545 0x534d 0x5420 0x4548 0x4220
     0000000000007f40: 0x4f4f 0x4c54 0x414f 0x4544 0x2052 0x4f57 0x4b52 0x4445
     0000000000007f50: 0x202e 0x6159 0x2179 0x0a21 0x000d 0x0000 0x0000 0x0000
     0000000000007f60: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007f70: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 

=======================================================================

Appendix E. Both bootloader and fakekernel in memory

This is the memory occupied by our fakekernel. This was obtained typing
this at the (qemu) prompt: (qemu) x /432h 0x7C00

     0000000000007c00: 0x0010 0x007a 0x0000 0x07f0 0x0001 0x0000 0x0000 0x0000
     0000000000007c10: 0xc88c 0xd88e 0xc08e 0x368d 0x7c4b 0x00b4 0x03b0 0x10cd
     0000000000007c20: 0x08ac 0x74c0 0xb409 0xbb0e 0x0007 0x10cd 0xf2eb 0x368d
     0000000000007c30: 0x7c00 0x80b2 0x42b4 0x13cd 0x00b4 0x16cd 0x00b4 0x03b0
     0000000000007c40: 0x10cd 0x00ea 0xf000 0xfa07 0xebf4 0x3efc 0x414b 0x494c
     0000000000007c50: 0x454d 0x4152 0x4220 0x4f4f 0x2054 0x4f4c 0x4441 0x5245
     0000000000007c60: 0x2d20 0x2d2d 0x5020 0x6572 0x7373 0x6520 0x746e 0x7265
     0000000000007c70: 0x7420 0x206f 0x7572 0x206e 0x656b 0x6e72 0x6c65 0x0d0a
     0000000000007c80: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007c90: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ca0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cb0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cc0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cd0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ce0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007cf0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d00: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d10: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d20: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d30: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d40: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d50: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d60: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d70: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d80: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007d90: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007da0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007db0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007dc0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007dd0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007de0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007df0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0xaa55
     0000000000007e00: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e10: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e20: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e30: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e40: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e50: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e60: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e70: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e80: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007e90: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ea0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007eb0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ec0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ed0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ee0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007ef0: 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
     0000000000007f00: 0x368d 0x7f18 0x08ac 0x74c0 0xb409 0xbb0e 0x0007 0x10cd
     0000000000007f10: 0xf2eb 0x00b4 0x16cd 0xfeeb 0x3e20 0x463e 0x4b41 0x2045
     0000000000007f20: 0x454b 0x4e52 0x4c45 0x4c20 0x414f 0x4544 0x2044 0x2d2d
     0000000000007f30: 0x202d 0x5449 0x5320 0x4545 0x534d 0x5420 0x4548 0x4220
     0000000000007f40: 0x4f4f 0x4c54 0x414f 0x4544 0x2052 0x4f57 0x4b52 0x4445
     0000000000007f50: 0x202e 0x6159 0x2179 0x0a21 0x000d 0x0000 0x0000 0x0000

=======================================================================

Appendix F. Source Code - Number of lines prediction based on another
            kernel I developed


```mermaid
pie title Source Code Distribution Prediction (lines)
    "x86-Assembly" :  9502
    "C" :  8566
    "Shel Script" :  66
    "Makefile/linker script" :  9
    "Documentation" :  508
```
