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
#[CmdletBinding()]
 
# Advanced Parameters: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-6
# Be sure to edit this to meet the validatations required as the allows and validate lines below may conflict with each other.  
<#
Param (
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true,
    Position=0,
    HelpMessage="Enter a help message for this parameter.")]
    [alias("Para0","Parameter0")]
    [AllowNull()] # Allows value of a mandatory parameter to be $null
    [AllowEmptyString()] # Allows value of a mandatory parameter to be an empty string ("")
    [AllowEmptyCollection()] # Allows value of a mandatory paramenter to be an empty collection @()
    [ValidateNotNull()] # Specifies that the parameter value cannot be $null
    [ValidateNotNullOrEmpty()] # Specifies that the parameter value cannot be $null and cannot be an empty string "". 
    [ValidateCount(1,5)] # Specifices the minimum and maximum number of parameter values a parameter accepts. Example: Computer1,Computer2,Computer3,Computer4,Computer5
    [ValidateLength(1,10)] # Specifies the minimum and maximum number of characters in a parameter or variable value. 
    [ValidatePattern("[0-9][0-9][0-9][0-9]")] # Specifies a regular expression that is compared to the parameter or variable value. 
    [ValidateRange(0,10)] # Specifies a numeric range for each parameter or variable value. 
    [ValidateScript({$_ -ge (Get-Date)})] # Specifies a script that is used to validate a parameter or variable value.
    [ValidateSet("Chocolate", "Strawberry", "Vanilla")] # Specifies a set of valid values for a parameter or variable.
    [string]$Param0,
    # Don't forget a comma between parameters. 
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$true,
    Position=1,
    HelpMessage="Enter a help message for this parameter.")]
    [alias("Para1","Parameter1")]
    [AllowNull()]
    [AllowEmptyString()]
    [AllowEmptyCollection()]
    [ValidateCount(1,5)]
    [ValidateLength(1,10)]
    [ValidatePattern("[0-9][0-9][0-9][0-9]")]
    [ValidateRange(0,10)]
    [ValidateScript({$_ -ge (Get-Date)})]
    [ValidateSet("Chocolate", "Strawberry", "Vanilla")]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [string]$Param1
)
#>

 
#-------------[Parameter Validation]-------------------------------------------
# Sanitize User Input
 
<#
# Check that the CSV file exists.
$csv = $csv.Trim()
if (-Not (Test-Path -PathType Leaf -Path $csv)) {
    Throw "CSV not found: $csv"
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
 
Start-Transcript -Path "$($env:USERPROFILE) + \$($iso8601)_PowershellTranscript.txt"
 
<# Pseudocode
 
Logic, flow, etc.
 
End Pseudocode #>

Stop-Transcript