#requires -version 5
<#
.SYNOPSIS
<Overview of script>
 
.DESCRIPTION
<Brief description of script>
 
.PARAMETER <Parameter_Name>
<Brief description of parameter input required. Repeat this attribute if required>

.PARAMETER NewCertThumbprint
The exact thumbprint of the cert to be imported. 
 
.INPUTS
<Inputs if any, otherwise state None>
 
.OUTPUTS
<Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
 
.NOTES
Author: Andrew Zbikowski <andrew@itouthouse.net>
Available script parameters from wacs.exe: https://github.com/PKISharp/win-acme/wiki/Install-script
* {0} or {CertCommonName}    - Common name (primary domain name)
* {1} or {CachePassword}     - The .pfx password (generated randomly for each renewal)
* {2} or {CacheFile}         - Full path of the cached.pfx file
* {4} or {CertFriendlyName}  - Friendly name of the generated certificate
* {5} or {CertThumbprint}    - Thumbprint of the generated certificate
* {7} or {RenewalId}         - Id of the renewal
* {3} or {6} or {StorePath}  - Path or store name used by the store plugin
* {StoreType}                - Name of the plugin (CentralSsl, CertificateStore or PemFiles)
 
.EXAMPLE
<Example goes here. Repeat this attribute for more than one example>
#>
 
#region Parameters
# Enable -Debug, -Verbose Parameters. Write-Debug and Write-Verbose!
[CmdletBinding()]
 
# Advanced Parameters: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-6
# Be sure to edit this to meet the validatations required as the allows and validate lines below may conflict with each other.  
Param (
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$false,
    Position=0,
    HelpMessage="Common name of the cert created by wacs.exe")]
    [ValidateNotNullOrEmpty()]
    [string]$CertCommonName,
    # Don't forget a comma between parameters. 
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$false,
    Position=1,
    HelpMessage="Path to the PEM files created by wacs.exe.")]
    [ValidateNotNullOrEmpty()] # Specifies that the parameter value cannot be $null and cannot be an empty string "". 
    [ValidateScript({Test-Path -Path $_ -PathType Container})] # Specifies a script that is used to validate a parameter or variable value.
    [string]$StorePath,
    # Don't forget a comma between parameters. 
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$false,
    Position=3,
    HelpMessage="StoreType from wacs.exe. There is only one correct answer.")]
    [ValidateNotNullOrEmpty()] # Specifies that the parameter value cannot be $null and cannot be an empty string "". 
    [ValidateSet("PemFiles")] # Specifies a set of valid values for a parameter or variable.
    [string]$StoreType,
    # Don't forget a comma between parameters. 
    [Parameter(Mandatory=$false,
    ValueFromPipeline=$false,
    Position=4,
    HelpMessage="Restart the PRTG Core service (required for PRTG to use the new cert).")]
    [switch]$RestartPRTGCoreService,
    # Don't forget a comma between parameters. 
    [Parameter(Mandatory=$false,
    ValueFromPipeline=$false,
    Position=5,
    HelpMessage="Restart the PRTG Probe service.")]
    [switch]$RestartPRTGProbeService,
    # Don't forget a comma between parameters. 
    [Parameter(Mandatory=$false,
    ValueFromPipeline=$false,
    Position=6,
    HelpMessage="Perform a test run that skips some checks and makes no changes.")]
    [switch]$TestRun # FIXME: This is so I can develop and test on a computer that doesn't have PRTG installed. Change to a WhatIf when things are working. :) 
)
#endregion Parameters
 
#region Declarations

# ISO 8601 Date Format. Accept no substitutes! 
$iso8601 = Get-Date -Format s
# Colon (:) isn't a valid character in file names.
$iso8601 = $iso8601.Replace(":","_")
# Just YYYY-MM-DD
#$datestamp = $iso8601.Substring(0,10)

