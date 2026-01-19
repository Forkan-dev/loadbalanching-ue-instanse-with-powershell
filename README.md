# Pixel Streaming Infrastructure Project

This repository contains the full infrastructure and supporting scripts for Unreal Engine Pixel Streaming, including orchestration, signalling, SFU, frontend, and testing tools.

## Structure

- **PixelStreamingInfrastructure/**: Main infrastructure and orchestration scripts for Pixel Streaming.
  - **Common/**: Shared TypeScript code, protobuf definitions, and utilities.
  - **Extras/**: Additional tools, tests, and scripts.
  - **Frontend/**: Frontend UI, libraries, and implementations.
  - **Matchmaker/**: Matchmaking service for streamers and clients.
  - **SFU/**: Selective Forwarding Unit for media relay.
  - **Signalling/**: Signalling server for WebRTC connections.
  - **SignallingWebServer/**: Web server for signalling and API endpoints.
- **Scripts/**: PowerShell scripts for orchestration, load balancing, and testing.
- **Windows/**: Windows-specific binaries and manifests.
- **Docs/**: Guides, migration notes, and security documentation.

## Key Features

- End-to-end Pixel Streaming infrastructure for Unreal Engine
- Modular TypeScript codebase for backend services
- Docker support for deployment and testing
- Playwright-based frontend testing
- Comprehensive documentation and migration guides

## Getting Started

1. Clone the repository:
   ```sh
   git clone <repo-url>
   ```
2. Install dependencies for each service (example for Common):
   ```sh
   cd PixelStreamingInfrastructure/Common
   npm install
   ```
3. See individual README files in each subfolder for service-specific setup and usage.

## Documentation

- See `PixelStreamingInfrastructure/README.md` for orchestration and infrastructure details.
- See `PixelStreamingInfrastructure/Common/README.md` for shared code and protobuf usage.
- See `Docs/` for migration guides and security guidelines.

## License

See `PixelStreamingInfrastructure/LICENSE.md` for license information.

---

For more details, refer to the documentation in each subfolder or open an issue for support.