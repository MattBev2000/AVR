#!/bin/bash


source .config


MCU=$TEMPLATE


PROGRAMMER=avrispmkII

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

