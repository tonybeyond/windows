#Requires -Version 5.1
param(
    [int]$MinIntervalSeconds = 10,
    [int]$MaxIntervalSeconds = 40,
    [int]$MoveDistance = 50,
    [int]$MoveDurationMs = 1500,
    [switch]$Debug
)

# Set debug preference
if ($Debug) {
    $DebugPreference = 'Continue'
}

# Add Windows API for mouse control
Add-Type @'
using System;
using System.Runtime.InteropServices;

public class MouseMover {
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    
    [DllImport("user32.dll")]
    public static extern void GetSystemMetrics(int nIndex);
    
    public struct POINT {
        public int X;
        public int Y;
    }
    
    public static POINT GetCurrentPosition() {
        POINT pos = new POINT();
        GetCursorPos(out pos);
        return pos;
    }
}
'@

# Logging function
function Write-MouseLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
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

# Smooth mouse movement function
function Move-MouseSmoothly {
    param(
        [int]$StartX,
        [int]$StartY,
        [int]$EndX,
        [int]$EndY,
        [int]$DurationMs = 1000,
        [int]$Steps = 50
    )
    
    try {
        $deltaX = $EndX - $StartX
        $deltaY = $EndY - $StartY
        $interval = [math]::Max(5, [math]::Floor($DurationMs / $Steps))
        
        Write-MouseLog "Moving mouse from ($StartX,$StartY) to ($EndX,$EndY) over $DurationMs ms" -Level "Debug"
        
        for ($i = 1; $i -le $Steps; $i++) {
            $progress = $i / $Steps
            
            # Use easing function for more natural movement
            $easedProgress = 1 - [math]::Pow(1 - $progress, 3)
            
            $newX = [math]::Round($StartX + $deltaX * $easedProgress)
            $newY = [math]::Round($StartY + $deltaY * $easedProgress)
            
            [MouseMover]::SetCursorPos($newX, $newY) | Out-Null
            Start-Sleep -Milliseconds $interval
        }
        
        return $true
    }
    catch {
        Write-MouseLog "Error during mouse movement: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Get safe movement bounds (stay within screen)
function Get-SafeMovementBounds {
    param(
        [int]$CurrentX,
        [int]$Distance
    )
    
    # Get screen dimensions (approximate)
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $margin = 100  # Keep some margin from screen edges
    
    $leftBound = [math]::Max($margin, $CurrentX - $Distance)
    $rightBound = [math]::Min($screenWidth - $margin, $CurrentX + $Distance)
    
    return @{
        Left = $leftBound
        Right = $rightBound
        Current = $CurrentX
    }
}

# Load System.Windows.Forms for screen info
try {
    Add-Type -AssemblyName System.Windows.Forms
}
catch {
    Write-MouseLog "Could not load System.Windows.Forms, using default screen bounds" -Level "Warning"
}

# Statistics tracking
$script:Stats = @{
    StartTime = Get-Date
    TotalMoves = 0
    RightMoves = 0
    LeftMoves = 0
}

function Show-MouseStats {
    $runtime = (Get-Date) - $script:Stats.StartTime
    $runtimeStr = "{0:hh\:mm\:ss}" -f $runtime
    
    Write-MouseLog "--- MOUSE MOVEMENT STATISTICS ---" -Level "Info"
    Write-MouseLog "Runtime: $runtimeStr" -Level "Info"
    Write-MouseLog "Total Movements: $($script:Stats.TotalMoves)" -Level "Info"
    Write-MouseLog "  Right: $($script:Stats.RightMoves)" -Level "Info"
    Write-MouseLog "  Left: $($script:Stats.LeftMoves)" -Level "Info"
    
    if ($runtime.TotalMinutes -gt 0) {
        $avgPerMin = [Math]::Round($script:Stats.TotalMoves / $runtime.TotalMinutes, 1)
        Write-MouseLog "Average: $avgPerMin movements/minute" -Level "Info"
    }
    Write-MouseLog "---" -Level "Info"
}

# Main execution
try {
    Write-MouseLog "Mouse Movement Simulator Started" -Level "Info"
    Write-MouseLog "Movement interval: $MinIntervalSeconds-$MaxIntervalSeconds seconds" -Level "Info"
    Write-MouseLog "Movement distance: $MoveDistance pixels" -Level "Info"
    Write-MouseLog "Movement duration: $MoveDurationMs ms" -Level "Info"
    Write-MouseLog "Press CTRL+C to stop" -Level "Info"
    Write-MouseLog "---" -Level "Info"
    
    $statisticsInterval = 0
    
    # Main loop
    while ($true) {
        # Get current mouse position
        $currentPos = [MouseMover]::GetCurrentPosition()
        Write-MouseLog "Current mouse position: ($($currentPos.X), $($currentPos.Y))" -Level "Debug"
        
        # Calculate safe movement bounds
        $bounds = Get-SafeMovementBounds -CurrentX $currentPos.X -Distance $MoveDistance
        
        # Move right
        $rightTarget = $bounds.Right
        Write-MouseLog "Moving right to X: $rightTarget" -Level "Info"
        
        if (Move-MouseSmoothly -StartX $currentPos.X -StartY $currentPos.Y -EndX $rightTarget -EndY $currentPos.Y -DurationMs $MoveDurationMs) {
            $script:Stats.RightMoves++
            $script:Stats.TotalMoves++
        }
        
        # Wait random interval
        $waitTime = Get-Random -Minimum $MinIntervalSeconds -Maximum $MaxIntervalSeconds
        Write-MouseLog "Waiting $waitTime seconds before moving left..." -Level "Debug"
        
        # Sleep with statistics updates
        $remainingTime = $waitTime
        while ($remainingTime -gt 0) {
            $sleepChunk = [Math]::Min(10, $remainingTime)
            Start-Sleep -Seconds $sleepChunk
            $remainingTime -= $sleepChunk
            
            # Show statistics every 5 minutes (300 seconds)
            $statisticsInterval += $sleepChunk
            if ($statisticsInterval -ge 300) {
                Show-MouseStats
                $statisticsInterval = 0
            }
        }
        
        # Get updated position (user might have moved mouse)
        $currentPos = [MouseMover]::GetCurrentPosition()
        $bounds = Get-SafeMovementBounds -CurrentX $currentPos.X -Distance $MoveDistance
        
        # Move left
        $leftTarget = $bounds.Left
        Write-MouseLog "Moving left to X: $leftTarget" -Level "Info"
        
        if (Move-MouseSmoothly -StartX $currentPos.X -StartY $currentPos.Y -EndX $leftTarget -EndY $currentPos.Y -DurationMs $MoveDurationMs) {
            $script:Stats.LeftMoves++
            $script:Stats.TotalMoves++
        }
        
        # Wait again before next cycle
        $waitTime = Get-Random -Minimum $MinIntervalSeconds -Maximum $MaxIntervalSeconds
        Write-MouseLog "Waiting $waitTime seconds before next cycle..." -Level "Debug"
        Start-Sleep -Seconds $waitTime
    }
}
catch [System.Management.Automation.PipelineStoppedException] {
    Write-MouseLog "Script stopped by user (CTRL+C)" -Level "Info"
}
catch {
    Write-MouseLog "Unexpected error: $($_.Exception.Message)" -Level "Error"
}
finally {
    Show-MouseStats
    Write-MouseLog "Mouse Movement Simulator stopped" -Level "Info"
}
