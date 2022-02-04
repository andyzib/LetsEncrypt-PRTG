#requires -version 5
<#
.SYNOPSIS
<Overview of script>
 
.DESCRIPTION
<Brief description of script>
 
.PARAMETER CertCommonName
Mandatory. {CertCommonName} from wacs.exe - Common name (primary domain name)

.PARAMETER StorePath
Mandatory. {StorePath} from wacs.exe - Path or store name used by the store plugin

.PARAMETER StoreType
Mandatory. {StoreType} from wacs.exe - Name of the plugin (CentralSsl, CertificateStore or PemFiles)

.PARAMETER RestartPRTGCoreService
Optional. Switch paramater to have this script restart PRTG Core Service after installing the certificate. Restarting this service is REQUIRED for PRTG to see the new certificate. 

.PARAMETER RestartPRTGProbeService
Optional. Switch parameter to have this script restart PRTG Probe Service after installing the certificate. Not required in the script author's experience, but other script users have reported otherwise. 

.PARAMETER TestRun
Optional. TestRun allows the author to run tests on a system that does not have PRTG installed. :)
 
.INPUTS
None
 
.OUTPUTS
A backup directory will be created in the PRTG cert folder. The backup directory will have a backup copy of the certificate that was replaced and a log file. 
 
.NOTES
Author: Andrew Zbikowski <andrew@itouthouse.net>
Latest version can be found at https://github.com/andyzib/LetsEncrypt-PRTG

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
WACSPost-PRTG.ps1 -CertCommonName {CertCommonName} -StorePath {StorePath} -StoreType {StoreType} -RestartPRTGCoreService
#>
 
