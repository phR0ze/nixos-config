# iso configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    "${pkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  environment.systemPackages = with pkgs; [
    git                 # Needed for clu installer automation
    jq                  # Needed for clu installer automation
  ];
}

# vim:set ts=2:sw=2:sts=2
