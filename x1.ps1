# ============================================================
#  HonestVL.com - Remove Microsoft Bloatware
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
Write-Host '  HONESTVL.COM - REMOVE BLOATWARE' -ForegroundColor Red
Write-Host '  Windows 11 25H2' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''

# --------------------------------------------------------
#  LIST OF BLOAT APPS TO REMOVE
# --------------------------------------------------------
$bloatApps = @(
    # Microsoft Bloat
    'Microsoft.Copilot'
    'Microsoft.BingSearch'
    'Microsoft.BingNews'
    'Microsoft.BingWeather'
    'Microsoft.BingFinance'
    'Microsoft.BingSports'
    'Microsoft.BingTranslator'
    'Microsoft.BingFoodAndDrink'
    'Microsoft.BingHealthAndFitness'
    'Microsoft.BingTravel'
    'Microsoft.BingMaps'
    'Microsoft.MicrosoftNews'

    # Social / Communication
    'Microsoft.MicrosoftTeams'
    'MicrosoftTeams'
    'Microsoft.SkypeApp'
    'Microsoft.People'
    'Microsoft.Messaging'

    # Entertainment / Media
    'Microsoft.ZuneMusic'
    'Microsoft.ZuneVideo'
    'Clipchamp.Clipchamp'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.GamingApp'
    'Microsoft.XboxApp'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.XboxIdentityProvider'
    'Microsoft.XboxSpeechToTextOverlay'

    # Productivity Bloat
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.Office.OneNote'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.MicrosoftJournal'
    'Microsoft.Todos'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.MicrosoftPowerBIForWindows'

    # Social / Third-Party Preinstalls
    'Microsoft.LinkedIn'
    'SpotifyAB.SpotifyMusic'
    'Disney.37853FC22B2CE'
    'BytedancePte.Ltd.TikTok'
    'FACEBOOK.FACEBOOK'
    'Facebook.Instagram'
    '5A894077.McAfeeSecurity'
    '4DF9E0F8.Netflix'
    'AmazonVideo.PrimeVideo'

    # Utilities Nobody Wants
    'Microsoft.Getstarted'
    'Microsoft.GetHelp'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.WindowsMaps'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.WindowsAlarms'
    'Microsoft.WindowsCamera'
    'Microsoft.YourPhone'
    'Microsoft.WindowsCommunicationsApps'
    'Microsoft.OutlookForWindows'
    'Microsoft.549981C3F5F10'
    'Microsoft.MixedReality.Portal'
    'Microsoft.3DBuilder'
    'Microsoft.Microsoft3DViewer'
    'Microsoft.Print3D'
    'Microsoft.OneConnect'
    'Microsoft.MSPaint'
    'Microsoft.Paint'

    # Widgets
    'MicrosoftWindows.Client.WebExperience'

    # AI / Recall
    'MicrosoftWindows.Client.AIX'
    'MicrosoftWindows.Client.Photon'

    # Dev bloat preinstalls
    'Microsoft.DevHome'

    # Misc
    'microsoft.windowscommunicationsapps'
    'Microsoft.CommsPhone'
    'Microsoft.ConnectivityStore'
    'Microsoft.ScreenSketch'
    'Microsoft.Windows.Ai.Copilot.Provider'
    'Microsoft.Copilot_8wekyb3d8bbwe'
    'Microsoft.Windows.DevHome'
    'Microsoft.Family'
    'Microsoft.WindowsStore.Copilot'
)

# --------------------------------------------------------
#  REMOVE INSTALLED APPS (All Users)
# --------------------------------------------------------
Write-Host '[1/3] Removing installed bloat apps...' -ForegroundColor Cyan
$removed = 0
$skipped = 0

