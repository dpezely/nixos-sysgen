#! /run/current-system/sw/bin/bash

# Useful while developing & debugging `sysgen.sh`, otherwise unnecessary

# Reset by unmounting target file systems to begin again gracefully

sudo umount /target/home
sudo umount /target/boot/efi
sudo umount /target

sudo cryptsetup luksClose /dev/mapper/homecrypt
