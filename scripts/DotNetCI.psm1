function Test-ProjectAssets {
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $Path,

        [String]
        $Prefix
    )

    Get-ChildItem `
        -Path "$Path/obj" `
        -File
}