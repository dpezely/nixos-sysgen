#! /bin/sh
#! /run/current-system/sw/bin/bash
set -x
# System Generation: install NixOS onto a new or existing machine
# when booted from official NixOS installation media.


# WARNING: specifying one of several options will destroy a different
# storage partition by overwriting it with a new file-system.


# This script mounts file systems to be used by NixOS during its
# installation.  These file systems may optionally be created, thus
# destroying anything previously existing on that partition.

# File system specified for /home may be optionally encrypted.

# Usage example with /dev/sda and NixOS being written to Partition 2
# on an existing machine.  Wipe & replace the operating system while
# preserving an encrypted /home parition:

# ./sysgen.sh \
#    --efi=sda1 \
#    --nixos=sda2 --new-nixos \
#    --home=sda4 --encrypted-home \
#    configuration-minimal.nix \
#    configuration-nominal.nix \
#    configuration-optimal.nix

# Based upon the Principle of Least Permission, it's unnecessary
# running this script with privileges.  Instead, you will be prompted
# for your password when `sudo` gets invoked.

# PRECONDITIONS:
# 1) SSD/disk storage partitions must have already been created via
# `gparted` or `fdisk` or similar;
# 2) Installation utilities for NixOS must be accessible via $PATH,
# such as when booting from official NixOS installation media.

set -e

# NixOS version isn't a parameter because this script is opinionated
# about commands it uses.  However, little tends to change between
# modern NixOS releases that would impact this script in particular.
NIXOS_VERSION=20.09
NIXOS_URL="https://nixos.org/channels/nixos-${NIXOS_VERSION}"

for param in "$@"; do
    case $param in
        --efi=*)
            efi_part="${param#*=}"
            ;;
        --new-efi)
            efi_newfs=1
            ;;
        --nixos=*)
            nixos_part="${param#*=}"
            ;;
        --new-nixos)
            nixos_newfs=1
            ;;
        --home=*)
            home_part="${param#*=}"
            ;;
        --new-home)
            home_newfs=1
            ;;
        --encrypted-home)
            home_encrypted=1
            ;;
        --*)
            echo "Unknown parameter: $param"
            exit 1
            ;;
        *)
            conf_files="$conf_files $param"
            ;;
    esac
done

for conf in $conf_files; do
    if [ ! -f "$conf" ]; then
        echo "Unable to find your file to become /target/etc/nixos/configuration.nix"
        echo "Not found: $conf"
        exit 1
    fi
done
if [ -z "$efi_part" -o ! -b /dev/$efi_part ]; then
    echo "Please specify device for EFI Boot partition; e.g., sda1 for /dev/sda1"
    [ -b /dev/$efi_part ] || echo "Not valid: /dev/$efi_part"
    exit 1
elif [ -z "$nixos_part" -o ! -b /dev/$nixos_part ]; then
    echo "Please specify device for NixOS installation; e.g., sda2 for /dev/sda2"
    [ -b /dev/$nixos_part ] || echo "Not valid: /dev/$nixos_part"
    exit 1
elif [ -z "$home_part" -o ! -b /dev/$home_part ]; then
    echo "Please specify device for /home; e.g., sda4 for /dev/sda4"
    [ -b /dev/$home_part ] || echo "Not valid: /dev/$home_part"
    exit 1
elif [ "$home_encrypted" -a ! -e "$(which cryptsetup)" ]; then
    echo 'For encrypted /home, `cryptsetup` must be installed.'
    exit 1
fi

# First, try for single, non-nested user definition:
user_names=$(grep 'users\.users\.' $conf_files | \
                 sed 's/^.*users\.users\.\([a-zA-Z0-9]*\)=.*$/\1/')
if [ -z "$user_names" ]; then
    # Probably should have used Perl4 for this entire script...
    for x in $(grep -H -n 'users\.users =' $conf_files | awk '{print $1}'); do
        conf=$(echo $x | cut -d ':' -f 1)
        line_number=$(echo $x | cut -d ':' -f 2)
        name=$(head -n $(( line_number + 1 )) $conf | tail -1 | \
                   sed 's/^\s*\([-a-zA-Z0-9]*\).*$/\1/')
        if [ -z "$(echo $user_names | grep $name)" ]; then
            user_names="$user_names $name"
        fi
    done
