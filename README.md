# Let's Encrypt PRTG
This is a collection of scripts to automatically install a Let's Encrypt certificate for [PRTG](https://www.paessler.com/prtg).

# Certify the Web: Certify-PRTG.ps1
Post request script to install a Let's Encrypt certificate obtained with Certify the Web in PRTG. 

## Requirments
* [PowerShell 5.0](https://docs.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1)
* You should already have Windows PowerShell 5.1 if you're running Windows 10 Anniversary Update or Windows Server 2016.
* [PSPKI](https://www.pkisolutions.com/tools/pspki) module that is availabe in the [PowerShell Gallery](https://www.powershellgallery.com/packages/PSPKI/3.4.2.0). 

## Installation
1. Open PowerShell as an administrator and run Install-Module PSPKI
2. Save the script to a directory (Example: E:\Scripts\Certify-PRTG\Certify-PRTG.ps1)

## Running
In the Certify the Web GUI:
1. Check Show Advanced Options.
2. Click Scripting. 
3. Click "..." and browse to the script or enter the full path to the script. 

# Windows ACME Simple (WACS)
A script for WACS is on my todo list. 
https://github.com/PKISharp/win-acme
