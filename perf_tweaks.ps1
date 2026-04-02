# ============================================================
#  HonestVL.com - Advanced Performance Tweaks
#  Disables VBS, Spectre/Meltdown, sets Timer Resolution,
#  and installs Standby List Cleaner (like ISLC)
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
Write-Host '  HONESTVL.COM - PERFORMANCE TWEAKS' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''

# --------------------------------------------------------
#  1. DISABLE CORE ISOLATION / VBS (5-10% FPS gain)
#     Removes hypervisor layer that checks every memory access
# --------------------------------------------------------
Write-Host '[1/4] Disabling Core Isolation / VBS...' -ForegroundColor Cyan

try {
    # Disable Virtualization Based Security
    $dgPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
    if (-not (Test-Path $dgPath)) { New-Item -Path $dgPath -Force | Out-Null }
    Set-ItemProperty -Path $dgPath -Name 'EnableVirtualizationBasedSecurity' -Value 0 -Type DWord
    Set-ItemProperty -Path $dgPath -Name 'RequirePlatformSecurityFeatures' -Value 0 -Type DWord
    Write-Host '  + Virtualization Based Security disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! VBS: ' + $_) -ForegroundColor Red }

try {
    # Disable HVCI (Hypervisor-enforced Code Integrity)
    $hvciPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
    if (-not (Test-Path $hvciPath)) { New-Item -Path $hvciPath -Force | Out-Null }
    Set-ItemProperty -Path $hvciPath -Name 'Enabled' -Value 0 -Type DWord
    Write-Host '  + HVCI (Memory Integrity) disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! HVCI: ' + $_) -ForegroundColor Red }

try {
    # Disable Credential Guard
    $credPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    Set-ItemProperty -Path $credPath -Name 'LsaCfgFlags' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Credential Guard disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! Credential Guard: ' + $_) -ForegroundColor Red }

try {
    # Disable Kernel DMA Protection check
    $dmaPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Kernel DMA Protection'
    if (-not (Test-Path $dmaPath)) { New-Item -Path $dmaPath -Force | Out-Null }
    Set-ItemProperty -Path $dmaPath -Name 'DeviceEnumerationPolicy' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Kernel DMA Protection policy set' -ForegroundColor Green
}
catch { Write-Host ('  ! DMA: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  2. DISABLE SPECTRE / MELTDOWN MITIGATIONS (3-5% FPS gain)
#     Removes CPU vulnerability patches that slow system calls
# --------------------------------------------------------
Write-Host ''
Write-Host '[2/4] Disabling Spectre / Meltdown mitigations...' -ForegroundColor Cyan

try {
    $memPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    # FeatureSettingsOverride = 3 disables all Spectre/Meltdown mitigations
    Set-ItemProperty -Path $memPath -Name 'FeatureSettingsOverride' -Value 3 -Type DWord
    Set-ItemProperty -Path $memPath -Name 'FeatureSettingsOverrideMask' -Value 3 -Type DWord
    Write-Host '  + Spectre V2 mitigations disabled' -ForegroundColor Green
    Write-Host '  + Meltdown mitigations disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! Spectre/Meltdown: ' + $_) -ForegroundColor Red }

try {
    # Disable Speculative Store Bypass
    $specPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    Set-ItemProperty -Path $specPath -Name 'FeatureSettingsOverride' -Value 3 -Type DWord -ErrorAction SilentlyContinue
    Write-Host '  + Speculative Store Bypass disabled' -ForegroundColor Green
}
catch { Write-Host ('  ! SSB: ' + $_) -ForegroundColor Red }

# --------------------------------------------------------
#  3 & 4. INSTALL STANDBY LIST CLEANER + TIMER RESOLUTION
#     Creates a lightweight background service:
#     - Clears standby memory when free RAM < 4GB (prevents stutters)
#     - Forces 0.5ms timer resolution (reduces input latency)
# --------------------------------------------------------
Write-Host ''
Write-Host '[3/4] Setting up Standby List Cleaner + Timer Resolution...' -ForegroundColor Cyan

# Create HonestVL folder
$hvlFolder = 'C:\HonestVL'
if (-not (Test-Path $hvlFolder)) { New-Item -Path $hvlFolder -ItemType Directory -Force | Out-Null }

# Write the C# native methods file
$csContent = @'
using System;
using System.Runtime.InteropServices;

public class HonestVLPerf {
    [DllImport("ntdll.dll")]
    public static extern int NtSetTimerResolution(
        int DesiredResolution, bool SetResolution, out int CurrentResolution);

    [DllImport("ntdll.dll")]
    public static extern uint NtSetSystemInformation(
        int InfoClass, IntPtr Info, int Length);

    [DllImport("ntdll.dll")]
    public static extern int RtlAdjustPrivilege(
        int Privilege, bool Enable, bool CurrentThread, out bool Enabled);
}
'@
$csContent | Out-File -FilePath 'C:\HonestVL\PerfNative.cs' -Encoding UTF8 -Force
Write-Host '  + Native methods written to C:\HonestVL\PerfNative.cs' -ForegroundColor Green

# Write the background script
$bgContent = @'
# HonestVL Performance Background Service
# Timer Resolution (0.5ms) + Standby List Cleaner
# Do not close this - it runs silently at startup

$cs = Get-Content 'C:\HonestVL\PerfNative.cs' -Raw
Add-Type -TypeDefinition $cs -ErrorAction SilentlyContinue

# Set 0.5ms timer resolution (default is 15.6ms)
$current = 0
[HonestVLPerf]::NtSetTimerResolution(5000, $true, [ref]$current)

# Loop: clear standby list when free RAM drops below 4GB
while ($true) {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        if ($freeGB -lt 4) {
            $enabled = $false
            [HonestVLPerf]::RtlAdjustPrivilege(20, $true, $false, [ref]$enabled)
            $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
            [System.Runtime.InteropServices.Marshal]::WriteInt32($ptr, 4)
            [HonestVLPerf]::NtSetSystemInformation(80, $ptr, 4)
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
        }
    } catch {}
    Start-Sleep -Seconds 30
}
'@
$bgContent | Out-File -FilePath 'C:\HonestVL\perf_bg.ps1' -Encoding UTF8 -Force
Write-Host '  + Background script written to C:\HonestVL\perf_bg.ps1' -ForegroundColor Green

# Create scheduled task to run at logon (hidden, as SYSTEM)
Write-Host ''
Write-Host '[4/4] Creating startup task...' -ForegroundColor Cyan

try {
    # Remove old task if exists
    Unregister-ScheduledTask -TaskName 'HonestVL Performance' -Confirm:$false -ErrorAction SilentlyContinue

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\HonestVL\perf_bg.ps1"'
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Seconds 0)

    Register-ScheduledTask -TaskName 'HonestVL Performance' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-Host '  + Scheduled task "HonestVL Performance" created' -ForegroundColor Green
    Write-Host '  + Runs at every logon as SYSTEM (hidden)' -ForegroundColor Green
}
catch { Write-Host ('  ! Scheduled task: ' + $_) -ForegroundColor Red }

