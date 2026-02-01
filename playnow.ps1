# PowerShell script to block PlayNow domains
$HOSTS_FILE = "$env:SystemRoot\System32\drivers\etc\hosts"

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Red
    exit 1
}

# Create file if missing
if (-not (Test-Path $HOSTS_FILE)) {
    "127.0.0.1 localhost" | Out-File $HOSTS_FILE -Encoding ASCII
}

# Read existing content
$content = Get-Content $HOSTS_FILE

# Remove any existing PlayNow block to prevent duplicates
$newContent = @()
$inBlock = $false
foreach ($line in $content) {
    if ($line -match "# PlayNow Block") { $inBlock = $true; continue }
    if ($line -match "# End PlayNow Block") { $inBlock = $false; continue }
    if (-not $inBlock) { $newContent += $line }
}

# Add PlayNow block
$newContent += ""
$newContent += "# PlayNow Block - $(Get-Date)"
$newContent += "127.0.0.1 playnow.com"
$newContent += "127.0.0.1 www.playnow.com"
$newContent += "# End PlayNow Block"

# Write back to system file
$newContent | Set-Content $HOSTS_FILE -Encoding ASCII

# Flush DNS cache so changes take effect immediately
ipconfig /flushdns | Out-Null

Write-Host "PlayNow domains blocked successfully!" -ForegroundColor Green
Write-Host "Modified: $HOSTS_FILE"
