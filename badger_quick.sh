#!/bin/bash

# ./badger_quick.sh /shellcode/full/path.bin

PP=$1
NAME=$(echo $PP | rev | cut -d'/' -f1 | rev | cut -d'.' -f1)
OUTDIR="$(echo $PP | rev | cut -d'/' -f2- | rev)/compiled"
mkdir $OUTDIR 2>/dev/null
echo Getting shellcode from $PP
echo Naming payload $NAME
echo Output dir is $OUTDIR
set -e
cp $PP badger.bin
echo '#include <windows.h>' > shellcode.h
echo '' >> shellcode.h
xxd -i badger.bin >> shellcode.h
make
mv shellcode.dll $OUTDIR/$NAME.dll
mv shellcode.exe $OUTDIR/$NAME.exe
rm badger.bin
echo DONE
