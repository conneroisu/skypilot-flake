# NixOS Module

The SkyPilot NixOS module provides complete system integration with automatic service management, monitoring, and security hardening. Perfect for production deployments and development servers.

## Features

- 🔧 **Complete Service Integration**: Systemd services for all SkyPilot components
- 🔐 **Security Hardened**: Dedicated users, proper permissions, firewall integration
- 📊 **Built-in Monitoring**: Metrics collection and health checking
- 🌐 **Web UI Support**: Optional web interface with automatic setup
- ☁️ **Multi-Cloud Ready**: Secure credential management for all providers
- 🔄 **Auto-Management**: Cluster lifecycle and resource optimization

## Quick Setup

### Basic Configuration

Add to your NixOS configuration:

```nix
{
  # Import the module
  imports = [ inputs.skypilot.nixosModules.default ];
  
  # Enable SkyPilot service
  services.skypilot.enable = true;
}
```

### Full-Featured Setup

```nix
{
  imports = [ inputs.skypilot.nixosModules.default ];
  
  services.skypilot = {
    enable = true;
    enableWebUI = true;
    enableCluster = true;
    systemdServices = true;
    
    # Web interface
    webUI = {
      port = 8080;
      host = "0.0.0.0";
      openFirewall = true;
    };
    
    # Cluster management
    cluster = {
      autoStop = 60; # Auto-stop after 60 minutes
      defaultInstanceType = "m5.large";
      defaultRegion = "us-west-2";
    };
    
    # Monitoring
    monitoring = {
      enable = true;
      metricsPort = 9090;
      logLevel = "INFO";
    };
    
    # Cloud credentials
    cloudCredentials = {
      aws = "/run/secrets/aws-credentials";
      gcp = "/run/secrets/gcp-service-account.json";
    };
  };
}
```

## Configuration Options

### Core Settings

#### `services.skypilot.enable`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enable the SkyPilot service

#### `services.skypilot.package`
- **Type**: `package`
- **Default**: Latest SkyPilot package
- **Description**: SkyPilot package to use

#### `services.skypilot.user` / `services.skypilot.group`
- **Type**: `string`
- **Default**: `"skypilot"`
- **Description**: System user and group for SkyPilot

### Directory Configuration

#### `services.skypilot.configDir`
- **Type**: `path`
- **Default**: `"/var/lib/skypilot/config"`
- **Description**: Configuration directory

#### `services.skypilot.logsDir`
- **Type**: `path`
- **Default**: `"/var/log/skypilot"`
- **Description**: Logs directory

#### `services.skypilot.cacheDir`
- **Type**: `path`
- **Default**: `"/var/cache/skypilot"`
- **Description**: Cache directory

### Web UI Options

#### `services.skypilot.enableWebUI`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enable web interface

#### `services.skypilot.webUI.port`
- **Type**: `port`
- **Default**: `8080`
- **Description**: Web UI port

#### `services.skypilot.webUI.host`
- **Type**: `string`
- **Default**: `"127.0.0.1"`
- **Description**: Bind address

#### `services.skypilot.webUI.openFirewall`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Open firewall for web UI

### Cluster Management

#### `services.skypilot.enableCluster`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable cluster management

#### `services.skypilot.cluster.autoStop`
- **Type**: `null or int`
- **Default**: `null`
- **Description**: Auto-stop idle clusters (minutes)

#### `services.skypilot.cluster.defaultInstanceType`
- **Type**: `null or string`
- **Default**: `null`
- **Example**: `"m5.large"`
- **Description**: Default instance type

#### `services.skypilot.cluster.defaultRegion`
- **Type**: `null or string`
- **Default**: `null`
- **Example**: `"us-west-2"`
- **Description**: Default region

### Monitoring

#### `services.skypilot.monitoring.enable`
- **Type**: `boolean`
- **Default**: `false`
- **Description**: Enable monitoring

#### `services.skypilot.monitoring.metricsPort`
- **Type**: `port`
- **Default**: `9090`
- **Description**: Metrics endpoint port

#### `services.skypilot.monitoring.logLevel`
- **Type**: `enum`
- **Options**: `["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]`
- **Default**: `"INFO"`
- **Description**: Log level

### Security & Credentials

#### `services.skypilot.cloudCredentials`
- **Type**: `attribute set of paths`
- **Default**: `{}`
- **Example**:
  ```nix
  {
    aws = "/run/secrets/aws-credentials";
    gcp = "/run/secrets/gcp-service-account.json";
    azure = "/run/secrets/azure-credentials";
  }
  ```
- **Description**: Cloud credential file paths

#### `services.skypilot.extraEnvironment`
- **Type**: `lines`
- **Default**: `""`
- **Example**:
  ```nix
  ''
    export AWS_PROFILE=skypilot
    export GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
  ''
  ```
- **Description**: Extra environment variables

## Service Management

The module creates several systemd services when enabled:

### `skypilot-web-ui.service`
Web interface service (when `enableWebUI = true`)

```bash
# Check status
systemctl status skypilot-web-ui

# View logs
journalctl -u skypilot-web-ui -f

# Restart service
systemctl restart skypilot-web-ui
```

### `skypilot-cluster-manager.service`
Cluster monitoring service (when `enableCluster = true`)

