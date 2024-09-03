BeforeAll {
    Remove-Module -Name "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
    $invokeAtomicPath = Join-Path (get-item $PSScriptRoot).parent.parent "Invoke-AtomicRedTeam.psd1"
    Import-Module $invokeAtomicPath -Force
}

Describe "Show Details" {

    It "Show brief details for <id>" -ForEach @(
        @{ Id = "T1497.001" }
        @{ Id = "All" }
    ) {
        Invoke-AtomicTest $Id -ShowDetails 6>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It "Show brief details for <id>" -ForEach @(
        @{ Id = "T1497.001" }
        @{ Id = "All" }
    ) {
        Invoke-AtomicTest $Id -ShowDetailsBrief 6>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It "Show brief details for <id> anyOS" -ForEach @(
        @{ Id = "T1497.001" }
        @{ Id = "All" }
    ) {
        Invoke-AtomicTest $Id -ShowDetailsBrief -anyOS 6>&1 | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

}


Describe "Check Prereqs for *nix" {
    $PSDefaultParameterValues = @{ 'It:Skip' = $IsWindows }
    It "Check Prereqs for <id>" -ForEach @(
        @{ Id = "T1070.006-1" }
    ) {
        Invoke-AtomicTest $Id -Cleanup
        $output = Invoke-AtomicTest $Id -CheckPrereqs 6>&1 | Out-String
        $output | Should -Match "Prerequisites not met"
        Invoke-AtomicTest $Id -GetPrereqs
        $output = Invoke-AtomicTest $Id -CheckPrereqs 6>&1 | Out-String
        $output | Should -Match "Prerequisites met"
        Invoke-AtomicTest $Id -Cleanup
    }
}

Describe "Check Prereqs for Windows" {
    BeforeAll {
        Import-Module PowerShellGet -Force
    }
    $PSDefaultParameterValues = @{ 'It:Skip' = $IsLinux -or $IsMacOS }

    It "Check Prereqs for <id>" -ForEach @(
        @{ Id = "T1070.006-5" }
    ) {
        $output = Invoke-AtomicTest $Id -CheckPrereqs 6>&1 | Out-String
        $output | Should -Match "Prerequisites not met"
        Invoke-AtomicTest $Id -GetPrereqs
        $output = Invoke-AtomicTest $Id -CheckPrereqs 6>&1 | Out-String
        $output | Should -Match "Prerequisites met"
    }

}

Describe "Run macOS tests" {
    BeforeEach {
        Mock -ModuleName  "Invoke-AtomicRedTeam" -CommandName "Read-Host" -MockWith { return "/tmp/atomic.txt" }
    }
    $PSDefaultParameterValues = @{ 'It:Skip' = $IsLinux -or $IsWindows }

    It "Run <id>" -ForEach @(
        @{ Id = "T1497.001"; TestNumbers = 4 }
    ) {
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -GetPrereqs
        $output = Invoke-AtomicTest $Id 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -Cleanup
    }

    It "Run <id> with InputArgs" -ForEach @(
        @{ Id = "T1070.006"; TestNumbers = 1 }
    ) {
        $InputArgs = @{"target_filename" = "/tmp/atomic.txt" }
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -InputArgs $InputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -InputArgs $InputArgs -Cleanup
    }

    It "Run <id> with InputArgs Prompt" -ForEach @(
        @{ Id = "T1070.006"; TestNumbers = 1 }
    ) {
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -PromptForInputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -PromptForInputArgs -Cleanup
    }


    It "Run <id> with timeout" -ForEach @(
        @{ Id = "T1018"; TestNumbers = 6 }
    ) {
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -TimeoutSeconds 0 6>&1 | Out-String
        $output | Should -Match "Process Timed out after 0 seconds"
    }

    It "Run with AttireLogger" {
        Invoke-AtomicTest "T1070.006-1" -GetPrereqs
        Invoke-AtomicTest "T1070.006-1" -LoggingModule "Attire-ExecutionLogger" -ExecutionLogPath timestamp.json
        Test-Path *.json | Should -Be $true
        Invoke-AtomicTest "T1070.006-1" -Cleanup
        Remove-Item *.json -ErrorAction SilentlyContinue
    }

    It "Run with SysLogEventLogger" {
        #TODO: Mock send-syslog function here.
        Invoke-AtomicTest "T1070.006-1" -GetPrereqs
        Invoke-AtomicTest "T1070.006-1" -LoggingModule "Syslog-ExecutionLogger"
        Invoke-AtomicTest "T1070.006-1" -Cleanup
    }
}

Describe "Run Ubuntu tests" {
    BeforeEach {
        Mock -ModuleName  "Invoke-AtomicRedTeam" -CommandName "Read-Host" -MockWith { return "/tmp/atomic.txt" }
    }

    $PSDefaultParameterValues = @{ 'It:Skip' = $IsMacOS -or $IsWindows }

    It "Run <id>" -ForEach @(
        @{ Id = "T1497.001"; TestNumbers = 1 }
    ) {
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -GetPrereqs
        $output = Invoke-AtomicTest $Id 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -Cleanup
    }

    It "Run <id> with InputArgs" -ForEach @(
        @{ Id = "T1070.006"; TestNumbers = 1 }
    ) {
        $InputArgs = @{"target_filename" = "/tmp/atomic.txt" }
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -InputArgs $InputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -InputArgs $InputArgs -Cleanup
    }


    It "Run <id> with InputArgs Prompt" -ForEach @(
        @{ Id = "T1070.006"; TestNumbers = 1 }
    ) {
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -PromptForInputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -PromptForInputArgs -Cleanup
    }


    It "Run <id> with timeout" -ForEach @(
        @{ Id = "T1018"; TestNumbers = 6 }
    ) {
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -TimeoutSeconds 0 6>&1 | Out-String
        $output | Should -Match "Process Timed out after 0 seconds"
    }

    It "Run with AttireLogger" {
        Invoke-AtomicTest "T1070.006-1" -GetPrereqs
        Invoke-AtomicTest "T1070.006-1" -LoggingModule "Attire-ExecutionLogger" -ExecutionLogPath timestamp.json
        Test-Path *.json | Should -Be $true
        Invoke-AtomicTest "T1070.006-1" -Cleanup
        Remove-Item *.json -ErrorAction SilentlyContinue
    }

    It "Run with SysLogEventLogger" {
        #TODO: Mock send-syslog function here.
        Invoke-AtomicTest "T1070.006-1" -GetPrereqs
        Invoke-AtomicTest "T1070.006-1" -LoggingModule "Syslog-ExecutionLogger"
        Invoke-AtomicTest "T1070.006-1" -Cleanup
    }
}

Describe "Run Windows tests" {
    BeforeEach {
        Mock -ModuleName  "Invoke-AtomicRedTeam" -CommandName "Read-Host" -MockWith { return "3" }
    }

    $PSDefaultParameterValues = @{ 'It:Skip' = $IsMacOS -or $IsLinux }

    It "Run <id>" -ForEach @(
        @{ Id = "T1057"; TestNumbers = 2 }
        @{ Id = "T1497.001"; TestNumbers = 3 }
        @{ Id = "T1497.001"; TestNumbers = 5 }
    ) {
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -GetPrereqs
        $output = Invoke-AtomicTest $Id 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -Cleanup
    }

    It "Run <id> with InputArgs" -ForEach @(
        @{ Id = "T1070.006"; TestNumbers = 10 }
    ) {
        $InputArgs = @{"days_to_modify" = "1" }
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -InputArgs $InputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -InputArgs $InputArgs -Cleanup
    }

    It "Run <id> with InputArgs Prompt" -ForEach @(
        @{ Id = "T1070.006"; TestNumbers = 10 }
    ) {
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -PromptForInputArgs 6>&1 | Out-String
        $output | Should -Match "Exit code: 0"
        Invoke-AtomicTest $Id -TestNumbers $TestNumbers -PromptForInputArgs -Cleanup
    }

    It "Run <id> with timeout" -ForEach @(
        @{ Id = "T1018"; TestNumbers = 5 }
    ) {
        $output = Invoke-AtomicTest $Id -TestNumbers $TestNumbers -TimeoutSeconds 0 6>&1 | Out-String
        $output | Should -Match "Process Timed out after 0 seconds"
    }

    It "Run PSSession tests" {
        Write-Output "y" | cmd /c WinRM quickconfig
        $s = New-PSSession -ComputerName localhost
        Invoke-AtomicTest "T1070.006-5" -Session $s -GetPrereqs
        Invoke-AtomicTest "T1070.006-5" -Session $s
        Invoke-AtomicTest "T1070.006-5" -Session $s -Cleanup
    }

    It "Run with WinEventLogger" {
        Invoke-AtomicTest "T1070.006-5" -GetPrereqs
        Invoke-AtomicTest "T1070.006-5" -LoggingModule "WinEvent-ExecutionLogger"
        # TODO: Add test to check if event is logged
        Invoke-AtomicTest "T1070.006-5" -Cleanup
    }

    It "Run with AttireLogger" {
        Invoke-AtomicTest "T1070.006-5" -GetPrereqs
        Invoke-AtomicTest "T1070.006-5" -LoggingModule "Attire-ExecutionLogger" -ExecutionLogPath timestamp.json
        Test-Path *.json | Should -Be $true
        Invoke-AtomicTest "T1070.006-5" -Cleanup
    }

    It "Run with SysLogEventLogger" {
        #TODO: Mock send-syslog function here.
        Invoke-AtomicTest "T1070.006-5" -GetPrereqs
        Invoke-AtomicTest "T1070.006-5" -LoggingModule "Syslog-ExecutionLogger"
        Invoke-AtomicTest "T1070.006-5" -Cleanup
    }

}

AfterAll {
    Remove-Module -Name "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
}