# NOTE: ... is needed because dikso passes diskoFile
{
  lib,
  disk ? "/dev/vda",
  withSwap ? false,
  swapSize,
  ...
}:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = disk;
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
              size = "100%";
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
                  "@persist" = {
                    mountpoint = "/persist";
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
          };
        };
      };
    };
  };
}
