@echo off
cls
rem  ---------------------------------------------------------
rem  Univerzitet Union, Racunarski fakultet u Beogradu
rem  08.2008. Operativni sistemi
rem  ---------------------------------------------------------
rem  RAF_OS : Trivijalni skolski operativni sistem
rem  Skript za prevodjenje na sistemu Windows (Command Prompt)
rem
rem  Inicijalna verzija 0.0.1 (Stevan Milinkovic, 20.08.2010.)
rem  ---------------------------------------------------------
rem
rem
rem  Upotreba:
rem  ---------
rem         make          - prevodnjenje i instaliranje RAF_OS
rem         make install  - instaliranje prevedenog RAF_OS
rem         make clean    - brisanje instalacionih binarnih datoteka 
rem 
rem  Direktorijumsko stablo
rem  ----------------------
rem  make.bat
rem  nasm.exe
rem <pomocni>
rem  <aplikacije>
rem          <bin>
rem          <demo>
rem          <src>
rem  <boot>
rem          <bin>
rem          <src>	
rem  <kenel>
rem          <bin>
rem          <src>
rem  <libc>
rem  -----------------------	
echo.

if "%1" == "install" goto install
if "%1" == "clean" goto clean

echo.
echo Prevodim RAF_OS operativni sistem
echo ----------------------------------
echo.
echo [1] Prevodim boot loader
nasm boot\src\boot.asm -f bin -o boot\bin\boot.bin

echo [2] Prevodim RAF_OS kernel
cd kernel\src
  ..\..\nasm kernel.asm -f bin -o ..\..\kernel\bin\kernel.bin
cd ..\..\

echo [3] Prevodim aplikacije
cd aplikacije\src
 for %%i in (*.asm) do ..\..\nasm -f bin %%i
 for %%i in (*.bin) do del %%i
 for %%i in (*.) do ren %%i %%i.bin

cd ..
  copy src\*.bin bin > nul
  del/q src\*.bin
cd ..

:install
if NOT EXIST "boot\bin\boot.bin" echo Ne postoji binarna instalacija RAF_OS
if NOT EXIST "boot\bin\boot.bin" goto quit

echo.
echo Instaliram RAF_OS operativni sistem
echo -----------------------------------
echo.
echo Kopiram boot sektor ...
pomocni\pb boot\bin\boot.bin
echo Instaliram kernel  ....
copy kernel\bin\kernel.bin a: > nul
cd aplikacije\bin
  echo Kopiram aplikacije .... 
  copy *.bin a: > nul
cd ..
cd demo
  copy *.* a: > nul
cd ..\..

echo.
echo RAF_OS je uspesno instaliran.
goto quit

:clean
del/q boot\bin\*.* > nul
del/q kernel\bin\*.* > nul
del/q kernel\bin\*.* > nul
del/q aplikacije\bin\*.* > nul

echo RAF_OS binarne datoteke uspesno obrisane.
:quit
echo.
