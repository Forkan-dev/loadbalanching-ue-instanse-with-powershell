# Auto-Stop on Disconnect - Setup Instructions

## What This Does
Automatically stops the UE instance when a user closes their browser tab or window.

## Files Modified/Created
1. ✅ `Scripts/agent_simple.ps1` - Added heartbeat endpoint and auto-stop logic
2. ✅ `Scripts/loadbalancer_simple.ps1` - Passes agent IP/port in URL
3. ✅ `PixelStreamingInfrastructure/SignallingWebServer/www/auto-stop.js` - JavaScript for browser

## Setup Steps

### 1. Copy auto-stop.js to your actual signaling server
```powershell
# Copy the file to your server's www folder
Copy-Item "D:\work-station\TestUE_File\PixelStreamingInfrastructure\SignallingWebServer\www\auto-stop.js" `
          "D:\work-station\TestUE_File\Windows\VideoTest\Samples\PixelStreaming\WebServers\SignallingWebServer\www\auto-stop.js"
```

### 2. Add the script to your player.html
Find your player HTML file and add this line before `</body>`:
```html
<script src="auto-stop.js"></script>
```

**Location options:**
- If using custom frontend: Edit your player.html
- If using default: You may need to rebuild the frontend with the script included
- **Quick solution**: Add inline script (see below)

### Quick Alternative (No HTML editing needed)
If you can't easily modify player.html, create a custom redirect page:

```powershell
# Edit: Windows\VideoTest\Samples\PixelStreaming\WebServers\SignallingWebServer\www\index.html
# Or create a new landing page that loads the script before redirecting
```

## How It Works
1. **Browser opens** → URL contains `?StreamerId=PC1&agent_ip=192.168.0.38&agent_port=3000`
2. **auto-stop.js loads** → Starts sending heartbeat every 5s to agent
3. **Agent receives heartbeat** → Keeps UE running
4. **Browser closes** → Stops heartbeat + sends `/stop` command
5. **Agent detects** → Either receives stop command OR heartbeat timeout (15s) → Kills UE

## Testing
1. Start agent: `.\agent_simple.ps1`
2. Start loadbalancer: `.\loadbalancer_simple.ps1`
3. Open browser → Connect to stream
4. Close tab → Watch agent console → Should see "Auto-stopping UE"

## Configuration
Edit timeout in `agent_simple.ps1`:
```powershell
$AUTO_STOP_TIMEOUT = 15  # Seconds without heartbeat before auto-stop
```

## Troubleshooting
**Heartbeat not working?**
- Check browser console for CORS errors
- Verify agent IP is accessible from browser
- Check firewall allows port 3000

**UE not stopping?**
- Check agent console for heartbeat messages
- Verify 15s timeout is appropriate for your network
- Check if `/stop` endpoint is being called
