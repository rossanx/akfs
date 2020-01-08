#
# File: Makefile
# This code is part of the kalimera system project.
# Author: Rossano Pablo Pinto (rossano at gmail dot com)
# Date: Tue Jan 07 14:17:32 BRT 2020
#



all:
	(cd src/bootloader; make all)
	#(cd src/kernel; make all)

run:
	#(cd bin; make run)

clean:
	(cd src/bootloader; make clean)
	#(cd src/kernel; make clean)


## UTILS
testbl:
	(cd src/bootloader; make test)

runbl:
	(cd src/bootloader; make run)
