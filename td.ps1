# PowerShell script to block TD Bank domains
$HOSTS_FILE = "$env:SystemRoot\System32\drivers\etc\hosts"

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Red
    exit 1
}

# Read existing content
if (Test-Path $HOSTS_FILE) { $content = Get-Content $HOSTS_FILE } else { $content = @() }

# Remove existing TD block to prevent duplicates
$newContent = @()
$skip = $false
foreach ($line in $content) {
    if ($line -match "# TD Block") { $skip = $true; continue }
    if ($line -match "# End TD Block") { $skip = $false; continue }
    if (-not $skip) { $newContent += $line }
}

# Add TD block
$newContent += ""
$newContent += "# TD Block - $(Get-Date)"
$newContent += "127.0.0.1 authentication.td.com"
$newContent += "127.0.0.1 easyweb.td.com"
$newContent += "127.0.0.1 www.authentication.td.com"
$newContent += "127.0.0.1 www.easyweb.td.com"
$newContent += "# End TD Block"

# Write back and flush DNS
$newContent | Set-Content $HOSTS_FILE -Encoding ASCII
ipconfig /flushdns | Out-Null

Write-Host "TD domains blocked successfully!" -ForegroundColor Green
