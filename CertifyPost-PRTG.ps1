#requires -version 5
<#
.SYNOPSIS
A Post-Request Script Hook for Certify The Web to install a cert for PRTG. 
 
.DESCRIPTION
<Brief description of script>
 
.PARAMETER <Parameter_Name>
A Post-Request Script Hook for Certify The Web to install a cert for PRTG. 
 
.INPUTS
None.
 
.OUTPUTS
* PowerShell Transcript written to the directory the script is saved in. 
* Current PRTG certificate files will be backed up to $PRTGCertRoot\Backup_$iso8601
* PEM file with private key and certificate will be written to $env:ProgramData\Certify\certes\assets\pfx
* Public Certificate File, PEM Format: $PRTGCertRoot\prtg.crt
* Private Key File, PEM Format: $PRTGCertRoot\prtg.key
* Let's Encrypt Intermediate Root CA: $PRTGCertRoot\root.pem

 
.NOTES
Author: Andrew Zbikowski <andrew@itouthouse.net>

Requires PSPKI module for PFX to PEM conversion. from.
Install-Module PSPKI should to the trick, see https://www.pkisolutions.com/tools/pspki for more on PSPKI. 
 
.EXAMPLE
DO NOT RUN MANUALLY! Configure as a Post-request PS Script in the Certify The Web GUI. 
#>

# Certify the Web Scipting Hooks documentation: https://docs.certifytheweb.com/docs/script-hooks.html
param($result)   # required to access the $result parameter

########## Configuration Section
# Where the PRTG certificates live. 
$PRTGCertRoot = 'C:\Program Files (x86)\PRTG Network Monitor\cert'
# Let's Encrypt Intermediate CA
$LEIntermediateCA = 'https://letsencrypt.org/certs/lets-encrypt-r3.pem'
# Restart PRTGCoreService (Required to update certificate)
$RestartPRTGCoreService = $true
# Restart PRTGProbeService (https://github.com/andyzib/LetsEncrypt-PRTG/issues/2)
$RestartPRTGProbeService = $false
# Restart PRTG
########## End of Configuration, no more changes! 

# PowerShell PKI module needed for certificate conversion. 
# https://www.pkisolutions.com/tools/pspki/
Import-Module -Name PSPKI -ErrorAction Stop

# ISO 8601 Date Format. Accept no substitutes! 
$iso8601 = Get-Date -Format s
# Colon (:) isn't a valid character in file names.
$iso8601 = $iso8601.Replace(":","_")

Start-Transcript -Path "$PSScriptRoot\$($iso8601)_CertifyPost-PRTG_Transcript.txt"

