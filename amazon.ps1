# PowerShell script to block Amazon domains
$HOSTS_FILE = "$env:SystemRoot\System32\drivers\etc\hosts"

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Run PowerShell as Administrator" -ForegroundColor Red
    exit 1
}

# Create if missing
if (-not (Test-Path $HOSTS_FILE)) {
    "127.0.0.1 localhost" | Out-File $HOSTS_FILE -Encoding ASCII
}

# Read content
$content = Get-Content $HOSTS_FILE

# Remove old Amazon block
$newContent = @()
$inBlock = $false
foreach ($line in $content) {
    if ($line -match "# Amazon Block") { $inBlock = $true; continue }
    if ($line -match "# End Amazon Block") { $inBlock = $false; continue }
    if (-not $inBlock) { $newContent += $line }
}

# Add Amazon block
$newContent += ""
$newContent += "# Amazon Block - $(Get-Date)"
$newContent += "127.0.0.1 amazon.com"
$newContent += "127.0.0.1 www.amazon.com"
$newContent += "127.0.0.1 amazon.ca"
$newContent += "127.0.0.1 www.amazon.ca"
$newContent += "# End Amazon Block"

# Write back
$newContent | Set-Content $HOSTS_FILE -Encoding ASCII

# Flush DNS
ipconfig /flushdns | Out-Null

Write-Host "Amazon domains blocked permanently!" -ForegroundColor Green
Write-Host "Hosts file: $HOSTS_FILE"
