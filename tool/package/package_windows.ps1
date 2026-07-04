$ErrorActionPreference = "Stop"
$Root = Resolve-Path "$PSScriptRoot\..\.."
$Dist = Join-Path $Root "dist"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Push-Location $Root
fvm flutter build windows --release
Copy-Item LICENSE,THIRD_PARTY_NOTICES.md build\windows\x64\runner\Release\
Compress-Archive -Force build\windows\x64\runner\Release\* `
  (Join-Path $Dist "JamHorse-windows.zip")
dart run msix:create --build-windows false --sign-msix false `
  --install-certificate false
Pop-Location
