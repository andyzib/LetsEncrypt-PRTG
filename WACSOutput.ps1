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
    Position=0)]
    [string]$StorePath,

    [Parameter(Mandatory=$true,
    Position=1)]
    [string]$StoreType
)

$Outfile = Join-Path -Path $PSScriptRoot -ChildPath "WACSOutput.txt"
$Output = "`n
CertCommonName = $CertCommonName `n
CachePassword = $CachePassword `n
CacheFile = $CacheFile `n
CertFriendlyName = $CertFriendlyName `n
CertThumbprint = $CertThumbprint `n
RenewalId = $RenewalId `n
StorePath = $StorePath `n
StoreType = $StoreType `n
`n"
$Output | Set-Content -Path $Outfile