#region Parameters
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
  $PRTGServerEXE = 'C:\Program Files (x86)\PRTG Network Monitor\64 bit\PRTG Server.exe'
} else {
  $PRTGServerEXE = $(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PRTGCoreService" -Name ImagePath).ImagePath
  $PRTGServerEXE = $PRTGServerEXE.Trim('"')
}

$PRTGInstallDir = $PRTGServerEXE | Split-Path | Split-Path
$PRTGCertDir = Join-Path -Path $PRTGInstallDir -ChildPath "cert"

# Verify PRTG directory. 
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

# Verify PRTG cert directory. 
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

#regioin Functions

Function New-BackupDirectory {
  <#
    Creates the backup directory and also verify that the script can write to the PRTG cert folder.
    If this function fails, the script will exit without making changes and no log file will be created. (wacs.exe will write to Windows Event Log)
  #>
  Param (
    [Parameter(Mandatory=$true)]
    [string]$PRTGCertDir,
    [Parameter(Mandatory=$true)]
    [string]$iso8601
  )
  $DirName = "Backup_$iso8601"
  $Dir = New-Item -Path $PRTGCertDir -Name $DirName -Type Directory -ErrorAction Continue
  if ($null -eq $Dir) {
    # Failed to create backup directory. Not good. 
    Return $null
  } else {
    Return $Dir.FullName
  }
}
#end Function New-BackupDirectory
Function Backup-PRTGCert {
  <#
    Creates a backup of the PRTG certificate currently in use. Only creats a copy, no changes to the existing cert. 
  #>
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
      Source = Join-Path -Path $SourceDir -ChildPath 'root.pem'
      Destination = Join-Path -Path $DestinationDir -ChildPath 'root.pem'
    }
  )

  foreach ($file in $Files) {
    Write-Host "Backing up $($file.Source) to $($file.Destination)..."
    Copy-Item -Path $file.Source -Destination $file.Destination
    if ( -Not (Test-Path -Path $file.Destination) ) {
      Write-Host "Unknown error when backing up $($file.Destination)." -ForegroundColor Red
      Write-Host "Unable to continue due to backup error. Exiting." -ForegroundColor Red
      Stop-Transcript
      Exit
    }
    Write-Host "Done!" -ForegroundColor Green
    Write-Host ""
  }

  # If we've gotten this far, the backup didn't fail so move to the next step. 
  Return $true

}
#end Function Backup-PRTGCert
Function Remove-OldPRTGCert {
  <#
    Removes the current PRTG cert from the cert directory. Returns $false if removal failed. 
  #>
  Param (
    [Parameter(Mandatory=$true)]
    [string]$PRTGCertDir
  )
  $Files = @(
    $(Join-Path -Path $PRTGCertDir -ChildPath 'prtg.crt'),
    $(Join-Path -Path $PRTGCertDir -ChildPath 'prtg.key'),
    $(Join-Path -Path $PRTGCertDir -ChildPath 'root.pem')
  )

  $result = $true # Only change to false if a file exists after removal attempt. 
  foreach ($file in $Files) {
    Write-Host "Deleting $file"
    Remove-Item -Path $file
    if (Test-Path -Path $file -PathType Leaf) {
      $result = $false
    } 
  }
  Return $result # Result will be $true if files were successfuly deleted, false if delete failed. 
}
#end Remove-OldPRTGCert
Function Install-NewPRTGCert {
  <#
    Copies the files from wacs.exe to the PRTG cert directory. Renames the wacs.exe files to what PRTG expects. 
  #>
  Param (
    [Parameter(Mandatory=$true)]
    [string]$CertCommonName,
    [Parameter(Mandatory=$true)]
    [string]$StorePath,
    [Parameter(Mandatory=$true)]
    [string]$PRTGCertDir
  )
  # Setup an array of custom objects to make this easier. 
  $Files = @(
    # prtg.crt
    [pscustomobject]@{
      Source = Join-Path -Path $StorePath -ChildPath "$($CertCommonName)-crt.pem"
      Destination = Join-Path -Path $PRTGCertDir -ChildPath 'prtg.crt'
    },
    # prtg.key
    [pscustomobject]@{
      Source = Join-Path -Path $StorePath -ChildPath "$($CertCommonName)-key.pem"
      Destination = Join-Path -Path $PRTGCertDir -ChildPath 'prtg.key'
    },
    # root.pem
    [pscustomobject]@{
      Source = Join-Path -Path $StorePath -ChildPath "$($CertCOmmonName)-chain-only.pem"
      Destination = Join-Path -Path $PRTGCertDir -ChildPath 'root.pem'
    }
  )
  # Copy from $StorePath to $PRTGCertDir. 
  $return = $true
  foreach ($file in $Files) {
    Write-Host "Copying $($file.Source) to $($file.Destination )... " 
    Copy-Item -Path $file.Source -Destination $file.Destination 
    if ( -Not (Test-Path -Path $file.Destination -PathType Leaf ) ) { 
      $return = $false # File failed to copy, restore backup and fail. 
      Write-Host "Failed." -ForegroundColor Red
    } else {
      Write-Host "Done." -ForegroundColor Green
    }
    Write-Host ""
  }
  Return $return
}
#end Install-NewPRTGCert
Function Restore-PRTGCert {
  <#
    If something failed, this function is called to restore the certificate from the backup. 
  #>
  Param (
    [Parameter(Mandatory=$true)]
    [string]$Backup,
    [Parameter(Mandatory=$true)]
    [string]$PRTGCertDir
  )
  $BackupDir = Join-Path -Path $PRTGCertDir -ChildPath $PRTGCertDir
  if ( -Not (Test-Path -Path $BackupDir -PathType Container) ) {
    $Message = "Backup directory $BackupDir was not found. Manual intervention to restore a valid certificate is required."
    Write-Host $Message -ForegroundColor Red
    Stop-Transcript
    Throw $Message
  }

  # Setup Files Array to make this easier. 
  $Files = @(
    # prtg.crt
    [pscustomobject]@{
      Source = Join-Path -Path $BackupDir -ChildPath 'prtg.crt'
      Destination = Join-Path -Path $PRTGCertDir -ChildPath 'prtg.crt'
    },
    # prtg.key
    [pscustomobject]@{
      Source = Join-Path -Path $BackupDir -ChildPath 'prtg.key'
      Destination = Join-Path -Path $PRTGCertDir -ChildPath 'prtg.key'
    },
    # root.pem
    [pscustomobject]@{
      Source = Join-Path -Path $BackupDir -ChildPath 'root.pem'
      Destination = Join-Path -Path $PRTGCertDir -ChildPath 'root.pem'
    }
  )

  # Copy from BackupDir to CertDir
  $return = $true # Change to false if a copy fails. 
  foreach ($file in $Files) {    
    Copy-Item -Path $file.Source -Destination $file.Destination 
    if ( -Not (Test-Path -Path $file.Destination -PathType Leaf) ) {
      $return = $false
    }    
  }
  Return $return
}
#end Restore-PRTGCert
 
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
$BackupDir = New-BackupDirectory -PRTGCertDir $PRTGCertDir -iso8601 $iso8601
if ($null -eq $BackupDir) {
  Write-Host "Unable to create backup directory for current PRTG certificate. Script cannot safely continue." -ForegroundColor Red
  Throw "Creating backup directory failed. Exiting without making changes."
}

