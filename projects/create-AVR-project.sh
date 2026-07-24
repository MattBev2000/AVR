#!/bin/bash

set -e


usage()
{
    echo "Usage: $0 -n <project-name> -t <avr-mcu>"
    echo "Example: $0 -n blink -t atmega328p"
    exit 1
}


while getopts "n:t:" opt
do
    case $opt in
        n)
            PROJECT_NAME=$OPTARG
            ;;
        t)
            TEMPLATE=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done


if [ -z "$PROJECT_NAME" ] || [ -z "$TEMPLATE" ]
then
    usage
fi


if [ -d "$PROJECT_NAME" ]
then
    echo "Error: directory '$PROJECT_NAME' already exists"
    exit 1
fi


echo
echo "Creating AVR project: $PROJECT_NAME"
echo "MCU: $TEMPLATE"
echo


mkdir -p "$PROJECT_NAME"

cd "$PROJECT_NAME"



################################
# Project configuration
################################

cat > .config <<EOF
TEMPLATE=$TEMPLATE
EOF



################################
# Directories
################################

mkdir -p \
src \
include \
lib \
build \
docs \
.vscode



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
* Author : mattia
* Date   : Fri Jul 24 11:52:53 AM CEST 2026
*
*/


/* -------------------- PREDEFINED MACROS & INCLUDES -------------------- */ // --------------------------------------------------------------------------------
#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>      // Interrupts abilitation


/* -------------------- USER INCLUDES -------------------- */ // --------------------------------------------------------------------------------


/* -------------------- USER MACROS -------------------- */ // --------------------------------------------------------------------------------


/* -------------------- USER GLOBAL VARIABLES -------------------- */ // --------------------------------------------------------------------------------


/* -------------------- USER FUNCTION -------------------- */ // --------------------------------------------------------------------------------



int main(void)  // START MAIN FUNCTION --------------------------------------------------------------------------------
{

    /* -------------------- USER INIT CODE -------------------- */

    while(1)  // START MAIN LOOP --------------------------------------------------------------------------------
    {

        /* -------------------- USER LOOP CODE -------------------- */
    
    }  // END MAIN LOOP --------------------------------------------------------------------------------

    /* -------------------- USER CLEANUP CODE -------------------- */ 
    return 0;

}  // END MAIN FUNCTION --------------------------------------------------------------------------------



EOF



################################
# Makefile
################################

cat > Makefile <<'EOF'

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

EOF



################################
# flash.sh
################################

cat > flash.sh <<'EOF'
#!/bin/bash


source .config


MCU=$TEMPLATE


PROGRAMMER=avrisp

HEX=build/main.hex



echo "Searching AVRISP programmer..."



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
    echo "AVRISP programmer not detected"
    echo

    exit 1

fi



if [ ! -f "$HEX" ]
then

    echo
    echo "ERROR: firmware not found"
    echo "Run: make"

    exit 1

fi



echo
echo "Flashing $HEX"
echo "MCU: $MCU"



avrdude \
-c $PROGRAMMER \
-p $MCU \
-U flash:w:$HEX:i



echo
echo "Flash completed successfully"

EOF


chmod +x flash.sh



################################
# VS Code IntelliSense
################################

cat > .vscode/c_cpp_properties.json <<EOF
{
    "configurations": [
        {
            "name": "AVR",
            "compilerPath": "/usr/bin/avr-gcc",
            "includePath": [
                "\${workspaceFolder}/**",
                "/usr/lib/avr/include"
            ],
            "defines": [
                "__AVR__",
                "F_CPU=16000000UL"
            ],
            "cStandard": "c17",
            "intelliSenseMode": "linux-gcc-x64"
        }
    ],
    "version": 4
}
EOF



################################
# Git ignore
################################

cat > .gitignore <<EOF

build/

*.elf
*.hex
*.eep
*.map

EOF



################################
# README
################################

cat > README.md <<EOF

# $PROJECT_NAME


AVR $TEMPLATE bare-metal project.



## Build


make



## Flash


make flash



## MCU


$TEMPLATE



## Structure


src/
    source files

include/
    headers

lib/
    libraries

build/
    generated files


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
echo " $PROJECT_NAME"

echo "MCU:"
echo " $TEMPLATE"

echo


if command -v tree >/dev/null 2>&1
then
    tree .
else
    find . -print
fi