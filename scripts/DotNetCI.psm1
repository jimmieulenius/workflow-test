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

    $contentObject = Get-Content `
        -Path "$Path/obj/project.assets.json" `
        -Raw `
    | ConvertFrom-Json `
        -AsHashtable

    if ($contentObject.targets) {
        $contentObject.targets.GetEnumerator() `
        | ForEach-Object {
            $version = $_.Key -split '/' `
            | Select-Object `
                -Last 1

            $version
        }
    }
}