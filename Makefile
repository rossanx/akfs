#
# File: Makefile
# This code is part of the kalimera system project.
# Author: Rossano Pablo Pinto (rossano at gmail dot com)
# Date: Tue Jan 07 14:17:32 BRT 2020
#



all:
	(cd src/bootloader; make all; cd -)
	(cd src/kernel; make all; cd -)

run:
	#(cd src/kernel; make run; cd -)

clean:
	(cd src/bootloader; make clean; cd -)
	(cd src/kernel; make clean; cd -)


## UTILS
testbl:
	(cd src/bootloader; make test; cd -)

