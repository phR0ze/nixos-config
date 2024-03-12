# Options
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;

  # We can leverage the write builders to create files in the user's home directory
  # https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeText

  #home.config.""
  #home.""

  # pkgs.writeShellScript

# Thoughts
# https://github.com/jakehamilton/config

#let
#
#  #cfg = config.apps.galculator;
#  #homedir = config.users.users.${args.settings.username}.home;
#in
#{
#  options.apps = mkOption {
#    description = "submodule example";
#    type = with types; attrsOf (submodule {
#      options = {
#        foo = mkOption {
#          type = int;
#        };
#        bar = mkOption {
#          type = str;
#        };
#      };
#    });
#  };
#}
let
  foo = pkgs.writeShellScriptBin "foobar" ''
    echo "{env}`HOME`"
  '';
in {
  environment.systemPackages = [ foo ];
}
