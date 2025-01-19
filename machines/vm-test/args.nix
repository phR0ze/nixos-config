{
  hostname = "vm-test";
  profile = "xfce/desktop";
  vm_enable = true;
  vm_cores = 1;
  vm_disk_size = 1;
  vm_memory_size = 4;
  vm_spice = false;
  vm_spice_port = 5970;
  vm_graphics = true;
  macvtap_host = "enp1s0";
  mbr = "/dev/sda";
  nic0_name = "eth0";
  resolution_x = 1920;
  resolution_y = 1080;
  autologin = true;
}
