#Requires -Version 5.1
param(
    [int]$MinSeconds = 10,
    [int]$MaxSeconds = 40,
    [int]$Distance = 50
)

# Add Windows API for mouse control
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Mouse {
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    public struct POINT { public int X; public int Y; }
}
'@

function Move-Mouse {
    param([int]$ToX, [int]$ToY, [int]$Steps = 30)
    
    $pos = New-Object Mouse+POINT
    [Mouse]::GetCursorPos([ref]$pos) | Out-Null
    
    $deltaX = ($ToX - $pos.X) / $Steps
    $deltaY = ($ToY - $pos.Y) / $Steps
    
    for ($i = 1; $i -le $Steps; $i++) {
        $newX = [int]($pos.X + $deltaX * $i)
        $newY = [int]($pos.Y + $deltaY * $i)
        [Mouse]::SetCursorPos($newX, $newY) | Out-Null
        Start-Sleep -Milliseconds 50
    }
}

Write-Host "Mini Mouse Mover Started - Press CTRL+C to stop" -ForegroundColor Green
Write-Host "Movement: $Distance pixels, Interval: $MinSeconds-$MaxSeconds seconds" -ForegroundColor Yellow

try {
    while ($true) {
        # Get current position
        $pos = New-Object Mouse+POINT
        [Mouse]::GetCursorPos([ref]$pos) | Out-Null
        
        # Move right
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Moving right..." -ForegroundColor White
        Move-Mouse -ToX ($pos.X + $Distance) -ToY $pos.Y
        
        Start-Sleep -Seconds (Get-Random -Minimum $MinSeconds -Maximum $MaxSeconds)
        
        # Move left  
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Moving left..." -ForegroundColor White
        Move-Mouse -ToX ($pos.X) -ToY $pos.Y
        
        Start-Sleep -Seconds (Get-Random -Minimum $MinSeconds -Maximum $MaxSeconds)
    }
}
catch {
    Write-Host "`nStopped" -ForegroundColor Red
}
