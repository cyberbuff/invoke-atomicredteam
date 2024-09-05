BeforeAll {
    Remove-Module -Name "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
    $invokeAtomicPath = (get-item $PSScriptRoot).parent.parent
    Import-Module (Join-Path $invokeAtomicPath "Invoke-AtomicRedTeam.psd1") -Force
}

Describe "Invoke-SetupAtomicRunner" {
        BeforeAll {
            Mock -ModuleName Invoke-AtomicRedTeam -CommandName Write-Host {}
        }

        Context "Should run as Root User" -Tag "Root" {
            BeforeAll {
                if($isWindows){
                    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                    $isAdmin | Should -BeTrue
                }else{
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

        Context "Should run as non-root" -Tag "Non-Root" {
            It "should run with elevated privileges" -Skip:$isWindows {
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
