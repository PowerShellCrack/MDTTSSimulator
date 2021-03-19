# MDTTSSimulator
Test PowerShell scripts with a task sequence environment

## How to use it
1. Install [ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
2. Install [MDT](https://www.microsoft.com/en-us/download/details.aspx?id=54259)
3. Run SetupMDTSimulator.cmd
4. Run RunMDTSimulator.cmd

## Customizations

You can add rules to the [customsettings.ini](CustomSettings.ini). 
Currently the TS.XML calls the [NewPSConsole.ps1](NewPSConsole.ps1) file...which calls PowerShell. However if your interested in running VSE or ISE, change the command to call NewVSEConsole.ps1 or NewISEConsole.ps1

THe TSEnv.ps1 allows you to run your code against a real deployment share. You may need to modify the pathe to the deploymentshare. 
