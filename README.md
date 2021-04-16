NixOS configuration for multiple laptops/workstations, with Home-Manager:
=========================================================================
With separation for home use and prototype work machines
========================================================

On new hardware or for a fresh OS install, incrementally deploy
progressively more comprehensive configuration files for NixOS and
Home-Manager.

There are two scripts: one runs during OS installation and the other after
booted into that OS image when user $HOME directories are still empty.

Use the first script-- as an example-- targeting `/dev/sda` with an existing
EFI Boot on partition `1`, NixOS to be written to Partition `2` which will
*wipe & replace* the operating system while preserving an existing encrypted
`/home` on partition `4`:
    
    ./sysgen.sh \
       --efi=sda1 \
       --nixos=sda2 --new-nixos \
       --home=sda4 --encrypted-home \
       configuration-minimal.nix \
       configuration-nominal.nix \
       configuration-optimal.nix

Alternatively, on a **new** machine or to **wipe & replace** everything:

    ./partition.sh --uefi --wipe-device=sda
    ./sysgen.sh \
       --efi=sda1   --new-efi \
       --nixos=sda2 --new-nixos \
       --home=sda4  --new-home --encrypted-home \
       configuration-[mno]*.nix

After booting into new NixOS image, deploy Home-Manager for multiple accounts:

    ./sysgen-home.sh home-{alice,bob}-[mno]*.nix

Again, the first command above will *destroy* anything on `/dev/sda2` and
install NixOS there.

If you want a fresh file system on the EFI Boot partition, add `--new-efi`.
If you want a new encrypted `/home` file system, add `--new-home`.

After applying the *sequence* of `configuration.nix` files, a similar
ordering of `home.nix` files gets applied for each of the users, Alice and
Bob, provided each is named in `configuration.nix`.

This **requires** configuration files specifying `stateVersion` of
**20.09 or newer**.  (This document uses `stable` releases.)

That's the least you need to know, assuming a partition scheme described
below.

The remainder of this document explains the [sysgen.sh](./sysgen.sh) and
[sysgen-home.sh](./sysgen-home.sh) scripts, their parameters and rationale
for using a sequence of three variants of `.nix` files.

Additional instructions for very specific use cases are in the Appendix.

## Intro
### Overview

The [sysgen.sh](./sysgen.sh) script utilizes a three step deployment strategy:

1. Bootstrap using a [minimal](./configuration-minimal.nix) config
   for the least needed to get NixOS working
2. Expand upon that base with a [nominal](./configuration-nominal.nix)
   config accommodating general use such as web, chat and email
3. Further expansion for an [optimal](./configuration-optimal.nix) config
   as the final destination

Each gets written as `/etc/nixos/configuration.nix` and applied in sequence
via `nixos-install`.  (Running `nixos-build switch` requires booting into
the instance of NixOS, thus unavailable during installation.)

As each configuration.nix file gets applied successfully by this script, the
system attains a new **known stable configuration**.

Upon completing each stage, the machine accommodates basic usage before
attempting to install every single package.  Basically, don't fail the
install due to a potentially optional package that might have an issue.

For instance, install printers in the third stage.  While a printer may be
important for your regular work, there is much that the machine can do
without a printer when stage two succeeds but stage three fails.

Names of these `configuration-*.nix` files conveniently sort alphabetically
in order of progression: minimal, nominal, optimal.  Use any names you like.

Feel free to use a single `configuration.nix` file, but some issues are more
easily investigated from within the running OS instance than via `chroot`.
Hence multiple stages each with its own config file are used here.

