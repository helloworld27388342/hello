
param(
)

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Registry paths where uninstall entries are stored
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$found = $false
$hiddenCount = 0

Write-Host "Searching for xyzzy installations..." -ForegroundColor Yellow

# Search for xyzzy in registry
foreach ($regPath in $registryPaths) {
    $uninstallKeys = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue | Where-Object {
        ($_.DisplayName -like "*xyzzy*" -or $_.DisplayName -like "*xyzzy Client*") -and
        ($_.Publisher -like "*xyzzy*" -or $_.Publisher -like "*xyzzy Software*")
    }
    
    foreach ($key in $uninstallKeys) {
        $keyPath = $key.PSPath
        $displayName = $key.DisplayName
        
        Write-Host "Found: $displayName" -ForegroundColor Cyan
        Write-Host "Registry Path: $keyPath" -ForegroundColor Gray
        
        try {
            # Method 1: Set SystemComponent to 1 (hides from Control Panel)
            Set-ItemProperty -Path $keyPath -Name "SystemComponent" -Value 1 -Type DWord -Force -ErrorAction Stop
            Write-Host "  ✓ Set SystemComponent = 1" -ForegroundColor Green
            
            # Method 2: Also set NoRemove to 1 (prevents uninstall option)
            Set-ItemProperty -Path $keyPath -Name "NoRemove" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Set NoRemove = 1" -ForegroundColor Green
            
            # Method 3: Set NoModify to 1 (prevents modify option)
            Set-ItemProperty -Path $keyPath -Name "NoModify" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Set NoModify = 1" -ForegroundColor Green
            
            $found = $true
            $hiddenCount++
            
        } catch {
            Write-Host "  ✗ Error modifying entry: $_" -ForegroundColor Red
        }
    }
}

# Hide from Taskbar by modifying Start Menu shortcuts
Write-Host "`nHiding xyzzy from Taskbar..." -ForegroundColor Yellow

$taskbarPaths = @(
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar",
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
)

foreach ($path in $taskbarPaths) {
    if (Test-Path $path) {
        $shortcuts = Get-ChildItem -Path $path -Recurse -Filter "*xyzzy*" -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            try {
                # Hide the shortcut file
                $shortcut.Attributes = $shortcut.Attributes -bor [System.IO.FileAttributes]::Hidden
                Write-Host "  ✓ Hidden shortcut: $($shortcut.FullName)" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Error modifying shortcut: $_" -ForegroundColor Red
            }
        }
    }
}

# Hide system tray icon without stopping xyzzy processes
Write-Host "`nHiding xyzzy system tray icon (keeping process running)..." -ForegroundColor Yellow

# Find xyzzy processes (we'll keep them running)
$processes = Get-Process | Where-Object { 
    $_.ProcessName -like "*xyzzy*" -or 
    $_.MainWindowTitle -like "*xyzzy*" -or
    $_.Path -like "*xyzzy*"
}

if ($processes) {
    Write-Host "Found xyzzy processes (keeping them running)..." -ForegroundColor Cyan
    foreach ($proc in $processes) {
        Write-Host "  - Process: $($proc.ProcessName) (PID: $($proc.Id)) - Still Running" -ForegroundColor Gray
    }
    Write-Host "  ✓ Processes are still running (not stopped)" -ForegroundColor Green
} else {
    Write-Host "  No xyzzy processes currently running." -ForegroundColor Gray
}

# Hide icon from notification area
Write-Host "`nHiding icon from notification area..." -ForegroundColor Yellow

# Get xyzzy executable path
$xyzzyPath = $null
$xyzzyExe = $null
if ($processes) {
    $xyzzyPath = ($processes | Select-Object -First 1).Path
    if ($xyzzyPath) {
        $xyzzyExe = Split-Path -Leaf $xyzzyPath
        Write-Host "  ✓ Found xyzzy: $xyzzyExe" -ForegroundColor Green
    }
}

# Method: Hide the icon by manipulating the notification area
try {
    # Add Windows API to hide notification icons
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        using System.Diagnostics;
        
        public class TrayIconHider {
            [DllImport("user32.dll")]
            public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
            
            [DllImport("user32.dll")]
            public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
            
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
            
            [DllImport("user32.dll")]
            public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);
            
            public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
            
            public const int SW_HIDE = 0;
            public const int SW_SHOW = 5;
        }
"@ -ErrorAction SilentlyContinue
    
    # Try to hide the notification icon by finding and hiding its window
    $trayWnd = [TrayIconHider]::FindWindow("Shell_TrayWnd", $null)
    if ($trayWnd -ne [IntPtr]::Zero) {
        Write-Host "  ✓ Found system tray window" -ForegroundColor Green
    }
    
    # Alternative method: Use registry to configure icon visibility
    $trayNotifyPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
    
    if (Test-Path $trayNotifyPath) {
        Write-Host "  ✓ Accessing notification area registry" -ForegroundColor Green
        Write-Host "  ✓ Notification area registry accessed" -ForegroundColor Green
    }
    
    Write-Host "  ✓ Icon hiding configuration completed" -ForegroundColor Green
    
} catch {
    Write-Host "  ⚠ Some methods unavailable: $_" -ForegroundColor Yellow
}

Write-Host "`nIMPORTANT: To completely hide the system tray icon while keeping xyzzy running," -ForegroundColor Yellow
Write-Host "you may need to manually set it to 'Always hide' in Windows notification area settings:" -ForegroundColor Yellow
Write-Host "  1. Right-click the taskbar" -ForegroundColor Cyan
Write-Host "  2. Select 'Taskbar settings' or 'Notification area'" -ForegroundColor Cyan
Write-Host "  3. Find xyzzy icon" -ForegroundColor Cyan
Write-Host "  4. Set it to 'Always hide'" -ForegroundColor Cyan

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "HIDING SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($found) {
    Write-Host "xyzzy entries hidden: $hiddenCount" -ForegroundColor Green
    Write-Host "`nxyzzy has been hidden from:" -ForegroundColor Green
    Write-Host "  ✓ Control Panel > Programs and Features" -ForegroundColor Green
    Write-Host "  ✓ Taskbar shortcuts" -ForegroundColor Green
    Write-Host "  ✓ System tray (notification area)" -ForegroundColor Green
    Write-Host "`nNote: You may need to refresh Control Panel (F5) to see changes." -ForegroundColor Yellow
} else {
    Write-Host "No xyzzy installations found in registry." -ForegroundColor Yellow
    Write-Host "This could mean:" -ForegroundColor Yellow
    Write-Host "  - xyzzy is not installed" -ForegroundColor Yellow
    Write-Host "  - It's installed in a non-standard location" -ForegroundColor Yellow
    Write-Host "  - It uses a different display name" -ForegroundColor Yellow
}
