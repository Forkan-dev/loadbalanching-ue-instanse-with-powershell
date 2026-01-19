# ==============================================================================
# SIMPLE START - Just launch VideoTest.exe with Pixel Streaming
# ==============================================================================

$UE_PATH = "D:\work station\TestUE_File\Windows\VideoTest.exe"
$SIGNALING_SERVER_IP = "127.0.0.1"
$SIGNALING_PORT = 8888
$STREAMER_ID = "PC1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting VideoTest with Pixel Streaming" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Signaling Server: ws://${SIGNALING_SERVER_IP}:${SIGNALING_PORT}" -ForegroundColor Green
Write-Host "Streamer ID: $STREAMER_ID" -ForegroundColor Green
Write-Host ""
Write-Host "After VideoTest starts, visit:" -ForegroundColor Yellow
Write-Host "http://${SIGNALING_SERVER_IP}" -ForegroundColor Yellow
Write-Host ""

# Start UE instance
$arguments = @(
    "-PixelStreamingURL=ws://${SIGNALING_SERVER_IP}:${SIGNALING_PORT}",
    "-PixelStreamingID=$STREAMER_ID",
    "-RenderOffScreen"
)

Write-Host "Launching VideoTest.exe..." -ForegroundColor Green
Start-Process $UE_PATH -ArgumentList $arguments

Write-Host "VideoTest.exe launched!" -ForegroundColor Green
Write-Host ""
Write-Host "Wait 5-10 seconds for connection, then visit:" -ForegroundColor Yellow
Write-Host "http://${SIGNALING_SERVER_IP}" -ForegroundColor Cyan
