BeforeAll {
    Remove-Module -Name "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
    $invokeAtomicPath = (Get-Item $PSScriptRoot).parent.parent.FullName
    Import-Module (Join-Path $invokeAtomicPath "Invoke-AtomicRedTeam.psd1") -Force
    $Global:artConfig = [PSCustomObject]@{

        # [optional] These two configs are calculated programatically, you probably don't need to change them
        basehostname               = $((hostname | Select-String -Pattern "(.*?)(-[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})?$").Matches.Groups[1].value)
        OS                         = $( if ($IsLinux) { "linux" } elseif ($IsMacOS) { "macos" } else { "windows" })

        # [optional(if using default install paths)] Paths to your Atomic Red Team "atomics" folder and your "invoke-atomicredteam" folder
        PathToInvokeFolder         = Join-Path $( if ($IsLinux -or $IsMacOS) { "~" } else { "C:" })  "/AtomicRedTeam/invoke-atomicredteam" # this is the default install path so you probably don't need to change this
        PathToPublicAtomicsFolder  = Join-Path $( if ($IsLinux -or $IsMacOS) { "~" } else { "C:" })  "AtomicRedTeam/atomics" # this is the default install path so you probably don't need to change this
        PathToPrivateAtomicsFolder = Join-Path $( if ($IsLinux -or $IsMacOS) { "~" } else { "C:" })   "PrivateAtomics/atomics" # if you aren't providing your own private atomics that are custom written by you, just leave this as is

        # [ Optional ] The user that will be running each atomic test
        user                       = $( if ($IsLinux -or $IsMacOS) { $env:USER } else { "$env:USERDOMAIN\foo" }) # example "corp\atomicrunner"

        # [optional] the path where you want the folder created that houses the logs and the runner schedule. Defaults to users home directory
        basePath                   = $( if (!$IsLinux -and !$IsMacOS) { $env:USERPROFILE } else { $env:HOME }) # example "C:\Users\atomicrunner"

        # [optional]
        scheduleTimeSpan           = New-TimeSpan -Days 7 # the time in which all tests on the schedule should complete
        kickOffDelay               = New-TimeSpan -Minutes 0 # an additional delay before Invoke-KickoffAtomicRunner calls Invoke-AtomicRunner
        scheduleFileName           = "AtomicRunnerSchedule.csv"

        # [optional] Logging Module, uses Syslog-ExecutionLogger if left blank and the syslogServer and syslogPort are set, otherwise it uses the Default-ExecutionLogger
        LoggingModule              = ''

        # [optional] Syslog configuration, default execution logs will be sent to this server:port
        syslogServer               = '' # set to empty string '' if you don't want to log atomic execution details to a syslog server (don't includle http(s):\\)
        syslogPort                 = 514
        syslogProtocol             = 'UDP' # options are UDP, TCP, TCPwithTLS

        verbose                    = $true; # set to true for more log output

        # [optional] logfile filename configs
        logFolder                  = "AtomicRunner-Logs"
        timeLocal                  = (Get-Date(get-date) -uformat "%Y-%m-%d").ToString()
        logFileName                = "$($artConfig.timeLocal)`_$($artConfig.basehostname)-ExecLog.csv"

        # amsi bypass script block (applies to Windows only)
        absb                       = $null

        # AtomicRunnerService install directory
        ServiceInstallDir          = "${ENV:windir}\System32"

    }

    $password = (New-Guid).Guid
    net user foo $password  /add /Y
    $securePassword =  $password | ConvertTo-SecureString -AsPlainText -Force
    $secureStringText = $securePassword | ConvertFrom-SecureString
    Set-Content $artConfig.credFile $secureStringText

    $atomicRunnerServiceFile = "$invokeAtomicPath/Public/Invoke-SetupAtomicRunner.ps1"
}

AfterAll {
    net user foo /delete
}

Describe "Invoke-SetupAtomicRunner" {
    BeforeAll {
        Mock -ModuleName Invoke-AtomicRedTeam -CommandName Write-Host {}
    }

    Context "Run Windows setup" -Skip:($IsLinux -or $IsMacOS) -Tag "Windows" {
        It "Should run without errors" {
            $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\AtomicRunnerService"
            Remove-Item $registryPath -Force -ErrorAction SilentlyContinue
            # run the setup
            Invoke-SetupAtomicRunner

            # check the results
            $artConfig.atomicLogsPath | Should -Exist
            $artConfig.runnerFolder | Should -Exist
            $artConfig.scheduleFile | Should -Exist
            "$PROFILE" | Should -FileContentMatch ".*import-module.*invoke-atomicredTeam.psd1"
            Get-Schedule | Should -BeNullOrEmpty
            Test-Path $registryPath | Should -BeTrue
            Get-ScheduledTask | Where-Object { $_.TaskName -like "KickOff-AtomicRunner" } | Should -BeFalse
           (Get-ItemProperty -Path $registryPath).Start | Should -BeExactly 2
           (Get-ItemProperty -Path $registryPath).DelayedAutostart | Should -BeExactly 1
        }

        It "Configure as Scheduled Task" {
            

            # run the setup
            Invoke-SetupAtomicRunner -asScheduledtask

            # check the results
            $artConfig.atomicLogsPath | Should -Exist
            $artConfig.runnerFolder | Should -Exist
            $artConfig.scheduleFile | Should -Exist
            "$PROFILE" | Should -FileContentMatch ".*import-module.*invoke-atomicredTeam.psd1"
            Get-Schedule | Should -BeNullOrEmpty
            Get-ScheduledTask | Where-Object { $_.TaskName -like "KickOff-AtomicRunner" } | Should -BeTrue
        }

        AfterEach {
            . "$invokeAtomicPath\Public\AtomicRunnerService.ps1" -Remove -ErrorAction Ignore
            Unregister-ScheduledTask "KickOff-AtomicRunner" -confirm:$false -ErrorAction Ignore
        }
    }

    Context "Should run as Root User" -Tag "Root" {
        BeforeAll {
            Write-Host $(sudo whoami)
            if ($isWindows) {
                $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                $isAdmin | Should -BeTrue
            }
            else {
                id -u | Should -Be 0
            }
        }

        It "Should run without errors Linux & MacOS" -Skip:$isWindows {
            # clean up any previous runs
            truncate -s 0 /etc/crontab

            # run the setup
            Invoke-SetupAtomicRunner

            # check the results
            $artConfig.atomicLogsPath | Should -Exist
            $artConfig.runnerFolder | Should -Exist
            $artConfig.scheduleFile | Should -Exist
            "/etc/crontab" | Should -FileContentMatch "Invoke-KickoffAtomicRunner"
            "$PROFILE" | Should -FileContentMatch ".*import-module.*invoke-atomicredTeam.psd1"
            Get-Schedule | Should -BeNullOrEmpty
        }
    }

    Context "Should run as non-root" -Tag "Non-Root" -Skip:$isWindows {
        It "should run with elevated privileges" {
            $isAdmin = $(id -u) -eq 0
            $isAdmin | Should -Be $false
        }

        It "Should throw errors" {
            {
                Invoke-SetupAtomicRunner
            } | Should -Throw -ErrorId "You must run the Invoke-SetupAtomicRunner script as root"
        }
    }

}
