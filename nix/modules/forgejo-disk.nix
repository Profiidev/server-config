{ pkgs, ... }:
{

  systemd.services.auto-mount-kubevirt-disk = {
    description = "Format and mount secondary KubeVirt volume by KubeVirt name";

    # Run as part of the system initialization phase, before standard local filesystems are checked
    requiredBy = [ "local-fs.target" ];
    before = [ "local-fs.target" ];

    # Ensure udev has triggered and populated /dev/disk/by-id/ paths
    after = [ "systemd-udev-settle.service" ];
    conflicts = [ "shutdown.target" ];

    onFailure = [ "emergency.target" ];

    path = [
      pkgs.util-linux
      pkgs.e2fsprogs
      pkgs.gptfdisk
    ];

    script = ''
      # Match the 'name' from your KubeVirt yaml manifest
      TARGET_DEVICE="/dev/vdb"
      MOUNT_PATH="/var/lib"

      # Wait up to 5 seconds for KubeVirt to surface the hotplugged device
      for i in {1..5}; do
        if [ -b "$TARGET_DEVICE" ]; then
          break
        fi
        echo "Waiting for $TARGET_DEVICE..."
        sleep 1
      done

      if [ ! -b "$TARGET_DEVICE" ]; then
        echo "Error: Target disk $TARGET_DEVICE did not appear."
        exit 1
      fi

      # Check if device already has a filesystem or partition layout
      if ! blkid "$TARGET_DEVICE" >/dev/null 2>&1; then
        echo "Device $TARGET_DEVICE is blank. Initializing..."

        # Create a single GPT partition spanning the whole disk
        sgdisk -N 1 "$TARGET_DEVICE"

        # The first partition is symlinked as '-part1' by udev
        PARTITION="/dev/vdb1"

        # Force kernel to register the new partition node
        udevadm settle

        # Format the partition with a filesystem label
        mkfs.ext4 -L runner-storage "$PARTITION"
      fi

      # Safely mount it
      mkdir -p "$MOUNT_PATH"
      if ! mountpoint -q "$MOUNT_PATH"; then
        mount -L runner-storage "$MOUNT_PATH"
        echo "Successfully mounted disk to $MOUNT_PATH"
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutSec = 30;
      # Safely unmount during system stop/reboot phases
      ExecStop = "umount /var/lib || true";
    };
  };
}
