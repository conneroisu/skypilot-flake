# Getting Started

Get up and running with SkyPilot on Nix in minutes. This guide covers installation, basic usage, and your first cloud deployment.

## Prerequisites

- Nix with flakes enabled
- Cloud provider credentials (AWS, GCP, Azure, etc.)
- Basic familiarity with SkyPilot concepts

## Quick Installation

### Try Without Installing

The fastest way to try SkyPilot is using `nix run`:

```bash
# Check SkyPilot version
nix run github:your-org/skypilot-flake -- --version

# View help
nix run github:your-org/skypilot-flake -- --help

# Check cloud access
nix run github:your-org/skypilot-flake -- check
```

### Development Environment

Enter a complete development environment with SkyPilot and all tools:

```bash
# Clone the repository (optional)
git clone https://github.com/your-org/skypilot-flake
cd skypilot-flake

# Enter development shell
nix develop

# Or directly from GitHub
nix develop github:your-org/skypilot-flake
```

The development environment includes:
- SkyPilot CLI (`sky`)
- Python 3.13 with pip
- Development tools (black, flake8, pytest, mypy)
- Auto-update script (`./update.sh`)

### System Installation

Install SkyPilot system-wide using Nix profiles:

```bash
# Install latest version
nix profile install github:your-org/skypilot-flake

# Or install specific package
nix profile install github:your-org/skypilot-flake#skypilot
```

## First Steps

### 1. Verify Installation

```bash
sky --version
# Output: skypilot, version 0.9.3
```

### 2. Check Cloud Access

```bash
sky check
```

This command verifies your cloud credentials and shows which clouds are accessible.

### 3. Launch Your First Cluster

Create a simple task file `hello.yaml`:

```yaml
# hello.yaml
resources:
  cpus: 2

run: |
  echo "Hello from SkyPilot!"
  echo "Running on: $(hostname)"
  echo "Cloud: $(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo 'unknown')"
```

Launch the task:

```bash
sky launch hello.yaml
```

### 4. Monitor and Manage

```bash
# Check cluster status
sky status

# View logs
sky logs

# SSH into cluster
sky ssh

# Stop clusters
sky stop --all

# Clean up
sky down --all
```

## Cloud Provider Setup

### AWS

1. **Install AWS CLI** (if not using the Nix environment):
   ```bash
   nix shell nixpkgs#awscli2
   ```

2. **Configure credentials**:
   ```bash
   aws configure
   ```

3. **Verify access**:
   ```bash
   sky check aws
   ```

### Google Cloud Platform

1. **Install gcloud** (if not using the Nix environment):
   ```bash
   nix shell nixpkgs#google-cloud-sdk
   ```

2. **Authenticate**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

3. **Set project**:
   ```bash
   gcloud config set project YOUR-PROJECT-ID
   ```

4. **Verify access**:
   ```bash
   sky check gcp
   ```

### Azure

1. **Install Azure CLI**:
   ```bash
   nix shell nixpkgs#azure-cli
   ```

2. **Login**:
   ```bash
   az login
   ```

3. **Verify access**:
   ```bash
   sky check azure
   ```

## Using with Flakes

### In Your Own Flake

Add SkyPilot as an input to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    skypilot.url = "github:your-org/skypilot-flake";
  };

  outputs = { self, nixpkgs, skypilot }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          skypilot.packages.${system}.default
          # Your other dependencies
        ];
      };
    };
}
```

### Development Shell

Create a `shell.nix` for non-flake environments:

```nix
let
  skypilot-flake = builtins.getFlake "github:your-org/skypilot-flake";
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  buildInputs = [
    skypilot-flake.packages.${pkgs.system}.default
  ];
}
```

## Next Steps

- **[NixOS Module](/guides/nixos-module/)**: Learn about the full NixOS integration
- **[Configuration](/reference/configuration/)**: Explore all configuration options
- **[Examples](/guides/examples/)**: See real-world usage examples
- **[Troubleshooting](/guides/troubleshooting/)**: Common issues and solutions

## Common Tasks

### Update to Latest Version

If you installed via flake, updates are automatic when you rebuild. For profile installations:

```bash
nix profile upgrade
```

Or rebuild your flake:

```bash
nix flake update && nix develop
```

### Working with Multiple Clouds

SkyPilot can automatically choose the best cloud for your workload:

```yaml
# multi-cloud.yaml
resources:
  cpus: 4
  memory: 16GB

setup: |
  pip install torch torchvision

run: |
  python my_training_script.py
```

```bash
# Let SkyPilot choose the best cloud
sky launch multi-cloud.yaml

# Or specify preferred clouds
sky launch multi-cloud.yaml --cloud aws,gcp
```

### Cost Optimization

Use spot instances for significant savings:

```yaml
# spot-task.yaml
resources:
  cpus: 8
  use_spot: true

run: |
  # Your long-running task here
  python train_model.py
```

```bash
sky launch spot-task.yaml --use-spot
```

You're now ready to orchestrate your workloads across any cloud with SkyPilot and Nix!