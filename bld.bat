@echo off
set MASM51=c:\masm32
set include=%MASM51%\include;%MASM51%\macros
set lib=%MASM51%\lib
set path=%path%;%MASM51%\bin

if "%1"=="" goto build
goto %1
goto build

:build
rem ScanStation build
rem call y:\bin\gawk.bat -f h2inc.awk idc.h > idc.inc
rc -v ScanSttn.rc
:cvtres -machine:ix86 ScanSttn.res

rem LIBUSB=-DUSE_LIBUSB=0
rem polib -def:libusb.def -machine:ix86 -out:libusb.lib

ml -nologo -c -coff GetDllVersion.asm
ml -nologo -c -coff presets.asm
ml -nologo -c -coff TimedMsgBox.asm
ml -nologo -c -coff %LIBUSB% ScanIntf.asm
ml -nologo -c -coff ScanSttn.asm
link -nologo -out:ScanSttn.exe -subsystem:windows ScanSttn.obj ScanIntf.obj TimedMsgBox.obj presets.obj GetDllVersion.obj ScanSttn.res
ml -coff test2.asm -link -subsystem:windows

shift
rem make %0 %1 %2 %3 %4 %5 %6
goto end

:clean
del test2.obj
del test2.exe
del GetDllVersion.obj
del ScanIntf.obj
del TimedMsgBox.obj
del presets.obj
del ScanSttn.obj
del ScanSttn.exe
del ScanSttn.res
del libusb.lib
goto end

:install
if exist ScanSttn.exe copy ScanSttn.exe "%AllUsersProfile%\Рабочий стол\"
goto end

:end


