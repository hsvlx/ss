# ============================================================
#  HonestVL.com - Dark Taskbar / Dark Mode
#  Run as Administrator
# ============================================================

# Check Admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }
    $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '"'
    Start-Process powershell.exe -ArgumentList $argString -Verb RunAs
    exit
}

Write-Host '========================================' -ForegroundColor Red
Write-Host '  HONESTVL.COM - DARK TASKBAR' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''

$themePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

# Set dark mode for system (taskbar, start menu, action center)
Write-Host '[1/3] Setting dark system theme (taskbar)...' -ForegroundColor Cyan
try {
    Set-ItemProperty -Path $themePath -Name 'SystemUsesLightTheme' -Value 0 -Type DWord
    Write-Host '  + Taskbar / Start Menu set to DARK' -ForegroundColor Green
}
catch { Write-Host ('  ! System theme: ' + $_) -ForegroundColor Red }

# Set dark mode for apps
Write-Host '[2/3] Setting dark app theme...' -ForegroundColor Cyan
try {
    Set-ItemProperty -Path $themePath -Name 'AppsUseLightTheme' -Value 0 -Type DWord
    Write-Host '  + Apps set to DARK' -ForegroundColor Green
}
catch { Write-Host ('  ! App theme: ' + $_) -ForegroundColor Red }

# Disable transparency for solid dark look
Write-Host '[3/3] Disabling transparency for solid dark taskbar...' -ForegroundColor Cyan
try {
    Set-ItemProperty -Path $themePath -Name 'EnableTransparency' -Value 0 -Type DWord
    Write-Host '  + Transparency disabled (solid black taskbar)' -ForegroundColor Green
}
catch { Write-Host ('  ! Transparency: ' + $_) -ForegroundColor Red }

# Restart Explorer to apply
Write-Host ''
Write-Host '[APPLY] Restarting Explorer...' -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Start-Process explorer

Write-Host ''
Write-Host '========================================' -ForegroundColor Red
Write-Host '  DARK TASKBAR APPLIED' -ForegroundColor Green
Write-Host '  honestvl.com' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''
Read-Host 'Press ENTER to close'
