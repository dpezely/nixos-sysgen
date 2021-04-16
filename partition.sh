#! /run/current-system/sw/bin/bash

# For disk partitioning, see the NixOS manual:
# https://nixos.org/manual/nixos/stable/#sec-installation-partitioning-UEFI

# This script probably DOESN'T do what you want.

# You've been warned.

# Preliminary to running sysgen.sh for the first time on new hardware,
# format target disk with partitioning scheme using alternate A/B (or
# red/green, etc.) root file systems, with separate EFI Boot, separate
# /home partitions.  This accommodates wipe & replace of OS without
# disturbing alternate OS or personal files.

# Example for EFI Boot on /dev/sda1, NixOS on /dev/sda2 and /Home on
# /dev/sda4, run:

# ./partition.sh --uefi --wipe-device=sda

# See README file for details.

set -e

for param in "$@"; do
    case $param in
        --uefi)
            use_gpt=1
            ;;
        --wipe-device=*)
            device="${param#*=}"
            ;;
        *)
            echo "Unknown parameter: $param"
            exit 1
            ;;
    esac
done

if [ -z "$use_gpt" ]; then
    echo "Confirm this is an UEFI system and thus use GPT (and not MBR)"
    echo "by supplying parameter: --uefi"
    exit 1
elif [ -z "$device" -o ! -b /dev/$device ]; then
    echo "Confirm that you will DESTROY ALL contents of storage device"
    echo "by supplying parameter --wipe-device=foo for /dev/foo{1,2,3,4}"
    exit 1
fi

# Note: swap partition is omitted because if you expect Linux to use
# swap, you're better off using a BSD flavour of Unix.  Therefore,
# create a swap file, but monitor it for when to reboot for sanity.

# The GNU Parted User Manual:
# https://www.gnu.org/software/parted/manual/parted.html#mkpart

# For SSD and modern disks, use GPT:
sudo parted /dev/$device -- mklabel gpt

# EFI Boot partition:
sudo parted /dev/$device -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/$device -- set 1 esp on

# NixOS partition:
sudo parted /dev/$device -- mkpart primary 512MiB 25.5GiB

# Other future OS partition:
sudo parted /dev/$device -- mkpart primary 25.5GiB 50.5GiB

# /home partition:
sudo parted /dev/$device -- mkpart primary 50.5GiB 100%

echo "Done."
