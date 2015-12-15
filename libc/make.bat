tasm start.asm
..\nasm raf.asm -t -f obj -o raf.obj
tcc -c -mt demo1.c
tlink start.obj raf.obj demo1.obj, demo1.com /t