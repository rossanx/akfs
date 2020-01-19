#!/bin/bash

#
# File: run-kalimera.sh
# This code is part of the kalimera system project.
# Author: Rossano Pablo Pinto (rossano at gmail dot com)
# Date: Tue Jan 07 14:17:32 BRT 2020
#

sudo qemu \
     -no-reboot \
     -cpu coreduo \
     -m 64 \
     -hda hd-kalimera.img \
     -boot c \
     -monitor stdio \
     -chardev pty,id=pts1,path=/dev/pts/1 \
     -device isa-serial,chardev=pts1 
     #-d cpu,pcall,cpu_reset -D /tmp/qemu-2020-01-13.log


