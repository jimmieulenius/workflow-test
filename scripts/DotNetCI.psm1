function New-Greet {
    param(
        [String]
        $Name
    )

    "Hello, $Name!" `
    | Out-Default
}