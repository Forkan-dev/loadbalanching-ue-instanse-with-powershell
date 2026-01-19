# Centralized Orchestration Setup

## Architecture
```
Client Browser → Orchestrator (Signaling PC) → Finds Free PC → Starts UE → Redirects Client
```

## Setup Steps

### 1. On Each Gaming PC (PC1, PC2, PC3, etc.)

Run the agent:
```powershell
.\Scripts\pc_agent.ps1
```

This agent:
- Listens on port 9000
- Waits for commands to start/stop UE
- Automatically uses PC name as StreamerId

### 2. On Signaling Server PC

**Edit the PC pool in `orchestrator.ps1`:**
```powershell
$PC_POOL = @(
    @{ ip = "192.168.1.50"; port = 9000; name = "PC1" }
    @{ ip = "192.168.1.51"; port = 9000; name = "PC2" }
    @{ ip = "192.168.1.52"; port = 9000; name = "PC3" }
)
```

**Run the orchestrator:**
```powershell
.\Scripts\orchestrator.ps1
```

### 3. Client Access

Clients visit:
```
http://YOUR-SIGNALING-SERVER-IP:3000/request-stream
```

**What happens:**
1. Orchestrator finds an idle PC
2. Sends API call to start UE on that PC
3. Auto-redirects client to stream

## API Endpoints

### PC Agent (Each Gaming PC - Port 9000)
- `GET /status` - Check if PC is idle or running
- `POST /start` - Start UE instance
- `POST /stop` - Stop UE instance

### Orchestrator (Signaling PC - Port 3000)
- `GET /request-stream` - Request a gaming session (auto-assigns PC)

## Testing

**Test PC agent:**
```powershell
# Check status
Invoke-RestMethod http://192.168.1.50:9000/status

# Start instance
Invoke-RestMethod http://192.168.1.50:9000/start -Method Post

# Stop instance
Invoke-RestMethod http://192.168.1.50:9000/stop -Method Post
```

**Test orchestrator:**
```
Open browser: http://localhost:3000/request-stream
```

## Flow Example

1. **Client 1** visits `http://signaling-server:3000/request-stream`
   - Orchestrator assigns **PC1**
   - Starts UE on PC1
   - Redirects to stream (StreamerId: PC1)

2. **Client 2** visits `http://signaling-server:3000/request-stream`
   - Orchestrator sees PC1 is busy
   - Assigns **PC2**
   - Starts UE on PC2
   - Redirects to stream (StreamerId: PC2)

3. Both clients play simultaneously on different PCs!

## Simple & Professional ✓
- No manual scripts per PC
- Automatic PC assignment
- Load balancing
- Remote control via API
- Clean architecture
