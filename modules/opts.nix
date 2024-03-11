# Options
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;

  # ### Home Manager
  # Home Manager's solution is to use a JSON payload and live xfconf-query calls after the system is
  # up and running to inject configuration. However this depends on the home manager daemon with 
  # possible runtime failures due to dbus or xfconf-query errors which I'd rather not incur.
  #
  # ### Solution
  # The nix way would be to make it declarative and readonly similar to environment.etc which lays 
  # down configuration with a readonly link to the nix store.
  # 1. Create a new home.file.".vimrc".source = ./vimrc;
  # 2. Use the existing security.pam.services.login.makeHomeDir for defaults

  # We can leverage the write builders to create files in the user's home directory
  # https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeText

  #home.config.""
  #home.""

  # pkgs.writeShellScript

# Thoughts
# https://github.com/jakehamilton/config

# Writing NixOS Modules
# https://nixos.org/manual/nixos/unstable/#sec-writing-modules
let

  #cfg = config.apps.galculator;
  #homedir = config.users.users.${args.settings.username}.home;
in
{
  options.apps = mkOption {
    description = "submodule example";
    type = with types; attrsOf (submodule {
      options = {
        foo = mkOption {
          type = int;
        };
        bar = mkOption {
          type = str;
        };
      };
    });
  };
}