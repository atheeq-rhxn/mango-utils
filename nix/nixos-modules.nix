{ config, lib, ... }:

with lib;

let
  cfg = config.programs.msnap;
in
{
  options.programs.msnap = {
    enable = mkEnableOption "msnap program";

    package = mkOption {
      type = types.package;
      defaultText = literalExpression "pkgs.msnap";
      description = "The msnap package";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
