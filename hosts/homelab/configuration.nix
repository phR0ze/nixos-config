# Homelab configuration
#
# ### Features
# - Homelab server deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    host.boot.efi = true;
    host.autolock = true;
    host.autologin = true;
    host.desktop.xfce.standard = true;
    devices.gpu.nvidia = { enable = true; open = true; };    # GeForce GTX 1660 (Turing)

    # UEFI capsule updates aren't supported in this machine's firmware setup, and
    # fwupd-refresh.service just fails/flaps on LVFS metadata downloads with no benefit.
    services.fwupd.enable = lib.mkForce false;

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    services.native.smb.enable = true;
    services.native.mullvad.enable = true;
    services.native.minecraft.enable = true;
    services.native.nix-cache.host.enable = true;
    services.oci.newt = {
      enable = true; user.uid = 2005; tag = "1.18.1";
    };

    # Caddy fronted services
    services.native.caddy.enable = true;
    services.native.adguardhome.enable = true;
    services.native.jellyfin.enable = true;
    services.oci.homarr = {
      enable = true; port = 8080; user.uid = 2000; tag = "v2.3.0";
    };
    services.oci.stirling-pdf = {
      enable = true; port = 8081; user.uid = 2001; tag = "3.1.0";
    };
    services.oci.oneup = {
      enable = true; port = 8082; user.uid = 2002; tag = "latest";
    };
    services.native.vaultwarden = {
      enable = true; port = 8222; subdomains = [ "vault" "vault-vpn" ];
    };
    services.native.immich = {
      enable = true; port = 2283; subdomains = [ "immich" "immich-vpn" ];
      cuda = true; cudaCapabilities = [ "7.5" ];    # GTX 1660 (Turing)
    };
    services.native.nextcloud = {
      enable = true; port = 8090; subdomains = [ "nextcloud" "nextcloud-vpn" ];
    };

    # Shared by Immich and Nextcloud, sized for 96 GB and 16 threads on a SATA SSD, leaving most of
    # the RAM to the page cache, Jellyfin, Immich ML and VMs
    services.postgresql.settings = {
      shared_buffers = "8GB";
      effective_cache_size = "48GB";
      work_mem = "32MB";
      maintenance_work_mem = "1GB";             # Immich's vector index builds
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      max_wal_size = "4GB";                     # fewer checkpoints during large imports
      max_worker_processes = 16;
      max_parallel_workers = 8;
      max_parallel_workers_per_gather = 4;
      max_parallel_maintenance_workers = 4;
    };

    # Additional apps
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
