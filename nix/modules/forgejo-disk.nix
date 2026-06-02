{ pkgs, ... }:
{
  boot.initrd = {
    # 1. Ensure KubeVirt/QEMU block drivers and ext4 modules are present in Stage 1
    kernelModules = [
      "virtio_blk"
      "ext4"
    ];

    # 2. Add required binaries to the initrd environment using the systemd-initrd way
    systemd.initrdBin = [
      pkgs.gptfdisk
      pkgs.e2fsprogs
      pkgs.util-linux
    ];

    # 3. Define the formatting service running completely inside Stage 1 systemd
    systemd.services.initrd-format-kubevirt-disk = {
      description = "Format secondary KubeVirt volume before pivot-root";

      # Hook into the early initrd device discovery phase
      wantedBy = [ "initrd-root-device.target" ];
      before = [ "initrd-root-device.target" ];
      after = [ "systemd-modules-load.service" ];

      path = [
        pkgs.gptfdisk
        pkgs.e2fsprogs
        pkgs.util-linux
      ];

      unitConfig = {
        DefaultDependencies = false;
      };

      script = ''
        TARGET_DEVICE="/dev/vdb"

        echo "=== Initrd KubeVirt Storage Provisioning ==="

        # Aggressive polling for the KubeVirt block device node
        for i in {1..20}; do
          if [ -b "$TARGET_DEVICE" ]; then break; fi
          sleep 0.1
        done

        if [ ! -b "$TARGET_DEVICE" ]; then
          echo "CRITICAL ERROR: Required disk $TARGET_DEVICE did not appear!" >&2
          exit 1
        fi

        # Check if device is completely blank
        if ! blkid "$TARGET_DEVICE" >/dev/null 2>&1; then
          echo "Device $TARGET_DEVICE is blank. Creating partition layout..."

          # Create a single GPT partition spanning the whole disk
          sgdisk -N 1 "$TARGET_DEVICE" || exit 1

          # Force the kernel to instantly notice the new partition inside the initrd
          udevadm settle || true

          echo "Formatting /dev/vdb1 with label 'runner-storage'..."
          mkfs.ext4 -O mmp -L runner-storage /dev/vdb1 || exit 1
        fi
        echo "=== Initrd Storage Provisioning Complete ==="
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  # 4. Use native NixOS filesystem mounting with top structural priority
  fileSystems."/var/lib" = {
    device = "/dev/disk/by-label/runner-storage";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];

    # Crucial: Tells NixOS to mount this in Stage 1 so it's ready when systemd transitions to Stage 2
    neededForBoot = true;
  };
}