foreach ($app in $bloatApps) {
    $packages = Get-AppxPackage -AllUsers -Name ('*' + $app + '*') -ErrorAction SilentlyContinue
    if ($packages) {
        foreach ($pkg in $packages) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                Write-Host ('  - Removed: ' + $pkg.Name) -ForegroundColor Green
                $removed++
            }
            catch {
                Write-Host ('  ! Failed: ' + $pkg.Name + ' - ' + $_) -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ('  + Removed ' + $removed + ' packages') -ForegroundColor Green
Write-Host ''

# --------------------------------------------------------
#  REMOVE PROVISIONED PACKAGES (Prevent Reinstall)
# --------------------------------------------------------
Write-Host '[2/3] Removing provisioned packages (prevent reinstall)...' -ForegroundColor Cyan
$provRemoved = 0

$provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

foreach ($app in $bloatApps) {
    $matches = $provisioned | Where-Object { $_.DisplayName -like ('*' + $app + '*') }
    foreach ($match in $matches) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $match.PackageName -ErrorAction SilentlyContinue | Out-Null
            Write-Host ('  - Deprovisioned: ' + $match.DisplayName) -ForegroundColor Green
            $provRemoved++
        }
        catch {
            Write-Host ('  ! Failed: ' + $match.DisplayName) -ForegroundColor Yellow
        }
    }
}

Write-Host ('  + Deprovisioned ' + $provRemoved + ' packages') -ForegroundColor Green
Write-Host ''

# --------------------------------------------------------
#  BLOCK REINSTALLATION VIA POLICY
# --------------------------------------------------------
Write-Host '[3/3] Blocking reinstallation via policy...' -ForegroundColor Cyan

try {
    # Disable consumer features (auto-installs candy crush etc)
    $cdmMachine = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    if (-not (Test-Path $cdmMachine)) { New-Item -Path $cdmMachine -Force | Out-Null }
    Set-ItemProperty -Path $cdmMachine -Name 'DisableWindowsConsumerFeatures' -Value 1 -Type DWord
    Set-ItemProperty -Path $cdmMachine -Name 'DisableCloudOptimizedContent' -Value 1 -Type DWord
    Set-ItemProperty -Path $cdmMachine -Name 'DisableSoftLanding' -Value 1 -Type DWord
    Write-Host '  + Consumer features disabled (no auto-reinstall)' -ForegroundColor Green
}
catch { Write-Host ('  ! Consumer features: ' + $_) -ForegroundColor Red }

try {
    # Disable silent app installs
    $cdmUser = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    Set-ItemProperty -Path $cdmUser -Name 'SilentInstalledAppsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'ContentDeliveryAllowed' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'OemPreInstalledAppsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'PreInstalledAppsEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'SubscribedContent-338388Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'SubscribedContent-338389Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'SubscribedContent-353694Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cdmUser -Name 'SubscribedContent-353696Enabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Silent app installs blocked' -ForegroundColor Green
}
catch { Write-Host ('  ! Silent installs: ' + $_) -ForegroundColor Red }

try {
    # Disable Copilot specifically
    $copilotUser = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    if (-not (Test-Path $copilotUser)) { New-Item -Path $copilotUser -Force | Out-Null }
    Set-ItemProperty -Path $copilotUser -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
    $copilotMachine = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    if (-not (Test-Path $copilotMachine)) { New-Item -Path $copilotMachine -Force | Out-Null }
    Set-ItemProperty -Path $copilotMachine -Name 'TurnOffWindowsCopilot' -Value 1 -Type DWord
    Write-Host '  + Copilot blocked via policy' -ForegroundColor Green
}
catch { Write-Host ('  ! Copilot policy: ' + $_) -ForegroundColor Red }

Write-Host ''
Write-Host '========================================' -ForegroundColor Red
Write-Host '  BLOATWARE REMOVAL COMPLETE' -ForegroundColor Green
Write-Host '' -ForegroundColor White
Write-Host '  Removed:' -ForegroundColor White
Write-Host ('    - ' + $removed + ' installed apps') -ForegroundColor Gray
Write-Host ('    - ' + $provRemoved + ' provisioned packages') -ForegroundColor Gray
Write-Host '    - Silent installs blocked' -ForegroundColor Gray
Write-Host '    - Consumer features disabled' -ForegroundColor Gray
Write-Host '    - Copilot blocked via policy' -ForegroundColor Gray
Write-Host '' -ForegroundColor White
Write-Host '  Apps NOT removed (essential):' -ForegroundColor Yellow
Write-Host '    Calculator, Photos, Store, Terminal,' -ForegroundColor Gray
Write-Host '    Snipping Tool, Notepad, Edge' -ForegroundColor Gray
Write-Host '' -ForegroundColor White
Write-Host '  honestvl.com' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''
Read-Host 'Press ENTER to close'