fi
if [ -z "$user_names" ]; then
    echo "Unable to extract user names from $conf_files"
    exit 1
fi
first_user=$(echo $user_names | cut -d ' ' -f 1)


[ $(id -u) = 0 ] || echo -e "\nsysgen: You may be prompted for password by sudo.\n"


# Ensure that the target mount point exists.  (Preserve /mnt for other uses.)
[ -d /target ] || sudo mkdir /target

# OS partition:
if [ "$nixos_newfs" ]; then
    # Create new file system
    sudo mkfs.ext4 -L NixOS /dev/$nixos_part
fi
sudo mount -o discard,noatime /dev/$nixos_part /target

# EFI boot partition:
if [ "$efi_newfs" ]; then
    # Create new file system
    sudo mkfs.vfat -F 32 -n EFI /dev/$efi_part
fi
[ -d /target/boot/efi ] || sudo mkdir -p /target/boot/efi
sudo mount /dev/$efi_part /target/boot/efi

# /home partition:
[ -d /target/home ] || sudo mkdir /target/home
if [ "$home_newfs" ]; then
    # Create new file system
    if [ "$home_encrypted" ]; then
        echo "Overwriting destination for /home per conventional practices"
        sudo dd if=/dev/urandom of=/dev/$home_part bs=1M status=progress
        sudo cryptsetup -h sha256 luksFormat /dev/$home_part
        sudo cryptsetup luksOpen /dev/$home_part homecrypt
        sudo mkfs.ext4 -L "Home encrypted" /dev/mapper/homecrypt
        sudo mount -o discard,noatime /dev/mapper/homecrypt /target/home
    else
        sudo mkfs.ext4 -L Home /dev/$home_part
        sudo mount -o discard,noatime /dev/$home_part /target/home
    fi
else
    # Use existing file system
    if [ "$home_encrypted" ]; then
        sudo cryptsetup luksOpen /dev/$home_part homecrypt
        sudo mount -o discard,noatime /dev/mapper/homecrypt /target/home
    else
        sudo mount -o discard,noatime /dev/$home_part /target/home
    fi
fi


# Sanity check: confirm each file system has been mounted
[ $(grep -c "/target " /etc/mtab) = 1 ] || \
    (echo "mount /target for NixOS" && lsblk && false)
[ $(grep -c "/target/boot/efi " /etc/mtab) = 1 ] || \
    (echo "mount /target/boot/efi" && lsblk && false)
[ $(grep -c "/target/home " /etc/mtab) = 1 ] || \
    (echo "mount /target/home" && lsblk && false)


# The following commands were largely ripped from
# https://nixos.org/manual/nixos/stable/#ch-installation

sudo nix-channel --add "$NIXOS_URL" nixpkgs
sudo nix-channel --update

nix-env -iE "_: with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [ nixos-generate-config nixos-install nixos-enter manual.manpages ]"

# Populate OS disk partition with NixOS bits
sudo $(which nixos-generate-config) --root /target


# Integrity checks:

# Compare values of UUIDs within hardware-configuration.nix file with output of `lsblk`.
efi_uuid=$(lsblk -n -o uuid /dev/$efi_part)
nixos_uuid=$(lsblk -n -o uuid /dev/$nixos_part)
if [ $home_encrypted ]; then
    home_uuid=$(lsblk -n -o uuid /dev/mapper/homecrypt)
else
    home_uuid=$(lsblk -n -o uuid /dev/$home_part)
fi

hw=/target/etc/nixos/hardware-configuration.nix
# Look in that file for semantic equivalents of:
#    fileSystems."/home".device = "dev/disk/by-uuid/...";
#    boot.initrd.luks.devices."homecrypt".device = "/dev/disk/by-uuid/...";
line_number=$(grep -H -n 'fileSystems."/boot/efi"' $hw | cut -d ':' -f 2)
if [ -z "$line_number" -o $line_number = 0 ]; then
    echo "Unable to find /boot/efi in $hw file"
    exit 1
