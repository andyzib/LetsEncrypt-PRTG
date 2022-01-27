#region Function Invoke-ISO8601Cleanup
Function Invoke-ISO8601Cleanup {
    <#
    .SYNOPSIS
    Cleans up files/directories that use YYYY-MM-DD naming. 

    .DESCRIPTION
    Cleans up files/directories that use YYYY-MM-DD naming. 

    .PARAMETER KeepNum
    The number of matching files/directories to keep on disk.  

    .PARAMETER BaseDir
    Directory containing files/directories. 

    .EXAMPLE
    Keep only the last 7 matching directoreis: Invoke-ISO8601Cleanup KeepNum 7 -BaseDir servershareLogs
    #>
    Param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false,
        HelpMessage="Keep this number of backups on disk.")]
        [ValidateNotNullOrEmpty()] # Specifies that the parameter value cannot be $null and cannot be an empty string . 
        [ValidateScript({$_ -gt 0})] # Specifies a script that is used to validate a parameter or variable value.
        [int]$KeepNum,
        # Don't forget a comma between parameters. 
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false,
        HelpMessage="Directory containing backups.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })] # Specifies a script that is used to validate a parameter or variable value.
        [string]$BaseDir,
        # Don't forget a comma between parameters. 
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="Filter for Get-ChildItem to use for selecting files/directories to consider for delete.")]
        [string]$Filter="Backup_20*",
        # Don't forget a comma between parameters. 
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="Enable WhatIf Mode.")]
        [switch]$WhatIf
    )

    # Only keep the number of backups specified by $MaxDays.  
    if ( $(Get-ChildItem -Path $BaseDir).Count -gt $MaxDays ) {
		Write-Host Performing log directory cleanup.
        $DeleteFolders = Get-ChildItem -Path $BaseDir -Filter $Filter | Sort-Object -Descending | Select-Object -Skip $MaxDays
        Foreach ($DelFolder in $DeleteFolders) {
            if ($WhatIf) {
                Remove-Item -LiteralPath $DelFolder.FullName -Recurse -Force -WhatIf
            } else {
                Remove-Item -LiteralPath $DelFolder.FullName -Recurse -Force
            }
        }
    } else {
        Write-Host "MaxDays or fewer backups stored on disk. Nothing to delete."
    }
}
#endregion Function Invoke-ISO8601Cleanup