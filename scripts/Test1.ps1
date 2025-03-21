$Organization = 'jimmieulenius'
$Name = 'ClassLibrary2'
$Version = '0.0.22'

Invoke-WebRequest `
    -Uri "https://nuget.pkg.github.com/$Organization/download/$Name/$Version/$Name.$Version.nupkg" `
    -OutFile "$Name.$Version.nupkg" `
    -Headers @{
        Authorization = "Token $($Env:JU_NUGET_PASSWORD)"
    }