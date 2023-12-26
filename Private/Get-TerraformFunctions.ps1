function Test-IncludesCloud ($test) {
    $cloud = ('office-365', 'azure-ad', 'google-workspace', 'saas', 'iaas', 'containers', 'iaas:aws', 'iaas:azure', 'iaas:gcp')
    foreach ($platform in $test.supported_platforms) {
        if ($cloud -contains $platform) {
            return $true
        }
    }
    return $false
}

function Test-IncludesTerraform($test, $AT, $testCount) {
    $AT = $AT.ToUpper()
    $pathToTerraform = Join-Path $PathToAtomicsFolder "\$AT\src\$AT-$testCount\$AT-$testCount.tf"
    $cloud = ('iaas', 'containers', 'iaas:aws', 'iaas:azure', 'iaas:gcp')
    foreach ($platform in $test.supported_platforms) {
        if ($cloud -contains $platform) {
            return $(Test-Path -Path $pathToTerraform)
        }
    }
    return $false
}

function Build-TFVars($AT, $testCount, $InputArgs) {
    $tmpDirPath = Join-Path $PathToAtomicsFolder "\$AT\src\$AT-$testCount"
    if ($InputArgs) {
        $destinationVarsPath = Join-Path "$tmpDirPath" "terraform.tfvars.json"
        $InputArgs | ConvertTo-Json | Out-File -FilePath $destinationVarsPath
    }
}

function Remove-TerraformFiles($AT, $testCount) {
    $tmpDirPath = Join-Path $PathToAtomicsFolder "\$AT\src\$AT-$testCount"
    Write-Host $tmpDirPath
    $tfStateFile = Join-Path $tmpDirPath "terraform.tfstate"
    $tfvarsFile = Join-Path $tmpDirPath "terraform.tfvars.json"
    if ($(Test-Path $tfvarsFile)) {
        Remove-Item -LiteralPath $tfvarsFile -Force
    }
    if ($(Test-Path $tfStateFile)) {
        (Get-ChildItem -Path $tmpDirPath).Fullname -match "terraform.tfstate*" | Remove-Item -Force
    }
}
