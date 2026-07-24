#!/bin/bash

set -e


usage() {
    echo "Usage: $0 -n <project-name>"
    exit 1
}


# Parse arguments
while getopts ":n:" opt; do
    case "$opt" in
        n)
            PROJECT_NAME="$OPTARG"
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
    echo "Error: Directory '$PROJECT_NAME' already exists."
    exit 1
fi


CREATION_DATE=$(date +"%Y-%m-%d")
AUTHOR="Bevilacqua Mattia"


echo "Creating AVR project: $PROJECT_NAME"


###############################################################################
# Create folders
###############################################################################

mkdir -p "$PROJECT_NAME/src"
mkdir -p "$PROJECT_NAME/include"
mkdir -p "$PROJECT_NAME/lib"
mkdir -p "$PROJECT_NAME/build"
mkdir -p "$PROJECT_NAME/.vscode"



###############################################################################
# main.c
###############################################################################

cat > "$PROJECT_NAME/src/main.c" << EOF
/*
 * main.c
 *
 * Created: $CREATION_DATE
 * Author : $AUTHOR
 */


/* -------------------------------------------------- SYSTEM INCLUDES & DEFINITIONS -------------------------------------------------- */

#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>



/* -------------------------------------------------- INCLUDES -------------------------------------------------- */


/* -------------------------------------------------- MACROS -------------------------------------------------- */


/* -------------------------------------------------- GLOBAL VARIABLES -------------------------------------------------- */


/* -------------------------------------------------- FUNCTIONS -------------------------------------------------- */



int main(void)  // START MAIN FUNCTION --------------------------------------------------
{

    /* ---------- PORTS INITIALIZATION ---------- */


    /* ---------- LOCAL VARIABLES ---------- */


    /* ---------- CODE INIT ---------- */



    while (1)  // START MAIN LOOP --------------------------------------------------
    {

        /* ---------- LOOP CODE ---------- */


    }  // END MAIN LOOP --------------------------------------------------



    /* ---------- POST-LOOP CODE ---------- */


    return 0;


}  // END MAIN FUNCTION --------------------------------------------------
EOF



###############################################################################
# Makefile
###############################################################################

cat > "$PROJECT_NAME/Makefile" << 'EOF'
MCU = atmega328p

F_CPU = 16000000UL


CC = avr-gcc
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
SIZE = avr-size


TARGET = main


SRC_DIR = src
INC_DIR = include
BUILD_DIR = build


SRC = $(wildcard $(SRC_DIR)/*.c)

OBJ = $(SRC:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)



CFLAGS = \
-mmcu=$(MCU) \
-DF_CPU=$(F_CPU) \
-I$(INC_DIR) \
-std=c17 \
-Wall \
-Wextra \
-Wpedantic \
-Os \
-g



all: $(BUILD_DIR)/$(TARGET).hex



$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@



$(BUILD_DIR)/$(TARGET).elf: $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@



$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@
	$(OBJDUMP) -S $< > $(BUILD_DIR)/$(TARGET).lst
	$(SIZE) $<



clean:
	rm -rf $(BUILD_DIR)/*



.PHONY: all clean
EOF



###############################################################################
# flash.sh
###############################################################################

cat > "$PROJECT_NAME/flash.sh" << 'EOF'
#!/bin/bash

set -e


MCU="atmega328p"
PROGRAMMER="avrispmkII"
HEX="build/main.hex"



if [ ! -f "$HEX" ]; then

    echo "ERROR: $HEX not found."
    echo "Compile first with:"
    echo "    make"

    exit 1

fi



echo "Programming $MCU..."
echo "Using programmer: $PROGRAMMER"



avrdude \
    -c "$PROGRAMMER" \
    -p "$MCU" \
    -U flash:w:"$HEX":i



echo
echo "Programming completed successfully."

EOF


chmod +x "$PROJECT_NAME/flash.sh"



###############################################################################
# VS Code tasks
###############################################################################

cat > "$PROJECT_NAME/.vscode/tasks.json" << 'EOF'
{
    "version": "2.0.0",

    "tasks": [

        {
            "label": "Build AVR",
            "type": "shell",
            "command": "make",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },


        {
            "label": "Flash AVR",
            "type": "shell",
            "command": "./flash.sh"
        },


        {
            "label": "Clean Build",
            "type": "shell",
            "command": "make clean"
        }

    ]
}
EOF



###############################################################################
# Finished
###############################################################################

echo
echo "AVR project created successfully!"
echo

echo "Structure:"
echo "$PROJECT_NAME/"
echo "├── Makefile"
echo "├── flash.sh"
echo "├── src/"
echo "│   └── main.c"
echo "├── include/"
echo "├── lib/"
echo "├── build/"
echo "└── .vscode/"
echo "    └── tasks.json"

echo
echo "Usage:"
echo "  cd $PROJECT_NAME"
echo "  make"
echo "  ./flash.sh"
echo