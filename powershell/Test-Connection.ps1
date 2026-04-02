# PingMonitor.ps1
# Continuous ping for 24 hours
# Logs every ping to a full log
# Logs drops / latency spikes / large jumps to a separate alert log

# ---------------- CONFIG ----------------
$Targets = [ordered]@{
    "Gateway"    = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
                    Where-Object { $_.NextHop -match '^\d+\.\d+\.\d+\.\d+$' } |
                    Sort-Object RouteMetric |
                    Select-Object -First 1 -ExpandProperty NextHop)
    "Cloudflare" = "1.1.1.1"
    "Google"     = "8.8.8.8"
}

$DurationHrs   = 24
$PingInterval  = 1      # seconds between loops
$LatencyDelta  = 100    # ms jump from previous ping to mark as spike
$HighLatencyMs = 200    # absolute latency threshold
$LogDir        = "C:\Tools\Logs"
$FullLog       = Join-Path $LogDir "PingFullLog.txt"
$AlertLog      = Join-Path $LogDir "PingAlerts.txt"

# ---------------- INIT ----------------
$EndTime = (Get-Date).AddHours($DurationHrs)
$PrevLatency = @{}
foreach ($name in $Targets.Keys) {
    $PrevLatency[$name] = $null
}

if (!(Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

Remove-Item $FullLog -ErrorAction SilentlyContinue
Remove-Item $AlertLog -ErrorAction SilentlyContinue

function Write-FullLog {
    param([string]$Message)
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" |
        Out-File -FilePath $FullLog -Append -Encoding UTF8
}

function Write-AlertLog {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    $line | Out-File -FilePath $AlertLog -Append -Encoding UTF8
    Write-Host $line
}

Write-FullLog  "Ping Monitor Started"
Write-AlertLog "Ping Monitor Started"
Write-FullLog  "Targets: $(($Targets.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')"
Write-AlertLog "Targets: $(($Targets.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')"

# ---------------- MAIN LOOP ----------------
while ((Get-Date) -lt $EndTime) {
    $results = @{}

    foreach ($name in $Targets.Keys) {
        $ip = $Targets[$name]

        try {
            $reply   = Test-Connection -ComputerName $ip -Count 1 -ErrorAction Stop
            $latency = [math]::Round(($reply | Select-Object -First 1).Latency, 2)
            $results[$name] = $latency

            # Log every successful ping
            Write-FullLog "[$name] Success - $ip - ${latency}ms"

            # High latency alert
            if ($latency -ge $HighLatencyMs) {
                Write-AlertLog "[$name] HIGH LATENCY - $ip - ${latency}ms"
            }

            # Large jump alert compared to previous latency
            if ($PrevLatency[$name] -ne $null -and
                [math]::Abs($latency - $PrevLatency[$name]) -ge $LatencyDelta) {
                Write-AlertLog "[$name] LATENCY JUMP - $ip - Prev: $($PrevLatency[$name]) ms, Current: $latency ms"
            }

            $PrevLatency[$name] = $latency
        }
        catch {
            $results[$name] = $null

            # Log failure in both logs
            Write-FullLog  "[$name] FAILED - $ip"
            Write-AlertLog "[$name] DROP - Ping failed to $ip"

            $PrevLatency[$name] = $null
        }
    }

    # ---------------- DIAGNOSIS ----------------
    $gwOk = $results["Gateway"] -ne $null
    $cfOk = $results["Cloudflare"] -ne $null
    $gOk  = $results["Google"] -ne $null

    if (-not $gwOk) {
        Write-AlertLog "[DIAGNOSIS] Local network issue - gateway unreachable"
    }
    elseif ($gwOk -and (-not $cfOk) -and (-not $gOk)) {
        Write-AlertLog "[DIAGNOSIS] WAN/ISP issue - gateway reachable but internet unreachable"
    }
    elseif ($gwOk -and ((-not $cfOk) -or (-not $gOk))) {
        $failed = @("Cloudflare", "Google") | Where-Object { $results[$_] -eq $null }
        Write-AlertLog "[DIAGNOSIS] Partial internet issue - failed: $($failed -join ', ')"
    }

    Start-Sleep -Seconds $PingInterval
}

Write-FullLog  "Ping Monitor Ended"
Write-AlertLog "Ping Monitor Ended"