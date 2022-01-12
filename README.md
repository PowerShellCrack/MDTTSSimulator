# MDTTSSimulator
Test PowerShell scripts with a task sequence environment

## How to use it
1. Install [ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
2. Install [MDT](https://www.microsoft.com/en-us/download/details.aspx?id=54259)
3. Run SetupMDTSimulator.cmd
    - Answer a few questions
1. Run MDT Simulator desktop shortcut

## Customizations

Y- ou can add rules to the [customsettings.ini](CustomSettings.ini). 

## What it does

The _SetupMDTSimulator.cmd_ script automated the MDT setup by:
 - copying required files from MDT distribution folder into a c:\MDTSimulator
 - copying customsettings.ini
 - generating the appropriate TS.xml file base don input
 - generating a run command calling a powershell script to start TS engine
 - and creating a shortcut