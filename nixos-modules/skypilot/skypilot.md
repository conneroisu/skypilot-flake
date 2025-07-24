# SkyPilot NixOS Module

This module provides enterprise-grade NixOS integration for SkyPilot, a framework for running LLMs, AI, and batch jobs on any cloud with automatic cost optimization and maximum GPU availability.

[![NixOS](https://img.shields.io/badge/NixOS-Compatible-blue?logo=nixos)](https://nixos.org)
[![SkyPilot](https://img.shields.io/badge/SkyPilot-v0.9.3-green)](https://github.com/skypilot-org/skypilot)
[![Tests](https://img.shields.io/badge/VM%20Tests-Passing-brightgreen)](./tests/)

## Quick Start

```nix
# Add to your flake.nix inputs
inputs.skypilot-flake.url = "github:yourorg/skypilot-flake";

# Enable in your NixOS configuration
services.skypilot.enable = true;
```

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

## Production Deployment Examples

### High-Availability Multi-Cloud Setup

```nix
{
  services.skypilot = {
    enable = true;
    enableWebUI = true;
    enableCluster = true;
    systemdServices = true;
    
    # Production user configuration
    user = "skypilot-prod";
    group = "skypilot-prod";
    
    # Web UI with authentication proxy
    webUI = {
      port = 8080;
      host = "127.0.0.1";  # Behind reverse proxy
      openFirewall = false;
    };
    
    # Cluster auto-scaling configuration
    cluster = {
      autoStop = 30;  # 30 minutes idle timeout
      defaultInstanceType = "g4dn.xlarge";
      defaultRegion = "us-west-2";
    };
    
    # Production monitoring
    monitoring = {
      enable = true;
      metricsPort = 9090;
      logLevel = "INFO";
    };
    
    # Multi-cloud configuration
    config = {
      cloud = {
        aws = {
          region = "us-west-2";
          availability_zone = "us-west-2a";
        };
        gcp = {
          project = "your-gcp-project";
          zone = "us-central1-a";
        };
        azure = {
          region = "westus2";
        };
      };
      
      # Cost optimization
      spot = {
        enabled = true;
        max_price = 2.0;
        fallback_to_ondemand = true;
      };
      
      # Resource limits
      resources = {
        max_concurrent_jobs = 10;
        default_timeout = 3600;
      };
    };
    
    # Secure credential management
    cloudCredentials = {
      aws = "/run/secrets/aws-credentials";
      gcp = "/run/secrets/gcp-service-account.json";
      azure = "/run/secrets/azure-credentials";
    };
    
    # Production environment variables
    extraEnvironment = ''
      export SKYPILOT_LOG_LEVEL=INFO
      export SKYPILOT_DISABLE_USAGE_STATS=true
      export PYTHONUNBUFFERED=1
    '';
  };
  
  # Reverse proxy for web UI
  services.nginx = {
    enable = true;
    virtualHosts."skypilot.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };
    };
  };
  
  # Monitoring integration
  services.prometheus = {
    exporters.node.enable = true;
    scrapeConfigs = [{
      job_name = "skypilot";
      static_configs = [{
        targets = [ "localhost:9090" ];
      }];
    }];
  };
  
  # Log aggregation
  services.filebeat = {
    enable = true;
    settings = {
      filebeat.inputs = [{
        type = "log";
        paths = [ "/var/log/skypilot/*.log" ];
        fields = { service = "skypilot"; };
      }];
    };
  };
}
```

### Development Environment

```nix
{
  services.skypilot = {
    enable = true;
    enableWebUI = true;
    enableCluster = false;  # Disable for dev
    
    webUI = {
      port = 3000;
      host = "0.0.0.0";
      openFirewall = true;
    };
    
    # Development configuration
    config = {
      cloud.aws.region = "us-east-1";  # Cheaper region
      spot.enabled = true;  # Always use spot for dev
    };
    
    # Development credentials (local files)
    cloudCredentials = {
      aws = config.age.secrets.aws-dev-credentials.path;
    };
    
    extraEnvironment = ''
      export SKYPILOT_LOG_LEVEL=DEBUG
      export SKYPILOT_DEV_MODE=true
    '';
  };
}
```

### Minimal Edge Deployment

```nix
{
  services.skypilot = {
    enable = true;
    enableWebUI = false;
    enableCluster = false;
    systemdServices = false;
    monitoring.enable = false;
    
    # Minimal resource usage
    configDir = "/tmp/skypilot/config";
    logsDir = "/tmp/skypilot/logs";
    cacheDir = "/tmp/skypilot/cache";
    
    # Basic cloud access
    config = {
      cloud.aws.region = "us-east-1";
    };
  };
}
```

## Examples

See the test configurations in `tests/skypilot-module.nix` for complete examples of different deployment scenarios.

## Best Practices

1. **Security**: Always use dedicated credentials with minimal required permissions
2. **Monitoring**: Enable monitoring in production for cost tracking and performance analysis
3. **Auto-scaling**: Configure auto-stop timers to prevent unnecessary cloud costs
4. **Backup**: Regularly backup SkyPilot configurations and job histories
5. **Updates**: Use the automated update script to keep SkyPilot current
6. **Testing**: Validate configurations in development before production deployment

## Support

- **Documentation**: Complete module reference in this file
- **Testing**: Comprehensive VM tests in `tests/` directory
- **Issues**: Report problems via GitHub issues
- **Updates**: Automated via `./update.sh` script