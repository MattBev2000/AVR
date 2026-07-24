#!/bin/bash

set -e

VERSION="6.3"
PREFIX="/usr/local"

echo
echo "======================================"
echo " Installazione AVRDUDE $VERSION"
echo "======================================"
echo


########################################
# Controllo root tramite sudo
########################################

if ! command -v sudo >/dev/null 2>&1
then
    echo "Errore: sudo non disponibile"
    exit 1
fi


########################################
# Dipendenze
########################################

echo "[1/7] Installazione dipendenze..."

sudo apt update

sudo apt install -y \
    build-essential \
    git \
    wget \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    flex \
    libelf-dev \
    libusb-dev \
    libusb-1.0-0-dev


########################################
# Directory lavoro
########################################

WORKDIR="$HOME/Downloads"

mkdir -p "$WORKDIR"

cd "$WORKDIR"


########################################
# Download sorgenti
########################################

echo
echo "[2/7] Download AVRDUDE $VERSION..."

if [ ! -d "avrdude-$VERSION" ]
then
    wget \
    https://github.com/avrdudes/avrdude/archive/refs/tags/v${VERSION}.tar.gz

    tar xvf v${VERSION}.tar.gz

else
    echo "Sorgenti già presenti"
fi


cd avrdude-$VERSION



########################################
# Bootstrap
########################################

echo
echo "[3/7] Bootstrap autotools..."

if [ ! -f configure ]
then
    ./bootstrap
else
    echo "configure già presente"
fi



########################################
# Configure
########################################

echo
echo "[4/7] Configurazione..."

make distclean 2>/dev/null || true


./configure \
CPPFLAGS="-I/usr/include/libusb-1.0" \
LDFLAGS="-lusb -lusb-1.0"



########################################
# Build
########################################

echo
echo "[5/7] Compilazione..."

make -j$(nproc)



########################################
# Installazione
########################################

echo
echo "[6/7] Installazione..."

sudo make install



########################################
# Aggiornamento linker
########################################

sudo ldconfig



########################################
# Test finale
########################################

echo
echo "[7/7] Verifica installazione..."

$PREFIX/bin/avrdude -v



echo
echo "======================================"
echo " AVRDUDE $VERSION installato"
echo "======================================"
echo

echo "Test AVR ISP mkII:"
echo

echo "$PREFIX/bin/avrdude -c avrispmkII -P usb -p atmega328p -v"

echo
echo "Se il programmatore viene trovato vedrai:"
echo "  Found AVRISP mkII"
echo