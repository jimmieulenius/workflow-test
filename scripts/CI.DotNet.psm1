function Test-ProjectAsset {
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Switch]
        $AllowPrerelease,

        [String[]]
        $Filter
    )

    function Test-Filter {
        param (
            [Parameter(Mandatory = $true)]
            [String]
            $Value
        )

        if ($Filter) {
            $result = $false

            foreach ($filterItem in $Filter) {
                if ($Value -ilike $filterItem) {
                    $result = $true

                    break
                }
            }

            return $result
        }

        return $true
    }

    function Test-PrereleaseVersion {
        param (
            [Parameter(Mandatory = $true)]
            [String]
            $Name,

            [Parameter(Mandatory = $true)]
            [String]
            $Version
        )

        if ($Version -like '*-*') {
            $invalidAsset.Add("$Name/$Version")
        }
    }

    if (-not $AllowPrerelease) {
        $contentObject = Get-Content `
            -Path "$Path/obj/project.assets.json" `
            -Raw `
        | ConvertFrom-Json `
            -AsHashtable

        if ($contentObject.project.version -like '*-*') {
            Write-Error "Invalid project version found in project.assets.json: $($contentObject.project.version)"
        }

        if ($contentObject.targets) {
            $invalidAsset = [System.Collections.Generic.List[String]]::new()

            $contentObject.targets.GetEnumerator() `
            | ForEach-Object {
                if ($_.Value) {
                    $_.Value.GetEnumerator() `
                    | ForEach-Object {
                        $component = $_.Key -split '/'
                        $name = $component[0]

                        if (
                            Test-Filter `
                                -Value $name
                        ) {
                            Test-PrereleaseVersion `
                                -Name $name `
                                -Version $component[1]
                        }

                        if ($_.Value.dependencies) {
                            $_.Value.dependencies.GetEnumerator() `
                            | ForEach-Object {
                                if (
                                    Test-Filter `
                                        -Value $_.Key
                                ) {
                                    Test-PrereleaseVersion `
                                        -Name $_.Key `
                                        -Version $_.Value
                                }
                            }
                        }
                    }
                }
            }

            if ($invalidAsset.Count -gt 0) {
                Write-Error "Invalid asset(s) found in project.assets.json:$([Environment]::NewLine)    $($invalidAsset -join "$([Environment]::NewLine)    ")"
            }
        }
    }
}

function Publish-Package {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Version]
        $Version,

        # [Parameter(ParameterSetName = 'Prerelease')]
        # [Switch]
        # $Prerelease,

        # [Parameter(ParameterSetName = 'Prerelease')]
        [String]
        $Suffix
    )

    # $Prerelease = $true
    # $Suffix = 'aaa'

    if (-not $Version) {
        $Version = (
            git tag `
                --sort=-v:refname `
        | Select-Object `
            -First 1
        )?.Substring(1) -as [Version]

        if ($Version) {
            $Version = [Version]::new(
                $Version.Major,
                $Version.Minor,
                $Version.Build + 1
            )
        } else {
            $Version = '0.0.1' -as [Version]
        }
    }

    $versionString = "$Version$(((-not [String]::IsNullOrEmpty($Suffix)) ? "-preview-$Suffix" : $null))"

    $versionString
}