{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.skypilot;
  
  # Use the SkyPilot package from the overlay or build it locally
  skypilot-pkg = if pkgs ? skypilot 
    then pkgs.skypilot 
    else pkgs.python3Packages.buildPythonApplication rec {
      pname = "skypilot";
      version = "0.9.3";

      src = pkgs.fetchFromGitHub {
        owner = "skypilot-org";
        repo = "skypilot";
        tag = "v${version}";
        hash = "sha256-iKNvzGiKM4QSG25CusZ1YRIou010uWyMLEAaFIww+FA=";
      };

      pyproject = true;
      build-system = with pkgs.python3Packages; [ setuptools ];

      propagatedBuildInputs = with pkgs.python3Packages; [
        aiofiles cachetools click colorama cryptography fastapi filelock
        httpx jinja2 jsonschema networkx packaging pandas pendulum
        prettytable psutil pydantic python-dotenv python-multipart
        pyyaml pulp requests rich setproctitle tabulate typing-extensions
        uvicorn wheel
      ];

      meta = {
        description = "Run LLMs and AI on any Cloud";
        homepage = "https://github.com/skypilot-org/skypilot";
        license = pkgs.lib.licenses.asl20;
        mainProgram = "sky";
      };
    };
  
  # Configuration file for SkyPilot
  skypilotConfig = pkgs.writeText "skypilot-config.yaml" (generators.toYAML { } cfg.config);
  
  # Environment script
  skypilotEnv = pkgs.writeShellScript "skypilot-env" ''
    export SKYPILOT_CONFIG_DIR=${cfg.configDir}
    export SKYPILOT_LOGS_DIR=${cfg.logsDir}
    export SKYPILOT_CACHE_DIR=${cfg.cacheDir}
    ${optionalString (cfg.config != { }) ''
      export SKYPILOT_CONFIG=${skypilotConfig}
    ''}
    ${cfg.extraEnvironment}
  '';

in {
  options.services.skypilot = {
    enable = mkEnableOption "SkyPilot cloud orchestration service";

    package = mkOption {
      type = types.package;
      default = skypilot-pkg;
      defaultText = literalExpression "pkgs.skypilot";
      description = "The SkyPilot package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "skypilot";
      description = "User account under which SkyPilot runs.";
    };

    group = mkOption {
      type = types.str;
      default = "skypilot";
      description = "Group under which SkyPilot runs.";
    };

    configDir = mkOption {
      type = types.path;
      default = "/var/lib/skypilot/config";
      description = "Directory where SkyPilot configuration files are stored.";
    };

    logsDir = mkOption {
      type = types.path;
      default = "/var/log/skypilot";
      description = "Directory where SkyPilot logs are stored.";
    };

    cacheDir = mkOption {
      type = types.path;
      default = "/var/cache/skypilot";
      description = "Directory where SkyPilot cache files are stored.";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
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
        }
      '';
      description = ''
        SkyPilot configuration as a Nix attribute set.
        This will be converted to YAML and made available to SkyPilot.
      '';
    };

    cloudCredentials = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        {
          aws = "/run/secrets/aws-credentials";
          gcp = "/run/secrets/gcp-service-account.json";
          azure = "/run/secrets/azure-credentials";
        }
      '';
      description = ''
        Paths to cloud credential files. These will be symlinked into the
        SkyPilot configuration directory with appropriate permissions.
      '';
    };

    extraEnvironment = mkOption {
      type = types.lines;
      default = "";
      example = ''
        export AWS_PROFILE=skypilot
        export GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
      '';
      description = "Extra environment variables to set for SkyPilot.";
    };

    enableWebUI = mkOption {
      type = types.bool;
      default = false;
      description = "Enable SkyPilot web UI service.";
    };

    webUI = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 8080;
            description = "Port for the SkyPilot web UI.";
          };

          host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Host address to bind the web UI to.";
          };

          openFirewall = mkOption {
            type = types.bool;
            default = false;
            description = "Open firewall for the web UI port.";
          };
        };
      };
      description = "Web UI configuration options.";
    };

    enableCluster = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SkyPilot cluster management.";
    };

    cluster = mkOption {
      type = types.submodule {
        options = {
          autoStop = mkOption {
            type = types.nullOr types.int;
            default = null;
            example = 60;
            description = "Automatically stop clusters after specified minutes of inactivity.";
          };

          defaultInstanceType = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "m5.large";
            description = "Default instance type for new clusters.";
          };

          defaultRegion = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "us-west-2";
            description = "Default region for new clusters.";
          };
        };
      };
      description = "Cluster management configuration options.";
    };

    systemdServices = mkOption {
      type = types.bool;
      default = true;
      description = "Create systemd services for SkyPilot daemon processes.";
    };

    enableSpotInstances = mkOption {
      type = types.bool;
      default = false;
      description = "Enable spot instance support by default.";
    };

    monitoring = mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable SkyPilot monitoring and metrics collection.";
          };

          metricsPort = mkOption {
            type = types.port;
            default = 9090;
            description = "Port for metrics endpoint.";
          };

          logLevel = mkOption {
            type = types.enum [ "DEBUG" "INFO" "WARNING" "ERROR" "CRITICAL" ];
            default = "INFO";
            description = "Log level for SkyPilot services.";
          };
        };
      };
      description = "Monitoring and logging configuration.";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.configDir;
      createHome = true;
      description = "SkyPilot service user";
    };

    users.groups.${cfg.group} = { };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.logsDir} 0755 ${cfg.user} ${cfg.group} -"
      "d ${cfg.cacheDir} 0755 ${cfg.user} ${cfg.group} -"
    ] ++ (mapAttrsToList (cloud: credFile: 
      "L+ ${cfg.configDir}/${cloud}-credentials 0600 ${cfg.user} ${cfg.group} - ${credFile}"
    ) cfg.cloudCredentials);

    # Install SkyPilot package system-wide
    environment.systemPackages = [ cfg.package ];

    # Environment variables for all users
    environment.variables = {
      SKYPILOT_CONFIG_DIR = cfg.configDir;
      SKYPILOT_LOGS_DIR = cfg.logsDir;
      SKYPILOT_CACHE_DIR = cfg.cacheDir;
    } // (optionalAttrs (cfg.config != { }) {
      SKYPILOT_CONFIG = toString skypilotConfig;
    });

    # Web UI service
    systemd.services.skypilot-web-ui = mkIf cfg.enableWebUI {
      description = "SkyPilot Web UI";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = "${skypilotEnv}";
        ExecStart = "${cfg.package}/bin/sky serve up --host ${cfg.webUI.host} --port ${toString cfg.webUI.port}";
        Restart = "always";
        RestartSec = "10s";
        WorkingDirectory = cfg.configDir;
        StandardOutput = "journal";
        StandardError = "journal";
      };
      environment = {
        SKYPILOT_CONFIG_DIR = cfg.configDir;
        SKYPILOT_LOGS_DIR = cfg.logsDir;
        SKYPILOT_CACHE_DIR = cfg.cacheDir;
      };
    };

    # Cluster management service
    systemd.services.skypilot-cluster-manager = mkIf (cfg.enableCluster && cfg.systemdServices) {
      description = "SkyPilot Cluster Manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = "${skypilotEnv}";
        ExecStart = "${cfg.package}/bin/sky status --refresh";
        Restart = "always";
        RestartSec = "300s"; # Check every 5 minutes
        WorkingDirectory = cfg.configDir;
        StandardOutput = "journal";
        StandardError = "journal";
      };
      environment = {
        SKYPILOT_CONFIG_DIR = cfg.configDir;
        SKYPILOT_LOGS_DIR = cfg.logsDir;
        SKYPILOT_CACHE_DIR = cfg.cacheDir;
      };
    };

    # Monitoring service
    systemd.services.skypilot-monitor = mkIf cfg.monitoring.enable {
      description = "SkyPilot Monitoring Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = "${skypilotEnv}";
        ExecStart = "${pkgs.python3}/bin/python -m http.server ${toString cfg.monitoring.metricsPort}";
        Restart = "always";
        RestartSec = "30s";
        WorkingDirectory = cfg.logsDir;
        StandardOutput = "journal";
        StandardError = "journal";
      };
      environment = {
        SKYPILOT_LOG_LEVEL = cfg.monitoring.logLevel;
        SKYPILOT_CONFIG_DIR = cfg.configDir;
        SKYPILOT_LOGS_DIR = cfg.logsDir;
        SKYPILOT_CACHE_DIR = cfg.cacheDir;
      };
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkIf cfg.webUI.openFirewall [ cfg.webUI.port ]
      ++ mkIf cfg.monitoring.enable [ cfg.monitoring.metricsPort ];

    # Auto-stop timer for clusters
    systemd.timers.skypilot-autostop = mkIf (cfg.cluster.autoStop != null) {
      description = "SkyPilot Auto-stop Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "${toString cfg.cluster.autoStop}min";
        Persistent = true;
      };
    };

    systemd.services.skypilot-autostop = mkIf (cfg.cluster.autoStop != null) {
      description = "SkyPilot Auto-stop Service";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = "${skypilotEnv}";
        ExecStart = "${cfg.package}/bin/sky autostop --all --idle ${toString cfg.cluster.autoStop}";
        WorkingDirectory = cfg.configDir;
      };
      environment = {
        SKYPILOT_CONFIG_DIR = cfg.configDir;
        SKYPILOT_LOGS_DIR = cfg.logsDir;
        SKYPILOT_CACHE_DIR = cfg.cacheDir;
      };
    };

    # Security hardening
    security.sudo.rules = mkIf cfg.enableCluster [
      {
        users = [ cfg.user ];
        commands = [
          {
            command = "${cfg.package}/bin/sky";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Kernel modules for container support
    boot.kernelModules = mkIf cfg.enableCluster [ "overlay" "br_netfilter" ];

    # System-wide SkyPilot configuration
    environment.etc."skypilot/config.yaml" = mkIf (cfg.config != { }) {
      text = generators.toYAML { } (cfg.config // {
        cluster = optionalAttrs (cfg.cluster.defaultInstanceType != null) {
          default_instance_type = cfg.cluster.defaultInstanceType;
        } // optionalAttrs (cfg.cluster.defaultRegion != null) {
          default_region = cfg.cluster.defaultRegion;
        };
        spot = optionalAttrs cfg.enableSpotInstances {
          enabled = true;
        };
      });
      mode = "0644";
    };

    # Assertions
    assertions = [
      {
        assertion = cfg.enableWebUI -> cfg.webUI.port > 0;
        message = "SkyPilot web UI port must be greater than 0";
      }
      {
        assertion = cfg.monitoring.enable -> cfg.monitoring.metricsPort > 0;
        message = "SkyPilot monitoring metrics port must be greater than 0";
      }
      {
        assertion = cfg.cluster.autoStop == null || cfg.cluster.autoStop > 0;
        message = "SkyPilot auto-stop time must be greater than 0 minutes";
      }
    ];
  };

  meta = {
    maintainers = with lib.maintainers; [ ];
    doc = ./skypilot.md;
  };
}