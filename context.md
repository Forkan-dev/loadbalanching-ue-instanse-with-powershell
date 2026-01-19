# Pixel Streaming System Architecture

## Overview
This system implements a custom **Load Balancing Solution for Unreal Engine Pixel Streaming**. It is designed to bridge a public-facing game server with a private fleet of GPU-capable worker machines, orchestrating the on-demand instantiation of Unreal Engine (UE) game sessions.

## Network Topology

The infrastructure is split between a **Public Server** (accessible via WAN) and a **Private Local Network** (LAN) hosting the worker nodes.

### 1. Public Server (The Gateway)
*   **Role**: Entry point for all web clients.
*   **IP**: `118.179.200.164` (Public)
*   **Services**:
    *   **Signaling Server**: Handles WebRTC handshaking (Node.js).
    *   **Load Balancer** (`loadbalancer_simple.ps1`): Manages user traffic and assigns worker resources.
    *   **Port 80/8888**: Signaling & WebRTC.
    *   **Port 50000** (or similar): Load Balancer HTTP listener.

### 2. Worker Nodes (The Compute)
*   **Role**: High-performance PC running the actual game instance.
*   **IP**: `192.168.0.x` (Local LAN)
*   **Services**:
    *   **Agent** (`agent_simple.ps1`): Lightweight HTTP listener on Port 3000.
    *   **Unreal Engine**: The game application running in `-RenderOffScreen` mode.
*   **Connectivity**: Must be able to reach the Public Server to stream media, but resides on the LAN.

## Component Workflow

The system follows a strict orchestrator pattern to ensure seamless user connection:

1.  **Client Request**: User visits the connection URL (e.g., `http://118.179.200.164:5502`).
2.  **Resource Check**: The **Load Balancer** queries the **Agent** on the Worker PC (LAN IP) via `http://<WorkerIP>:3000/status`.
3.  **Provisioning**:
    *   If the Worker is `idle`, the Load Balancer sends a `POST /start` command.
    *   The **Agent** launches the Unreal Engine executable app.
    *   UE connects seamlessly to the Public Signaling Server.
4.  **Handoff**:
    *   The Load Balancer constructs a unique stream URL: `http://118.179.200.164/?StreamerId=PC1`.
    *   The user is automatically redirected to this URL.
5.  **Streaming**: The user enters the gameplay session via standard Pixel Streaming WebRTC.

## Operational Logic

### Load Balancer (`loadbalancer_simple.ps1`)
*   **Loop**: Listens for incoming HTTP requests.
*   **Discovery**: Iterates through a configured `$PC_POOL` to find an available node.
*   **Error Handling**: If nodes are busy or unreachable (timeout > 5s), serves a "System Busy" page with auto-reload.

### Agent (`agent_simple.ps1`)
*   **State Management**: Tracks if the specific UE process is running (PID tracking).
*   **Start Command**: Launches the game process with specific flags:
    *   `-PixelStreamingURL`: Connects back to the Public Server.
    *   `-PixelStreamingID`: Identifies itself (e.g., "PC1").
    *   `-RenderOffScreen`: Optimizes for server-side execution.
