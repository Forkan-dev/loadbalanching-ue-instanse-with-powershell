$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:4560/")

try {
    $listener.Start()
    Write-Host "Test server running on port 4560..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

    while ($true) {
        $context = $listener.GetContext()
        $response = $context.Response
        $html = "<h1>Worker PC is reachable!</h1><p>Connection successful from: $($context.Request.RemoteEndPoint)</p>"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()
        Write-Host "Request received from: $($context.Request.RemoteEndPoint)" -ForegroundColor Cyan
    }
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Dispose()
    Write-Host "Test server stopped." -ForegroundColor Yellow
}