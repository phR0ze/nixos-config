# home-manager iso configuration
# --------------------------------------------------------------------------------------------------
{ args, config, lib, ... }:
{
  config = {
    home.file.".bash_profile".text = ''
      if [ ! if clu ]; then
        curl -sL -o clu https://raw.githubusercontent.com/phR0ze/nixos-config/main/clu
      fi
      chmod +x clu
      sudo ./clu -f https://github.com/phR0ze/nixos-config
    '';

    home = {
      username = "nixos";
      homeDirectory = "/home/nixos";
      stateVersion = args.systemSettings.stateVersion;
    };
  };
}

# vim:set ts=2:sw=2:sts=2
