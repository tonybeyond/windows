#Requires -Version 5.1
param(
    [int]$MinSeconds = 5,
    [int]$MaxSeconds = 60
)

Add-Type -AssemblyName System.Windows.Forms

$keystrokes = @("^{CTRL}", "+{SHIFT}", "{F15}")

Write-Host "Simple Activity Simulator Started - Press CTRL+C to stop" -ForegroundColor Green
Write-Host "Interval: $MinSeconds-$MaxSeconds seconds" -ForegroundColor Yellow

try {
    while ($true) {
        # Random keystroke
        $key = $keystrokes | Get-Random
        $keyName = switch ($key) {
            "^{CTRL}" { "CTRL" }
            "+{SHIFT}" { "SHIFT" }
            "{F15}" { "F15" }
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Sending $keyName" -ForegroundColor White
        [System.Windows.Forms.SendKeys]::SendWait($key)
        
        # Random wait
        $waitTime = Get-Random -Minimum $MinSeconds -Maximum $MaxSeconds
        Write-Host "Next keystroke in $waitTime seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $waitTime
    }
}
catch {
    Write-Host "`nStopped" -ForegroundColor Red
}
