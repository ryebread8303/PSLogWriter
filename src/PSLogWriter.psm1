using module ".\loglevel-enum.psm1"
using module ".\PSLogger.class.psm1"
<#
.SYNOPSIS
Helper function handles needed logging capability in scripts.
.DESCRIPTION
This function relies on an enum to be added to your script. Paste the following block 
into your script to add the needed enum:

enum LogLevel {
    Verbose
    Info
    Warning
    Error
    Critical
}

If you want to log INFO or VERBOSE entries, you'll need to set a $LogLevel variable 
to the appropriate level.
.NOTES
AUTHOR: O'Ryan R Hedrick
COMPANY: Ft Leonard Wood Network Enterprise Center
LAST UPDATE: 20 APR 2022
INTENDED AUDIENCE: Script writers
TODO:
* Log to event viewer
#>


function Start-Log {
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [string]
        $Path
    )
    [PSLogger]::new($path)
}
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [string]
        $Message,
        [Parameter(mandatory=$true)]
        [string]
        $Severity,
        [Parameter(mandatory=$true,ParameterSetName="File")]
        [switch]
        $File,
        [Parameter(ParameterSetName="File")]
        [ValidateSet("Simple","CMTrace")]
        [string]
        $Format = "Simple",
        [Parameter(ParameterSetName="File",mandatory=$false)]
        [string]
        $component = '',
        [switch]
        $Console,
        [Parameter(mandatory=$true,ParameterSetName="File")]
        [PSLogger]
        $AsyncLogger,
        [Parameter()]
        [LogLevel]
        $LogLevel
    )
    $DateTimeStamp = get-date -format yyyyMMdd:HHmmZz
    #If the calling script has not set a $LogLevel variable, assume it should be set to Warning
    if ($null -eq $LogLevel){$LogLevel = [LogLevel]"Warning"}
    if ([LogLevel]$Severity -lt [LogLevel]$LogLevel) {
        return
        }
    $ErrorColors = @{
        BackgroundColor = "Black"
        ForeGroundColor = "Red"
    }
    $WarningColors = @{
        BackgroundColor = "Black"
        ForeGroundColor = "Yellow"
    }
    If($File){
        switch ($format) {
            'Simple' {$AsyncLogger.QueueLog($Message,$Severity)}
            'CMTrace' {$AsyncLogger.QueueLog($Message,$Severity,$Component)}
        }
        
    }
    If($Console){
        $string = "$Severity : $DateTimeStamp : $Message"
        switch ($Severity) {
            'Critical' {Write-Host $string @ErrorColors}
            'Error' {Write-Host $string @ErrorColors}
            'Warning' {Write-Host $string @WarningColors}
            'Info' {Write-Host $string}
            'Verbose' {Write-Host $string}
        }
    }
}