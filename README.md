# KALIMERA - akfs

Kalimera - A(nother) Kernel From Scratch

Yes, this is another operating system kernel written from scratch. There are tons of the same out there.

So far, the planned features/architecture are: x86 (32 bits), protected-mode, ring 0 only, no paging, multitasking - kernel threads only, network communication (ethernet), IPv4, UDP, ICMP, BOOTP, ARP, RARP, serial communication, interrupts, exceptions, keyboard input.

It should be small and simple enough to enable anyone to grasp the workings of the entire kernel. Yep, you've just read it. It will be written in AT&T assembly language syntax and C.

```mermaid
pie title Source Code Distribution so far (lines)
    "x86-Assembly" :  3448
    "Shel Script" :  154
    "Makefile/linker script" :  540
    "Documentation" :  1214
```

Please, read the file [docs/journal.md](docs/journal.md).
