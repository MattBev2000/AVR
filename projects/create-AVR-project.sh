#!/bin/bash

set -e


usage()
{
    echo "Usage: $0 -n <project-name>"
    exit 1
}


while getopts "n:" opt
do
    case $opt in
        n)
            PROJECT_NAME=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done


if [ -z "$PROJECT_NAME" ]; then
    usage
fi


if [ -d "$PROJECT_NAME" ]; then
    echo "Error: directory '$PROJECT_NAME' already exists"
    exit 1
fi


echo "Creating AVR project: $PROJECT_NAME"


mkdir -p "$PROJECT_NAME"

cd "$PROJECT_NAME"



################################
# Directories
################################

mkdir -p \
src \
include \
lib \
build \
docs



touch src/.gitkeep
touch include/.gitkeep
touch lib/.gitkeep
touch build/.gitkeep
touch docs/.gitkeep



################################
# main.c
################################

cat > src/main.c <<EOF
/*
*
*
*
*/

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>


int main(void)
{


    while(1)
    {


    }


    return 0;
}

EOF



################################
# Makefile
################################

cat > Makefile <<'EOF'

MCU = atmega328p

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

EOF



################################
# flash.sh
################################

cat > flash.sh <<'EOF'
#!/bin/bash


MCU=atmega328p

PROGRAMMER=avrisp

HEX=build/main.hex



echo "Searching AVRISP USB programmer..."



if ! command -v avrdude >/dev/null 2>&1
then
    echo "ERROR: avrdude not installed"
    exit 1
fi



if ! avrdude \
    -c $PROGRAMMER \
    -p $MCU \
    -v >/dev/null 2>&1

then

    echo
    echo "ERROR:"
    echo "AVRISP USB ATMEL AVR Programmer not detected"
    echo
    echo "Check:"
    echo "- USB connection"
    echo "- programmer power"
    echo "- udev permissions"

    exit 1

fi



echo "Programmer detected"



if [ ! -f "$HEX" ]
then

    echo
    echo "ERROR: firmware not found"
    echo "Run: make"

    exit 1

fi



echo
echo "Flashing $HEX..."



avrdude \
-c $PROGRAMMER \
-p $MCU \
-U flash:w:$HEX:i



echo
echo "Flash completed successfully"

EOF


chmod +x flash.sh



################################
# .gitignore
################################

cat > .gitignore <<EOF

# AVR generated files

build/

*.elf
*.hex
*.eep
*.map

EOF



################################
# README.md
################################

cat > README.md <<EOF
# $PROJECT_NAME


AVR ATmega328P bare-metal project.



## Build


make



## Flash


./flash.sh



## Programmer


AVRISP USB ATMEL AVR Programmer



## Structure


src/

    source files


include/

    header files


lib/

    custom libraries


build/

    generated files


docs/

    documentation

EOF



################################
# Final output
################################

echo
echo "================================="
echo " AVR project created successfully"
echo "================================="
echo

echo "Project:"
echo "  $PROJECT_NAME"

echo


if command -v tree >/dev/null 2>&1
then
    tree .
else
    find . -print | sed 's|^\./||'
fi