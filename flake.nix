{
  description = "Screenshot and screencast utility for mangowm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, flake-parts, nixpkgs } @ inputs:
      flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      flake = {
        nixosModules.msnap = import ./nix/nixos-modules.nix self;
      };

      perSystem = {
        config,
        pkgs,
        ...
      }: let
        inherit (pkgs) callPackage ;
        msnap = callPackage ./nix/msnap.nix {};
        shellOverride = old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [];
          buildInputs = old.buildInputs ++ [];
        };
      in {
        packages.default = msnap;
        overlayAttrs = {
          inherit (config.packages) msnap;
        };
        packages = {
          inherit msnap;
        };
        devShells.default = msnap.overrideAttrs shellOverride;
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
