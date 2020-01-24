#
# File: Makefile
# This code is part of the kalimera system project.
# Author: Rossano Pablo Pinto (rossano at gmail dot com)
# Date: Tue Jan 07 14:17:32 BRT 2020
#
OUTPUTDIR=../../bin

all: ${OUTPUTDIR}/kalimera.o ${OUTPUTDIR}/kalimera.bin ${OUTPUTDIR}/kalimera.map

${OUTPUTDIR}/kalimera.bin ${OUTPUTDIR}/kalimera.map: ${OUTPUTDIR}/kalimera.o ${OUTPUTDIR}/utils.o ${OUTPUTDIR}/exceptions0to31.o
	ld -x -s -m elf_i386 -Tlinker-script ${OUTPUTDIR}/kalimera.o ${OUTPUTDIR}/utils.o ${OUTPUTDIR}/exceptions0to31.o -o ${OUTPUTDIR}/kalimera.bin -Map ${OUTPUTDIR}/kalimera.map

${OUTPUTDIR}/kalimera.o: kalimera.s
	as -32 --gstabs+ -o ${OUTPUTDIR}/kalimera.o kalimera.s

${OUTPUTDIR}/utils.o: utils.c
	gcc -fno-stack-protector -fno-pic -m32 -c utils.c -o ${OUTPUTDIR}/utils.o

${OUTPUTDIR}/exceptions0to31.o: exceptions0to31.s
	as -32 --gstabs+ -o ${OUTPUTDIR}/exceptions0to31.o exceptions0to31.s



clean:
	rm -f ${OUTPUTDIR}/kalimera.o
	rm -f ${OUTPUTDIR}/kalimera.bin
	rm -f ${OUTPUTDIR}/kalimera.map
	rm -f ${OUTPUTDIR}/hd-kalimera.img
	rm -f ${OUTPUTDIR}/run-kalimera.sh
	rm -f ${OUTPUTDIR}/exceptions0to31.o
	rm -f ${OUTPUTDIR}/utils.o
	(cd ../bootloader; make clean; cd -)
	@echo ">>>+++++ Showing remaining files at ${OUTPUTDIR}:"
	ls ${OUTPUTDIR}

## UTILS
run: ${OUTPUTDIR}/hd-kalimera.img
	(cd ${OUTPUTDIR}; ./run-kalimera.sh; cd -)

${OUTPUTDIR}/hd-kalimera.img: ${OUTPUTDIR}/kalimera.bin ${OUTPUTDIR}/bootloader.bin
	dd if=/dev/zero of=${OUTPUTDIR}/hd-kalimera.img bs=1024 count=10000
	dd if=${OUTPUTDIR}/bootloader.bin of=${OUTPUTDIR}/hd-kalimera.img bs=1 conv=notrunc
	dd if=${OUTPUTDIR}/kalimera.bin of=${OUTPUTDIR}/hd-kalimera.img bs=1 conv=notrunc seek=512
	cp run-kalimera.sh ${OUTPUTDIR}/run-kalimera.sh
	chmod 755 ${OUTPUTDIR}/run-kalimera.sh


${OUTPUTDIR}/bootloader.bin:
# MAKE SURE WE DISABLE __FAKEKERNEL__
	sed -i 's/.set __FAKEKERNEL__, 1/#.set __FAKEKERNEL__, 0/g' ../bootloader/bootloader.s
	(cd ../bootloader; make all; cd -)


############################ RUN TESTS ######################################

## GENERATES A DIVIDE BY ZERO EXCEPTION
zero: 
	sed -i 's/#.set __DIVIDE_BY_ZERO_EXCEPTION__, 0/.set __DIVIDE_BY_ZERO_EXCEPTION__, 1/g' kalimera.s
	(make all && make ${OUTPUTDIR}/hd-kalimera.img)
	sed -i 's/.set __DIVIDE_BY_ZERO_EXCEPTION__, 1/#.set __DIVIDE_BY_ZERO_EXCEPTION__, 0/g' kalimera.s
	(cd ${OUTPUTDIR}; ./run-kalimera.sh; cd -)

## GENERATES AN INVALID OPCODE EXCEPTION
opcode: 
	sed -i 's/#.set __INVALID_OPCODE_EXCEPTION__, 0/.set __INVALID_OPCODE_EXCEPTION__, 1/g' kalimera.s
	(make all && make ${OUTPUTDIR}/hd-kalimera.img)
	sed -i 's/.set __INVALID_OPCODE_EXCEPTION__, 1/#.set __INVALID_OPCODE_EXCEPTION__, 0/g' kalimera.s
	(cd ${OUTPUTDIR}; ./run-kalimera.sh; cd -)


## GENERATES A General Protection Fault EXCEPTION
gpf: 
	sed -i 's/#.set __GPF_EXCEPTION__, 0/.set __GPF_EXCEPTION__, 1/g' kalimera.s
	(make all && make ${OUTPUTDIR}/hd-kalimera.img)
	sed -i 's/.set __GPF_EXCEPTION__, 1/#.set __GPF_EXCEPTION__, 0/g' kalimera.s
	(cd ${OUTPUTDIR}; ./run-kalimera.sh; cd -)
