<#

.EXAMPLE
$MDTSimulatorPath = "C:\MDTSimulator"
$DeploymentShare = "\\$env:COMPUTERNAME\dep-psdforked$"
$Mode = 'PSD'
$Environment = 'VSCode'

. "C:\MDTSimulator\Start-MDTSimulator.ps1" -MDTSimulatorPath $mdtSimulatorPath -DeploymentShare $DeploymentShare -Mode $Mode -Environment $Environment


#>

#requires -Version 5.1
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $False,
        Position = 0)]
    [string]$MDTSimulatorPath = $PSScriptRoot,

    [parameter(Mandatory=$true)]
    [string]$DeploymentShare,

    [parameter(Mandatory=$false)]
    [ValidateSet('MDT','PSD')]
    [string]$Mode = 'MDT',

    [parameter(Mandatory=$false)]
    [ValidateSet('Powershell','ISE','VSCode')]
    [string]$Environment = 'ISE',
    
    [switch]$NoSquencer
)

#$RootPath = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]
##=============================
## FUNCTIONS
##=============================

Function Test-IsVSCodeInstalled{
    Param([switch]$Passthru)
    $Paths = (Get-Item env:Path).Value.split(';')
    If($paths -like '*Microsoft VS Code*'){
        If($Passthru){
            Return ($paths -like '*Microsoft VS Code*')
        }Else{
            return $true
        }
        
    }Else{
        return $false
    }
}


