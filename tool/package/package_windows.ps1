$ErrorActionPreference = "Stop"
$Root = Resolve-Path "$PSScriptRoot\..\.."
$Dist = Join-Path $Root "dist"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
Push-Location $Root
# Prefer the FVM-pinned SDK when FVM is installed.
$UseFvm = [bool](Get-Command fvm -ErrorAction SilentlyContinue)
if ($UseFvm) { fvm flutter build windows --release } else { flutter build windows --release }
if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed" }
Copy-Item LICENSE,THIRD_PARTY_NOTICES.md build\windows\x64\runner\Release\
Compress-Archive -Force build\windows\x64\runner\Release\* `
  (Join-Path $Dist "JamHorse-windows.zip")
$MsixArgs = @("run", "msix:create", "--build-windows", "false", "--sign-msix", "false", "--install-certificate", "false")
if ($UseFvm) { fvm dart @MsixArgs } else { dart @MsixArgs }
Pop-Location
