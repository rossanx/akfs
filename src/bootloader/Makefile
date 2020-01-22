#
# File: Makefile
# This code is part of the kalimera system project.
# Author: Rossano Pablo Pinto (rossano at gmail dot com)
# Date: Tue Jan 07 14:17:32 BRT 2020
#


OUTPUTDIR=../../bin

all: ${OUTPUTDIR}/bootloader.o ${OUTPUTDIR}/bootloader.bin

${OUTPUTDIR}/bootloader.o: bootloader.s
	as -32 bootloader.s -o ${OUTPUTDIR}/bootloader.o

${OUTPUTDIR}/bootloader.bin: ${OUTPUTDIR}/bootloader.o
	ld -m elf_i386 -M -Map=${OUTPUTDIR}/bootloader.map -Ttext 0x7c00 --oformat=binary ${OUTPUTDIR}/bootloader.o -o ${OUTPUTDIR}/bootloader.bin

clean:
	rm -f ${OUTPUTDIR}/bootloader.o
	rm -f ${OUTPUTDIR}/bootloader.bin
	rm -f ${OUTPUTDIR}/bootloader.map
	rm -f ${OUTPUTDIR}/fakekernel.o
	rm -f ${OUTPUTDIR}/fakekernel.bin
	rm -f ${OUTPUTDIR}/fakekernel.map
	rm -f ${OUTPUTDIR}/hd-fakekernel.img
	rm -f ${OUTPUTDIR}/run-bootloader-test.sh
	@echo ">>>+++++ Showing remaining files at ${OUTPUTDIR}:"
	ls ${OUTPUTDIR}

## UTILS
test: ${OUTPUTDIR}/hd-fakekernel.img
	cp run-bootloader-test.sh ${OUTPUTDIR}/run-bootloader-test.sh
	chmod 755 ${OUTPUTDIR}/run-bootloader-test.sh
	cd ${OUTPUTDIR}; ./run-bootloader-test.sh; cd -
	sed -i 's/.set __FAKEKERNEL__, 1/#.set __FAKEKERNEL__, 0/g' bootloader.s

${OUTPUTDIR}/hd-fakekernel.img: ${OUTPUTDIR}/fakekernel.bin ${OUTPUTDIR}/bootloader.bin
	sed -i 's/#.set __FAKEKERNEL__, 0/.set __FAKEKERNEL__, 1/g' bootloader.s
	(make all)

	dd if=/dev/zero of=${OUTPUTDIR}/hd-fakekernel.img bs=1024 count=10000
	dd if=${OUTPUTDIR}/bootloader.bin of=${OUTPUTDIR}/hd-fakekernel.img bs=1 conv=notrunc
	dd if=${OUTPUTDIR}/fakekernel.bin of=${OUTPUTDIR}/hd-fakekernel.img bs=1 conv=notrunc seek=512


${OUTPUTDIR}/fakekernel.bin: ${OUTPUTDIR}/fakekernel.o
	ld -x -s -m elf_i386 -Map=${OUTPUTDIR}/fakekernel.map -Tlinker-script-fakekernel ${OUTPUTDIR}/fakekernel.o -o ${OUTPUTDIR}/fakekernel.bin


${OUTPUTDIR}/fakekernel.o: fakekernel.s
	as -32 --gstabs+ fakekernel.s -o ${OUTPUTDIR}/fakekernel.o

