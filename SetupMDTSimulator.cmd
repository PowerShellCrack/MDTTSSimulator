CLS
@ECHO OFF
ECHO		*********************************************************
ECHO		*							*
ECHO		*	 Prepare MDT Simulation Directory    		*
ECHO		*							*
ECHO		*********************************************************
SET MDTSourceFiles=C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution
SET INSTALLPATH=%systemdrive%\MDTSimulator
SET TSSCRIPT=%INSTALLPATH%\OpenEditor.ps1

SET /P DEPSHARE=What is the Deployment share UNC [eg. \\192.168.1.10\Deploymentshare$]? 

ECHO What is the Editor you'd like to use: 
ECHO   A. Powershell
ECHO   B. PowerShell ISE
ECHO   C. Visual Studio Code
choice /c ABC /m "Please select one of the above options"
IF %ERRORLEVEL% EQU 1 (
	SET SIMENV=PowerShell
	SET EDITORPATH="C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe"
	SET LAUNCHCMD=
)
IF %ERRORLEVEL% EQU 2 (
	SET SIMENV=ISE
	SET EDITORPATH="C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"
	SET LAUNCHCMD=
)
IF %ERRORLEVEL% EQU 3 (
	SET SIMENV=VSCode
	SET EDITORPATH="%userprofile%\AppData\Local\Programs\Microsoft VS Code\code.exe"
	SET POSTARGS=-ArgumentList "%DEPSHARE% %INSTALLPATH%\TSEnv.ps1 --new-window"
	SET LAUNCHCMD=cmd /c
)

ECHO Are you simulating MDT or PSD:
ECHO   A. MDT
ECHO   B. PSD
choice /c AB /m "Please select one of the above options"
IF %ERRORLEVEL% EQU 1 (
	SET MODE=MDT
)
IF %ERRORLEVEL% EQU 2 (
	SET MODE=PSD
)


ECHO Building %TSSCRIPT% file
ECHO Start-Process %EDITORPATH% %POSTARGS% -Wait > %TSSCRIPT%
timeout 1 > NUL

ECHO Building Simuator Folder
mkdir "%INSTALLPATH%" 2> NUL
mkdir "%INSTALLPATH%\x64" 2> NUL
mkdir "%INSTALLPATH%\00000409" 2> NUL
mkdir "%INSTALLPATH%\Modules" 2> NUL
timeout 1 > NUL

ECHO Install MDT Simulator required files
xcopy /O /X /E /H /K /Y "%MDTSourceFiles%\Tools\Modules" "%INSTALLPATH%\Modules" > NUL
xcopy /O /X /E /H /K /Y "%MDTSourceFiles%\Tools\x64\00000409" "%INSTALLPATH%\00000409" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\Microsoft.BDD.Utility.dll" "%INSTALLPATH%\x64" > NUL
copy /y "%MDTSourceFiles%\Tools\00000409\tsres.dll" "%INSTALLPATH%\00000409" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\CcmCore.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\ccmgencert.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\CcmUtilLib.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\Smsboot.exe" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\SmsCore.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\msvcp120.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\msvcr120.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TsCore.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TSEnv.exe" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TsManager.exe" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TsmBootstrap.exe" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TsMessaging.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TsProgressUI.exe" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Tools\x64\TsResNlc.dll" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Scripts\ZTIDataAccess.vbs" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Scripts\ZTIGather.wsf" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Scripts\ZTIGather.xml" "%INSTALLPATH%" > NUL
copy /y "%MDTSourceFiles%\Scripts\ZTIUtility.vbs" "%INSTALLPATH%" > NUL

ECHO Copying CustomSettings.ini from %DEPSHARE%
copy /y "%DEPSHARE%\Control\CustomSettings.ini" "%INSTALLPATH%" > NUL
timeout 1 > NUL

ECHO Copying TS Files
::copy /y "%~dp0CustomSettings.mdtsample.ini" "%INSTALLPATH%" > NUL
copy /y "%~dp0TSEnv.ps1" "%INSTALLPATH%" > NUL
copy /y "%~dp0Start-MDTSimulator.ps1" "%INSTALLPATH%" > NUL
timeout 1 > NUL

ECHO Setting Up Powershell Modules
xcopy /O /X /E /H /K /Y "%MDTSourceFiles%\Tools\Modules" "%windir%\System32\WindowsPowerShell\v1.0\Modules" > NUL
timeout 1 > NUL

ECHO Generating TS.XML
ECHO ^<^?xml version="1.0"?^> > "%INSTALLPATH%\TS.xml
ECHO ^<sequence version="3.00" name="Custom Task Sequence" description="MDT Simulator"^> >> "%INSTALLPATH%\TS.xml
ECHO   ^<step type="BDD_InstallApplication" name="Launching %SIMENV% with %MODE% Environment Variables" description="" disable="false" continueOnError="false" runIn="WinPEandFullOS" successCodeList="0 3010"^> >> "%INSTALLPATH%\TS.xml
ECHO     ^<defaultVarList^> >> "%INSTALLPATH%\TS.xml
ECHO       ^<variable name="ApplicationGUID" property="ApplicationGUID"^>^</variable^> >> "%INSTALLPATH%\TS.xml
ECHO       ^<variable name="ApplicationSuccessCodes" property="ApplicationSuccessCodes"^>0 3010^<^/variable^> >> "%INSTALLPATH%\TS.xml
ECHO     ^</^defaultVarList^> >> "%INSTALLPATH%\TS.xml
ECHO     ^<action^>"%INSTALLPATH%\Modules\Microsoft.BDD.TaskSequenceModule\Microsoft.BDD.Thunk40.exe" "%INSTALLPATH%\Modules\Microsoft.BDD.TaskSequenceModule\Microsoft.BDD.TaskSequencePSHost40.exe" "%TSSCRIPT%" "C:\MININT\SMSOSD\OSDLOGS"^<^/action^> >> "%INSTALLPATH%\TS.xml
ECHO   ^<^/step^> >> "%INSTALLPATH%\TS.xml
ECHO ^<^/sequence^> >> "%INSTALLPATH%\TS.xml
timeout 1 > NUL

ECHO Generating RunMDTSimulator.cmd
ECHO Powershell -ExecutionPolicy Bypass -NoProfile -File "%INSTALLPATH%\Start-MDTSimulator.ps1" -Mode %MODE% -MDTSimulatorPath %INSTALLPATH% -DeploymentShare "%DEPSHARE%" -Environment %SIMENV% > "%INSTALLPATH%\RunMDTSimulator.cmd
timeout 1 > NUL

ECHO Creating Desktop Shortcut
copy /y "%~dp0MDT Simulator.lnk" "%systemdrive%\Users\Public\desktop" > NUL
timeout 1 > NUL

ECHO		*********************************************************
ECHO		*							*
ECHO		*    Launch the MDT Simulator from desktop shortcut     *
ECHO		*							*
ECHO		*********************************************************

timeout 5 > NUL
pause
exit