Function Test-IsAdmin{
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

#if any previous MDT process ran, remove it
#Remove-Item -Path C:\MININT -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
#Remove-Item -Path E:\MININT -Recurse -Force -ErrorAction SilentlyContinue | Out-Null


$TsCoreCopyPaths = @(
    "C:\Windows\System32\WindowsPowerShell\v1.0"
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\WSIM"
)

$BDDCopyPath = @(
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\Microsoft.BDD.TaskSequenceModule"
)


#check for MDT simulator and ZTI module are installed
If( (Test-Path $MDTSimulatorPath) )
{
    switch($Environment){
        'VSCode'     {
            $VscodePoshPath = (Get-ChildItem "$env:UserProfile\.vscode\extensions\ms-vscode.powershell-*\modules").FullName | Select -Last 1
            $TsCoreCopyPaths += "$VscodePoshPath\PowerShellEditorServices\bin\Desktop"

            $BDDCopyPath += "$VscodePoshPath\Microsoft.BDD.TaskSequenceModule"
        }
    }


    Foreach($path in $TsCoreCopyPaths){
        If(-Not(Test-Path $path)){
            Write-Host "Creating path: $path" -ForegroundColor Cyan
            mkdir $path | Out-Null
        }
        Copy-Item "$MDTSimulatorPath\Modules\Microsoft.BDD.TaskSequenceModule\Interop.TSCore.dll" $path -Force | Out-Null
    }

    Foreach($path in $BDDCopyPath){
        If(-Not(Test-Path $path)){
            Write-Host "Creating path: $path" -ForegroundColor Cyan
            mkdir $path | Out-Null
        }
        Copy-Item "$MDTSimulatorPath\Modules\Microsoft.BDD.TaskSequenceModule\*" $path -Force | Out-Null
    }

    Import-Module "$MDTSimulatorPath\Modules\ZTIutility\ZTIutility.psm1" -Verbose -Force

    Write-Host "Starting MDT Simulation in $Mode mode..." -ForegroundColor Cyan
    Try{
        switch($Mode){

            'MDT' {
                Try{
                    . "$MDTSimulatorPath\Gather.ps1"
                }Catch{
                    Write-Host "Unable to gather modules [$MDTSimulatorPath\Gather.ps1]; ensure all required files are in the correct path" -ForegroundColor Red
                    Exit
                }
            }
            'PSD'{
                Try{
                    Write-Verbose "Gathering modules from $DeploymentShare\Tools\Modules"
                    Get-ChildItem "$Deploymentshare\Tools\Modules" -Recurse -File | ForEach-Object {    
                        $Folder = Split-Path (Split-Path $_.FullName -Parent) -Leaf
                        
                        New-Item -Path "$MDTSimulatorPath\Modules\$Folder" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                        Write-Verbose "Copying module: $($_.FullName) to $MDTSimulatorPath\Modules\$Folder"
                        Copy-Item $_.FullName -Destination "$MDTSimulatorPath\Modules\$Folder" -Force -ErrorAction SilentlyContinue | Out-Null
                    
                        #Import-Module $_.FullName -ErrorAction SilentlyContinue -Verbose:$VerbosePreference | Out-Null
                    }
                    # $Path = "$MDTSimulatorPath\Modules"
                    if($verbosePreference -eq "Continue")
                    {
                        $Global:PSDDebug = $true
                    }
                    #. "$MDTSimulatorPath\PSDGather.ps1" -Path "$MDTSimulatorPath\Modules" 
                    Import-Module "$MDTSimulatorPath\Modules\Microsoft.BDD.TaskSequenceModule" -Scope Global
                    Import-Module "$MDTSimulatorPath\Modules\PSDUtility"
                    Import-Module "$MDTSimulatorPath\Modules\PSDGather"
                    Get-PSDLocalInfo
                    #Save-PSDVariables
                    $MinintLoc = Get-PSDLocalDataPath
                    #Pop-Location
                    Push-Location $MinintLoc
                }Catch{
                    Write-Host ("Unable to gather modules [.\$MDTSimulatorPath\PSDGather.ps1 -Path '$MDTSimulatorPath\Modules']: {0}" -f $_.Exception.Message) -ForegroundColor Red
                    Exit
                }
            }
        }
        Write-Host "Modules loaded successfully" -ForegroundColor Green
    }Catch{
        Write-Host "Unable to gather modules; ensure all required files are in the correct path" -ForegroundColor Red
        Exit
    }

    #grab TSscript called by NePSConsole.ps1
    $TSStartupScript = Get-Content "$MDTSimulatorPath\TSEnv.ps1"

    #change the path to the deploymentshare in the TSenv.ps1 file (cannot be called as argument)
    $TSStartupScript[0] = "`$MDTShare = `"$DeploymentShare`""
    $TSStartupScript | Out-File "$MDTSimulatorPath\TSEnv.ps1" -Force

    # to identify correct running process; append the admin value to end of windows (used in VSCode)
    If(Test-IsAdmin -PassThru){$AppendWindow = ' [Administrator]'}Else{$AppendWindow = $null}

    Write-Host "Launching MDT environment in $Environment..." -ForegroundColor Green
    switch($Environment){
        'Powershell' {

                        $ProcessPath = "C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell.exe"
                        $ProcessArgument="$MDTSimulatorPath\TSEnv.ps1"

                        #detection for process window
                        $Window = "MDT Simulator Terminal"
                        $sleep = 5
                        }

        'ISE'        {
                        $ProcessPath = "C:\Windows\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"
                        $ProcessArgument="$MDTSimulatorPath\TSEnv.ps1"

                        #detection for process window
                        $Window = "MDT Simulator Terminal"
                        $sleep = 30
                        }

        'VSCode'     {
                        If(Test-IsVSCodeInstalled){
                            $ProcessPath = (Test-IsVSCodeInstalled -Passthru) + '\code.cmd'
                            If($Mode -eq 'PSD'){
                                $ProcessArgument="$DeploymentShare $MDTSimulatorPath\TSEnv.ps1 $DeploymentShare\Scripts\PSDGather.ps1 $DeploymentShare\Scripts\PSDStart.ps1 --new-window --wait"
                            }Else{
                                $ProcessArgument="$DeploymentShare $MDTSimulatorPath\TSEnv.ps1 --new-window --wait"
                            }

                            #detection for process window
                            $titleName = $DeploymentShare.split('\')[-1]
                            $Window = "TSEnv.ps1 - " + $titleName +" - Visual Studio Code" + $AppendWindow
                            $sleep = 30
                        }
                        Else{
                            Write-host "Visual Studio Code was not found; Unable to start MDT simulator with it.`nInstall at https://code.visualstudio.com/ or run command Start-MyVSCodeInstall" -BackgroundColor Red -ForegroundColor White
                        }
                     }

    }

    #create OpenEditor.ps1 file
    ('Write-Host "Starting "' + $Environment +'"...DO NOT CLOSE THIS WINDOW!" -ForegroundColor Red') | Out-File "$MDTSimulatorPath\OpenEditor.ps1" -Force
    ('Start-Process "' + $ProcessPath +'" -ArgumentList "' + $ProcessArgument +'" -Wait') | Out-File "$MDTSimulatorPath\OpenEditor.ps1" -Force -Append

    #replace content with path to TSenv.ps1
    #($TSConsoleScript).replace($QoutedText[0],$ProcessPath).replace($QoutedText[2],$ProcessArgument) | Set-Content "$MDTSimulatorPath\OpenEditor.ps1"

    Write-Host "Copy collected variables to MININT folder..."
    Copy-Item "$MinintLoc\SMSOSD\OSDLOGS\VARIABLES.DAT" $MDTSimulatorPath -Force -ErrorAction SilentlyContinue | Out-Null

    If(-not $NoSquencer){
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
            Try{
                Start-Process "$MDTSimulatorPath\TsmBootstrap.exe" -ArgumentList "/env:SAStart" | Out-Null
            }Catch{
                Write-Host "Unable to start TsmBootstrap.exe; Ensure it is in the correct path" -ForegroundColor Red
                Return $null
            }
            #Start-Process "$MDTSimulatorPath\TsmBootstrap.exe" -ArgumentList "/env:SAContinue" | Out-Null
            $maxWait = 20
            
            
            $started = $false
            #check process until it opens
            Do {
                $status = Get-Process | Where-Object {$_.MainWindowTitle -eq $Window}

                If (!($status)) { Write-Host '.' -NoNewline -ForegroundColor Cyan ; Start-Sleep -Seconds 1 }

                Else { Write-Host ('Simulator terminal started in {0}' -f $Environment) -ForegroundColor Green; $started = $true; Start-sleep $sleep}
                $timeout++
            }
            Until ( $started -or ($timeout -eq $maxWait) )
        }
    }
}
Else{
        Write-Host ("No MDT Simulator found in path [{0}]..." -f $MDTSimulatorPath) -ForegroundColor Red
}


Pop-Location