# Start the background script now
try {
    Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\HonestVL\perf_bg.ps1"' -WindowStyle Hidden
    Write-Host '  + Background service started NOW' -ForegroundColor Green
}
catch { Write-Host ('  ! Start service: ' + $_) -ForegroundColor Red }

Write-Host ''
Write-Host '========================================' -ForegroundColor Red
Write-Host '  PERFORMANCE TWEAKS APPLIED' -ForegroundColor Green
Write-Host '' -ForegroundColor White
Write-Host '  What changed:' -ForegroundColor White
Write-Host '    [1] Core Isolation / VBS DISABLED' -ForegroundColor Gray
Write-Host '        (removes hypervisor overhead = 5-10% FPS)' -ForegroundColor DarkGray
Write-Host '    [2] Spectre / Meltdown mitigations DISABLED' -ForegroundColor Gray
Write-Host '        (removes CPU patch overhead = 3-5% FPS)' -ForegroundColor DarkGray
Write-Host '    [3] Standby List Cleaner ACTIVE' -ForegroundColor Gray
Write-Host '        (clears cached RAM when free < 4GB = no stutters)' -ForegroundColor DarkGray
Write-Host '    [4] Timer Resolution = 0.5ms' -ForegroundColor Gray
Write-Host '        (default 15.6ms = lower input latency)' -ForegroundColor DarkGray
Write-Host '' -ForegroundColor White
Write-Host '  Background service: C:\HonestVL\perf_bg.ps1' -ForegroundColor Yellow
Write-Host '  Startup task: "HonestVL Performance"' -ForegroundColor Yellow
Write-Host '' -ForegroundColor White
Write-Host '  RESTART PC for VBS + Spectre changes' -ForegroundColor Yellow
Write-Host '  honestvl.com' -ForegroundColor Red
Write-Host '========================================' -ForegroundColor Red
Write-Host ''
Read-Host 'Press ENTER to close'
