# Development tooling
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [

  ];

  environment.systemPackages = with pkgs; [
    rustup                              # Rust installer
  ];
}
