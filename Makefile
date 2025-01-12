SDK=/opt/DA145xx_SDK/6.0.22.1401
INCLUDES=\
    -I.\
    -I${SDK}/sdk/platform/include\
    -I${SDK}/sdk/platform/arch\
    -I${SDK}/sdk/platform/arch/ll\
    -I${SDK}/sdk/platform/driver/uart\
    -I${SDK}/sdk/platform/driver/dma\
    -I${SDK}/sdk/platform/driver/gpio\
    -I${SDK}/sdk/platform/driver/syscntl\
    -I${SDK}/sdk/platform/arch/compiler\
    -I${SDK}/sdk/platform/system_library/include\
    -I${SDK}/sdk/platform/utilities/otp_cs\
    -I${SDK}/sdk/platform/utilities/otp_hdr\
    -I${SDK}/sdk/platform/core_modules/rf/api\
    -I${SDK}/sdk/platform/include/CMSIS/5.9.0/CMSIS/Core/Include

CFLAGS=\
    ${INCLUDES}\
    -D__DA14531__\
    -mthumb\
    -march=armv6s-m\
    -fno-omit-frame-pointer\
    -ffunction-sections\
    -fdata-sections\
    --specs=nosys.specs\
    --specs=nano.specs

CFLAGS+=-flto

LDFLAGS1=\
    -Wl,--as-needed\
    -Wl,--eh-frame-hdr\
    -Wl,-z,noexecstack\
    -L.\

LDFLAGS2=\
    -Wl,--gc-sections\
    -no-pie\
    --specs=nano.specs\
    --specs=nosys.specs\
    -L${SDK}/sdk/common_project_files/misc\
    -mthumb\
    -march=armv6s-m\
    -fno-omit-frame-pointer\

LDLAGS+=-flto

LIBS=-lsdk

CC=arm-none-eabi-gcc
AR=arm-none-eabi-gcc-ar
LD=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
SIZE=arm-none-eabi-size

all: firmware.bin

clean:
	rm -f *.o libsdk.a firmware.elf firmware.bin ldscript_DA14531.lds

ivtable.o: ${SDK}/sdk/platform/arch/boot/GCC/ivtable_DA14531.S
	${CC} ${CFLAGS} -c -o $@ ${SDK}/sdk/platform/arch/boot/GCC/ivtable_DA14531.S
startup.o: ${SDK}/sdk/platform/arch/boot/GCC/startup_DA14531.S
	${CC} ${CFLAGS} -c -o $@ ${SDK}/sdk/platform/arch/boot/GCC/startup_DA14531.S
hardfault_handler.o: ${SDK}/sdk/platform/arch/main/hardfault_handler.c
	${CC} ${CFLAGS} -c -o $@ ${SDK}/sdk/platform/arch/main/hardfault_handler.c
nmi_handler.o: ${SDK}/sdk/platform/arch/main/nmi_handler.c
	${CC} ${CFLAGS} -c -o $@ ${SDK}/sdk/platform/arch/main/nmi_handler.c
system_DA14531.o: ${SDK}/sdk/platform/arch/boot/system_DA14531.c
	${CC} ${CFLAGS} -c -o $@ ${SDK}/sdk/platform/arch/boot/system_DA14531.c
otp_cs.o: ${SDK}/sdk/platform/utilities/otp_cs/otp_cs.c
	${CC} ${CFLAGS} -c -o $@ ${SDK}/sdk/platform/utilities/otp_cs/otp_cs.c
main.o: main.c
	${CC} ${CFLAGS} -c -o $@ main.c

ldscript_DA14531.lds: ${SDK}/sdk/common_project_files/ldscripts/ldscript_DA14531.lds.S
	${CPP} -o $@ -I. -I${SDK}/sdk/common_project_files ${SDK}/sdk/common_project_files/ldscripts/ldscript_DA14531.lds.S

libsdk.a: main.o hardfault_handler.o nmi_handler.o system_DA14531.o otp_cs.o startup.o ivtable.o
	${AR} cq $@ $^

firmware.elf: libsdk.a main.o ldscript_DA14531.lds
	${LD} ${LDFLAGS1} -o $@ ${LDFLAGS2} ${LIBS} -Tldscript_DA14531.lds

firmware.bin: firmware.elf
	${OBJCOPY} -Obinary $^ $@
	${SIZE} firmware.elf