# Verify Certify successfully renewed the cert. 
if ($result.IsSuccess) {
    # Verify the path to PRTG's Certificate Directory is configured correctly.
    if (Test-Path -Path $PRTGCertRoot -PathType Container) {
        # Verify the backup path for the current certificate exists or create it. 
        $BackupPath = $PRTGCertRoot + "\Backup_" + $iso8601
        if (-Not (Test-Path -Path $BackupPath -PathType Container)) {
            Try { New-Item -Path $PRTGCertRoot -Name "\Backup_$iso8601" -ItemType "Directory" }
            Catch { Throw "Failed to create backup directory for current certificate. Aborting without making changes." }
        }
        # Backup the current certificate files. 
        # prtg.crt
        Try { Copy-Item -Path "$PRTGCertRoot\prtg.crt" -Destination "$BackupPath\prtg.crt" }
        Catch { Throw "Failed to backup prtg.crt to $BackupPath. Aborting without making changes." }
        # prtg.key
        Try { Copy-Item -Path "$PRTGCertRoot\prtg.key" -Destination "$BackupPath\prtg.key" }
        Catch { Throw "Failed to backup prtg.key to $BackupPath. Aborting without making changes." }
        # root.pem
        Try { Copy-Item -Path "$PRTGCertRoot\root.pem" -Destination "$BackupPath\root.pem" }
        Catch { Throw "Failed to backup root.pem to $BackupPath. Aborting without making changes." }

        # Remove existing certificate files. 
        # prtg.crt
        Try { Remove-Item -Path "$PRTGCertRoot\prtg.crt" }
        Catch { Throw "Failed to delete $PRTGCertRoot\prtg.crt. Aborting without making further changes." }
        # prtg.key
        Try { Remove-Item -Path "$PRTGCertRoot\prtg.key" }
        Catch { Throw "Failed to delete $PRTGCertRoot\prtg.key. Aborting without making further changes." }
        # root.pem
        Try { Remove-Item -Path "$PRTGCertRoot\root.pem" }
        Catch { Throw "Failed to delete $PRTGCertRoot\root.pem. Aborting without making further changes." }

        # Write the new Let's Encrypt certificate obtained by Certify. 
        
        # Get the cert from the store. 
        $CertPFX = Get-ChildItem -Path "cert:\LocalMachine\my\$($result.ManagedItem.CertificateThumbprintHash)"
        # Convert PFX to PEM
        # This Split-Path should return something like C:\ProgramData\Certify\certes\assets\pfx
        $CertifyAssetDir = Split-Path -Path $result.ManagedItem.CertificatePath -Parent
        $TempPEM = "$CertifyAssetDir\$($result.ManagedItem.CertificateThumbprintHash).pem"
        # Convert-PfxToPem will only save a file. 
        $resultTEMP = Convert-PfxToPem -Certificate $CertPFX -OutputFile $TempPEM
        # Read in the PEM cert file in -Raw format so RegEx works. 
        $CertPEM = Get-Content $TempPEM -Raw 
        # Split Private Key and Certificate using RegEx. 
        $pattern = "(?sm).*-----BEGIN PRIVATE KEY-----(.*)-----END PRIVATE KEY-----.*-----BEGIN CERTIFICATE-----(.*)-----END CERTIFICATE-----"
        if ($CertPEM -match $pattern) {
            $OutPrivateKeyPEM = "-----BEGIN PRIVATE KEY-----$($Matches[1])-----END PRIVATE KEY-----"

            $OutCertificatePEM = "-----BEGIN CERTIFICATE-----$($Matches[2])-----END CERTIFICATE-----"
        } else {
            Throw "Unable to match Private Key and Certificate"
        }
        # Write the prtg.cer and prtg.key files. 
        $OutCER = "$PRTGCertRoot\prtg.crt"
        $resultTEMP = Set-Content -Path $OutCER -Value $OutCertificatePEM
        $OutKey = "$PRTGCertRoot\prtg.key"
        $resultTEMP = Set-Content -Path $OutKey -Value $OutPrivateKeyPEM       
        # Write Public Cert to root.pem (https://github.com/andyzib/LetsEncrypt-PRTG/issues/3)
        $OutRootPem = "$PRTGCertRoot\root.pem"
        $resultTEMP = Set-Content -Path $OutRootPem -Value $OutCertificatePEM
        # Download LE Intermediate and Append to root.pem.
        $OutFile = Join-Path -Path $env:TEMP -ChildPath "LEIntermediate.txt"
        $resultTEMP = Invoke-WebRequest -Uri $LEIntermediateCA -OutFile $OutFile
        # Append $OutFile to root.pem
        Get-Content -Path $OutFile | Add-Content -Path $OutRootPem         
        
        # Cleanup
        Remove-Item -Path $OutFile

        # Restart PRTG. 
        if ($RestartPRTGCoreService) {
            Restart-Service -Name PRTGCoreService -Force
        }

        if ($RestartPRTGProbeService) {
            Restart-Service -Name RestartPRTGProbeService -Force
        }

    }
} else {
    Throw "Certify did not renew certificate. Aboring without making changes."
}
Stop-Transcript