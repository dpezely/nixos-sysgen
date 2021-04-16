# Optimal version of /etc/nixos/configuration.nix

# See https://nixos.org/nixos/manual/ or configuration.nix(5) man page,
# https://nixos.org/manual/nixos/stable/options.html
# or when running locally, run ‘nixos-help’ which opens the web browser
# to a `file:` URL.

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # For less wear & tear on SSD, add options: noatime,discard
  fileSystems = {
    "/".options = [ "noatime" "discard" "errors=remount-ro" ];
    "/boot/efi".options = [ "noatime" "umask=0077" ];
    "/home".options = [ "noatime" "discard" ];
  };

  # https://nixos.org/nixos/manual/options.html#opt-swapDevices
  # Being Linux and not BSD Unix, using swap indicates overload, so keep it small
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];

  boot = {
    # The systemd-boot EFI boot loader is unable to load EFI binaries
    # from other partitions, so use Grub2 instead for dual-boot.
    loader = {
      systemd-boot.enable = false;
      efi.efiSysMountPoint = "/boot/efi";
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        devices = [ "nodev" ]; # Must be set for an ASSERT to pass in grub.nix
        enableCryptodisk = true;
        useOSProber = true; # Append entries for other OSs detected by os-probe
      };
    };

    # initrd.luks.devices."homecrypt".fallbackToPassword = true;
    plymouth.enable = false;

    #cleanTmpDir = true;
    tmpOnTmpfs = true;
  };

  networking = {
    hostName = "nixos"; # FIXME: Define your hostname.

    # NetworkManager may be controlled by `nmcli` or `nmtui` or desktop widget.
    # Users that can change settings must belong to the networkmanager group.
    networkmanager.enable = true;

    # Deprecated:
    # https://nixos.org/manual/nixos/stable/options.html#opt-networking.useDHCP
    useDHCP = false;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };
  
  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_CA.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "en_CA.UTF-8/UTF-8" ];
  };
  console.keyMap = "us";
  time.timeZone = "Canada/Pacific";

  # List packages installed in system profile. To search, run: nix search wget
  environment.systemPackages = with pkgs; [
    cryptsetup

    # Home-Manager should be installed per-user so that user-land issues can't
    # block OS updates: `nix-shell "<home-manager>" -A install`
    # FIXME v20.09 as of 2021-04-14, per-user `home-manager` can't be found.
    home-manager                # DELETE ME

    ntp

    # These require nixpkgs.config.allowUnfree=true:
    # microcodeIntel microcodeAmd
  ];
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.

  programs = {
    # https://nixos.org/nixos/manual/options.html#opt-programs.nm-applet.enable
    nm-applet.enable = true;    # Network Manager applet

    # https://nixos.org/nixos/manual/options.html#opt-programs.mtr.enable
    mtr.enable = true;          # alternative to `traceroute`

    vim.defaultEditor = true;
  };

  services = {
    cron = {
      enable = true;
      systemCronJobs = [ "44 8 * * Wed  ntpdate ca.pool.ntp.org" ];
    };

    dictd = {
      enable = true;
      # https://search.nixos.org/packages?query=dictdDBs
      DBs = with pkgs.dictdDBs; [ wiktionary wordnet ];
      # FIXME other dictionaries? foldoc gcide jargon vera
    };

    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      challengeResponseAuthentication = false;
    };

    printing = {
      enable = true;
      browsedConf = ''
        BrowseRemoteProtocols dnssd cups
      ''; 
      logLevel = "warn";
      startWhenNeeded = false;
      webInterface = false;
    };

    ntp.enable = false;         # use cron job for ntpdate instead

    xserver = {
      enable = true;
      displayManager.defaultSession = "xfce"; # https://nixos.wiki/wiki/Xfce
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
      layout = "us";            # Keyboard layout
      libinput.enable = true;   # Enable touchpad support
      # xkbOptions = "eurosign:e";
    };
  };

  networking.firewall = {
    enable = true;
    allowPing = false;
    allowedTCPPorts = [ 22 ];
    # allowedTCPPortRanges = [ { from = 8080; to = 8089 } ];
  };
  
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # hardware.printers.ensurePrinters."Brother MFC-J870DW" = {
  #   deviceUri = "socket://192.168.1.250";
  # };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
      autoPrune = {
        enable = true;
        dates = "quarterly";
        flags = [ "--all" ];    # Remove all *unused* images
      };
    };

    virtualbox.host = {
      enable = true;
      addNetworkInterface = true;
      # enableHardening = true;
      headless = true;
    };
  };

  nix.allowedUsers = [ "@wheel" "@builders" ];

  # Define user accounts.  Remember to set a password with ‘passwd’.
  users.users = {
    daniel = {
      description = "Daniel";
      extraGroups = [
        "wheel" "staff" "networkmanager" "vboxusers"
      ];
      isNormalUser = true;
    };
    dpezely = {
      description = "dpezely";
      extraGroups = [
        "wheel" "staff" "networkmanager" "vboxusers"
      ];
      isNormalUser = true;
    };
  };

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09";
}
