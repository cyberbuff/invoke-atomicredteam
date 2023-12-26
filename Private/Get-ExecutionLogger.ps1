function Test-LoggerExists($LoggingModule, $LoggerFunction) {
    if (Get-Command "$LoggingModule\$LoggerFunction" -erroraction silentlycontinue) {
        Write-Verbose "All logging commands found"
    }
    else {
        Write-Host "$LoggerFunction not found or loaded from the wrong module"
        return
    }
}

function Get-ExecutionLogger($invocatedCommand, $LoggingModule, $artConfig) {
    if (-not $LoggingModule) {
        # no logging module explicitly set
        # syslog logger
        $syslogOptionsSet = [bool]$artConfig.syslogServer -and [bool]$artConfig.syslogPort
        if ( $artConfig.LoggingModule -eq "Syslog-ExecutionLogger" -or (($artConfig.LoggingModule -eq '') -and $syslogOptionsSet) ) {
            if ($syslogOptionsSet) {
                $LoggingModule = "Syslog-ExecutionLogger"
            }
            else {
                Write-Host -Fore Yellow "Config.ps1 specified: Syslog-ExecutionLogger, but the syslogServer and syslogPort must be specified. Using the default logger instead"
                $LoggingModule = "Default-ExecutionLogger"
            }
        }
        elseif (-not [bool]$artConfig.LoggingModule) {
            # loggingModule is blank (not set), so use the default logger
            $LoggingModule = "Default-ExecutionLogger"
        }
        else {
            $LoggingModule = $artConfig.LoggingModule
        }
    }

    if (Get-Module -name $LoggingModule) {
        Write-Verbose "Using Logger: $LoggingModule"
    }
    else {
        Write-Host -Fore Yellow "Logger not found: ", $LoggingModule
    }

    # Change the defult logFile extension from csv to json and add a timestamp if using the Attire-ExecutionLogger
    if ($LoggingModule -eq "Attire-ExecutionLogger") { $ExecutionLogPath = $ExecutionLogPath.Replace("Invoke-AtomicTest-ExecutionLog.csv", "Invoke-AtomicTest-ExecutionLog-timestamp.json") }
    $ExecutionLogPath = $ExecutionLogPath.Replace("timestamp", $(Get-Date -UFormat %s))

    if (Test-LoggerExists $LoggingModule "Start-ExecutionLog" && Test-LoggerExists $LoggingModule "Write-ExecutionLog" && Test-LoggerExists $LoggingModule "Stop-ExecutionLog" ) {
        Write-Verbose "All logging commands found"
    }

    # Since there might a comma(T1559-1,2,3) Powershell takes it as array.
    # So converting it back to string.
    if ($AtomicTechnique -is [array]) {
        $AtomicTechnique = $AtomicTechnique -join ","
    }

    # Splitting Atomic Technique short form into technique and test numbers.
    $AtomicTechniqueParams = ($AtomicTechnique -split '-')
    $AtomicTechnique = $AtomicTechniqueParams[0]

    if ($AtomicTechniqueParams.Length -gt 1) {
        $ShortTestNumbers = $AtomicTechniqueParams[-1]
    }

    if ($null -eq $TestNumbers -and $null -ne $ShortTestNumbers) {
        $TestNumbers = $ShortTestNumbers -split ','
    }

}