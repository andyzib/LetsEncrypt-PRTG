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
 
#-------------[Parameters]-----------------------------------------------------
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
    HelpMessage="Full path to JSON configuration file for this script.")]
    [string]$Conf=$(Join-Path -Path $PSScriptRoot -ChildPath WACSPost.json)
)

 
#-------------[Parameter Validation]-------------------------------------------

# Configuration File
if (-Not (Test-Path -PathType Leaf -Path $Conf)) {
  Throw "Configuration file not found: $Conf."
} else {
  $arrConf = Get-Content -Path $Conf | ConvertFrom-Json
}
#>
 
<#
# Strip trailing \ from $outdir
$outdir = $outdir.Trim()
$outdir = $outdir.TrimEnd("\")
# Check that outdir exists.
if (-Not (Test-Path -PathType Container -Path $outdir)) {
    Throw "Output directory note found: $outdir"
}
#>
 
<#
# Strip illegal file name characters with a RegEx.
# https://gallery.technet.microsoft.com/scriptcenter/Remove-Invalid-Characters-39fa17b1
$outstring = [RegEx]::Replace($outstring, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')
#>
 
#-------------[Initializations]------------------------------------------------
 
#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"
 
#Import-Module activedirectory -ErrorAction Stop
 
#-------------[Declarations]---------------------------------------------------

# ISO 8601 Date Format. Accept no substitutes! 
$iso8601 = Get-Date -Format s
# Colon (:) isn't a valid character in file names.
$iso8601 = $iso8601.Replace(":","_")
# Just YYYY-MM-DD
#$datestamp = $iso8601.Substring(0,10)
 
#-------------[Functions]------------------------------------------------------
 
<#
 
Function <FunctionName>{
  Param()
 
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
 
  Process{
    Try{
      <code goes here>
    }
   
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
 
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}
 
#>
 
#-------------[Execution]------------------------------------------------------
 
#Start-Transcript -Path "$($env:USERPROFILE) + \$($iso8601)_PowershellTranscript.txt"
 
<# Pseudocode
 
Logic, flow, etc.
 
End Pseudocode #>

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
$sourcePRTGcrt = Join-Path -Path $StorePath -ChildPath "$($CertCommonName)-crt.pem"
$destinPRTGcrt = Join-Path -Path $arrConf.PRTGCertPath -ChildPath 'prtg.crt'

Write-Host "Source prtg.crt:      $sourcePRTGcrt"
Write-Host "Destination prtg.crt: $destinPRTGcrt"
Write-Host ""

# prtg.key
$sourcePRTGkey = Join-Path -Path $StorePath -ChildPath "$($CertCommonName)-key.pem"
$destinPRTGkey = Join-Path -Path $arrConf.PRTGCertPath -ChildPath 'prtg.key'

Write-Host "Source prtg.key:      $sourcePRTGkey"
Write-Host "Destination prtg.key: $destinPRTGkey"
Write-Host ""

# root.pem
$sourceROOTpem = Join-Path -Path $StorePath -ChildPath "$($CertCOmmonName)-chain-only.pem"
$destinROOTpem = Join-Path -Path $arrConf.PRTGCertPath -ChildPath 'root.pem'

Write-Host "Source root.pem:      $sourceROOTpem"
Write-Host "Destination root.pem: $destinROOTpem"
Write-Host ""

# Find PRTG
## HKLM:\SYSTEM\CurrentControlSet\Services\PRTGCoreService
### ImagePath
## HKLM:\SYSTEM\CurrentControlSet\Services\PRTGProveService
### ImagePath

# Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion -Name "ProgramFilesDir"
#$PRTGServerEXE = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PRTGCoreService" -Name ImagePath
# For testing when PRTG isn't installed. 
# This eliminates an item in the configuration file. 
$PRTGServerEXE = @{
  ImagePath = 'C:\Program Files (x86)\PRTG Network Monitor\64 bit\PRTG Server.exe'
}
$PRTGInstallDir = $PRTGServerEXE.ImagePath | Split-Path | Split-Path
$PRTGCertDir = Join-Path -Path $PRTGInstallDir -ChildPath "certs"

Write-Host $PRTGCertDir

# Restart PRTG. 
<#
if ($arrConf.RestartPRTGCoreService) {
  Restart-Service -Name PRTGCoreService -Force
}

if ($arrConf.RestartPRTGProbeService) {
  Restart-Service -Name RestartPRTGProbeService -Force
}
#>


#Stop-Transcript