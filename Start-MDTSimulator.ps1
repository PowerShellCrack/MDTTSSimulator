[CmdletBinding()]
Param(
    [Parameter(Mandatory = $False,
        Position = 0)]
    [string]$MDTSimulatorPath = 'C:\MDTSimulator',

    [parameter(Mandatory=$true)]
    [string]$DeploymentShare,

    [parameter(Mandatory=$false)]
    [ValidateSet('MDT','PSD')]
    [string]$Mode = 'MDT',

    [parameter(Mandatory=$false)]
    [ValidateSet('Powershell','ISE','VSCode')]
    [string]$Environment = 'Powershell'        
)


##=============================
## FUNCTIONS
##=============================
#region FUNCTION: Check if running in ISE
Function Test-IsISE {
    # try...catch accounts for:
    # Set-StrictMode -Version latest
    try {
        return ($null -ne $psISE);
    }
    catch {
        return $false;
    }
}
#endregion

#region FUNCTION: Check if running in Visual Studio Code
Function Test-VSCode{
    if($env:TERM_PROGRAM -eq 'vscode') {
        return $true;
    }
    Else{
        return $false;
    }
}
#endregion


Function Test-IsVSCodeInstalled{
    $Paths = (Get-Item env:Path).Value.split(';')
    If($paths -like '*Microsoft VS Code*'){
        return $true
    }Else{
        return $false
    }
}


Function Test-IsAdmin
{
<#
.SYNOPSIS
   Function used to detect if current user is an Administrator.

.DESCRIPTION
   Function used to detect if current user is an Administrator. Presents a menu if not an Administrator

.NOTES
    Name: Test-IsAdmin
    Author: Boe Prox
    DateCreated: 30April2011

.EXAMPLE
    Test-IsAdmin


Description
-----------
Command will check the current user to see if an Administrator. If not, a menu is presented to the user to either
continue as the current user context or enter alternate credentials to use. If alternate credentials are used, then
the [System.Management.Automation.PSCredential] object is returned by the function.
#>
    [cmdletbinding()]
    Param([switch]$PassThru)

    Write-Verbose "Checking to see if current user context is Administrator"
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning "You are not currently running this under an Administrator account! `nThere is potential that this command could fail if not running under an Administrator account."
        Write-Verbose "Presenting option for user to pick whether to continue as current user or use alternate credentials"
        If($PassThru){return $false}

        #Determine Values for Choice
        $choice = [System.Management.Automation.Host.ChoiceDescription[]] @("Use &Alternate Credentials","&Continue with current Credentials")

        #Determine Default Selection
        [int]$default = 0

        #Present choice option to user
        $userchoice = $host.ui.PromptforChoice("Warning","Please select to use Alternate Credentials or current credentials to run command",$choice,$default)

        Write-Debug "Selection: $userchoice"

        #Determine action to take
        Switch ($Userchoice)
        {
            0
            {
                #Prompt for alternate credentials
                Write-Verbose "Prompting for Alternate Credentials"
                #$Credential = Get-Credential
		$Credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "NetBiosUserName")
		Write-Output $Credential
            }
            1
            {
                #Continue using current credentials
                Write-Verbose "Using current credentials"
                $Credential = New-Object psobject -Property @{
    		    UserName = "$env:USERDNSDOMAIN\$env:USERNAME"
		}
		Write-Output $Credential
            }
        }

    }
    Else
    {
        Write-Verbose "Passed Administrator check"
        If($PassThru){return $true}
    }
}


