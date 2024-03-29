# User updatable system options
{
  stateVersion = "23.11";

  # Configuration overriden by user selections in the clu installer
  fullname = "admin";             # user's full name to use for general purposes
  email = "nixos@nixos.org";      # email to use for general configuration
  username = "admin";             # initial admin user to create during install
  userpass = "admin";             # admin user password securely entered during boot
  git_user = "admin";             # username to use for github, gitlab or other git tools
  git_email = "nixos@nixos.org";  # email to use for github, gitlab or other git tools
  hostname = "nixos";             # hostname to use for the install
  profile = "xfce/desktop";       # pre-defined configurations in path './profiles' selection
  autologin = true;               # automatically log the user in after boot when true
  
  # Configuration set via automation
  efi = true;                     # EFI system boot type
  mbr = "nodev";                  # MBR system boot device
  system = "x86_64-linux";        # system architecture to use
  timezone = "America/Boise";     # time-zone selection
  locale = "en_US.UTF-8";         # locale selection

  #wmType = if (wm == "hyprland") then "wayland" else "x11";
  term = "alacritty";             # default terminal to use
  fontName = "Intel One Mono";    # default font name
  #fontPkg = pkgs.intel-one-mono;  # default font package
}