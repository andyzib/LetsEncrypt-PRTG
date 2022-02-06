# Win-ACME & PRTG

This is a post request script to install a certificate acquired using Certify the Web into [PRTG](https://www.paessler.com/prtg).

## Requirements

* [PowerShell 5.1](https://docs.microsoft.com/en-us/skypeforbusiness/set-up-your-computer-for-windows-powershell/download-and-install-windows-powershell-5-1)
* You should already have Windows PowerShell 5.1 if you're running Windows 10 Anniversary Update or Windows Server 2016.
* [Win-ACME](https://www.win-acme.com/) and associated plugins for your environment.

## Using Win-ACME

This documentation doesn't cover how to use Win-ACME to acquire a certificate. Consult the [Win-ACME Manual](https://www.win-acme.com/manual/getting-started) and [Win-ACME Command Line Reference](https://www.win-acme.com/reference/cli).

## Prepare your system

1. Download Win-ACME and any plugins you need for your environment.
2. Create a directory where Win-ACME can store the PEM files for your ACME certificate. This directory should have limited permissions as the Private Key for your certificate will be stored unencrypted.
3. Create a directory where the post install script will be saved.
4. When running wacs.exe, select only the PEM files option as storage. Select the menu item or CLI parameter for no password for the private key.
5. Select run an external script or program for your install option.
6. Give the full path to the WACSPost-PRTG.ps1 script.
7. Use the following parameters: -CertCommonName {CertCommonName} -StorePath {StorePath} -StoreType {StoreType} -RestartPRTGCoreService

## About RestartPRTGCoreService

This is an optional parameter that will restart PRTG Core Service after the script installs the new certificate acquired by wacs.exe. While restarting the PRTG Core Service is required for PRTG to use the new certificate, not every environment will want PRTG automatically restarted. I **strongly recommend** including -REstartPRTGCoreService. Adjust the timing of the win-acme task in Windows Task Scheduler to reflect your organization's maintenance windows to ensure your certificate doesn't expire. By default, win-acme creates a task that runs daily at 9 AM. You can run the task weekly or even once a month without concern as long as you are monitoring the certificate. You have PRTG, you should add a sensor that is monitoring PRTG's certificate expiration!

## About and RestartPRTGProbeService

Restarting the PRTG Probe Service is not required in my experience, however [grumpymojo](https://github.com/grumpymojo) reported [having to do so](https://github.com/andyzib/LetsEncrypt-PRTG/issues/2) for their PRTG install. I've included the option to restart the PRTG Probe Service for anyone who finds they need it.

## Configuring the Install Script in wacs.exe interactive mode

Coming Soon.

## Configuring the Install Script in wacs.exe non-interactive mode

Coming Soon.
