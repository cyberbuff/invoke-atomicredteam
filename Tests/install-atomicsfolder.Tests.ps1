BeforeAll {
    function Get-AtomicsDir() {
        if ($isWindows) {
            return "$Env:HOMEDRIVE/AtomicRedTeam/atomics"
        }
        else {
            return "$Env:HOME/AtomicRedTeam/atomics"
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
        Install-AtomicsFolder
        Test-Path $Path | Should -be $true
        (Get-ChildItem $Path -File -Recurse).Count | Should -BeGreaterThan 0
    }

    It "Installs successfully with custom install path" {
        Install-AtomicsFolder -InstallPath $InstallPath
        Test-Path $InstallPath | Should -be $true
        (Get-ChildItem $InstallPath -File -Recurse).Count | Should -BeGreaterThan 0
    }

    It "Installs successfully with a different repo owner" {
        Install-AtomicsFolder -InstallPath $InstallPath -RepoOwner "cyberbuff"
        Test-Path $InstallPath | Should -be $true
        (Get-ChildItem $InstallPath -File -Recurse).Count | Should -BeGreaterThan 0
    }

    It "Installs successfully with no payloads" {
        Install-AtomicsFolder -NoPayloads -InstallPath $InstallPath
        Test-Path $InstallPath | Should -be $true
        # When the payloads are not downloaded, the folder count will be equal to the YAML files.
        $folderCount = (Get-ChildItem "$InstallPath/atomics" -Directory -Recurse).Count
        $fileCount = (Get-ChildItem "$InstallPath/atomics" -File -Recurse).Count
        $fileCount | Should -be $folderCount
    }

    It "Error if the folder already exists" {
        Install-AtomicsFolder -InstallPath $InstallPath
        $output = Install-AtomicsFolder  -InstallPath $InstallPath 6>&1 | Out-String
        $output | Should -Match "An atomics folder already exists"
    }

    AfterEach {
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}