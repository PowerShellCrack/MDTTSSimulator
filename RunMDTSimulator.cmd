CLS
@ECHO OFF
set CuDIR=%~dp0
if exist C:\MININT rd C:\MININT /s /q
cscript "%~dp0ZTIGather.wsf"
copy C:\MININT\SMSOSD\OSDLOGS\VARIABLES.DAT %CuDIR% /Y > NUL
ECHO.
ECHO NOTE: Once New PowerShell window opens be sure to run:
ECHO cscript ZTIGather.wsf /debug:true
ECHO This will gather all custom properties
ECHO.
"%~dp0TsmBootstrap.exe" /env:SAStart

start C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"