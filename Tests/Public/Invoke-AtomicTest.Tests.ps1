BeforeAll {
    Remove-Module -Name "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
    $invokeAtomicPath = Join-Path (get-item $PSScriptRoot).parent.parent "Invoke-AtomicRedTeam.psd1"
    Import-Module $invokeAtomicPath -Force
    Install-Module -Name Posh-SYSLOG -Force
}

Describe "Show Details for <id>" -ForEach @(
    @{ Id = "T1497.001-1" }
    @{ Id = "T1497.001" }
    @{ Id = "All" }
) {
    It "Show details" {
        Invoke-AtomicTest $Id -ShowDetails 6>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It "Show brief details" {
        Invoke-AtomicTest $Id -ShowDetailsBrief 6>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It "Show brief details for any OS" {
        Invoke-AtomicTest $Id -ShowDetailsBrief -anyOS 6>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
    }
}

Describe "Check Prereqs for <name>" -ForEach @(
    @{ Name = "Linux & MacOS"; Tests = @("T1070.006-1"); ShouldSkip = $IsWindows }
    @{ Name = "Windows"; Tests = @("T1070.006-5"); ShouldSkip = !$IsWindows }
) {
    $PSDefaultParameterValues = @{ 'It:Skip' = $ShouldSkip }

    BeforeEach {
        Invoke-AtomicTest $_ -Cleanup
    }

    It "Check Prereqs for <_>" -ForEach $Tests {
        $output = Invoke-AtomicTest $_ -CheckPrereqs 6>&1 | Out-String
        $output | Should -Match "Prerequisites not met"
        Invoke-AtomicTest $_ -GetPrereqs
        $output = Invoke-AtomicTest $_ -CheckPrereqs 6>&1 | Out-String
        $output | Should -Match "Prerequisites met"
    }

    AfterEach {
        Invoke-AtomicTest $_ -Cleanup
    }
}

Describe "Run Atomics for <name>" -ForEach @(
    @{ Name = "Linux"; Tests = @("T1070.006-1"); ShouldSkip = !$IsLinux }
    @{ Name = "MacOS"; Tests = @("T1497.001-4"); ShouldSkip = !$IsMacOS }
    @{ Name = "Windows"; Tests = @("T1057-2", "T1497.001-3", "T1497.001-5"); ShouldSkip = !$IsWindows }
) {
    $PSDefaultParameterValues = @{ 'It:Skip' = $ShouldSkip }

    BeforeEach {
        Invoke-AtomicTest $_ -GetPrereqs
    }

    It "Run test <_>" -ForEach $Tests {
        $output = Invoke-AtomicTest $_ 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
    }

    It "Run test <_> with Timeout" -ForEach $Tests {
        $output = Invoke-AtomicTest $_ -TimeoutSeconds 0 6>&1 | Out-String
        $output | Should -Match "Process Timed out after 0 seconds"
    }

    AfterEach {
        Invoke-AtomicTest $_ -Cleanup
    }
}

Describe "Run Atomics with Input Args for <name>" -ForEach @(
    @{ Name = "Linux"; ShouldSkip = !$IsLinux; Tests = @(
            @{ Id = "T1070.006-1"; InputArgs = @{"target_filename" = "/tmp/atomic.txt" } }
        );
    }
    @{ Name = "MacOS"; ShouldSkip = !$IsMacOS; Tests = @(
            @{ Id = "T1070.006-1"; InputArgs = @{"target_filename" = "/tmp/atomic.txt" } }
        );
    }
    @{ Name = "Windows"; ShouldSkip = !$IsWindows; Tests = @(
            @{ Id = "T1070.006-10"; InputArgs = @{"days_to_modify" = "1" } }
        );
    }
) {
    $PSDefaultParameterValues = @{ 'It:Skip' = $ShouldSkip; 'It:ForEach' = $Tests }
    BeforeEach {
        Invoke-AtomicTest $Id -InputArgs $InputArgs -GetPrereqs
    }

    It "Run <id> with InputArgs" {
        $output = Invoke-AtomicTest $Id -InputArgs $InputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -InputArgs $InputArgs -Cleanup
    }

    AfterEach {
        Invoke-AtomicTest $Id -InputArgs $InputArgs -GetPrereqs
    }

}


Describe "Check LoggingFramework for <name>" -ForEach @(
    @{ Name = "Linux"; Tests = @("T1070.006-1"); ShouldSkip = !$IsLinux }
    @{ Name = "MacOS"; Tests = @("T1497.001-4"); ShouldSkip = !$IsMacOS }
    @{ Name = "Windows"; Tests = @("T1057-2", "T1497.001-3", "T1497.001-5"); ShouldSkip = !$IsWindows }
) {
    $PSDefaultParameterValues = @{ 'It:Skip' = $ShouldSkip; 'It:ForEach' = $Tests }

    BeforeEach {
        Invoke-AtomicTest $_ -GetPrereqs
    }

    It "Run with AttireLogger" {
        Invoke-AtomicTest $_ -LoggingModule "Attire-ExecutionLogger" -ExecutionLogPath "timestamp.json"
        Test-Path *.json | Should -BeTrue
        Remove-Item *.json -ErrorAction SilentlyContinue
    }

    It "Run with Default-ExecutionLogger" {
        Invoke-AtomicTest $_ -LoggingModule "Default-ExecutionLogger" -ExecutionLogPath  "$PSScriptRoot/temp.csv"
        Test-Path "$PSScriptRoot/temp.csv" | Should -BeTrue
        Remove-Item "$PSScriptRoot/temp.csv" -ErrorAction SilentlyContinue
    }

    It "Run with Syslog-ExecutionLogger" {
        $Global:artConfig = [pscustomobject]@{
            syslogServer   = '127.0.0.1'
            syslogPort     = 514
            syslogProtocol = 'UDP'
        }
        Mock -CommandName Send-SyslogMessage -ModuleName Syslog-ExecutionLogger -MockWith { return $true }
        Invoke-AtomicTest $_ -LoggingModule "Syslog-ExecutionLogger"
        Assert-MockCalled -CommandName Send-SyslogMessage -ModuleName Syslog-ExecutionLogger -Exactly -Times 1
    }

    It "Run with Default-ExecutionLogger,Syslog-ExecutionLogger" {
        $Global:artConfig = [pscustomobject]@{
            syslogServer   = '127.0.0.1'
            syslogPort     = 514
            syslogProtocol = 'UDP'
        }
        Mock -CommandName Send-SyslogMessage -ModuleName Syslog-ExecutionLogger -MockWith { return $true }
        Invoke-AtomicTest $_ -LoggingModule "Syslog-ExecutionLogger,Default-ExecutionLogger" -ExecutionLogPath  "$PSScriptRoot/temp.csv"
        Test-Path "$PSScriptRoot/temp.csv" | Should -BeTrue
        Remove-Item "$PSScriptRoot/temp.csv" -ErrorAction SilentlyContinue
        Assert-MockCalled -CommandName Send-SyslogMessage -ModuleName Syslog-ExecutionLogger -Exactly -Times 1
    }

    AfterEach {
        Invoke-AtomicTest $_ -Cleanup
    }
}


Describe "Run Windows Specific tests" {
    $PSDefaultParameterValues = @{ 'It:Skip' = $IsMacOS -or $IsLinux }

    It "Run PSSession tests" {
        Write-Output "y" | cmd /c WinRM quickconfig
        $s = New-PSSession -ComputerName localhost
        Invoke-AtomicTest "T1070.006-5" -Session $s -GetPrereqs
        Invoke-AtomicTest "T1070.006-5" -Session $s
        Invoke-AtomicTest "T1070.006-5" -Session $s -Cleanup
    }

    It "Run with WinEventLogger" {
        Remove-EventLog -LogName "Atomic Red Team" -ErrorAction SilentlyContinue
        Invoke-AtomicTest "T1070.006-5" -GetPrereqs
        Invoke-AtomicTest "T1070.006-5" -LoggingModule "WinEvent-ExecutionLogger"
        (Get-EventLog -LogName "Atomic Red Team"  -EntryType Information).Count | Should -BeExactly 1
        Invoke-AtomicTest "T1070.006-5" -Cleanup
        Remove-EventLog -LogName "Atomic Red Team" -ErrorAction SilentlyContinue
    }

}

AfterAll {
    Remove-Module -Name "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
}
