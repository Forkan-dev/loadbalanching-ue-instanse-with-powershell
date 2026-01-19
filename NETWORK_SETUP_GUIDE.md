# Multi-PC Load Balancing Setup Guide

## Overview
This guide explains how to set up load balancing across multiple PCs where:
- **SERVER PC**: Runs signaling server + loadbalancer (orchestrator)
- **GAMING PCs** (PC1, PC2, PC3...): Run UE instances + agent

---

## Prerequisites
- All PCs must be on the same network
- Windows Firewall must allow ports: 3000, 8888, 50000, 80
- All PCs must have the VideoTest files installed

---

## Step 1: Find Your SERVER PC's IP Address

On the **SERVER PC**, open PowerShell and run:
```powershell
ipconfig
```

Look for **IPv4 Address** (e.g., `192.168.1.100`)

**Write down this IP - you'll need it everywhere!**

---

## Step 2: Configure SERVER PC

### A. Edit `loadbalancer_simple.ps1`

Open: `Scripts\loadbalancer_simple.ps1`

**Find these lines (around line 5-10):**
```powershell
# For LOCAL TEST (same PC):
$PC_POOL = @(
    @{ ip = "127.0.0.1"; port = 3000; name = "PC1" }
)
$SIGNALING_SERVER_IP = "127.0.0.1"
```

**Comment them out and uncomment the network section:**
```powershell
# For LOCAL TEST (same PC):
# $PC_POOL = @(
#     @{ ip = "127.0.0.1"; port = 3000; name = "PC1" }
# )
# $SIGNALING_SERVER_IP = "127.0.0.1"

# For NETWORK (multiple PCs) - Uncomment and update:
$PC_POOL = @(
    @{ ip = "192.168.1.101"; port = 3000; name = "PC1" },
    @{ ip = "192.168.1.102"; port = 3000; name = "PC2" },
    @{ ip = "192.168.1.103"; port = 3000; name = "PC3" }
)
$SIGNALING_SERVER_IP = "192.168.1.100"  # Your SERVER PC's IP
```

**Update:**
- Change IPs to match your GAMING PCs' actual IP addresses
- Change `$SIGNALING_SERVER_IP` to your SERVER PC's IP (from Step 1)
- Add/remove PCs from the pool as needed

### B. Configure Signaling Server

Open: `Windows\VideoTest\Samples\PixelStreaming\WebServers\SignallingWebServer\config.json`

**Change:**
```json
{
  "UseFrontend": false,
  "UseMatchmaker": false,
  "UseHTTPS": false,
  "LogToFile": true,
  "HomepageFile": "player.html",
  "AdditionalRoutes": {},
  "EnableWebserver": true,
  "HttpPort": 80,
  "StreamerPort": 8888,
  "SFUPort": 8889
}
```

**Key settings:**
- `HttpPort: 80` - Main web interface
- `StreamerPort: 8888` - UE instances connect here

---

## Step 3: Configure GAMING PCs (PC1, PC2, PC3...)

### A. Copy Files to Each Gaming PC

Copy these files to each gaming PC:
- `Scripts\agent_simple.ps1`
- `Windows\VideoTest.exe` (entire VideoTest folder)

### B. Edit `agent_simple.ps1` on EACH Gaming PC

Open: `Scripts\agent_simple.ps1`

**Find these lines (around line 5-10):**
```powershell
# For LOCAL TEST (same PC):
$SIGNALING_SERVER_IP = "127.0.0.1"
$PC_NAME = "PC1"
```

**Comment them out and uncomment the network section:**
```powershell
# For LOCAL TEST (same PC):
# $SIGNALING_SERVER_IP = "127.0.0.1"
# $PC_NAME = "PC1"

# For NETWORK (multiple PCs) - Uncomment and update:
$SIGNALING_SERVER_IP = "192.168.1.100"  # Your SERVER PC's IP
$PC_NAME = "PC1"  # Change to PC2, PC3 on other machines
```

**Update:**
- Change `$SIGNALING_SERVER_IP` to your SERVER PC's IP (from Step 1)
- Change `$PC_NAME` to match the PC:
  - First gaming PC: `"PC1"`
  - Second gaming PC: `"PC2"`
  - Third gaming PC: `"PC3"`

