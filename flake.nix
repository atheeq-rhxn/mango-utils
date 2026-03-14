{
  description = "Screenshot and screencast utility for mangowm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
      {
        packages = forAllSystems (system: {
          default = nixpkgs.${system}.callPackage ./nix/msnap.nix { };
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/msnap";
        };
      });

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.msnap;
          msnapPkg = self.packages.${pkgs.system}.default;
        in
          {
          imports = [ ./nix/nixos-module.nix ];

          config = lib.mkIf cfg.enable {
            programs.msnap.package = lib.mkDefault msnapPkg;
          };
        };
      };  
}
