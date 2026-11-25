# NOTE: ... is needed because dikso passes diskoFile
{
  lib,
  disk ? "/dev/vda",
  imageSize ? "10G",
  withSwap ? false,
  swapSize,
  # node disks: fixed root, rest is an LVM thin pool for LINSTOR (Piraeus)
  withLinstor,
  rootSize,
  ...
}:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = disk;
        imageSize = imageSize;
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };
            ESP = {
              size = "512M";
              type = "EF00";
              priority = 2;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = if withLinstor then rootSize else "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "defaults"
                      "subvol=root"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "discard=async"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "defaults"
                      "subvol=root"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "discard=async"
                    ];
                  };
                  "@swap" = lib.mkIf withSwap {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "${swapSize}G";
                  };
                };
              };
            };
            linstor = lib.mkIf withLinstor {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "linstor_vg";
              };
            };
          };
        };
      };
    };
    lvm_vg = lib.mkIf withLinstor {
      linstor_vg = {
        type = "lvm_vg";
        lvs.thin = {
          size = "100%FREE";
          lvm_type = "thin-pool";
        };
      };
    };
  };
}
