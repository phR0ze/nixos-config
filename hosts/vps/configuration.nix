# vps configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened for public internet consuption
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../layers/console/low-mem.nix
    ../../layers/console/vps.nix
  ];

  config = {
    host.type.bootable = true;
    host.user.secret = true;

    boot.tmp.cleanOnBoot = true;

    networking.domain = "";
    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [ ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZ38JIVxhBApaKUZ4oB4kRLzIrbY/I8o4tBtApxPgrHOhEIyL5isyUXjJFypqeki8j3CHLWe4ObWPb3rAMrpjogn9yMfQSHZMTxUGJ4X9TIznx7tRLK5owMuW1BCDZoITKBkDbkAZsY5EmXK7yimWc8cosKiGhvpDUm0JCvRG3e3pQo9zi+on9i3WiO0SxbUDU9xJSQwfVmx6sFv17TldXUX8TlGYtvQpHLQSOB8Tlwa69phiFGFRodLyjuOqe5XwhwVqsrmkbHDBG7RcdLF6hyRDyRs6MpmkvVKjc04GP/3hT9tTixZc1NulGLK8ltPKBA3/0FMNKkAxmEW+Y+9FJ''  ];
  };
}