```bash
# Check cluster status
systemctl status skypilot-cluster-manager

# View cluster logs
journalctl -u skypilot-cluster-manager -f
```

### `skypilot-monitor.service`
Monitoring and metrics service (when `monitoring.enable = true`)

```bash
# Check monitoring status
systemctl status skypilot-monitor

# View monitoring logs
journalctl -u skypilot-monitor -f
```

### `skypilot-autostop.timer`
Auto-stop timer (when `cluster.autoStop` is set)

```bash
# Check timer status
systemctl list-timers skypilot-autostop

# Run autostop manually
systemctl start skypilot-autostop
```

## Advanced Configurations

### Production Deployment

```nix
{
  services.skypilot = {
    enable = true;
    enableWebUI = true;
    enableCluster = true;
    systemdServices = true;
    enableSpotInstances = true;
    
    # Custom user for security
    user = "skypilot-prod";
    group = "skypilot-prod";
    
    # Secure web UI
    webUI = {
      port = 8443;
      host = "127.0.0.1"; # Only local access
      openFirewall = false; # Use reverse proxy
    };
    
    # Aggressive cost optimization
    cluster = {
      autoStop = 30; # Stop after 30 minutes
      defaultInstanceType = "t3.micro";
    };
    
    # Comprehensive monitoring
    monitoring = {
      enable = true;
      metricsPort = 9090;
      logLevel = "WARNING";
    };
    
    # Production configuration
    config = {
      cluster = {
        default_instance_type = "c5.large";
        default_region = "us-east-1";
      };
      spot = {
        enabled = true;
        max_price = 0.50;
      };
      resources = {
        disk_size = 100;
        disk_type = "gp3";
      };
    };
    
    # Secure credentials using sops-nix
    cloudCredentials = {
      aws = config.sops.secrets.aws-credentials.path;
      gcp = config.sops.secrets.gcp-service-account.path;
    };
  };
  
  # Reverse proxy for web UI
  services.nginx = {
    enable = true;
    virtualHosts."skypilot.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8443";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        '';
      };
    };
  };
}
```

### Development Server

```nix
{
  services.skypilot = {
    enable = true;
    enableWebUI = true;
    enableCluster = false; # No cluster management
    systemdServices = false; # Manual control
    
    # Open web UI
    webUI = {
      port = 8080;
      host = "0.0.0.0";
      openFirewall = true;
    };
    
    # Development-friendly settings
    config = {
      cluster = {
        default_instance_type = "t3.small";
      };
      spot = {
        enabled = false; # Reliability over cost
      };
    };
  };
}
```

### Multi-Cloud Setup

```nix
{
  services.skypilot = {
    enable = true;
    enableCluster = true;
    
    config = {
      cloud = {
        aws = {
          region = "us-west-2";
          use_spot = true;
        };
        gcp = {
          project = "my-ml-project";
          zone = "us-central1-a";
          use_spot = true;
        };
        azure = {
          region = "eastus";
          use_spot = false;
        };
      };
      
      # Cloud selection preferences
      allowed_clouds = ["aws", "gcp", "azure"];
      preferred_clouds = ["aws", "gcp"];
      
      # Cost optimization
      spot = {
        enabled = true;
        max_price = 1.0;
        retry_until_up = true;
      };
    };
    
    cloudCredentials = {
      aws = "/run/secrets/aws-credentials";
      gcp = "/run/secrets/gcp-service-account.json";
      azure = "/run/secrets/azure-credentials";
    };
  };
}
```

## Troubleshooting

### Service Issues

Check service status:
```bash
systemctl status skypilot-*
```

View logs:
```bash
journalctl -u skypilot-web-ui -f
journalctl -u skypilot-cluster-manager -f
```

### Permission Problems

Check file ownership:
```bash
ls -la /var/lib/skypilot/
ls -la /var/log/skypilot/
```

Fix permissions:
```bash
sudo chown -R skypilot:skypilot /var/lib/skypilot/
sudo chown -R skypilot:skypilot /var/log/skypilot/
```

### Configuration Validation

Test configuration syntax:
```bash
python3 -c "import yaml; yaml.safe_load(open('/etc/skypilot/config.yaml'))"
```

Validate SkyPilot config:
```bash
sudo -u skypilot sky check
```

### Firewall Issues

Check open ports:
```bash
ss -tlnp | grep -E ":(8080|9090)"
```

Test connectivity:
```bash
curl -I http://localhost:8080
curl -I http://localhost:9090/metrics
```

## Integration Examples

### With Prometheus

```nix
{
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "skypilot";
        static_configs = [
          {
            targets = [ "127.0.0.1:9090" ];
          }
        ];
      }
    ];
  };
}
```

### With Grafana

```nix
{
  services.grafana = {
    enable = true;
    settings.server.http_port = 3000;
  };
  
  # Dashboard for SkyPilot metrics
  services.grafana.provision.dashboards.settings.providers = [
    {
      name = "skypilot";
      type = "file";
      options.path = "/etc/grafana/dashboards";
    }
  ];
}
```

The NixOS module provides a complete, production-ready SkyPilot deployment with minimal configuration. Perfect for both development and production use cases.