if ($TestRun) {
  # For a TestRun, we don't need PRTG installed so just set the expected variable. 
  $PRTGServerEXE = @{
    ImagePath = 'C:\Program Files (x86)\PRTG Network Monitor\64 bit\PRTG Server.exe'
  }
} else {
  $PRTGServerEXE = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PRTGCoreService" -Name ImagePath
}

$PRTGInstallDir = $PRTGServerEXE.ImagePath | Split-Path | Split-Path
$PRTGCertDir = Join-Path -Path $PRTGInstallDir -ChildPath "cert"

if ( (Test-Path -Path $PRTGInstallDir -PathType Container) ) { 
  Write-Host "PRTG installation directory found at $PRTGInstallDir." -ForegroundColor Green
} else {
  # Behave deifferently on a test run. Might be testing on a PC without PRTG installed.   
  if (-Not $TestRun) {
    Throw "PRTG installation directory NOT FOUND at $PRTGInstallDir."
  } else {
    Write-Host "PRTG installation directory NOT FOUND at $PRTGInstallDir." -ForegroundColor Red
  }
}

if ( (Test-Path -Path $PRTGCertDir -PathType Container) ) {
  Write-Host "PRTG certificate directory found at $PRTGCertDir." -ForegroundColor Green
} else {
  # Behave deifferently on a test run. Might be testing on a PC without PRTG installed.   
  if (-Not $TestRun) {
    Throw "PRTG certificate directory NOT FOUND at $PRTGCertDir."
  } else {
    Write-Host "PRTG certificate directory NOT FOUND at $PRTGCertDir." -ForegroundColor Red
  }
}

#endregion Declarations

#region Verifications
# Test that cert dir is writable (create backup directory?)
#endregion Verifications

#regioin Functions

Function New-BackupDirectory {
  $Dir = New-Item -Path $PRTGCertDir -Name $iso8601 -Type Directory -ErrorAction Continue
  if ($null -eq $Dir) {
    # Failed to create backup directory. Not good. 
    Return $null
  } else {
    Return $Dir.FullName
  }
}
Function Backup-PRTGCert {
  Param (
    [Parameter(Mandatory=$true)]
    [string]$SourceDir,
    [Parameter(Mandatory=$true)]
    [string]$DestinationDir
  )

  $Files = @(
    # prtg.crt
    [pscustomobject]@{
      Source = Join-Path -Path $SourceDir -ChildPath 'prtg.crt'
      Destination = Join-Path -Path $DestinationDir -ChildPath 'prtg.crt'
    },
    # prtg.key
    [pscustomobject]@{
      Source = Join-Path -Path $SourceDir -ChildPath 'prtg.key'
      Destination = Join-Path -Path $DestinationDir -ChildPath 'prtg.key'
    },
    # root.pem
    [pscustomobject]@{
      Source = Join-Path -Path $SourceDir -ChildPath 'prtg.crt'
      Destination = Join-Path -Path $DestinationDir -ChildPath 'prtg.crt'
    }
  )

  foreach ($file in $Files) {
    Copy-Item -Path $file.Source -Destination $file.Destination
    if ( -Not (Test-Path -Path $file.Destination) ) {
      Write-Host "Unknown error when backing up $($file.Destination)." -ForegroundColor Red
      Write-Host "Unable to continue due to backup error. Exiting." -ForegroundColor Red
      Stop-Transcript
      Exit
    }
  }

  # If we've gotten this far, the backup didn't fail so move to the next step. 
  Return $true

}
#end Function Backup-PRTGCert
Function Remove-OldPRTGCert {
  Param (
    [Parameter(Mandatory=$true)]
    [string]$PRTGCertDir
  )
  $Files = @(
    $(Join-Path -Path $PRTGCertDir -ChildPath 'prtg.crt'),
    $(Join-Path -Path $PRTGCertDir -ChildPath 'prtg.key'),
    $(Join-Path -Path $PRTGCertDir -ChildPath 'prtg.crt')
  )
  foreach ($file in $Files) {
    Remove-Item -Path $file
    if (Test-Path -Path $file -PathType Leaf) {
      $result = $false
    } else {
      $result = $true
    }
  }
  Return $result # Result will be $true if files were successfuly deleted, false if delete failed. 
}
Function Install-NewPRTGCert {}
Function Restore-PRTGCert {}
Function Restart-PRTGServices {}

