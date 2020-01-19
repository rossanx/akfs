#
# File: Makefile
# This code is part of the kalimera system project.
# Author: Rossano Pablo Pinto (rossano at gmail dot com)
# Date: Tue Jan 07 14:17:32 BRT 2020
#
OUTPUTDIR=../../bin

all: ${OUTPUTDIR}/kalimera.o ${OUTPUTDIR}/kalimera.bin ${OUTPUTDIR}/kalimera.map

${OUTPUTDIR}/kalimera.bin ${OUTPUTDIR}/kalimera.map: ${OUTPUTDIR}/kalimera.o
	ld -x -s -m elf_i386 -Tlinker-script ${OUTPUTDIR}/kalimera.o -o ${OUTPUTDIR}/kalimera.bin -Map ${OUTPUTDIR}/kalimera.map

${OUTPUTDIR}/kalimera.o: kalimera.s
	as -32 --gstabs+ -o ${OUTPUTDIR}/kalimera.o kalimera.s

clean:
	rm -f ${OUTPUTDIR}/kalimera.o
	rm -f ${OUTPUTDIR}/kalimera.bin
	rm -f ${OUTPUTDIR}/kalimera.map
	rm -f ${OUTPUTDIR}/hd-kalimera.img
	rm -f ${OUTPUTDIR}/run-kalimera.sh
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
	(cd ../bootloader; make all; cd -)

