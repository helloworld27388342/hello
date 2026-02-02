# PowerShell script to UNBLOCK TD Bank domains
$HOSTS_FILE = "$env:SystemRoot\System32\drivers\etc\hosts"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Run as Administrator" -ForegroundColor Red
    exit 1
}

if (Test-Path $HOSTS_FILE) {
    $content = Get-Content $HOSTS_FILE
    $newContent = @()
    $skip = $false

    foreach ($line in $content) {
        if ($line -match "# TD Block") { $skip = $true; continue }
        if ($line -match "# End TD Block") { $skip = $false; continue }
        if (-not $skip) { $newContent += $line }
    }

    $newContent | Set-Content $HOSTS_FILE -Encoding ASCII
    ipconfig /flushdns | Out-Null
    Write-Host "TD Bank has been unblocked!" -ForegroundColor Cyan
}
