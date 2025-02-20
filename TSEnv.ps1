$MDTShare = "\\SERVER\SHARE"

$MDTModule = "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"


#fix mdt registry path
$MDTRegPath = "HKLM:\SOFTWARE\Microsoft\Deployment 4"
#If((Get-ItemProperty $MDTRegPath -Name Install_Dir -ErrorAction SilentlyContinue).Install_Dir -ne $MDTSimulator)
#{
#    Set-ItemProperty $MDTRegPath -Name "Install_Dir" -Value $MDTSimulator -Force
#}

$host.UI.RawUI.WindowTitle = "MDT Simulator Terminal"
cls

#If powershell is not 5.1, exit
If($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1)
{
    Write-Host "This script requires PowerShell 5.1" -ForegroundColor Red
    Exit
}

Write-host "Loading TS environment and Progress UI COM objects" -ForegroundColor Cyan
#region FUNCTION: Attempt to connect to Task Sequence environment
Function Test-SMSTSENV{
    try{
        # Create an object to access the task sequence environment
        $global:tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    }
    catch{
        return $false
    }
    Finally{
        #set global Logpath
        if ($global:tsenv){
            #grab the progress UI
            $global:TSProgressUi = New-Object -ComObject Microsoft.SMS.TSProgressUI
            $global:tsenv
        }
    }
}
#endregion

<#
Import-Module "C:\MDTSimulator\\Modules\Microsoft.BDD.TaskSequenceModule\Microsoft.BDD.TaskSequenceModule.psd1" -Verbose -Force
. "C:\MDTSimulator\\PSDGather.ps1" -Path "$MDTShare\Tools\Modules"
#. "$MDTSimulator\PSDGather.ps1" -Path "$MDTShare\Tools\Modules"
#>
If(Test-path $MDTModule)
{
    Import-Module $MDTModule -Verbose -Force
    If($MDTShare -notmatch ($MDTShare.replace('\','\\')))
    {
        $Drive = New-PSDrive -Name DS001 -PSProvider MDTProvider -Root $MDTShare -ErrorAction SilentlyContinue
        If(-Not(Get-PSDrive DeploymentShare -ErrorAction SilentlyContinue))
        {
            $Drive = New-PSDrive -Name DeploymentShare -PSProvider MDTProvider -Root $MDTShare
        }
        Get-PSDrive -PSProvider MDTProvider
        
    }Else{

        Write-Host 'To Map deploymentshare: ' -ForegroundColor Cyan -NoNewline
        Write-Host "New-PSDrive -Name DeploymentShare -PSProvider mdtprovider -Root \\<Server>\<deploymentshare>" -ForegroundColor White
    }
}Else{
    Write-Host "MDT is not installed; may have limited functionality" -ForegroundColor Yellow
}

Import-Module "$MDTSimulatorPath\Modules\Microsoft.BDD.TaskSequenceModule" -Scope Global
Import-Module "$MDTSimulatorPath\Modules\PSDUtility"
Import-Module "$MDTSimulatorPath\Modules\PSDGather"

Push-Location $MDTShare
#Set-Location $MDTShare


If(Test-SMSTSENV)
{
    $tsVariables = $global:tsenv.GetVariables() | ForEach-Object {
        [PSCustomObject]@{
            Name = $_
            Value = $global:tsenv.Value($_)
        }
        #$_ + "=" + $tsenv.Value($_)
    }
    $tsVariables  | Format-Table -AutoSize

    '-----------------------------------------------------'
    write-host 'To retrieve all TS variables: ' -ForegroundColor Cyan -NoNewline
    write-host '$tsenv.GetVariables()'
    write-host 'As example, to specify a TS variable: ' -ForegroundColor Cyan -NoNewline
    write-host '$tsenv.Value("Make")'
    '-----------------------------------------------------'

}Else{

    Write-Host "Unable to get TS environment" -ForegroundColor red

    
    $OrginalMDTPath = "C:\Program Files\Microsoft Deployment Toolkit\"
    Get-ItemProperty $MDTRegPath -Name Install_Dir -ErrorAction SilentlyContinue
    If((Get-ItemProperty $MDTRegPath -Name Install_Dir -ErrorAction SilentlyContinue).Install_Dir -ne $OrginalMDTPath)
    {
        Set-ItemProperty $MDTRegPath -Name "Install_Dir" -Value $OrginalMDTPath -Force
    }
}


