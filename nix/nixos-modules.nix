self: { config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.msnap;
in
{
  options.programs.msnap = {
    enable = lib.mkEnableOption "msnap, a mangowm screenshot tool";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.msnap;
      description = "The msnap package to use";
    };
  };
};

config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
