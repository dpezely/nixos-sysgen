#! /bin/sh
#! /run/current-system/sw/bin/bash
set -x
# System Generation with Home Manager: install Home Manaer for NixOS
# and install a progression of configurations from minimal, nominal
# to optimal.

# Requires configurations adhering to Home Manager 20.09 or newer
# because of username and home directory named explicitly within the
# `home.nix` config file.  This ensures the correct config for the
# current user.

# Usage example on a running NixOS installation for separate users:

# ./sysgen-home.sh \
#    home-{alice,bob}-minimal.nix \
#    home-{alice,bob}-nominal.nix \
#    home-{alice,bob}-optimal.nix

# When installing a configuration for a different user than the one
# running this script, `sudo` gets invoked.  Only the active user
# needs sudo privileges, such as an admin installing for an employee
# or parent installing for a child.

# Based upon the Principle of Least Permission, it's unnecessary
# running this script with privileges.  Instead, you will be prompted
# for your password when `sudo` gets invoked.

# PRECONDITIONS: NixOS already running and configured; see sysgen.sh

set -e

# NixOS version isn't a parameter because this script is opinionated
# about commands it uses.  However, little tends to change between
# modern NixOS releases that would impact this script in particular.
NIXOS_VERSION=20.09
HOME_MANAGER_URL="https://github.com/nix-community/home-manager/archive/release-${NIXOS_VERSION}.tar.gz"

for param in "$@"; do
    case $param in
        --*)
            echo "Unknown parameter: $param"
            exit 1
            ;;
        *)
            conf_files="$conf_files $param"
            ;;
    esac
done

uid=$(id -u)

if [ $uid = 0 ]; then
    echo "Avoid running this script as root: $0"
    echo "Instead, it will prompt for your password when invoking sudo,"
    echo "and nix channels are managed at the user-level."
    exit 1
fi

echo "sysgen: You may be prompted for password by sudo."

echo 'export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH' \
    > /tmp/HM.$$.sh
export BASH_ENV=/tmp/HM.$$.sh

for conf in $conf_files; do
    if [ ! -f "$conf" ]; then
        echo "Unable to find your file to become ~/.config/nixpkgs/home.nix"
        echo "Not found: $conf"
        exit 1
    fi
    echo "sysgen: Examining: $conf"

    # Extract username and homeDirectory from this config.
    # Use of grep is fragile here, so home.nix older than 20.09 fails:
    username=$(grep -m 1 username $conf | sed 's/^.*"\([^"]*\)".*$/\1/')
    home_path=$(grep -m 1 homeDirectory $conf | sed 's/^.*"\([^"]*\)".*$/\1/')

    if [ -z "$username" -o -z "$home_path" ]; then
        echo "sysgen: unable to extract username, homeDirectory from $conf"
    else
        echo "sysgen: Deploying: $conf"

        # "Like packages installed via nix-env, channels are managed at user-level."
        # --https://nixos.wiki/wiki/Nix_channels
        if [ "$USER" = "$username" ]; then
            mkdir -p "$home_path/.config/nixpkgs"
            if [ ! $(nix-instantiate '<nixpkgs>' -A hello) ]; then
                echo "Sanity check failed for $username"
            else
                # Don't test for existence, as /home may predate OS install
                nix-channel --add "$HOME_MANAGER_URL" home-manager
                # Separate `bash -l` processes are equivalent to logout & login
                bash -l -c 'nix-channel --update'
                bash -l -c 'nix-shell "<home-manager>" -A install'
                # Deploy config:
                cp -b --preserve=timestamps $conf \
                    "$home_path/.config/nixpkgs/home.nix"
                bash -l -c "home-manager switch"
            fi
        else                    # same but with `sudo -u $username`
            sudo -u $username mkdir -p "$home_path/.config/nixpkgs"
            if [ ! $(sudo -u $username nix-instantiate '<nixpkgs>' -A hello) ]; then
                echo "Sanity check failed for $username"
            else
                sudo -u $username \
                    nix-channel --add '$HOME_MANAGER_URL' home-manager
                sudo -u $username nix-channel --update
                sudo -u $username --preserve-env=BASH_ENV \
                    nix-shell '<home-manager>' -A install
                sudo -u $username cp -b --preserve=timestamps $conf \
                    "$home_path/.config/nixpkgs/home.nix"
                sudo -u $username --preserve-env=BASH_ENV home-manager switch
            fi
        fi
    fi
done

echo -e "\nsysgen: Done."
