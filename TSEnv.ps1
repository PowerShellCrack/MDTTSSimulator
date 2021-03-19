$MDTShare = "\\Server\deploymentshare"

$host.UI.RawUI.WindowTitle = "MDT Simulator Terminal"
cls
Write-host "Loading TS environment and Progress UI COM objects" -ForegroundColor Cyan
#region FUNCTION: Attempt to connect to Task Sequence environment
Function Test-SMSTSENV{
    try{
        # Create an object to access the task sequence environment
        $global:tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
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

If(Test-SMSTSENV){

    $MDTModule = "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

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

    If(Test-path $MDTModule)
    {
        Import-Module $MDTModule;
        If($MDTShare -notmatch ($MDTShare.replace('\','\\')))
        {
            $Drive = New-PSDrive -Name DS001 -PSProvider MDTProvider -Root $MDTShare -ErrorAction SilentlyContinue
            If(-Not(Get-PSDrive DeploymentShare -ErrorAction SilentlyContinue))
            {
                $Drive = New-PSDrive -Name DeploymentShare -PSProvider MDTProvider -Root $MDTShare
                Get-PSDrive -PSProvider MDTProvider
            }
        }
        Else{
            Write-Host 'To Map deploymentshare: ' -ForegroundColor Cyan -NoNewline
            Write-Host "New-PSDrive -Name DeploymentShare -PSProvider mdtprovider -Root \\<Server>\<deploymentshare>" -ForegroundColor White
        }
    }
    Else{
        Write-Host "MDT is not installed; may have limited functionality" -ForegroundColor Yellow
    }

    write-host "Use these commands:" -ForegroundColor Cyan
    Get-Command -Module MicrosoftDeploymentToolkit,PSDUtility,PSDDeploymentShare,PSDGather,ZTIUtility,PSDWizard | Sort Source | Select Name,Source | Format-Table

    Set-Location $MDTShare
}
Else{
    Write-Host "Unable to start MDT Simulator" -ForegroundColor red
}

