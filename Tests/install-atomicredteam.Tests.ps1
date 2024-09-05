BeforeAll {
    function Get-AtomicsDir() {
        if ($isWindows) {
            return "$Env:HOMEDRIVE/AtomicRedTeam/invoke-atomicredteam"
        }
        else {
            return "$Env:HOME/AtomicRedTeam/invoke-atomicredteam"
        }
    }

    . $PSCommandPath.Replace('.Tests.ps1', '.ps1').Replace('/Tests/', '/').Replace('\Tests\', '\')
}

Describe "install-atomicsfolder" {

    BeforeEach {
        $InstallPath = Join-Path "$([IO.Path]::GetTempPath())" "$([Guid]::NewGuid())"
    }

    It "Installs successfully with default parameters" {
        $Path = Get-AtomicsDir
        Install-AtomicRedTeam -Force
        Test-Path $Path | Should -BeTrue
        Import-Module "$Path\Invoke-AtomicRedTeam.psd1" -Force
        $LASTEXITCODE | Should -Be 0
    }

    It "Installs successfully with custom install path" {
        Install-AtomicRedTeam -InstallPath $InstallPath
        Test-Path "$InstallPath\invoke-atomicredteam" | Should -BeTrue
        Import-Module "$InstallPath\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
        $LASTEXITCODE | Should -Be 0
    }

    It "Installs successfully with a different repo owner" {
        Install-AtomicRedTeam -InstallPath $InstallPath -RepoOwner "cyberbuff"
        Test-Path "$InstallPath\invoke-atomicredteam" | Should -BeTrue
        Import-Module "$InstallPath\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
        $LASTEXITCODE | Should -Be 0
    }

    It "Installs successfully with atomics" {
        Install-AtomicRedTeam -InstallPath $InstallPath -getAtomics
        Test-Path "$InstallPath\invoke-atomicredteam" | Should -BeTrue
        Import-Module "$InstallPath\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
        $LASTEXITCODE | Should -Be 0
        (Get-ChildItem "$InstallPath/atomics" -File -Recurse).Count |  Should -BeGreaterThan 0
    }

    It "Installs successfully with atomics and no payloads" {
        Install-AtomicRedTeam -InstallPath $InstallPath -getAtomics -NoPayloads
        Test-Path "$InstallPath\invoke-atomicredteam" | Should -BeTrue
        Import-Module "$InstallPath\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
        $LASTEXITCODE | Should -Be 0
        # When the payloads are not downloaded, the folder count will be equal to the YAML files.
        $folderCount = (Get-ChildItem "$InstallPath/atomics" -Directory -Recurse).Count
        $fileCount = (Get-ChildItem "$InstallPath/atomics" -File -Recurse).Count
        $fileCount | Should -be $folderCount
    }

    It "Error if the folder already exists" {
        Install-AtomicRedTeam -InstallPath $InstallPath
        $output = Install-AtomicRedTeam  -InstallPath $InstallPath 6>&1 | Out-String
        $output | Should -Match "Atomic Redteam already exists"
    }

    AfterEach {
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Module "Invoke-AtomicRedTeam" -ErrorAction SilentlyContinue
    }
}