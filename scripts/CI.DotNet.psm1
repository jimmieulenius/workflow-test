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

                        $shouldProcess = $true

                        if ($Filter) {
                            $shouldProcess = $false

                            foreach ($filterItem in $Filter) {
                                if ($name -ilike $filterItem) {
                                    $shouldProcess = $true

                                    break
                                }
                            }
                        }

                        if ($shouldProcess) {
                            $version = $component[1]

                            if ($version -like '*-*') {
                                $invalidAsset.Add($_.Key)
                            }
                        }
                    }
                }
            }

            if ($invalidAsset.Count -gt 0) {
                throw @"
Invalid asset(s) found in project.assets.json:
    $($invalidAsset -join "$([Environment]::NewLine)    ")
"@
            }
        }
    }
}