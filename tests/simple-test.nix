{ pkgs }:

pkgs.nixosTest {
  name = "skypilot-simple";

  # Optimized for fast testing
  meta = {
    maintainers = [ ];
    timeout = 300; # 5 minutes max
  };

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../nixos-modules/skypilot ];

    services.skypilot = {
      enable = true;
      enableCluster = false;
      enableWebUI = false;
      systemdServices = false;
      monitoring.enable = false;
    };

    # Minimal VM resources for faster testing
    virtualisation = {
      memorySize = 1024;
      diskSize = 2048;
      cores = 2;
      graphics = false;
    };

    # Disable unnecessary services for faster boot
    systemd.services.network-manager.enable = false;
    networking.useDHCP = false;
    networking.interfaces.eth1.useDHCP = true;
  };

  testScript = ''
    start_all()
    
    print("Starting SkyPilot simple functionality test...")
    machine.wait_for_unit("multi-user.target")
    
    # Test basic installation
    print("Testing SkyPilot installation...")
    machine.succeed("which sky")
    
    # Test version command
    print("Testing SkyPilot version...")
    version_output = machine.succeed("sky --version")
    assert "skypilot, version" in version_output
    print(f"✓ SkyPilot version: {version_output.strip()}")
    
    # Test help command
    print("Testing SkyPilot help...")
    help_output = machine.succeed("sky --help")
    assert "Usage: sky" in help_output
    print("✓ SkyPilot help command working")
    
    # Test user/group creation
    print("Testing user and group creation...")
    machine.succeed("id skypilot")
    machine.succeed("getent group skypilot")
    print("✓ SkyPilot user and group created")
    
    # Test directory structure
    print("Testing directory structure...")
    machine.succeed("test -d /var/lib/skypilot/config")
    machine.succeed("test -d /var/log/skypilot")
    machine.succeed("test -d /var/cache/skypilot")
    print("✓ SkyPilot directories created")
    
    # Test environment variables
    print("Testing environment variables...")
    env_output = machine.succeed("env | grep SKYPILOT || true")
    if "SKYPILOT" in env_output:
        print("✓ SkyPilot environment variables set")
    else:
        print("⚠ SkyPilot environment variables not found (may be expected)")
    
    print("=" * 50)
    print("✅ All simple tests passed successfully!")
    print("=" * 50)
  '';
}
