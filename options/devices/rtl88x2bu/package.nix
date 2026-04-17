# RTL8822BU out-of-tree kernel module (morrownr/88x2bu-20210702)
#
# ### Why not the in-kernel rtw88_8822bu driver?
# The in-kernel rtw88 driver repeatedly fails to get TX reports from the firmware
# under sustained load, causing 20-30 second throughput collapses. The morrownr
# driver is derived from Realtek's vendor source and handles USB TX flow control
# correctly, avoiding the firmware stall.
#
# ### Update instructions
# 1. run: ./get_new_version.sh
# 2. update `rev` and `version` below
# 3. get new hash:
#    nix-shell -p nix-prefetch-github --run \
#      'nix-prefetch-github morrownr 88x2bu-20210702 --rev <new-rev>'
# 4. update `hash` below
#---------------------------------------------------------------------------------------------------
{ lib, stdenv, fetchFromGitHub, kernel, bc }:

stdenv.mkDerivation rec {
  pname = "rtl88x2bu";
  version = "2026-01-08";

  src = fetchFromGitHub {
    owner = "morrownr";
    repo = "88x2bu-20210702";
    rev = "fecac340fb117eb979f4bb6d28e29730384c382b";
    hash = "sha256-n7yplPTQjBLfF00HPMIb7o1xhQgW2sYKBWQ4uAnxvH0=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ bc ];

  # kernel.makeFlags includes --eval=undefine modules which conflicts with the driver's Makefile.
  # Build explicitly using the standard out-of-tree kernel module convention instead.
  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd) \
      ARCH=${stdenv.hostPlatform.linuxArch} \
      CROSS_COMPILE=${stdenv.cc.targetPrefix} \
      CONFIG_RTL8822BU=m \
      modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ko=$(find . -name '88x2bu.ko*' | head -1)
    install -D "$ko" $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/wireless/$(basename "$ko")
    runHook postInstall
  '';

  meta = {
    description = "Out-of-tree driver for Realtek RTL8822BU USB WiFi adapter";
    homepage = "https://github.com/morrownr/88x2bu-20210702";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
