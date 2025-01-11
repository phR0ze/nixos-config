{
  hostname = "homelab";
  shares_enable = false;
  efi = false;
  mbr = "/dev/sda";
  autologin = false;
  nic0_name = "ens18";

#  vms = [
#    { enable = false; hostname = "nixos70"; }
#    { enable = false; hostname = "nixos71"; }
#  ];
}
