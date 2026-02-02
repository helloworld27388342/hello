# PowerShell script to UNBLOCK Amazon domains
$HOSTS_FILE = "$env:SystemRoot\System32\drivers\etc\hosts"

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Red
    exit 1
}

if (Test-Path $HOSTS_FILE) {
    $content = Get-Content $HOSTS_FILE
    $newContent = @()
    $skip = $false

    foreach ($line in $content) {
        # Start skipping when we hit the block header
        if ($line -match "# Amazon Block") { $skip = $true; continue }
        # Stop skipping after the block footer
        if ($line -match "# End Amazon Block") { $skip = $false; continue }
        
        # Only keep lines that are NOT inside the block
        if (-not $skip) {
            $newContent += $line
        }
    }

    # Write the cleaned content back to the file
    $newContent | Set-Content $HOSTS_FILE -Encoding ASCII
    
    # Flush DNS to restore access immediately
    ipconfig /flushdns | Out-Null
    Write-Host "Amazon has been unblocked!" -ForegroundColor Cyan
}