# 2. Start the transcript, writing to the backup directory. 
$TranscriptFile = Join-Path -Path $BackupDir -ChildPath "$($MyInvocation.MyCommand.Name)_LOG.txt"
Start-Transcript -Path $TranscriptFile
Write-Host ""

# 3. Backup exiting cert files. 
Write-Host "Backing up current certificate files to $BackupDir." -ForegroundColor Cyan 
Write-Host ""
$BackupResult = Backup-PRTGCert -SourceDir $PRTGCertDir -DestinationDir $BackupDir
if ($BackupResult -eq $false) {
  Write-Host "Backup of the current PRTG certificate failed. Script cannot safely continue." -ForegroundColor Red
  Write-Host "No changes were made to curent PRTG certificate." -ForegroundColor Yellow
  Throw "Backup of current certificate failed. Exiting without making changes."
}
Write-Host "Backup of current certificate files complete." -ForegroundColor Green
Write-Host ""

# 4. Delete existing cert files.
Write-Host "Deleting the old certificate files." -ForegroundColor Cyan
Write-Host ""
$Deleted = Remove-OldPRTGCert -PRTGCertDir $PRTGCertDir

if ($Deleted -eq $false) {
  $Restored = Restore-PRTGCert -Backup $iso8601 -PRTGCertDir $PRTGCertDir
  if ($Restored) {
    Write-Host "Removing old certificate failed, but changes were successfully reverted." -ForegroundColor Yellow    
  } else {
    Write-Host "Removing old certificate failed, and changes could not be reverted. Manual intervention is required!" -ForegroundColor Red
  }
  Write-Host ""
  Stop-Transcript
  Exit
} else {
  Write-Host ""
  Write-Host "Old certificate files were successfully removed." -ForegroundColor Green
  Write-Host ""
}

# 5. Install new cert files. 
Write-Host "Installing new certificate." -ForegroundColor Cyan
Write-Host ""
$Installed = Install-NewPRTGCert -CertCommonName $CertCommonName -StorePath $StorePath -PRTGCertDir $PRTGCertDir
if ($Installed -eq $false) {
  $Restored = Restore-PRTGCert -Backup $iso8601 -PRTGCertDir $PRTGCertDir
  if ($Restored) {
    Write-Host "New certificate installation failed, but changes were successfully reverted." -ForegroundColor Yellow    
  } else {
    Write-Host "New certificate installation failed, and changes could not be reverted. Manual intervention is required!" -ForegroundColor Red
  }
  Stop-Transcript
  Exit
} else {
  Write-Host "New certificate installation was successful!" -ForegroundColor Green
  Write-Host ""
}

# 6. Restart-PRTGServices. 

if ($RestartPRTGCoreService) {
  Write-Host "Restarting PRTGCoreService." 
  Restart-Service -Name PRTGCoreService -Force
  Write-Host "Done!" -ForegroundColor Green
  Write-Host ""
}

if ($RestartPRTGProbeService) {
  Write-Host "Restarting RestartPRTGProbeService." 
  Restart-Service -Name RestartPRTGProbeService -Force
  Write-Host "Done!" -ForegroundColor Green
  Write-Host ""
}

Write-Host "Certificate post-install script completed. Review logs for errors, happy monitoring!" -ForegroundColor Cyan
Write-Host ""
Stop-Transcript