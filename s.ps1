# ============================================================
#  HonestVL.com - Taskbar & Desktop Cleanup
#  Windows 11 25H2 Compatible
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
Write-Host '  HONESTVL.COM - TASKBAR TWEAKS' -ForegroundColor Red
Write-Host '  Windows 11 25H2' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''

$advPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$searchPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'
$cdmPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

# --------------------------------------------------------
#  REMOVE COPILOT (App + Registry + Policy)
# --------------------------------------------------------
Write-Host '[COPILOT] Removing Copilot completely...' -ForegroundColor Cyan

# Uninstall Copilot app
try {
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*Microsoft.Copilot*' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*Microsoft.Copilot*' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    Write-Host '  + Copilot app uninstalled' -ForegroundColor Green
}
catch { Write-Host ('  ! Copilot app: ' + $_) -ForegroundColor Red }

# Disable Copilot via registry (user level)
try {
    $copilotUser = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    if (-not (Test-Path $copilotUser)) { New-Item -Path $copilotUser -Force | Out-Null }
    Set-ItemProperty -Path $copilotUser -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
    Set-ItemProperty -Path $advPath -Name 'ShowCopilotButton' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Copilot disabled via user registry' -ForegroundColor Green
}
catch { Write-Host ('  ! Copilot user reg: ' + $_) -ForegroundColor Red }

# Disable Copilot via policy (machine level)
try {
    $copilotMachine = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    if (-not (Test-Path $copilotMachine)) { New-Item -Path $copilotMachine -Force | Out-Null }
    Set-ItemProperty -Path $copilotMachine -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
    Write-Host '  + Copilot disabled via machine policy' -ForegroundColor Green
}
catch { Write-Host ('  ! Copilot machine reg: ' + $_) -ForegroundColor Red }

# Block Copilot from reinstalling via Windows Update
try {
    $storePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'
    if (-not (Test-Path $storePolicy)) { New-Item -Path $storePolicy -Force | Out-Null }
    Set-ItemProperty -Path $storePolicy -Name 'RemoveWindowsStore' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    # Block auto-install of Copilot
    $cdmMachine = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    if (-not (Test-Path $cdmMachine)) { New-Item -Path $cdmMachine -Force | Out-Null }
    Set-ItemProperty -Path $cdmMachine -Name 'DisableWindowsConsumerFeatures' -Value 1 -Type DWord
    Set-ItemProperty -Path $cdmMachine -Name 'DisableCloudOptimizedContent' -Value 1 -Type DWord
    Write-Host '  + Copilot blocked from reinstalling' -ForegroundColor Green
}
catch { Write-Host ('  ! Copilot block: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  REMOVE WIDGETS (App + Registry + Service)
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[WIDGETS] Removing Widgets completely...' -ForegroundColor Cyan

# Uninstall Widgets (Web Experience Pack)
try {
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*WebExperience*' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*WebExperience*' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    Write-Host '  + Widgets (Web Experience Pack) uninstalled' -ForegroundColor Green
}
catch { Write-Host ('  ! Widgets app: ' + $_) -ForegroundColor Red }

# Disable Widgets via registry
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarDa' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    $widgetPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
    if (-not (Test-Path $widgetPolicy)) { New-Item -Path $widgetPolicy -Force | Out-Null }
    Set-ItemProperty -Path $widgetPolicy -Name 'AllowNewsAndInterests' -Value 0 -Type DWord
    Write-Host '  + Widgets disabled via registry' -ForegroundColor Green
}
catch { Write-Host ('  ! Widgets reg: ' + $_) -ForegroundColor Red }

# Stop and disable Widget service
try {
    Stop-Process -Name 'WidgetService' -Force -ErrorAction SilentlyContinue
    Stop-Process -Name 'Widgets' -Force -ErrorAction SilentlyContinue
    Write-Host '  + Widget processes killed' -ForegroundColor Green
}
catch { Write-Host ('  ! Widget process: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  REMOVE TASKBAR BLOAT ICONS
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[TASKBAR] Removing bloat icons...' -ForegroundColor Cyan

# Remove Chat / Teams
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarMn' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*MicrosoftTeams*' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Write-Host '  + Chat / Teams removed' -ForegroundColor Green
}
catch { Write-Host ('  ! Chat: ' + $_) -ForegroundColor Red }

# Remove Task View
try {
    Set-ItemProperty -Path $advPath -Name 'ShowTaskViewButton' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Task View removed' -ForegroundColor Green
}
catch { Write-Host ('  ! Task View: ' + $_) -ForegroundColor Red }

# Set Search to icon only
try {
    Set-ItemProperty -Path $searchPath -Name 'SearchboxTaskbarMode' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Search set to icon only' -ForegroundColor Green
}
catch { Write-Host ('  ! Search: ' + $_) -ForegroundColor Red }

# Remove Pen menu
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarSn' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Pen menu removed' -ForegroundColor Green
}
catch { Write-Host ('  ! Pen: ' + $_) -ForegroundColor Red }

# Remove Virtual Touchpad
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarTp' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Virtual touchpad removed' -ForegroundColor Green
}
catch { Write-Host ('  ! Touchpad: ' + $_) -ForegroundColor Red }

