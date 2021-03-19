@ECHO OFF
set MDTSourceFiles=C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution
set INSTALLPATH=%systemdrive%\MDTSimulator

ECHO Build Simuator Folder
mkdir %INSTALLPATH% 2> NUL
mkdir "%INSTALLPATH%\x64" 2> NUL
mkdir "%INSTALLPATH%\00000409" 2> NUL

ECHO Install MDT Simulator
::xcopy /O /X /E /H /K /Y "%MDTSourceFiles%\x64" "%INSTALLPATH%\x64"
::xcopy /O /X /E /H /K /Y "%MDTSourceFiles%\00000409" "%INSTALLPATH%\00000409"
copy /y "%MDTSourceFiles%\Tools\x64\Microsoft.BDD.Utility.dll" "%INSTALLPATH%\x64"
copy /y "%MDTSourceFiles%\Tools\00000409\tsres.dll" "%INSTALLPATH%\00000409"
copy /y "%MDTSourceFiles%\Tools\x64\cmCore.dll" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\ccmgencert.dll" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\CcmUtilLib.dll" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\CustomSettings.ini" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\Smsboot.exe" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\SmsCore.dll" "%INSTALLPATH%"

copy /y "%MDTSourceFiles%\Tools\x64\TsCore.dll" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\TSEnv.exe" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\TsManager.exe" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\TsmBootstrap.exe" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\TsMessaging.dll" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\TsProgressUI.exe" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Tools\x64\TsResNlc.dll" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Scripts\ZTIDataAccess.vbs" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Scripts\ZTIGather.wsf" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Scripts\ZTIGather.xml" "%INSTALLPATH%"
copy /y "%MDTSourceFiles%\Scripts\ZTIUtility.vbs" "%INSTALLPATH%"

REM Custom Files
copy /y "%~dp0CustomSettings.ini" "%INSTALLPATH%"
copy /y "%~dp0TS.XML" "%INSTALLPATH%"
copy /y "%~dp0TSEnv.ps1" "%INSTALLPATH%"
copy /y "%~dp0NewPSConsole.ps1" "%INSTALLPATH%"
copy /y "%~dp0RunMDTSimulator.cmd" "%INSTALLPATH%"
copy /y "%~dp0MDT Simulator.lnk" "%systemdrive%\Users\Public\desktop"

ECHO Setting Up Powershell Modules
xcopy /O /X /E /H /K /Y "%MDTSourceFiles%\Modules" "%windir%\System32\WindowsPowerShell\v1.0\Modules"

::Powershell -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser" 

Echo Launch the MDT Simulator link from your desktop
timeout 10 > NUL
exit