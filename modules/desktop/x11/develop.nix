# Development tooling
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../../development/vscode
  ];

  development.rust.enable = true;

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
  ];
}
