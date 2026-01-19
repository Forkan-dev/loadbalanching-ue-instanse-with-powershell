# ==============================================================================
# PC AGENT - SIMPLIFIED VERSION
# ==============================================================================

param([int]$Port = 3000)

$UE_PATH = "D:\work-station\TestUE_File\Windows\VideoTest.exe"

# ============ CONFIGURATION ============
# For LOCAL TEST (same PC):
# $SIGNALING_SERVER_IP = "127.0.0.1"
# $PC_NAME = "PC1"

# For NETWORK (multiple PCs) - Uncomment and update:
$SIGNALING_SERVER_IP = "118.179.200.164"  # Your SERVER PC's IP
$PC_NAME = "PC1"  # Unique identifier for this PC
# =======================================

$SIGNALING_PORT = 8888
$ueProcess = $null
$ueStartTime = $null
$AUTO_STOP_TIMEOUT = 10  # Stop UE after 10 seconds of running (for testing)
$CHECK_INTERVAL = 10  # Check every 10 seconds

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PC AGENT: $PC_NAME (Port $Port)" -ForegroundColor Cyan
Write-Host "Auto-stop: ${AUTO_STOP_TIMEOUT}s max runtime" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")

try {
    $listener.Start()
    Write-Host "Listener started!" -ForegroundColor Green
    Write-Host "Waiting for requests..." -ForegroundColor Yellow
    Write-Host ""

    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.LocalPath
        
        # Check auto-stop timeout on every request
        if ($null -ne $ueProcess -and !$ueProcess.HasExited -and $null -ne $ueStartTime) {
            $runningTime = ((Get-Date) - $ueStartTime).TotalSeconds
            if ($runningTime -gt $AUTO_STOP_TIMEOUT) {
                Write-Host "  Auto-stopping UE (running for ${runningTime}s)" -ForegroundColor Yellow
                $ueProcess.Kill()
                $ueProcess.WaitForExit(5000)
                $script:ueProcess = $null
                $script:ueStartTime = $null
            }
        }
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $path request from $($request.RemoteEndPoint)" -ForegroundColor Cyan
        
        if ($path -eq "/start") {
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($UE_PATH)
            $existingProc = Get-Process -Name $processName -ErrorAction SilentlyContinue
            
            if (($null -ne $ueProcess -and !$ueProcess.HasExited) -or ($null -ne $existingProc)) {
                $result = @{ status = "already_running"; pc_name = $PC_NAME } | ConvertTo-Json
                Write-Host "  Already running" -ForegroundColor Yellow
            }
            else {
                $arguments = "-PixelStreamingURL=ws://${SIGNALING_SERVER_IP}:${SIGNALING_PORT} -PixelStreamingID=$PC_NAME -RenderOffScreen"
                $script:ueProcess = Start-Process $UE_PATH -ArgumentList $arguments -WindowStyle Hidden -PassThru
                $script:ueStartTime = Get-Date
                Write-Host "  Started UE (PID: $($ueProcess.Id))" -ForegroundColor Green
                $result = @{ status = "started"; pc_name = $PC_NAME; pid = $ueProcess.Id } | ConvertTo-Json
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($result)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/stop") {

    	Write-Host "  Stopping all instances of VideoTestClient-Win64-Shipping.exe..." -ForegroundColor Yellow

    	cmd /c "taskkill /F /IM VideoTestClient-Win64-Shipping.exe 2>NUL"

    	# Reset internal tracking
    	$script:ueProcess = $null
    	$script:ueStartTime = $null

    	$result = @{ status = "stopped"; pc_name = $PC_NAME } | ConvertTo-Json
	}

        elseif ($path -eq "/status") {
            # Extract process name for robust checking
            $existingProc = Get-Process -Name "VideoTestClient-Win64-Shipping" -ErrorAction SilentlyContinue
            
            # Running if internal var is valid OR if we find the process in Windows
            $isRunning = ($null -ne $ueProcess -and !$ueProcess.HasExited) -or ($null -ne $existingProc)
            
            $result = @{ 
                status = if ($isRunning) { "running" } else { "idle" }
                pc_name = $PC_NAME
                pid = if ($isRunning) { 
                    if ($null -ne $ueProcess) { $ueProcess.Id } 
                    elseif ($null -ne $existingProc) { $existingProc.Id } 
                    else { $null } 
                } else { $null }
                uptime = if ($isRunning -and $null -ne $ueStartTime) { [int]((Get-Date) - $ueStartTime).TotalSeconds } else { 0 }
            } | ConvertTo-Json
            Write-Host "  Status: $(if ($isRunning) { 'running' } else { 'idle' })" -ForegroundColor Gray
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($result)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            $html = "<html><body><h1>PC Agent: $PC_NAME</h1><p>Status: Running</p></body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $listener.Stop()
    $listener.Close()
    if ($null -ne $ueProcess -and !$ueProcess.HasExited) {
        $ueProcess.Kill()
    }
    Write-Host "Agent stopped." -ForegroundColor Green
}
