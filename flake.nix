{
  description = "SkyPilot - Run LLMs and AI on any Cloud";

  # Flake inputs - pinned to stable versions for reproducibility
  inputs = {
    # Main package source - using unstable for latest Python packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Utilities for multi-system support
    flake-utils.url = "github:numtide/flake-utils";
    # Tree formatter for code formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, flake-utils, treefmt-nix }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Configure tree formatter with Nix and Python formatters
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixpkgs-fmt.enable = true; # Format Nix files
            black.enable = true; # Format Python files  
            isort.enable = true; # Sort Python imports
          };
        };

        # SkyPilot package definition with all required dependencies
        skypilot = pkgs.python3Packages.buildPythonApplication rec {
          pname = "skypilot";
          version = "0.9.3"; # Updated automatically by update.sh script

          # Source from GitHub releases - hash auto-calculated by update script
          src = pkgs.fetchFromGitHub {
            owner = "skypilot-org";
            repo = "skypilot";
            tag = "v${version}";
            hash = "sha256-iKNvzGiKM4QSG25CusZ1YRIou010uWyMLEAaFIww+FA=";
          };

          pyproject = true;

          # Build system requirements
          build-system = with pkgs.python3Packages; [ setuptools ];

          # Runtime dependencies - keep in sync with sky/setup_files/dependencies.py
          propagatedBuildInputs = with pkgs.python3Packages; [
            # Async I/O and web framework dependencies
            aiofiles
            fastapi
            httpx
            pydantic
            python-multipart
            uvicorn

            # Core utilities
            cachetools
            click
            colorama
            cryptography
            filelock
            jinja2
            jsonschema
            packaging
            python-dotenv
            pyyaml
            requests
            rich
            setproctitle
            tabulate
            typing-extensions
            wheel

            # Data processing and optimization
            networkx
            pandas
            pendulum
            prettytable
            psutil
            pulp
          ];

          meta = {
            description = "Run LLMs and AI on any Cloud";
            longDescription = ''
              SkyPilot is a framework for running LLMs, AI, and batch jobs on any
              cloud, offering maximum cost savings, highest GPU availability, and
              managed execution.
            '';
            homepage = "https://github.com/skypilot-org/skypilot";
            license = pkgs.lib.licenses.asl20;
            maintainers = with pkgs.lib.maintainers; [ seanrmurphy ];
            mainProgram = "sky";
          };
        };
      in
      {
        # Package outputs - SkyPilot CLI and library
        packages = {
          default = skypilot; # Default package for `nix build`
          skypilot = skypilot; # Named package for `nix build .#skypilot`
        };

        # Development shell with SkyPilot and development tools
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python runtime and package management
            python3
            python3Packages.pip
            python3Packages.setuptools
            python3Packages.wheel

            # Development and quality tools
            python3Packages.black # Code formatter
            python3Packages.flake8 # Linter
            python3Packages.pytest # Test runner
            python3Packages.mypy # Type checker

            # Include SkyPilot for testing and development
            skypilot
          ];

          shellHook = ''
            echo "SkyPilot development environment"
            echo "Available commands:"
            echo "  sky --help    - SkyPilot CLI"
            echo "  python        - Python interpreter"
            echo "  pip           - Package installer"
            echo "  black         - Code formatter"
            echo "  flake8        - Linter"
            echo "  pytest        - Test runner"
            echo "  mypy          - Type checker"
            echo ""
            echo "Run './update.sh' to update to the latest SkyPilot version"
          '';
        };

        # Code formatter using treefmt (nixpkgs-fmt, black, isort)
        formatter = treefmtEval.config.build.wrapper;

        # NixOS VM tests for the SkyPilot module
        checks = {
          skypilot-module = import ./tests/skypilot-module.nix {
            inherit pkgs;
            inherit (pkgs) lib;
          };
        };
      })) // {
        # NixOS module for SkyPilot service
        nixosModules = {
          default = import ./nixos-modules/skypilot;
          skypilot = import ./nixos-modules/skypilot;
        };

        # Overlay for other flakes to use
        overlays.default = final: prev: {
          skypilot = self.packages.${prev.system}.skypilot;
        };
      };
}
