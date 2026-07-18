{
  description = "msnap — screenshot and screencast utility for mangowm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      overlays.default = final: prev: {
        msnap = final.callPackage ./nix/default.nix { };
      };

      packages = forAllSystems (
        pkgs:
        let
          pkgs' = pkgs.extend self.overlays.default;
        in
        {
          msnap = pkgs'.msnap;
          default = pkgs'.msnap;
        }
      );

      apps = forAllSystems (pkgs: {
        msnap = {
          type = "app";
          program = "${self.packages.${pkgs.system}.msnap}/bin/msnap";
        };
      });
    };
}
