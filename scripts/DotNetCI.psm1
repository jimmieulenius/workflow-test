function Test-ProjectAssets {
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Switch]
        $AllowPrerelease,

        [String]
        $Filter
    )

    if (-not $AllowPrerelease) {
        $contentObject = Get-Content `
            -Path "$Path/obj/project.assets.json" `
            -Raw `
        | ConvertFrom-Json `
            -AsHashtable

        if ($contentObject.targets) {
            $contentObject.targets.GetEnumerator() `
            | ForEach-Object {
                if ($_.Value) {
                    $_.Value.GetEnumerator() `
                    | ForEach-Object {
                        $components = $_.Key -split '/'
                        $name = $components[0]

                        if (
                            ([String]::IsNullOrEmpty($Filter)) `
                            -or ($_.Key -ilike $Filter) `
                        ) {
                            $version = $components[1]

                            if ($version -like '*-*') {
                                throw "Prerelease version '$version' detected in '$name'"
                            }
                        }
                    }
                }
            }
        }
    }
}