#Requires -Version 5.1
param(
    [int]$MinIntervalSeconds = 5,
    [int]$MaxIntervalSeconds = 60,
    [switch]$Debug
)

# Set debug preference
if ($Debug) {
    $DebugPreference = 'Continue'
}

# Add necessary assembly for SendKeys
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [Info] System.Windows.Forms loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [Error] Failed to load System.Windows.Forms" -ForegroundColor Red
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [Warning] Ensure you are running Windows PowerShell (powershell.exe)" -ForegroundColor Yellow
    exit 1
}

# Logging function
function Write-ActivityLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Error" { Write-Host $logEntry -ForegroundColor Red }
        "Warning" { Write-Host $logEntry -ForegroundColor Yellow }
        "Debug" { 
            if ($DebugPreference -ne 'SilentlyContinue') {
                Write-Host $logEntry -ForegroundColor Gray
            }
        }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

# Available keystrokes to simulate - FIXED SYNTAX
$KeyStrokes = @(
    @{ Name = "CTRL"; Keys = "^" },
    @{ Name = "SHIFT"; Keys = "+" },
    @{ Name = "F15 (Keep Awake)"; Keys = "{F15}" }
)

# Statistics tracking
$script:Stats = @{
    StartTime = Get-Date
    TotalKeystrokes = 0
    CtrlCount = 0
    ShiftCount = 0
    F15Count = 0
}

function Send-RandomKeystroke {
    try {
        # Select random keystroke (weighted towards CTRL and SHIFT)
        $randomChoice = Get-Random -Minimum 1 -Maximum 101
        
        if ($randomChoice -le 40) {
            # 40% chance - CTRL
            $keystroke = $KeyStrokes[0]
            $script:Stats.CtrlCount++
        }
        elseif ($randomChoice -le 80) {
            # 40% chance - SHIFT  
            $keystroke = $KeyStrokes[1]
            $script:Stats.ShiftCount++
        }
        else {
            # 20% chance - F15 (keep awake)
            $keystroke = $KeyStrokes[2]
            $script:Stats.F15Count++
        }
        
        Write-ActivityLog "Sending $($keystroke.Name) keystroke" -Level "Info"
        [System.Windows.Forms.SendKeys]::SendWait($keystroke.Keys)
        
        $script:Stats.TotalKeystrokes++
        
        return $true
    }
    catch {
        Write-ActivityLog "Failed to send keystroke: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

function Show-Statistics {
    $runtime = (Get-Date) - $script:Stats.StartTime
    $runtimeStr = "{0:hh\:mm\:ss}" -f $runtime
    
    Write-ActivityLog "--- STATISTICS ---" -Level "Info"
    Write-ActivityLog "Runtime: $runtimeStr" -Level "Info"
    Write-ActivityLog "Total Keystrokes: $($script:Stats.TotalKeystrokes)" -Level "Info"
    Write-ActivityLog "  CTRL: $($script:Stats.CtrlCount)" -Level "Info"
    Write-ActivityLog "  SHIFT: $($script:Stats.ShiftCount)" -Level "Info"
    Write-ActivityLog "  F15: $($script:Stats.F15Count)" -Level "Info"
    
    if ($runtime.TotalMinutes -gt 0) {
        $avgPerMin = [Math]::Round($script:Stats.TotalKeystrokes / $runtime.TotalMinutes, 1)
        Write-ActivityLog "Average: $avgPerMin keystrokes/minute" -Level "Info"
    }
    Write-ActivityLog "---" -Level "Info"
}

function Get-NextInterval {
    return Get-Random -Minimum $MinIntervalSeconds -Maximum $MaxIntervalSeconds
}

# Main execution
try {
    Write-ActivityLog "Simple User Activity Simulator Started" -Level "Info"
    Write-ActivityLog "Keystroke interval: $MinIntervalSeconds-$MaxIntervalSeconds seconds" -Level "Info"
    Write-ActivityLog "Available keystrokes: CTRL (40%), SHIFT (40%), F15/Keep-Awake (20%)" -Level "Info"
    Write-ActivityLog "Press CTRL+C to stop" -Level "Info"
    Write-ActivityLog "---" -Level "Info"
    
    # Initial keystroke
    Send-RandomKeystroke | Out-Null
    
    $statisticsInterval = 0
    
    # Main loop
    while ($true) {
        # Get next random interval
        $sleepSeconds = Get-NextInterval
        $nextKeystrokeTime = (Get-Date).AddSeconds($sleepSeconds)
        
        Write-ActivityLog "Next keystroke in $sleepSeconds seconds (at $($nextKeystrokeTime.ToString('HH:mm:ss')))" -Level "Debug"
        
        # Sleep with periodic status updates
        $remainingTime = $sleepSeconds
        while ($remainingTime -gt 0) {
            $sleepChunk = [Math]::Min(10, $remainingTime)
            Start-Sleep -Seconds $sleepChunk
            $remainingTime -= $sleepChunk
            
            # Show statistics every 5 minutes (300 seconds)
            $statisticsInterval += $sleepChunk
            if ($statisticsInterval -ge 300) {
                Show-Statistics
                $statisticsInterval = 0
            }
        }
        
        # Send keystroke
        Send-RandomKeystroke | Out-Null
    }
}
catch [System.Management.Automation.PipelineStoppedException] {
    Write-ActivityLog "Script stopped by user (CTRL+C)" -Level "Info"
}
catch {
    Write-ActivityLog "Unexpected error: $($_.Exception.Message)" -Level "Error"
}
finally {
    Show-Statistics
    Write-ActivityLog "Simple User Activity Simulator stopped" -Level "Info"
}