Function Set-WindowPosition {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $Process,

        [parameter(Mandatory=$false)]
        [ValidateSet('Hide','Minimize','Maximize','Restore')]
        [string]$Position,

        [switch]$Show
    )
    Begin{
        Try{
            $WindowCode = '
                [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
                [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
            '
            $AsyncWindow = Add-Type -MemberDefinition $WindowCode -Name Win32ShowWindowAsync -namespace Win32Functions -PassThru
        }
        Catch{

        }
        Finally{
            $hwnds = @($Process)
        }
    }
    Process{
        Foreach($hwnd in $hwnds)
        {
            switch($Position)
            {

             # hide the window (remove from the taskbar)
            'Hide'      {$null = $AsyncWindow::ShowWindowAsync($hwnd.MainWindowHandle, 0)}

            'Maximize'  {$null = $AsyncWindow::ShowWindowAsync($hwnd.MainWindowHandle, 3)}

             #open window
             #{$null = $AsyncWindow::ShowWindowAsync($hwnd0.MainWindowHandle, 4)}

            'Minimize'  {$null = $AsyncWindow::ShowWindowAsync($hwnd.MainWindowHandle, 6)}
                    # restore the window to its original state
            'Retore'    {$null = $AsyncWindow::ShowWindowAsync($hwnd.MainWindowHandle, 9)}
            }

            # being in front
            If($Show){
                $null = $AsyncWindow::SetForegroundWindow($hwnd.MainWindowHandle)
            }
        }
    }End{

    }
}


##=============================
## MAIN
##=============================
#stop an Task Sequence process
Get-Process TS* | Stop-Process -Force

#check for MDT simulator and ZTI module are installed
If( (Test-Path $MDTSimulatorPath) -and (Get-Module -ListAvailable -Name ZTIUtility) )
{
    Import-Module ZTIutility

    #if any previous MDT process ran, remove it
    Remove-Item -Path C:\MININT -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

    Write-Host "Starting MDT Simulation..." -ForegroundColor Green
    switch($Mode){

        'MDT' {
                cscript "$MDTSimulatorPath\ZTIGather.wsf" /debug:true
        }
        'PSD'{
                Push-Location $MDTSimulatorPath
                . "$MDTSimulatorPath\PSDGather.ps1"
                #Get-ChildItem "$MDTSimulatorPath\Modules" -Recurse -Filter *.psm1 | Sort -Descending | ForEach-Object {Import-Module $_.FullName -ErrorAction SilentlyContinue | Out-Null}
                Pop-Location
        }
    }
    #grab console script called by TS.xml
    $TSConsoleScript = Get-content "$MDTSimulatorPath\OpenEditor.ps1"

    #grab TSscript called by NePSConsole.ps1
    $TSStartupScript = Get-Content "$MDTSimulatorPath\TSEnv.ps1"

    #change the path to the deploymentshare in the TSenv.ps1 file (cannot be called as argument)
    ($TSStartupScript).replace("\\Server\deploymentshare",$DeploymentShare) | Set-Content "$MDTSimulatorPath\TSEnv.ps1" -Force

    # to identify correct running process; append the admin value to end of windows (used in VSCode)
    If(Test-IsAdmin -PassThru){$AppendWindow = ' [Administrator]'}Else{$AppendWindow = $null}

    switch($Environment){
        'Powershell' {
                        #$Command = "Start-Process `"C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe`" -ArgumentList `"-noexit -noprofile -file C:\MDTSimulator\TSEnv.ps1`" ï¿½Wait" | Set-Content "$MDTSimulatorPath\OpenEditor.ps1"
                        $ProcessPath = "C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe"
                        $ProcessArgument="$MDTSimulatorPath\TSEnv.ps1"

                        #replace content with path to TSenv.ps1
                        ($TSConsoleScript).replace("C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe",$ProcessPath).replace("C:\MDTSimulator\TSEnv.ps1",$ProcessArgument) |
                                    Set-Content "$MDTSimulatorPath\OpenEditor.ps1"

                        #detection for process window
                        $Window = "MDT Simulator Terminal"
                        $sleep = 5
                        }
        'ISE'        {
                        $ProcessPath = "C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"
                        $ProcessArgument="$MDTSimulatorPath\TSEnv.ps1"

                        #replace content with ISE process and path to TSenv.ps1
                        ($TSConsoleScript).replace("C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe",$ProcessPath).replace("-noexit -noprofile -file C:\MDTSimulator\TSEnv.ps1",$ProcessArgument) |
                                    Set-Content "$MDTSimulatorPath\OpenEditor.ps1"

                        #detection for process window
                        $Window = "MDT Simulator Terminal"
                        $sleep = 30
                        }
        'VSCode'     {
                        If(Test-IsVSCodeInstalled){
                            $ProcessPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\code.exe"
                            $ProcessArgument="$DeploymentShare $MDTSimulatorPath\TSEnv.ps1 $DeploymentShare\Script\PSDStart.ps1 --new-window"

                            #replace content with VScode process and path to TSenv.ps1
                            ($TSConsoleScript).replace("C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe",$ProcessPath).replace("-noexit -noprofile -file C:\MDTSimulator\TSEnv.ps1",$ProcessArgument) |
                                        Set-Content "$MDTSimulatorPath\OpenEditor.ps1"

                            #detection for process window
                            $titleName = $DeploymentShare.split('\')[-1]
                            $Window = "TSEnv.ps1 - " + $titleName +" - Visual Studio Code" + $AppendWindow
                            $sleep = 30
                        }Else{
                            Write-host "Visual Studio Code was not found; Unable to start MDT simulator with it.`nInstall at https://code.visualstudio.com/ or run command Start-MyVSCodeInstall" -BackgroundColor Red -ForegroundColor White
                        }
                        }
    }

    Write-Host "Copy Collected variables to MININT folder..."
    Copy-Item 'C:\MININT\SMSOSD\OSDLOGS\VARIABLES.DAT' $MDTSimulatorPath -Force -ErrorAction SilentlyContinue | Out-Null

    Write-Host "Building TSenv: Starting TaskSequence bootstrapper" -ForegroundColor Cyan -NoNewline

    $MDTTerminalProcess = Get-Process | Where-Object {$_.MainWindowTitle -eq $Window}
    If($MDTTerminalProcess){
        Set-WindowPosition $MDTTerminalProcess -Position Restore -Show
        Write-Host ('...Simulator terminal already started in {0}' -f $Environment) -ForegroundColor Green
    }
    Else{
        If( ($Environment -eq 'VSCode') -and -Not(Test-IsVSCodeInstalled) ){
            Return $null
        }

        $timeout = 1
        Start-Process "$MDTSimulatorPath\TsmBootstrap.exe" -ArgumentList "/env:SAStart" | Out-Null
        #Start-Process "$MDTSimulatorPath\TsmBootstrap.exe" -ArgumentList "/env:SAContinue" | Out-Null
        $started = $false
        #check process until it opens
        Do {

            $status = Get-Process | Where-Object {$_.MainWindowTitle -eq $Window}

            If (!($status)) { Write-Host '.' -NoNewline -ForegroundColor Cyan ; Start-Sleep -Seconds 1 }

            Else { Write-Host ('Simulator terminal started in {0}' -f $Environment) -ForegroundColor Green; $started = $true; Start-sleep $sleep}
            $timeout++
        }
        Until ( $started -or ($timeout -eq 60) )
    }

    #change the path to the deploymentshare back to dfault
    #$TSStartupScript | Set-Content "$MDTSimulatorPath\TSEnv.ps1" -Force
    $TSConsoleScript | Set-Content "$MDTSimulatorPath\OpenEditor.ps1" -Force
}
Else{
        Write-Host ("No MDT Simulator found in path [{0}]..." -f $MDTSimulatorPath) -ForegroundColor Red
}