#>
 
#endregioin Functions
 

 
<# Pseudocode
 
  1. Create the backup directory, exit script on fail: New-BackupDirectory
  2. Start the transcript, writing to the backup directory. 
  3. Backup exiting cert files. 
  4. Delete existing cert files.
  5. Install new cert files. 
  6. Restart-PRTGServices. 

  If step 3, 4, or 5 fails back out cleanly. Restoring original files if required. 
 
End Pseudocode #>


# 1. Create the backup directory, exit script on fail: New-BackupDirectory
$BackupDir = New-BackupDirectory
if ($null -eq $BackupDir) {
  Write-Host "Unable to create backup directory for current PRTG certificate. Script cannot safely continue." -ForegroundColor Red
  Throw "Backup of current certificate failed. Exiting without making changes."
}

# 2. Start the transcript, writing to the backup directory. 
$TranscriptFile = Join-Path -Path $BackupDir -ChildPath 'PowershellTranscript.txt'
Start-Transcript -Path $TranscriptFile

# 3. Backup exiting cert files. 
Write-Host "Backing up current certificate files to $BackupDir." -ForegroundColor Cyan 
Backup-PRTGCert -SourceDir $PRTGCertDir -DestinationDir $BackupDir

# 4. Delete existing cert files.
$Deleted = Remove-OldPRTGCert -PRTGCertDir $PRTGCertDir

if ($Deleted -eq $false) {
  Restore-PRTGCert -Backup $iso8601
}

# 5. Install new cert files. 
# 6. Restart-PRTGServices. 


<#
CertCommonName = testprtg.cybertron.itouthouse.net
StorePath = C:\prtgdev 
StoreType = PemFiles

testprtg.cybertron.itouthouse.net-chain-only.pem
testprtg.cybertron.itouthouse.net-chain.pem
testprtg.cybertron.itouthouse.net-crt.pem
testprtg.cybertron.itouthouse.net-key.pem

PRTG needs prtg.crt, prtg.key, and root.pem



#> 

  # prtg.crt
#$sourcePRTGcrt = Join-Path -Path $StorePath -ChildPath "$($CertCommonName)-crt.pem"
#$destinPRTGcrt = Join-Path -Path $arrConf.PRTGCertPath -ChildPath 'prtg.crt'

#Write-Host "Source prtg.crt:      $sourcePRTGcrt"
#Write-Host "Destination prtg.crt: $destinPRTGcrt"
#Write-Host ""

# prtg.key
#$sourcePRTGkey = Join-Path -Path $StorePath -ChildPath "$($CertCommonName)-key.pem"
#$destinPRTGkey = Join-Path -Path $arrConf.PRTGCertPath -ChildPath 'prtg.key'

#Write-Host "Source prtg.key:      $sourcePRTGkey"
#Write-Host "Destination prtg.key: $destinPRTGkey"
#Write-Host ""

# root.pem
#$sourceROOTpem = Join-Path -Path $StorePath -ChildPath "$($CertCOmmonName)-chain-only.pem"
#$destinROOTpem = Join-Path -Path $arrConf.PRTGCertPath -ChildPath 'root.pem'

#Write-Host "Source root.pem:      $sourceROOTpem"
#Write-Host "Destination root.pem: $destinROOTpem"
#Write-Host ""

# Restart PRTG. 
<#
if ($RestartPRTGCoreService) {
  Restart-Service -Name PRTGCoreService -Force
}

if ($RestartPRTGProbeService) {
  Restart-Service -Name RestartPRTGProbeService -Force
}
#>


#Stop-Transcript