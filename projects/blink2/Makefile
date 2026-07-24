
include .config


MCU = $(TEMPLATE)

TARGET = main


CC = avr-gcc
OBJCOPY = avr-objcopy
SIZE = avr-size


SRC = $(wildcard src/*.c)
LIB = $(wildcard lib/*.c)


CFLAGS = \
-mmcu=$(MCU) \
-DF_CPU=16000000UL \
-Os \
-Wall \
-Iinclude



all: build/$(TARGET).hex



build:
	mkdir -p build



build/$(TARGET).elf: $(SRC) $(LIB) | build

	$(CC) $(CFLAGS) \
	$(SRC) $(LIB) \
	-o $@



build/$(TARGET).hex: build/$(TARGET).elf

	$(OBJCOPY) \
	-O ihex \
	-R .eeprom \
	$< \
	$@

	$(SIZE) $<



flash:

	./flash.sh



clean:

	rm -rf build/*



.PHONY: all flash clean

