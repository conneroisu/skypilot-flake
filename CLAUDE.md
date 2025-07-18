# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides a comprehensive Nix flake for SkyPilot, a framework for running LLMs, AI, and batch jobs on any cloud. The project includes:

1. **SkyPilot Package**: Complete Nix package with all 28 required dependencies
2. **Development Environment**: Full dev shell with Python tools and SkyPilot CLI
3. **Automatic Updates**: Script that fetches latest releases and updates hashes programmatically
4. **NixOS Module**: Configurable system service integration for SkyPilot
5. **VM Testing**: Comprehensive NixOS tests for module validation
6. **Code Formatting**: Multi-language formatter (Nix, Python)

## Key Commands

### Essential Development Commands

```bash
# Build SkyPilot package
nix build .#skypilot --cores 4 --max-jobs 4

# Enter development environment with all tools
nix develop

# Update to latest SkyPilot version automatically
./update.sh

# Format all code (Nix, Python)
nix fmt

# Run comprehensive tests
nix flake check --cores 4 --max-jobs 4
```

### Testing and Validation

```bash
# Run simple NixOS module test
nix build .#checks.x86_64-linux.skypilot-simple --cores 4 --max-jobs 4

# Run comprehensive module tests (currently disabled due to config issues)
# nix build .#checks.x86_64-linux.skypilot-module --cores 4 --max-jobs 4

# Test SkyPilot functionality
nix run .#skypilot -- --version
nix run .#skypilot -- --help
```

### Module Development

```bash
# Test NixOS module in VM
nixos-rebuild build-vm --flake .#

# Validate module configuration options
nix eval .#nixosModules.default
```

## Architecture

### Core Structure

- **`flake.nix`**: Main flake definition with SkyPilot package, dev shell, and formatter
- **`update.sh`**: Automated update script with error handling and rollback
- **`nixos-modules/skypilot/`**: NixOS service module for system integration
- **`tests/`**: NixOS VM tests for module validation

### Package Definition Architecture

The SkyPilot package in `flake.nix` follows a multi-layered dependency structure:

1. **Async I/O Layer**: aiofiles, fastapi, httpx, pydantic, uvicorn
2. **Core Utilities**: click, colorama, cryptography, jinja2, requests, rich
3. **Data Processing**: networkx, pandas, pendulum, psutil, pulp

Dependencies are kept in sync with `sky/setup_files/dependencies.py` from upstream.

### NixOS Module Architecture

The module (`nixos-modules/skypilot/default.nix`) provides:

- **Service Management**: Systemd services for web UI, cluster manager, monitoring
- **Configuration**: YAML config generation with cloud provider settings
- **Security**: User isolation, file permissions, optional sudo rules
- **Monitoring**: Metrics collection and logging services
- **Networking**: Firewall integration and port management

### Update System

The `update.sh` script implements a robust update workflow:

1. **Version Detection**: GitHub API integration for latest release detection
2. **Hash Calculation**: Automatic SRI hash generation using `nix-prefetch-url`
3. **Validation**: Build verification before committing changes
4. **Error Recovery**: Automatic rollback on failure with backup/restore

## Important Implementation Details

### Core Constraints

- **Resource Limits**: Always use `--cores 4 --max-jobs 4` for builds to prevent resource exhaustion
- **Hash Format**: Use SRI format (`sha256-...`) for all source hashes
- **Python Version**: Package targets Python 3.13 from nixos-unstable

### Module Configuration Patterns

When modifying the NixOS module:

1. **Conditional Configuration**: Use `mkIf` with proper conditions to avoid accessing undefined options
2. **Service Dependencies**: Web UI and monitoring services depend on `network.target`
3. **File Permissions**: Configuration files use mode `0644`, directories use `0755`
4. **User Management**: All services run under dedicated `skypilot` user with proper group isolation

### Testing Considerations

- **VM Tests**: Tests run in isolated NixOS VMs with limited resources (1-4GB RAM)
- **Service Validation**: Tests verify systemd service configuration but may not start all services
- **Network Isolation**: VM tests cannot access external cloud APIs
- **Configuration Validation**: Tests focus on YAML syntax and file generation

### Known Issues and Workarounds

1. **Cluster Configuration Access**: Module accesses `cfg.cluster` options even when `enableCluster = false`
   - **Workaround**: Use conditional access with `mkIf cfg.enableCluster` for all cluster-related configuration

2. **Sudo Rules**: Security.sudo.rules can conflict with VM test environments
   - **Current Solution**: Sudo rules are commented out to avoid test failures

3. **Web UI Service**: May fail to start in VM tests due to missing cloud credentials
   - **Test Approach**: Verify service configuration rather than runtime functionality

## Development Workflow

### Making Changes

1. **Package Updates**: Modify `propagatedBuildInputs` in `flake.nix` when upstream dependencies change
2. **Module Features**: Add new options to `nixos-modules/skypilot/default.nix` with proper validation
3. **Testing**: Always run `nix flake check` before committing changes
4. **Documentation**: Update module documentation in `nixos-modules/skypilot/skypilot.md`

### Release Process

1. **Version Update**: Run `./update.sh` to get latest SkyPilot release
2. **Dependency Sync**: Verify dependencies match upstream `dependencies.py`
3. **Testing**: Validate all tests pass with new version
4. **Documentation**: Update README.md with new version numbers

The flake is designed for automatic maintenance with minimal manual intervention required.