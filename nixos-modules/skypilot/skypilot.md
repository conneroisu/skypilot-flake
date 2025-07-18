# SkyPilot NixOS Module

This module provides a comprehensive NixOS integration for SkyPilot, a framework for running LLMs, AI, and batch jobs on any cloud.

## Features

- **Complete SkyPilot Installation**: Installs and configures SkyPilot with all dependencies
- **User & Group Management**: Creates dedicated system user and group for SkyPilot
- **Directory Management**: Sets up configuration, logging, and cache directories
- **Systemd Services**: Optional systemd services for cluster management and monitoring
- **Web UI Support**: Optional web interface for SkyPilot management
- **Cloud Credentials**: Secure handling of cloud provider credentials
- **Monitoring**: Built-in monitoring and metrics collection
- **Security Hardening**: Proper permissions and optional sudo rules
- **Firewall Integration**: Automatic firewall configuration for services

## Basic Configuration

```nix
{
  services.skypilot = {
    enable = true;
  };
}
```

## Advanced Configuration

```nix
{
  services.skypilot = {
    enable = true;
    enableWebUI = true;
    enableCluster = true;
    systemdServices = true;
    
    # Custom user and directories
    user = "skypilot";
    group = "skypilot";
    configDir = "/var/lib/skypilot/config";
    logsDir = "/var/log/skypilot";
    cacheDir = "/var/cache/skypilot";
    
    # Web UI configuration
    webUI = {
      port = 8080;
      host = "0.0.0.0";
      openFirewall = true;
    };
    
    # Cluster management
    cluster = {
      autoStop = 60; # minutes
      defaultInstanceType = "m5.large";
      defaultRegion = "us-west-2";
    };
    
    # Monitoring
    monitoring = {
      enable = true;
      metricsPort = 9090;
      logLevel = "INFO";
    };
    
    # SkyPilot configuration
    config = {
      cloud = {
        aws = {
          region = "us-west-2";
        };
        gcp = {
          project = "my-project";
          zone = "us-central1-a";
        };
      };
      spot = {
        enabled = true;
        max_price = 1.0;
      };
    };
    
    # Cloud credentials
    cloudCredentials = {
      aws = "/run/secrets/aws-credentials";
      gcp = "/run/secrets/gcp-service-account.json";
    };
    
    # Extra environment variables
    extraEnvironment = ''
      export AWS_PROFILE=skypilot
      export GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/gcp-service-account.json
    '';
  };
}
```

## Configuration Options

### Core Options

- `enable`: Enable the SkyPilot service
- `package`: SkyPilot package to use
- `user`/`group`: System user and group for SkyPilot
- `configDir`/`logsDir`/`cacheDir`: Directory paths for SkyPilot data

### Web UI Options

- `enableWebUI`: Enable the web interface
- `webUI.port`: Web UI port (default: 8080)
- `webUI.host`: Bind address (default: 127.0.0.1)
- `webUI.openFirewall`: Open firewall for web UI

### Cluster Management

- `enableCluster`: Enable cluster management features
- `cluster.autoStop`: Auto-stop idle clusters (minutes)
- `cluster.defaultInstanceType`: Default instance type
- `cluster.defaultRegion`: Default cloud region

### Monitoring

- `monitoring.enable`: Enable monitoring service
- `monitoring.metricsPort`: Metrics endpoint port
- `monitoring.logLevel`: Logging level

### Security

- `cloudCredentials`: Paths to cloud credential files
- `extraEnvironment`: Additional environment variables
- `systemdServices`: Enable systemd service management

## Systemd Services

When `systemdServices = true`, the following services are created:

1. **skypilot-web-ui**: Web interface service (if `enableWebUI = true`)
2. **skypilot-cluster-manager**: Cluster status monitoring
3. **skypilot-monitor**: Metrics and monitoring service
4. **skypilot-autostop**: Auto-stop timer for idle clusters

## Cloud Provider Setup

### AWS

```nix
{
  services.skypilot = {
    cloudCredentials.aws = "/run/secrets/aws-credentials";
    config.cloud.aws = {
      region = "us-west-2";
    };
    extraEnvironment = ''
      export AWS_PROFILE=default
    '';
  };
}
```

### Google Cloud Platform

```nix
{
  services.skypilot = {
    cloudCredentials.gcp = "/run/secrets/gcp-service-account.json";
    config.cloud.gcp = {
      project = "my-project";
      zone = "us-central1-a";
    };
    extraEnvironment = ''
      export GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/gcp-service-account.json
    '';
  };
}
```

### Azure

```nix
{
  services.skypilot = {
    cloudCredentials.azure = "/run/secrets/azure-credentials";
    config.cloud.azure = {
      region = "eastus";
    };
  };
}
```

## Security Considerations

1. **User Isolation**: SkyPilot runs under a dedicated system user
2. **File Permissions**: Configuration and credential files have restricted permissions
3. **Firewall Integration**: Only specified ports are opened
4. **Credential Management**: Cloud credentials are symlinked with proper permissions
5. **Sudo Rules**: Optional sudo access for cluster management operations

## Testing

The module includes comprehensive NixOS VM tests that verify:

- Basic installation and configuration
- Service functionality
- Web UI setup
- Monitoring services
- Custom configurations
- Security and permissions
- SkyPilot command functionality

Run tests with:

```bash
nix build .#checks.x86_64-linux.skypilot-module
```

## Troubleshooting

### Common Issues

1. **Service fails to start**: Check logs with `journalctl -u skypilot-*`
2. **Permission denied**: Verify file permissions in config directories
3. **Cloud access**: Ensure credentials are properly configured
4. **Network issues**: Check firewall rules and port bindings

### Log Locations

- System logs: `journalctl -u skypilot-*`
- SkyPilot logs: `/var/log/skypilot/`
- Configuration: `/var/lib/skypilot/config/`

## Examples

See the test configurations in `tests/skypilot-module.nix` for complete examples of different deployment scenarios.