# Remove Touch Keyboard
try {
    $inputPath = 'HKCU:\SOFTWARE\Microsoft\TabletTip\1.7'
    if (-not (Test-Path $inputPath)) { New-Item -Path $inputPath -Force | Out-Null }
    Set-ItemProperty -Path $inputPath -Name 'TipbandDesiredVisibility' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Touch keyboard hidden' -ForegroundColor Green
}
catch { Write-Host ('  ! Touch keyboard: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  TASKBAR BEHAVIOR
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[TASKBAR] Setting behavior...' -ForegroundColor Cyan

# Align taskbar to left
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarAl' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Taskbar aligned to LEFT' -ForegroundColor Green
}
catch { Write-Host ('  ! Alignment: ' + $_) -ForegroundColor Red }

# Never combine taskbar buttons
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarGlomLevel' -Value 2 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Taskbar buttons: never combine' -ForegroundColor Green
}
catch { Write-Host ('  ! Combine: ' + $_) -ForegroundColor Red }

# Hide taskbar on other displays
try {
    Set-ItemProperty -Path $advPath -Name 'MMTaskbarEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Taskbar hidden on secondary displays' -ForegroundColor Green
}
catch { Write-Host ('  ! Multi-monitor: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  SYSTEM TRAY
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[TRAY] Cleaning system tray...' -ForegroundColor Cyan

# Show all tray icons
try {
    Set-ItemProperty -Path $advPath -Name 'AutoTrayNotifyIcon' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + All tray icons visible' -ForegroundColor Green
}
catch { Write-Host ('  ! Tray icons: ' + $_) -ForegroundColor Red }

# Remove People
try {
    Set-ItemProperty -Path $advPath -Name 'TaskbarSi' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    $peoplePath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
    if (Test-Path $peoplePath) {
        Set-ItemProperty -Path $peoplePath -Name 'PeopleBand' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
    Write-Host '  + People / Meet Now hidden' -ForegroundColor Green
}
catch { Write-Host ('  ! People: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  START MENU
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[START MENU] Cleaning up...' -ForegroundColor Cyan

# Disable recommendations
try {
    Set-ItemProperty -Path $advPath -Name 'Start_IrisRecommendations' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Recommendations disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! Recommendations: ' + $_) -ForegroundColor Red }

# Disable recently added + most used apps
try {
    $startPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start'
    Set-ItemProperty -Path $startPath -Name 'ShowRecentList' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $startPath -Name 'ShowFrequentList' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Recently added / most used apps hidden' -ForegroundColor Green
}
catch { Write-Host ('  ! Recent apps: ' + $_) -ForegroundColor Red }

# Disable ALL suggested content + ads + silent app installs
try {
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-310093Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-314563Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-338387Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-338388Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-338389Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-338393Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-353694Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SubscribedContent-353696Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SystemPaneSuggestionsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SoftLandingEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'OemPreInstalledAppsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'PreInstalledAppsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'PreInstalledAppsEverEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'SilentInstalledAppsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'ContentDeliveryAllowed' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'RotatingLockScreenOverlayEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmPath -Name 'RotatingLockScreenEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + All ads, suggestions, silent installs disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! Suggestions: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  REMOVE WINDOWS AI / RECALL
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[AI] Removing Windows Recall and AI features...' -ForegroundColor Cyan

# Uninstall Recall
try {
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like '*Recall*' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like '*Recall*' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    Write-Host '  + Recall app removed' -ForegroundColor Green
}
catch { Write-Host ('  ! Recall app: ' + $_) -ForegroundColor Red }

# Disable Recall via policy
try {
    $aiPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
    if (-not (Test-Path $aiPath)) { New-Item -Path $aiPath -Force | Out-Null }
    Set-ItemProperty -Path $aiPath -Name 'DisableAIDataAnalysis' -Value 1 -Type DWord
    Set-ItemProperty -Path $aiPath -Name 'TurnOffSavingSnapshots' -Value 1 -Type DWord
    Write-Host '  + Recall disabled via policy' -ForegroundColor Green
}
catch { Write-Host ('  ! Recall policy: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  DESKTOP / FILE EXPLORER
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[DESKTOP] Cleaning up...' -ForegroundColor Cyan

# Show file extensions
try {
    Set-ItemProperty -Path $advPath -Name 'HideFileExt' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + File extensions visible' -ForegroundColor Green
}
catch { Write-Host ('  ! File ext: ' + $_) -ForegroundColor Red }

# Show hidden files
try {
    Set-ItemProperty -Path $advPath -Name 'Hidden' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Hidden files visible' -ForegroundColor Green
}
catch { Write-Host ('  ! Hidden: ' + $_) -ForegroundColor Red }

# Disable snap assist flyout
try {
    Set-ItemProperty -Path $advPath -Name 'SnapAssist' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Snap assist flyout disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! Snap: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  NOTIFICATIONS - Kill Distractions
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[NOTIFICATIONS] Disabling distractions...' -ForegroundColor Cyan

# Disable notification sounds
try {
    $notifPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
    if (-not (Test-Path $notifPath)) { New-Item -Path $notifPath -Force | Out-Null }
    Set-ItemProperty -Path $notifPath -Name 'NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $notifPath -Name 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Notification sounds + lock screen toasts disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! Notifications: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  CLASSIC RIGHT-CLICK CONTEXT MENU
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[CONTEXT MENU] Restoring classic right-click...' -ForegroundColor Cyan
try {
    $clsidPath = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    if (-not (Test-Path $clsidPath)) { New-Item -Path $clsidPath -Force | Out-Null }
    Set-ItemProperty -Path $clsidPath -Name '(Default)' -Value '' -Type String
    Write-Host '  + Classic right-click menu restored' -ForegroundColor Green
}
catch { Write-Host ('  ! Context menu: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  RESTART EXPLORER
# --------------------------------------------------------
Write-Host '' -ForegroundColor White
Write-Host '[APPLY] Restarting Explorer...' -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Start-Process explorer

Write-Host '' -ForegroundColor White
Write-Host '========================================' -ForegroundColor Red
Write-Host '  ALL TASKBAR TWEAKS APPLIED (25H2)' -ForegroundColor Green
Write-Host '' -ForegroundColor White
Write-Host '  What changed:' -ForegroundColor White
Write-Host '    - Copilot UNINSTALLED + blocked from reinstall' -ForegroundColor Gray
Write-Host '    - Widgets UNINSTALLED + service killed' -ForegroundColor Gray
Write-Host '    - Chat/Teams UNINSTALLED' -ForegroundColor Gray
Write-Host '    - Recall UNINSTALLED + disabled via policy' -ForegroundColor Gray
Write-Host '    - Task View, Pen, Touchpad, Keyboard removed' -ForegroundColor Gray
Write-Host '    - Search set to icon only' -ForegroundColor Gray
Write-Host '    - Taskbar aligned to left, never combine' -ForegroundColor Gray
Write-Host '    - All tray icons visible' -ForegroundColor Gray
Write-Host '    - ALL Start Menu ads/suggestions killed' -ForegroundColor Gray
Write-Host '    - Silent app installs blocked' -ForegroundColor Gray
Write-Host '    - Classic right-click menu restored' -ForegroundColor Gray
Write-Host '    - File extensions + hidden files visible' -ForegroundColor Gray
Write-Host '    - Notification sounds disabled' -ForegroundColor Gray
Write-Host '' -ForegroundColor White
Write-Host '  RESTART PC for full effect' -ForegroundColor Yellow
Write-Host '  honestvl.com' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''
Read-Host 'Press ENTER to close'
