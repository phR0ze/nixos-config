{
  # Configuration set by user selections in the clu installer
  # ------------------------------------------------------------------------------------------------
  fullname = "nixos";             # user's full name to use for general purposes
  email = "nixos@nixos.org";      # email to use for general configuration
  username = "nixos";             # initial admin user to create during install
  userpass = "nixos";             # admin user password securely entered during boot
  git_user = "nixos";             # username to use for github, gitlab or other git tools
  git_email = "nixos@nixos.org";  # email to use for github, gitlab or other git tools
  hostname = "nixos";             # hostname to use for the install
  profile = "xfce/desktop";       # pre-defined configurations in path './profiles' selection
  autologin = true;               # automatically log the user in after boot when true
  
  # Configuration set via automation in the clu installer
  # ------------------------------------------------------------------------------------------------
  efi = true;                     # EFI system boot type
  mbr = "nodev";                  # MBR system boot device
  system = "x86_64-linux";        # system architecture to use
  timezone = "America/Boise";     # time-zone selection
  locale = "en_US.UTF-8";         # locale selection
}
