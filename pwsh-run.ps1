# Ensure running as admin
$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($windowsIdentity)
$isAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Not running as admin. Relaunching as administrator..."
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set repo and .bat filename
$repoOwner = "Batlez"
$repoName = "Batlez-Tweaks"
$batFileName = "Batlez Tweaks.bat"
$branch = "main" # Change if needed

# Download the .bat file to temp
$tempBat = Join-Path $env:TEMP $batFileName
$encodedBatName = [uri]::EscapeDataString($batFileName)
$rawUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/$encodedBatName"
Invoke-WebRequest -Uri $rawUrl -OutFile $tempBat

# Execute the .bat file
Write-Host "Running $batFileName as administrator..."
Start-Process -FilePath $tempBat -Verb RunAs -Wait

# Cleanup
Remove-Item $tempBat -Force
Write-Host "Done!"