This script is intended to follow guidance from the NixOS Manual on
[installation](https://nixos.org/manual/nixos/stable/#ch-installation).

### Recommended Partitioning Scheme

This storage partition layout likely *differs* from others using NixOS.

The following disk/storage partitioning scheme has been used and tested with
the scripts included in this repo.

(See NixOS manual on
[partitioning](https://nixos.org/manual/nixos/stable/#sec-installation-partitioning-UEFI)
especially for EFI Boot.)

Same disk:

- Partition 1: EFI Boot partition as vFAT
- Partition 2: First OS, the target for this NixOS install
- Partition 3: Alternate OS; e.g., other Linux distro
- Partition 4: Encrypted `/home` shared between Linux distros

The above layout may be produced using the [partition.sh](./partition.sh)
script, which is a trivial script without useful options.

The primary reason for the partitioning scheme above:

The whole point is to *easily accommodate wipe & replace* of the primary
operating system without disturbing contents of `/home` and while preserving
a *previously known good working OS* installation in the "alternate"
partition.

It also helps with maintaining an alternate Linux distribution or
dual-booting another OS.  (e.g., was useful with Ubuntu LTS versus non-LTS
as separate tenants)

### Pre-install Preparation
Especially for those relatively new to NixOS and Home-Manager:

**Begin** with [NixOS installation
media](https://nixos.org/download.html#download-nixos), such as bootable
image on a USB stick/thumbdrive.

**Preview** instructions for [Installing from another Linux
distribution](https://nixos.org/nixos/manual/#sec-installing-from-other-distro),
but beware of conditional steps and multi-step sequences.

A quick skim-read of those instructions will help if your situation differs
from conditions under which the instructions below were written.

**Search** [GitHub](https://github.com/search?q=%22configuration.nix%22) and
[GitLab](https://gitlab.com/explore?utf8=%E2%9C%93&name=configuration.nix)
for sample configurations that are more current.

Remember to check those `*.nix` files for their value of
`system.stateVersion` (probably near end of file) for something reasonably
close to the version that you'll be installing.  Values represent year and
month of NixOS release.

### Bootstrapping

Boot the NixOS installer via their USB stick image.

(Alternatively, boot into another Unix/POSIX-like OS on same machine,
provided that NixOS installation utilities are in $PATH.)

The results of running `nix-channel --list` will likely be empty on a new
machine.

Continue reading to use the [sysgen.sh](./sysgen.sh) script.

## Step 1: Minimal NixOS Installation

Everything happens from this one custom script, [sysgen.sh](./sysgen.sh),
for System Generation: install NixOS onto a new or existing machine.

Again, this begins by using a minimal config-- the least you need to get a
working system that is usable for next steps towards attaining a nominally
usable that accommodate common use cases and finally your optimal setup.

No user-preferred software gets installed at this stage because we don't
want to risk the installation failing due to a problem with an arbitrary
piece of software.

> **WARNING:** specifying one of several options to the script will
> *destroy* a different storage partition by overwriting it with a new
> file-system.

At minimum, this script mounts file systems to be used by NixOS during its
installation.

File system specified for `/home` may be optionally encrypted.

> Why encrypt /home?
>
> If for no other reason, all storage devices eventually fail.  When they
> do, you will likely be without opportunity to wipe its contents before
> properly disposing of the defunct media.  Therefore, consider the entire
> lifecycle of your storage devices before you begin using each one.
>
> For protecting everything else, consider BIOS encryption of the entire
> disk.  It's less than ideal but more than sufficient for most uses.

Usage example with `/dev/sda` and NixOS being written to Partition `2`
on an **existing** machine:

    ./sysgen.sh \
       --efi=sda1 \
       --nixos=sda2 --new-nixos \
       --home=sda4 --encrypted-home \
       configuration-minimal.nix

On a **new** machine or new SSD/disk, *all* file systems need to be created:

    ./partition.sh --uefi --wipe-device=sda
    ./sysgen.sh \
       --efi=sda1 --new-efi \
       --nixos=sda2 --new-nixos \
       --home=sda4 --new-home --encrypted-home \
       configuration-minimal.nix

Based upon the Principle of Least Permission, it's unnecessary running these
scripts with privileges.  Instead, each prompts for your password when
`sudo` gets invoked selectively.

**PRECONDITIONS:**

1. SSD/disk storage partitions must have already been created via `gparted`
   or `fdisk` or similar;
   + See NixOS manual on
   [Partitioning](https://nixos.org/manual/nixos/stable/#sec-installation-partitioning)
   + See [partition.sh](./partition.sh) for an *opinionated* approach
2. Installation utilities for NixOS must be accessible via `$PATH`, such as
   when booting from official NixOS installation media.

## Step 2: Nominal Use

Continuing the example with `/dev/sda` and NixOS being written to Partition
`2` after having installed the *minimal* configuration, and install the
*nominal* version:

    ./sysgen.sh \
       --efi=sda1 \
       --nixos=sda2 \
       --home=sda4 --encrypted-home \
       configuration-nominal.nix

Note that the config file changed to *nominal.nix*, and the various
parameters that would have an adverse impact to any file system have been
removed.

Items added to the resulting `configuration.nix` file might include
[Home-Manager](https://github.com/nix-community/home-manager), cron jobs,
other services, virtualization hosts such as VirtualBox, etc.

On a new machine with a freshly created `/home`, there will be nothing to do
for Home-Manager yet.

Whether or not to include Home-Manager within a top-level
`configuration.nix` file gets debated with strong opinions on each side.

Arguments *against* it emphasize strict robustness, because you don't want
problems in user-land blocking a system upgrade.

Arguments *for* it often focus on convenience for the end-user because
updates may be a one-step process, albeit all-or-nothing success/fail.

Mainly, the definition of "nominal" for your should be based upon having
enough to be functional for the majority of your tasks.  For many people,
this might exclude printers because those can introduce a world of hurt.

## Step 3: Optimal For Daily Work

This third round may be unnecessary for most people and conventional use
cases.

For this stage, `configuration-optimal.nix` adds printers, a distinction
between accounts for personal versus work use, etc.  Printers can be
problematic due to seemingly random coverage for drivers, which is why it
gets deferred to this later stage.

Continuing the example with `/dev/sda` and NixOS being written to Partition
`2` after having installed both the *minimal* and *nominal* configuration.nix
files in sequence:

    ./sysgen.sh \
       --efi=sda1 \
       --nixos=sda2 \
       --home=sda4 --encrypted-home \
       configuration-optimal.nix

Note that the config file changed again but to *optimal.nix*.

Upon successful completion, the machine should be ready for all usernames
specified in that `.nix` file for daily work.

If using Home-Manager, however, keep reading...

## Home-Manager
It has been said many times within the Nix and NixOS communities that nearly
everyone there uses Home-Manager with slim exception of the newest and most
experienced members of the community.

This script is but one humble approach to simplify things for Nix newbies.

The idea of sysgen.sh above continues here but applied to each user's home
directory.

That is, progressively more comprehensive configurations get applied.  After
all when things go wrong, it's generally easier to resolve issues from
within a working system than from outside.  Therefore, this avoids the
all-or-nothing consequences that many new to Home-Manager often experience.

Usage is similar to the above script:

    ./sysgen-home.sh \
       home-{alice,bob}-minimal.nix \
       home-{alice,bob}-nominal.nix \
       home-{alice,bob}-optimal.nix

More concisely:

    ./sysgen-home.sh home-*.nix

The script extracts `username` and `homeDirectory` from each `.nix` file
supplied and installs it judiciously.

Because of that functionality, *only `home.nix` files for 20.09 or newer*
are supported.

The script uses `sudo` targeting each named user when adding the channel,
updating channels and installing the config as the user's `home.nix` file.

Channels are added only once per user for each run of the script, regardless
of number of variants given for each user.  Multiple adds should be benign,
such as when testing new configuration files.

### Why Separate Scripts?
Ideally, `sysgen-home.sh` would be called as part of `sysgen.sh` but that
would fail for the following reasons.

- Essentially, `nixos-install` just writes bits to the storage device
- When running `nixos-build` or `nix-instantiate`, run-time services are
  required:
  + Communication with these requires `/proc` or sockets such as
    `/nix/var/nix/daemon-socket/socket`
  + Those of course aren't connected when `nixos-install` runs from NixOS
    installation media
- Overly complicated hacks such as extracting a necessary utility to run
  within a chroot'd environment ultimately would require replicating
  significant parts of NixOS management, which would be counter-productive

In short, separating functionality as with scripts in this repo was borne
out of necessity-- not choice.  The only real choice was isolating each bit
of functionality into its own script for simplicity of usage and
maintenance.

## Caveat about included `home.nix` files
Conventional use of Home-Manager would control *all* your config files such
as `~/.bashrc`, but that is **not** currently the case here.

Such config files under Home-Manager remain a work-in-progress.

Fortunately when custom dot files already exist, Home-Manager refrains from
overwriting anything.

The included `home-*.nix` files explicitly avoid using managed dot files
nearly everything except web browsers.  (e.g., the `~/.emacs` file that
originated with Emacs 18.50-something will take some time before being
completely migrated-- if ever.)

## Appendix
### Dual-Boot Linux/Linux
Play nice with dual-boot Linux/Linux (e.g., NixOS versus Xubuntu) where
PATHs differ (such as for autostart, plank, jumpapp), because NixOS doesn't
abide by Linux FHS policies.

Consider:

	XDG_CONFIG_HOME = $HOME/.config_nixos

while preserving `$HOME/.config` for the other Linux distro on this same
machine.

Maybe begin with:

    rsync -a ~/.config/ ~/.config_nixos/

And add the following to your `configuration-optimal.nix` file, and be
certain to maintain a consistent path above with the one below:

    environment.variables = {
      XDG_CONFIG_HOME = "$HOME/.config_nixos";
    }

Within each subdirectory tree, avoid sharing via hard-links or sym-links in
case any particular app modifies a config file in-place.

For instance, convert keyboard shortcut settings to use NixOS paths.

Change from `/usr/bin/` to `/run/current-system/sw/bin/` using `sed`
utility:

    sed 's%/usr/bin/%/run/current-system/sw/bin/%g' \
     < ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
     > /tmp/xfce4-keyboard-shortcuts.xml

    cp /tmp/xfce4-keyboard-shortcuts.xml \
       ~/.config_nixos/xfce4/xfconf/xfce-perchannel-xml/

Perform similar updates for the following files.  However, create an
intermediate file which then gets copied whole into place.  Otherwise,
settings managers may mangle contents as these files are being overwritten.

- `~/.config/autostart/*.desktop`
- `~/.config/plank/dock*/launchers/*.dockitem`

### Xfce4 Keyboard Shortcuts
- Edit `~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml`
- Considering using `jumpapp` so that tapping the same key chord later
  brings window manager focus to the same window
- Path to anything installed via Home-Manager is `$HOME/.nix-profile/bin`
  but may need to manually expand `$HOME`
- Path to anything installed via configuration.nix would be
  `/run/current-system/sw/bin/`
### Emacs
https://www.reddit.com/r/NixOS/comments/mogdox/fastest_way_of_getting_emacs_with_nixmode_during/

For one-off runs:

    nix-shell --packages '(pkgs.emacsPackagesGen pkgs.emacs-nox).emacsWithPackages (f: [f.melpaPackages.nix-mode])'

### Rust Programming Language

Example: building a release of a Rust language project

First option is installing
[cargo](https://search.nixos.org/packages?query=cargo#result-cargo) /
[rustup](https://search.nixos.org/packages?query=rust#result-rustup)
system-wide in `/etc/nixos/configuration.nix`, which then would allow
compiling Rust projects as with any other Linux distro.

Second option is for containment and isolation via `nix-shell` on-demand:

    cd project/
    nix-shell -p cargo
    cargo build

In both cases-- similarly as with other Linux distros-- the compiler
toolchain lags behind official releases from
[rust-lang.org](https://rust-lang.org)

See Also:

- https://notes.srid.ca/rust-nix
- https://www.reddit.com/r/NixOS/comments/mr394e/how_do_you_install_packages_not_in_nixpkgs/

### Android Dev Kit

Example: build a release of an Android app with embedded Rust-based library

TODO

### Suspicious Software

Example: running Microsoft Teams, Skype or Zoom

While a machine unplugged when not used may be best, followed by a proper
virtual machine, then perhaps a sandbox like BSD Jails...  
(And of course you know better than using Docker or LXC containers as a security measure, right?  RIGHT?)  
A `chroot`'d environment is better than nothing.

NixOS as a better tripwire:  
A compromised executable leads to checksum comparison failure for early
detection, which was a commonly used technique in the
[1990's](https://dl.acm.org/doi/10.1145/191177.191183).

Finally, disposing of dependencies-- or at least destroying a hospitable
environment in which the potentially compromised app requires to run-- as
happens when using `nix-shell`...  

The overall attack vector will have been greatly reduced and detection
heightened.

TODO

### Printer
This is an example of adapting an existing NixOS printer driver
for creating a *similar* one: Brother MFC J470DW vs MFC J870DW
(i.e., `400` series versus `800`).

There is an existing [lpr driver](https://github.com/NixOS/nixpkgs-channels/blob/nixos-unstable/pkgs/misc/cups/drivers/mfcj470dwlpr/)
and
[CUPS wrapper](https://github.com/NixOS/nixpkgs-channels/blob/nixos-unstable/pkgs/misc/cups/drivers/mfcj470dwcupswrapper/)
for the other printer since 2016.

NixOS packages may be created from Debian packages, which is how that one
functions.

Files to be substituted come from the manufacturer's official support website for
[MFC
J870DW](https://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=mfcj870dw_us_eu_as&os=128).

Values within the Nix package to be substituted:

- Product / device name appears in multiple locations throughout each
  `default.nix` file
- URL to tarball containing `.deb` file
  + The friendly Arch Linux community has direct URLs to RPM versions
  + https://aur.archlinux.org/packages/brother-mfc-j870dw/
- SHA256 checksum of tarball
- Be sure to update the `downloadPage` value
- Revise `maintainers` list at bottom of each `default.nix` file

Tasks:

1. Clone entire [nixpkgs-channels](https://github.com/NixOS/nixpkgs-channels)
   repo, which as of the eve of NixOS 21.05 is roughly 1 GiB in size:
   + `git clone https://github.com/NixOS/nixpkgs-channels`
2. Replicate selected drivers as placeholders for new ones:
   + `cd nixpkgs-channels/pkgs/misc/cups/drivers/`
   + `cp -pr mfcj470dwlpr/ mfcj870dwlpr/`
   + `cp -pr mfcj470dwcupswrapper/ mfcj870dwcupswrapper/`
3. Modify:
   + Confirm strict case sensitivity:  
     `grep -c mfcj470dw mfcj870dw*/default.nix` vs
     `grep -c -i mfcj470dw mfcj870dw*/default.nix`
   + First global replace-- note use of `g` at end of `sed` command:  
     `sed -i 's/mfcj470dw/mfcj870dw/g' mfcj870dw*/default.nix`
   + Inspect for other instances of product name:  
     `grep 470 mfcj870dw*/default.nix`
   + Second global replace:  
     `sed -i 's/MFC-J470DW/MFC-J870DW/g' mfcj870dw*/default.nix`
   + Confirm changes occurred:  
     `grep -i 'mfc.*j470dw' mfcj870dw*/default.nix`
   + Revise and confirm URLs manually...
   + Download URLs...
   + Compute SHA256 sums:  
     `shasum -a 256 mfcj870dw*`
   + Substitute checksums manually...
4. Test locally...
5. Create Pull Request...

### Servers
- OpenSSL lurks as a dependency such as with ipsec-tools
  + See pkgs/top-level/all-packages.nix
  + `grep ipsecTools -A 4 pkgs/top-level/all-packages.nix`
### CI/CD Pipeline
- https://hydra.nixos.org/
  + https://github.com/NixOS/hydra
  + https://nixos.wiki/wiki/Hydra
- https://www.reddit.com/r/NixOS/comments/mosc45/cs_syd_the_cinix_pattern/
- https://cs-syd.eu/posts/2021-04-11-the-ci-nix-pattern?source=reddit

## References

Referenced directly or indirectly from this document:

- [Install NixOS](https://nixos.org/manual/nixos/stable/#ch-installation)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
  + [NixOS options](https://nixos.org/manual/nixos/stable/options.html)
  + [NixOS packages](https://nixos.org/nixos/packages.html)
  + [search](https://search.nixos.org/packages)
- Home-Manager:
  + Nix community [Home-Manager](https://github.com/nix-community/home-manager)
  + rycee's original [Home-Manager](https://rycee.gitlab.io/home-manager/)
  + [Home-Manager options](https://nix-community.github.io/home-manager/options.html)
  + Use the same set of packages from NixOS for Home-Manager
- [NixOS Forum](https://discourse.nixos.org/)
- [Planet NixOS](https://planet.nixos.org/)

Keeping up with the Nixes:

- [weekly.nixos.org](https://weekly.nixos.org/) since 2017


See also:

- [home-manager-helper](https://dustinlacewell.github.io/home-manager-helper/)
