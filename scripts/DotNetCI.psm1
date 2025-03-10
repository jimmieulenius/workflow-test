function Test-ProjectAssets {
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [Switch]
        $AllowPrerelease,

        [String]
        $Prefix
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
                        if ([String]::IsNullOrEmpty($Prefix) -or $_.Key.StartsWith($Prefix)) {
                            $components = $_.Key -split '/'
                            $name = $components[0]
                            $version = $components[1]

                            if ($version -contains '-') {
                                throw "Prerelease version '$version' detected in '$name'"
                            }
                        }
                    }
                }
            }
        }
    }
}