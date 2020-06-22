function Invoke-AtomicTestByGUID
{
[CmdletBinding(DefaultParameterSetName = 'technique',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
     Param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [ValidateNotNullOrEmpty()]
        [String]
        $TestGuids,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $ShowDetails,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $ShowDetailsBrief,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [String]
        $PathToAtomicsFolder = $( if ($IsLinux -or $IsMacOS) { $Env:HOME + "/AtomicRedTeam/atomics" } else { $env:HOMEDRIVE + "\AtomicRedTeam\atomics" }),

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $CheckPrereqs = $false,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $PromptForInputArgs = $false,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $GetPrereqs = $false,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $Cleanup = $false,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [switch]
        $NoExecutionLog = $false,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [String]
        $ExecutionLogPath = $( if ($IsLinux -or $IsMacOS) { "/tmp/Invoke-AtomicTest-ExecutionLog.csv" } else { "$env:TEMP\Invoke-AtomicTest-ExecutionLog.csv" }),

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [switch]
        $Force,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [HashTable]
        $InputArgs,
    
        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [Int]
        $TimeoutSeconds = 120,

        [Parameter(Mandatory = $false, ParameterSetName = 'technique')]
        [System.Management.Automation.Runspaces.PSSession[]]$Session

        )
    Begin{}
    Process{
        if ($TestGuids -match "^\w{8}(-\w{4}){3}-\w{12}$"){
            $res = (Get-ChildItem -Path $PathToAtomicsFolder -Include *.yaml -Recurse | Select-String -Pattern $TestGuids) -match "(T\d{4}(.\d{3})*)\/\1" #Filter only the technique id as files like index.yaml also contains GUID.
            if ($res.count -eq 1){ # Can be removed as two tests wont have the same GUIDs.
                $id = (Get-Item $res[0].Path).Basename
                Invoke-AtomicTest $id @PSBoundParameters
            }else{
                Write-Host -Fore Red "ERROR: $TestGuids does not exist`nCheck your Atomic GUID and your PathToAtomicsFolder parameter"
            }
        }else{
            Write-Host -Fore Red "ERROR: $TestGuids is not a valid format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).`nCheck your Atomic GUID."
        }
    }
    End{}
}