### C. Update UE_PATH if Needed

If VideoTest.exe is in a different location, update line 3:
```powershell
$UE_PATH = "D:\work-station\TestUE_File\Windows\VideoTest.exe"
```

---

## Step 4: Configure Windows Firewall

### On SERVER PC:
Open PowerShell **as Administrator** and run:
```powershell
New-NetFirewallRule -DisplayName "LoadBalancer" -Direction Inbound -LocalPort 50000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SignalingServer-HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SignalingServer-WS" -Direction Inbound -LocalPort 8888 -Protocol TCP -Action Allow
```

### On EACH Gaming PC:
Open PowerShell **as Administrator** and run:
```powershell
New-NetFirewallRule -DisplayName "Agent" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

---

## Step 5: Start Everything

### On SERVER PC:

**Terminal 1 - Start Signaling Server:**
```powershell
cd D:\work-station\TestUE_File\Windows\VideoTest\Samples\PixelStreaming\WebServers\SignallingWebServer\
node cirrus.js
```
Wait for: `Streamer listening on port 8888`

**Terminal 2 - Start Loadbalancer (as Administrator):**
```powershell
cd D:\work-station\TestUE_File\Scripts
.\loadbalancer_simple.ps1
```
Wait for: `Listener started!`

### On EACH Gaming PC:

**Start Agent (as Administrator):**
```powershell
cd D:\work-station\TestUE_File\Scripts
.\agent_simple.ps1
```
Wait for: `Listener started!`

---

## Step 6: Test It!

### From Any PC on the Network:

Open browser and go to:
```
http://192.168.1.100:50000
```
(Use your SERVER PC's IP)

**What happens:**
1. Loadbalancer finds an idle gaming PC
2. Sends start command to the agent on that PC
3. Agent launches VideoTest.exe
4. VideoTest connects to signaling server
5. Browser redirects to the stream
6. You see the UE stream!

Multiple clients can connect - each gets assigned to an available PC!

---

## Verification Checklist

- [ ] All PCs can ping each other
- [ ] Firewall rules are added
- [ ] Server PC IP is correct in all scripts
- [ ] PC_NAME is unique on each gaming PC (PC1, PC2, PC3)
- [ ] Signaling server shows "Streamer listening on port 8888"
- [ ] Loadbalancer shows "Listener started!"
- [ ] Each agent shows "Listener started!"
- [ ] Accessing http://SERVER_IP:50000 redirects to stream

---

## Troubleshooting

### "Cannot reach PC1/PC2/PC3" in loadbalancer
- Check gaming PC agent is running
- Verify firewall allows port 3000 on gaming PC
- Ping the gaming PC from server PC
- Check IP addresses in loadbalancer config

### Browser loads forever
- Check signaling server is running (port 8888)
- Verify firewall allows port 80 and 8888 on server PC
- Check agent received the /start command

### UE doesn't start
- Check UE_PATH in agent_simple.ps1 is correct
- Verify VideoTest.exe exists on gaming PC
- Check agent terminal for error messages

### Stream connects but black screen
- Wait 10-15 seconds for UE to fully load
- Check signaling server terminal for connections
- Verify SIGNALING_SERVER_IP is correct in agent script

---

## Port Reference

| Port  | Purpose              | Runs On        | Firewall |
|-------|---------------------|----------------|----------|
| 80    | Web interface       | SERVER PC      | Allow    |
| 3000  | Agent API           | GAMING PCs     | Allow    |
| 8888  | Signaling WebSocket | SERVER PC      | Allow    |
| 50000 | Loadbalancer        | SERVER PC      | Allow    |

---

## Quick Commands

### Check if port is listening:
```powershell
netstat -ano | findstr :3000
```

### Test agent connectivity:
```powershell
Invoke-WebRequest -Uri "http://192.168.1.101:3000/status"
```

### Stop all UE instances:
```powershell
Get-Process VideoTest -ErrorAction SilentlyContinue | Stop-Process -Force
```
