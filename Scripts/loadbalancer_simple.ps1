# ==============================================================================
# LOAD BALANCER - SIMPLIFIED VERSION
# ==============================================================================

param([int]$Port = 50000)

# ============ CONFIGURATION ============
# For LOCAL TEST (same PC):
# $PC_POOL = @(
#     @{ ip = "127.0.0.1"; port = 3000; name = "PC1" }
# )
# $SIGNALING_SERVER_IP = "127.0.0.1"

# For NETWORK (multiple PCs) - Uncomment and update:
$pc_pool = @(
    @{ ip = "192.168.0.38"; port = 3000; name = "PC1" }  # Local IP (same network)
)
$SIGNALING_SERVER_IP = "118.179.200.164"  # Server's public IP
# =======================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LOAD BALANCER (Port $Port)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Managing $($PC_POOL.Count) PCs" -ForegroundColor Green

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")

# Cooldown tracker to prevent double-starts (browser retries)
$lastStartTime = [DateTime]::MinValue


try {
    $listener.Start()
    Write-Host "Listener started!" -ForegroundColor Green
    Write-Host "Visit: http://127.0.0.1:$Port" -ForegroundColor Yellow
    Write-Host ""

    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        if ($path -eq "/favicon.ico") {
            $response.StatusCode = 404
            $response.Close()
            continue
        }
        
        # New Status Handler - Just checks status of all PCs without starting
        if ($path -eq "/status") {
            $poolStatus = @()
            foreach ($pc in $PC_POOL) {
                try {
                    $s = Invoke-RestMethod -Uri "http://$($pc.ip):$($pc.port)/status" -TimeoutSec 2
                    $poolStatus += $s
                } catch {
                    $poolStatus += @{ pc_name = $pc.name; status = "unreachable"; error = $_.Exception.Message }
                }
            }
            $json = $poolStatus | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        # STRICT CHECK: Only allow "/" to start the game
        # Any other path (e.g. apple-touch-icon, etc.) gets 404
        if ($path -ne "/") {
            $response.StatusCode = 404
            $response.Close()
            continue
        }

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Start Request from $($request.RemoteEndPoint)" -ForegroundColor Cyan
        
        # COOLDOWN CHECK: If we just started a PC < 5 seconds ago, ignore this request
        # This fixes the "Double Browser Request" issue
        if (((Get-Date) - $lastStartTime).TotalSeconds -lt 5) {
            Write-Host "  Ignored: Cooldown active" -ForegroundColor DarkGray
            $response.StatusCode = 429 # Too Many Requests
            $html = "<html><head><meta http-equiv='refresh' content='2'></head><body><h1>Please wait...</h1><p>System is processing.</p></body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        # Find available PC
        $availablePC = $null
        # Debug: Track errors
        $debugErrors = @()

        foreach ($pc in $PC_POOL) {
            try {
                Write-Host "  Checking $($pc.name)..." -ForegroundColor Gray
                $status = Invoke-RestMethod -Uri "http://$($pc.ip):$($pc.port)/status" -TimeoutSec 5
                if ($status.status -eq "idle") {
                    $availablePC = $pc
                    Write-Host "  $($pc.name) is available!" -ForegroundColor Green
                    break
                } else {
                    $debugErrors += "$($pc.name): Busy (Status: $($status.status))"
                }
            } catch {
                $err = "Cannot reach $($pc.name): $($_.Exception.Message)"
                Write-Host "  $err" -ForegroundColor Red
                $debugErrors += $err
            }
        }
        
        if ($null -eq $availablePC) {
            Write-Host "  No PCs available!" -ForegroundColor Red
            
            $errorHtml = $debugErrors -join "<br>"
            
            $html = @"
<!DOCTYPE html>
<html>
<head><title>No PCs Available</title></head>
<body style="font-family: Arial; text-align: center; padding-top: 50px;">
    <h1>All PCs are busy or unreachable</h1>
    <div style="color: red; background: #ffeeee; padding: 15px; margin: 20px auto; max-width: 600px; border-radius: 5px;">
        <strong>Debug Info:</strong><br>
        $errorHtml
    </div>
    <p>Please try again...</p>
    <script>setTimeout(() => location.reload(), 5000);</script>
</body>
</html>
"@
        }
        else {
            Write-Host "  Starting UE on $($availablePC.name)..." -ForegroundColor Green
            $lastStartTime = Get-Date
            
            try {
                $startResult = Invoke-RestMethod -Uri "http://$($availablePC.ip):$($availablePC.port)/start" -Method Post -TimeoutSec 5
                Start-Sleep -Seconds 2
                
                $streamUrl = "http://${SIGNALING_SERVER_IP}/?StreamerId=$($availablePC.name)&AgentIP=$($availablePC.ip)&AgentPort=$($availablePC.port)"
                Write-Host "  Redirecting to: $streamUrl" -ForegroundColor Yellow
                
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Starting Stream</title>
    <meta http-equiv="refresh" content="2;url=$streamUrl">
</head>
<body style="font-family: Arial; text-align: center; padding-top: 100px;">
    <h1>Starting UE on $($availablePC.name)</h1>
    <p>Connecting to stream...</p>
    <p><a href="$streamUrl">Click here if not redirected</a></p>
</body>
</html>
"@
            } catch {
                Write-Host "  Failed to start: $($_.Exception.Message)" -ForegroundColor Red
                $html = "<html><body><h1>Error</h1><p>Failed to start instance</p></body></html>"
            }
        }
        
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Loadbalancer stopped." -ForegroundColor Green
}