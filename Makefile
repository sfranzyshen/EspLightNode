all : image.elf
FW_FILE_1:=0x00000.bin
FW_FILE_2:=0x40000.bin

TARGET_OUT:=image.elf
OBJS:=  user/user_main.o \
	user/output_protocols/ws2812.o \
	user/output_protocols/ws2801.o \
	user/output_protocols/lpd6803.o \
	user/input_protocols/tpm2net.o \
	user/input_protocols/artnet.o \
	user/config/config.o \
	user/config/httpd.o 

SRCS:=  user/user_main.c \
	user/output_protocols/ws2812.c \
	user/output_protocols/ws2801.c \
	user/output_protocols/lpd6803.c \
	user/input_protocols/tpm2net.c \
	user/input_protocols/artnet.c \
	user/config/config.c \
	user/config/httpd.c

GCC_FOLDER:=/home/user/esp8266/crosstool-NG/builds
ESPTOOL_PY:=/home/user/esp8266/esptool/esptool.py
FW_TOOL:=/home/user/esp8266/other/esptool/esptool
SDK:=/home/user/esp8266/esp_iot_sdk_v0.9.3


XTLIB:=$(SDK)/lib
XTGCCLIB:=$(GCC_FOLDER)/xtensa-lx106-elf/lib/gcc/xtensa-lx106-elf/4.8.2/libgcc.a
FOLDERPREFIX:=$(GCC_FOLDER)/xtensa-lx106-elf/bin
PREFIX:=$(FOLDERPREFIX)/xtensa-lx106-elf-
CC:=$(PREFIX)gcc

CDEFINES:=-DENABLE_TPM2NET -DENABLE_ARTNET -DENABLE_WS2812
CFLAGS:=-mlongcalls -O2 -I$(SDK)/include -Iuser -Iuser/output_protocols -Iuser/input_protocols -Iuser/config $(CDEFINES)

LDFLAGS_CORE:=\
	-nostdlib \
	-Wl,--relax -Wl,--gc-sections \
	-L$ $(SDK)/lib/liblwip.a \
	$(SDK)/lib/libnet80211.a \
	$(SDK)/lib/liblwip.a \
	$(SDK)/lib/libwpa.a \
	$(SDK)/lib/libnet80211.a \
	$(SDK)/lib/libphy.a \
	$(SDK)/lib/libmain.a \
	$(SDK)/lib/libpp.a \
	$(SDK)/lib/libc.a \
	$(SDK)/lib/libhal.a \
	$(SDK)/lib/libjson.a \
	$(SDK)/lib/libssl.a \
	$(XTGCCLIB) \
	-T $(SDK)/ld/eagle.app.v6.ld

LINKFLAGS:= \
	$(LDFLAGS_CORE) \
	-B$(XTLIB)

$(TARGET_OUT) : $(SRCS)
	$(PREFIX)gcc $(CFLAGS) $^ -flto $(LINKFLAGS) -o $@

$(FW_FILE_1): $(TARGET_OUT)
	@echo "FW $@"
	$(FW_TOOL) -eo $(TARGET_OUT) -bo $@ -bs .text -bs .data -bs .rodata -bc -ec

$(FW_FILE_2): $(TARGET_OUT)
	@echo "FW $@"
	$(FW_TOOL) -eo $(TARGET_OUT) -es .irom0.text $@ -ec

burn : $(FW_FILE_1) $(FW_FILE_2)
	($(ESPTOOL_PY) --port /dev/ttyUSB0 write_flash 0x00000 0x00000.bin 0x40000 0x40000.bin)||(true)

clean :
	rm -rf user/*.o $(TARGET_OUT) $(FW_FILE_1) $(FW_FILE_2)


