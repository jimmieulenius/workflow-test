function Test-ProjectAssets {
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

        if ($contentObject.targets) {
            $invalidAsset = [System.Collections.Generic.List[String]]::new()

            $contentObject.targets.GetEnumerator() `
            | ForEach-Object {
                if ($_.Value) {
                    $_.Value.GetEnumerator() `
                    | ForEach-Object {
                        $component = $_.Key -split '/'
                        $name = $component[0]

                        # $shouldProcess = $true

                        # if ($Filter) {
                        #     $shouldProcess = $false

                        #     foreach ($filterItem in $Filter) {
                        #         if ($name -ilike $filterItem) {
                        #             $shouldProcess = $true

                        #             break
                        #         }
                        #     }
                        # }

                        # if ($shouldProcess) {
                        if (
                            Test-Filter `
                                -Value $name
                        ) {
                            $version = $component[1]

                            # if ($version -like '*-*') {
                            #     $invalidAsset.Add($_.Key)
                            # }

                            Test-PrereleaseVersion `
                                -Name $name `
                                -Version $version
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
                throw "Invalid asset(s) found in project.assets.json:$([Environment]::NewLine)    $($invalidAsset -join "$([Environment]::NewLine)    ")"
            }
        }
    }
}