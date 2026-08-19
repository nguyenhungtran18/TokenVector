@echo off
:: tkvread.bat <duong_dan_file> [mode] - doc 1 file qua Universal Context
:: Compressor va in ra stdout. Dung de giam token khi phai nap ca file lon
:: vao context.
::
::   mode = num   (mac dinh) bo comment+docstring, GIU so dong goc  -38% token
::   mode = struct               bo comment+docstring, khong so dong -47% token
::   mode = full                 chi bo comment, giu docstring        -20% token
::
:: Log/JSON/text tu dong di theo nhanh rieng cua engine (log -98%).
setlocal
if "%~1"=="" ( echo Cach dung: tkvread.bat ^<file^> [num^|struct^|full] & exit /b 1 )
if not exist "%~1" ( echo Khong tim thay file: %~1 & exit /b 1 )

set "DIR=%~dp0"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=num"

if /i "%MODE%"=="num"    set "EXE=%DIR%compress_num_cli.exe"
if /i "%MODE%"=="struct" set "EXE=%DIR%compress_struct_cli.exe"
if /i "%MODE%"=="full"   set "EXE=%DIR%compress_cli.exe"
if not defined EXE ( echo Mode khong hop le: %MODE% ^(num^|struct^|full^) & exit /b 1 )
if not exist "%EXE%" ( echo Thieu %EXE% - chay: python tkv.py build "TokenVector - Only\examples\stdlib\compress_%MODE%_cli.tkv" & exit /b 1 )

:: XOA ket qua cu TRUOC khi chay: neu exe crash giua chung, khong con file cu
:: nam lai de bi doc nham thanh ket qua cua LAN NAY. Da gap that: input rong
:: lam exe crash, tkvread in ra noi dung cua FILE TRUOC DO ma khong bao gi.
del /q "%DIR%_compress_out.txt" 2>nul
copy /y "%~1" "%DIR%_compress_in.txt" >nul
"%EXE%" >nul
if not exist "%DIR%_compress_out.txt" (
    echo [tkvread] LOI: engine khong tao duoc ket qua ^(exe that bai^) - doc thang file goc thay vi tin ban nen.
    exit /b 2
)
type "%DIR%_compress_out.txt"
