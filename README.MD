## MaxiSim
### Default (5-60 seconds interval)
``` powershell
.\MaxiSim.ps1
```

### Custom interval (10-30 seconds)
``` powershell
.\MaxiSim.ps1 -MinIntervalSeconds 10 -MaxIntervalSeconds 30
```

### With debug output
``` powershell
.\MaxiSim.ps1 -Debug
```

## MiniSim
### Default (5-60 seconds)
``` powershell
.\MiniSim.ps1
```

### Custom interval (0-120 seconds)
``` powershell
.\MiniSim.ps1 -MinSeconds 0 -MaxSeconds 120
```

## MouseMouver
### Default settings (10-40 seconds, 50 pixels, 1.5 second movement)
``` powershell
.\MouseMover.ps1
```

### Custom settings
``` powershell
.\MouseMover.ps1 -MinIntervalSeconds 5 -MaxIntervalSeconds 30 -MoveDistance 100
```

### With debug output
``` powershell
.\MouseMover.ps1 -Debug
```

## MiniMouseMouver
### Default (10-40 seconds, 50 pixels)
``` powershell
.\MiniMouseMover.ps1
```

### Custom interval and distance
```
.\MiniMouseMover.ps1 -MinSeconds 15 -MaxSeconds 60 -Distance 75
```
