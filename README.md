# MDTTSSimulator

Test MDT task sequence environment items from desktop without launching a deployment

## Install it

1. Install [ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
2. Install [MDT](https://www.microsoft.com/en-us/download/details.aspx?id=54259)
3. Run SetupMDTSimulator.cmd
    - Answer a few questions
4. Run MDT Simulator from desktop shortcut
5. Once session window is open (Powershell/ISE/Code). You need to run the `C:\MDTSimluator\TSEnv.ps1` script.

> TIP: Best if ran as elevated Administrator.

## Tested Deployment Shares

- MDT (this is by default)
- PSD (You must add PSD modules to C:\MDTSimulator\Modules folder)

## Simulated Testing

**For MDT:** Add rules to the [customsettings.ini](CustomSettings.mdtsample.ini), then relaunch the simulator

**For PSD:** Within the session window running the simulator, additional rules can be loaded:

```powershell
#Enable Debugging 
$PSDDebug = $true

#EXAMPLE: Additional rules can be loaded
Invoke-PSDRules -FilePath '\\<SERVER>\<MDTSHARE>\Control\CustomSettings.ini' -MappingFile 'C:\MDTSimulator\Modules\PSDGather\ZTIGather.xml'

#EXAMPLE: Launch the new PSDWizard
Show-PSDWizard -ResourcePath '\\<SERVER>\<MDTSHARE>\Scripts\PSDWizardNew' -Language en-US -Theme Dark -ScriptPath '\\<SERVER>\<MDTSHARE>\Scripts' -Verbose
```

## What does it do?

The _SetupMDTSimulator.cmd_ script:

- Copies required files from MDT distribution folder into a C:\MDTSimulator
- Copies CustomSettings.ini from deploymentshare to C:\MDTSimulator
- Generates the TS.xml file based on input
- Generates a batch script that will call a powershell script to start TS engine
- Creates a desktop shortcut

## Known Issues

- Simulator must run in elevated mode; Desktop shortcut is configured to run as Administrator already
- Running this within Powershell 7 does not work. It won't load the tasksequence bootstrap modules properly.
- Simulator may fail if set to VSCode (Visual Studio Code) and Powershell 7 is the extension; it must launch with Powershell 5 to work
- If your deploymentshare CustomSettings.ini is not valid, it may not launch correctly. Overwrite using the sample provided then relaunch
- Only the session windows that is open will have the TS environment loaded; if closed, it will kill the simulation