fi
check_efi_uuid=$(head -n $(( line_number + 1 )) $hw | tail -1 | \
                     sed 's/^.*by-uuid.\(.*\).;$/\1/')
line_number=$(grep -H -n 'fileSystems."/"' $hw | cut -d ':' -f 2)
if [ -z "$line_number" -o $line_number = 0 ]; then
    echo "Unable to find root partition in $hw file"
    exit 1
fi
check_nixos_uuid=$(head -n $(( line_number + 1 )) $hw | tail -1 | \
                       sed 's/^.*by-uuid.\(.*\).;$/\1/')
line_number=$(grep -H -n 'fileSystems."/home"' $hw | cut -d ':' -f 2)
if [ -z "$line_number" -o $line_number = 0 ]; then
    echo "Unable to find /home partition in $hw file"
    exit 1
fi
check_home_uuid=$(head -n $(( line_number + 1 )) $hw | tail -1 | \
                      sed 's/^.*by-uuid.\(.*\).;$/\1/')

if [ "$check_efi_uuid" != "$efi_uuid" ]; then
    echo "Sanity check failed for /target/efi/boot ($efi_part)"
    echo "Expected: $efi_uuid"
    echo "Found:    $check_efi_uuid"
    lsblk --fs
    exit 1
elif [ "$check_nixos_uuid" != "$nixos_uuid" ]; then
    echo "Sanity check failed for /target ($nixos_part)"
    echo "Expected: $nixos_uuid"
    echo "Found:    $check_nixos_uuid"
    lsblk --fs
    exit 1
elif [ "$check_home_uuid" != "$home_uuid" ]; then
    echo "Sanity check failed for /target/home ($home_part)"
    echo "Expected: $home_uuid"
    echo "Found:    $check_home_uuid"
    lsblk --fs
    exit 1
fi


# Finally, install NixOS based upon specified file for configuration.nix

for conf in $conf_files; do
    echo -e "\nsysgen: Deploying: $conf\n"

    # Put your preferred NixOS config file into its proper place
    sudo cp -b --preserve=timestamps "$conf" /target/etc/nixos/configuration.nix

    # Perform the actual NixOS install; set password at end of this script
    sudo nixos-install --root /target --no-root-passwd
done

echo -e "\nsysgen: NixOS install has completed.  Finishing...\n"

if [ "$home_encrypted" ]; then
    echo "Closing encrypted volume gracefully"
    sudo umount /target/home
    sudo cryptsetup luksClose /dev/mapper/homecrypt
fi


# All this, just to confirm whether or not password needs to be set...
# First, try for single, non-nested user definition:
user_names=$(grep 'users\.users\.' $conf_files | \
                 sed 's/^.*users\.users\.\([a-zA-Z0-9]*\)=.*$/\1/' | \
                 sort -u)
if [ -z "$user_names" ]; then
    # This is why Perl4 thrived...
    for x in $(grep -H -n 'users\.users =' $conf_files | awk '{print $1}'); do
        conf=$(echo $x | cut -d ':' -f 1)
        line_number=$(echo $x | cut -d ':' -f 2)
        name=$(head -n $(( line_number + 1 )) $conf | tail -1 | \
                   sed 's/^\s*\([-a-zA-Z0-9]*\).*$/\1/')
        if [ -z "$(echo $user_names | grep $name)" ]; then
            user_names="$user_names $name"
        fi
    done
fi

# Globbing a path for use within chroot for `passwd`
sbin=$(ls -1td /target/nix/store/*-system-path/sbin | head -1 | sed 's%^/target%%')

# Set root password here so that installs above proceed unattended:
echo "sudo chroot /target passwd root"
sudo chroot /target $sbin/passwd root

for name in $user_names; do
    if [ $(grep -c "^${name}:" /target/etc/passwd) != 0 ]; then
        echo "sudo chroot /target passwd $name"
        sudo chroot /target $sbin/passwd $name
    fi
done

echo -e "\nsysgen: Done."
