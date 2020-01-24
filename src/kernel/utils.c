/*  
    File: utils.c
    This code is part of the kalimera system project.
    Author: Rossano Pablo Pinto (rossano at gmail dot com)
    Date: Tue Mar 24 17:52:46 BRT 2015
*/

#define VRAM 0xb8000

/* MAKE SURE YOU PASS A ZERO TERMINATED STRING !!!!*/
void print(int lin, int col, char * str, int bgcolor, int fgcolor)
{
  char *vram = (char *)VRAM+lin*160+col;
  while (*str != 0) {
    *vram++ = *str++;
    *vram++ = bgcolor | fgcolor;
  }
}

