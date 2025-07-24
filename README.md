# SkyPilot Nix Flake

A Nix flake for [SkyPilot](https://github.com/skypilot-org/skypilot) - Run LLMs and AI on any Cloud.

This flake provides SkyPilot v0.9.3 with automatic updates, development environment, and code formatting tools.

## 🚀 Quick Start

### Install SkyPilot

```bash
# Build and install SkyPilot
nix build .#skypilot
./result/bin/sky --version

# Or run directly without installing
nix run .#skypilot -- --version
```

### Development Environment

```bash
# Enter development shell with SkyPilot and dev tools
nix develop

# Available tools in dev shell:
# - sky (SkyPilot CLI)
# - python, pip
# - black, flake8, pytest, mypy
```

### Code Formatting

```bash
# Format Nix and Python files
nix fmt
```

## 📦 What's Included

### Packages
- **`packages.default`** / **`packages.skypilot`**: SkyPilot CLI and Python library
- Compatible with all systems (Linux, macOS, both x86_64 and ARM64)

### Development Shell
- **Python 3.13** with full SkyPilot installation
- **Development tools**: black, flake8, pytest, mypy
- **Package management**: pip, setuptools, wheel

### Formatter
- **nixpkgs-fmt**: Format Nix files
- **black**: Format Python files  
- **isort**: Sort Python imports

## 🔄 Automatic Updates

This flake includes an automated update script that fetches the latest SkyPilot release:

```bash
# Update to latest SkyPilot version
./update.sh
```

The script will:
1. ✅ Check for the latest GitHub release
2. ✅ Update version and calculate new hash automatically
3. ✅ Verify the build works before committing changes
4. ✅ Rollback on any errors
5. ✅ Update flake.lock file

**No manual hash updates required!** The script handles everything programmatically.

## 🛠️ Usage Examples

### Basic Usage

```bash
# Check SkyPilot version
nix run .#skypilot -- --version

# Get help
nix run .#skypilot -- --help

# Launch a cluster (requires cloud credentials)
nix run .#skypilot -- launch --help
```

### Development Workflow

```bash
# Enter dev environment
nix develop

# Test your SkyPilot configurations
sky check

# Run your own SkyPilot tasks
sky launch my-task.yaml

# Format code before committing
exit  # Leave dev shell
nix fmt
```

### Building from Source

```bash
# Build the package
nix build .#skypilot

# Check build outputs
ls -la result/

# Run the built binary
./result/bin/sky --version
```

## 📋 Requirements

- **Nix** with flakes enabled
- **Internet connection** for GitHub API access (update script)
- **Cloud credentials** configured for SkyPilot usage

### Enable Nix Flakes

Add to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

## 🔧 Configuration

### Customizing Dependencies

The package dependencies are organized by category in `flake.nix`:

```nix
propagatedBuildInputs = with pkgs.python3Packages; [
  # Async I/O and web framework dependencies
  aiofiles fastapi httpx pydantic python-multipart uvicorn
  
  # Core utilities  
  cachetools click colorama cryptography filelock jinja2
  jsonschema packaging python-dotenv pyyaml requests rich
  setproctitle tabulate typing-extensions wheel
  
  # Data processing and optimization
  networkx pandas pendulum prettytable psutil pulp
];
```

### Development Tools

Modify the `devShells.default` section to add additional development tools:

```nix
buildInputs = with pkgs; [
  # Add your preferred tools here
  python3Packages.ipython  # Interactive Python shell
  python3Packages.jupyter  # Jupyter notebooks
  # ... etc
];
```

## 🤝 Contributing

1. **Make changes** to `flake.nix` or other files
2. **Format code**: `nix fmt`
3. **Test builds**: `nix flake check`
4. **Update if needed**: `./update.sh`

## 📄 License

This flake configuration is provided under the same license as SkyPilot (Apache 2.0).

SkyPilot itself is developed by the SkyPilot team and available at: https://github.com/skypilot-org/skypilot

## 🔗 Links

- **SkyPilot Documentation**: https://skypilot.readthedocs.io/
- **SkyPilot GitHub**: https://github.com/skypilot-org/skypilot
- **Nix Flakes Manual**: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html

---

> **Note**: This is an unofficial Nix flake for SkyPilot. For official support, please refer to the SkyPilot project documentation.