# Home Manager config -- see https://github.com/nix-community/home-manager

# Install as $XDG_CONFIG_HOME/nixpkgs/home.nix
# Install home-manager itself, run: nix-env -iA nixos.home-manager
# Activate this configuration, run: home-manager switch
# For rollbacks, see https://github.com/nix-community/home-manager#rollbacks

{ pkgs, ... }:

{
  home = {
    username = "daniel";
    homeDirectory = "/home/daniel";
    keyboard.layout = "us";
    stateVersion = "20.09";
  };

  # List packages installed in user profile. To search, run: nix search wget
  home.packages = with pkgs; [
    alsaUtils
    aspell aspellDicts.en aspellDicts.en-computers aspellDicts.en-science
    mate.atril
    audacity
    bash  # Add to .bashrc: . "~/.nix-profile/etc/profile.d/hm-session-vars.sh"
    blender
    dict
    dnsutils
    emacs26                     # FIXME: upgrade .emacs for Emacs 27
    #clang gnumake binutils pkg-config libressl zlib
    #clojure jre leiningen
    python3Full
    mpc_cli python38Packages.notify2  # For mpd
    musescore
    obs-studio
    plank
    #pavucontrols  # For audio
    ripgrep ripgrep-all xsv
    rustup rustfmt rustracer cargo  # For Rust language
    thunderbird
    traceroute
    virtualboxHeadless
    wget
    whois
    wordnet
    wmctrl jumpapp
    xfce.xfce4-battery-plugin
    xfce.xfce4-dict
    xfce.xfce4-mpc-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-screenshooter
    xfce.xfce4-volumed-pulse
    xorg.oclock
    ##xpdf  # Use Atril or other instead

    # These require nixpkgs.config.allowUnfree=true in configuration.nix:
    google-chrome freeoffice slack teams zoom-us
  ];

  programs = {
    alacritty.enable = true;

    # Enabling Bash here requires migrating *all* ~/.bash* files to home-manager
    #bash.enable = true;

    chromium = {
      #enable = true;
      # https://nixos.org/nixos/manual/options.html#opt-programs.chromium
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      ];
    };

    # Enabling Emacs here requires migrating its config files to home-manager
    #emacs.enable = true;

    firefox = {
      enable = true;

      # As of 20.09, EXTENSIONS should still be installed manually:
      # https://nix-community.github.io/home-manager/options.html \
      # #opt-programs.firefox.extensions

      profiles."profile" = {
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.contentblocking.category" = "custom";
          "browser.ctrlTab.recentlyUsedOrder" = false;

          # Disable implict spyware:
          # https://www.makeuseof.com/ways-fortify-firefox-browser/
          "browser.newtabpage.activity-stream.feeds.system.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.havePinned" = "";
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "";
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.pinned" = "[]";
          "browser.ping-centre.telemetry" = false;
          "browser.safebrowsing.blockedURIs.enabled" = false;
          "browser.safebrowsing.downloads.enabled" = false;
          "browser.safebrowsing.downloads.remote.block_dangerous" = false;
          "browser.safebrowsing.downloads.remote.block_dangerous_host" = false;
          "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
          "browser.safebrowsing.downloads.remote.block_uncommon" = false;
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.safebrowsing.downloads.remote.url" = "";
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.phishing.enabled" = false;

          "browser.search.region" = "CA";
          "browser.search.isUS" = false;
          "browser.search.suggest.enabled" = false;
          "browser.search.widget.inNavBar" = true;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.startup.homepage" = "about:blank";
          "browser.startup.blankWindow" = true;
          "browser.startup.firstrunSkipsHomepage" = false;
          "browser.startup.homepage_welcome_url" = "about:blank";
          "browser.tabs.warnOnClose" = false;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.topsites.useRemoteSetting" = false;

          # Keep value as a single string with embedded quotes:
          "browser.uiCustomization.state" = "{\"placements\":{\"widget-overflow-fixed-list\":[\"stop-reload-button\",\"preferences-button\",\"panic-button\",\"add-ons-button\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"urlbar-container\",\"search-container\",\"downloads-button\",\"ublock0_raymondhill_net-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"PersonalToolbar\":[\"personal-bookmarks\",\"managed-bookmarks\"]},\"seen\":[\"developer-button\",\"ublock0_raymondhill_net-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"widget-overflow-fixed-list\",\"toolbar-menubar\",\"TabsToolbar\",\"PersonalToolbar\"],\"currentVersion\":16,\"newElementCount\":4}";

          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.urlbar.placeholderName.private" = "DuckDuckGo";
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.topsites" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "distribution.searchplugins.defaultLocale" = "en-CA";
          "experiments.activeExperiment" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "extensions.fxmonitor.enabled" = false;
          "extensions.pocket.api" = "";
          "extensions.pocket.enabled" = false;
          "extensions.pocket.onSaveRecs" = false;
          "extensions.pocket.site" = "";
          "geo.enabled" = false;
          "permissions.default.geo" = 2;
          "general.useragent.locale" = "en-CA";
          "general.warnOnAboutConfig" = false;
          "keyword.enabled" = false;
          "media.autoplay.default" = 5;
          "media.videocontrols.picture-in-picture.enabled" = false;
          "network.allow-experiments" = false;
          "network.cookie.cookieBehavior" = 1;
          "network.cookie.lifetimePolicy" = 2;
          "network.dns.disablePrefetch" = true;
          "network.dns.disablePrefetchFromHTTPS" = true;
          "network.predictor.cleaned-up" = true;
          "network.predictor.enabled" = false;
          "network.predictor.enable-prefetch" = false;
          "network.prefetch-next" = false;

          "pdfjs.defaultZoomValue" = "100%";
          "print.print_footercenter" = "&PT";
          "print.print_footerleft" = "";
          "print.print_footerright" = "";
          "print.print_headerleft" = "";
          "print.print_headerright" = "";
          # "print.printer_MFCJ870DW.print_footercenter" = "&PT";
          # "print.printer_MFCJ870DW.print_footerleft" = "";
          # "print.printer_MFCJ870DW.print_footerright" = "";
          # "print.printer_MFCJ870DW.print_headerleft" = "";
          # "print.printer_MFCJ870DW.print_headerright" = "";
          # "print.printer_Mozilla_Save_to_PDF.print_footercenter" = "&PT";
          # "print.printer_Mozilla_Save_to_PDF.print_footerleft" = "";
          # "print.printer_Mozilla_Save_to_PDF.print_footerright" = "";
          # "print.printer_Mozilla_Save_to_PDF.print_headerleft" = "";
          # "print.printer_Mozilla_Save_to_PDF.print_headerright" = "";
          # "print.printer_Print_to_File.print_footercenter" = "&PT";
          # "print.printer_Print_to_File.print_footerleft" = "";
          # "print.printer_Print_to_File.print_footerright" = "";
          # "print.printer_Print_to_File.print_headerleft" = "";
          # "print.printer_Print_to_File.print_headerright" = "";

          "privacy.history.custom" = true;
          "privacy.purge_trackers.date_in_cookie_database" = "0";
          "privacy.sanitize.timeSpan" = 4;

          "services.sync.prefs.sync.browser.newtabpage.activity-stream.feeds.topsites" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.feeds.showSponsoredTopSites" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "services.sync.prefs.sync.browser.urlbar.suggest.topsites" = false;

          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.hybridContent.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.reportingpolicy.firstRun" = false;
          "toolkit.telemetry.server" = "";
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "ui.key.menuAccessKeyFocuses" = false;
          "view_source.wrap_long_lines" = true;
        };

        # https://nix-community.github.io/home-manager/options.html \
        # #opt-programs.firefox.profiles._name_.userChrome
        # ~/.mozilla/firefox/*.default-release/chrome/userChrome.css
        userChrome = ''
          @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
          /* Remove Bookmark Item Icons */
          #personal-bookmarks toolbarbutton:not([type=menu]) image {
            display: none !important;
            -moz-margin-end: 0px !important;
          }
          /*Hide Bookmark Folder Icon*/
          #personal-bookmarks toolbarbutton[type=menu] image {
            display: none !important;
            -moz-margin-end: 0px !important;
          }
          #personal-bookmarks toolbarbutton[container="true"] .toolbarbutton-menu-dropmarker {
            display: none !important;
          }
      '';
      };
    };

    gpg.enable = true;

    htop.enable = true;

    jq.enable = true;

    git = {
      enable = true;
      userName = "Daniel Pezely";
      userEmail = "first name at last name dot com";
      aliases = {
        up = "!git remote update -p; git merge --ff-only @{u}";
      };
      extraConfig = {
        core = {
	        editor = "emacsclient";
	        excludesfile = "/home/daniel/.gitignore";

          # macos: 
	        #editor =
          # "/Applications/Emacs.app/Contents/MacOS/bin-x86_64-10_14/emacsclient";
	        #excludesfile = "/Users/daniel/.gitignore";

	        pager = "cat";
        };
        pull = {
          ff = "only";
        };
      };
      ignores = [ "*~" ".#*" "#*#" ".cvsignore" ".DS_Store" ".gitignore"
                  ".hg" ".hgrc" ".local/" ".svn" ".svnignore" "*.beam"
                  "*.dump" "*.elc" "*.*fasl" "*.log" "*.o" "a.out" "*.pyc"
                  "*.pyo" "CVS" "jsmin" "TAGS" "var/" "save/" "scratch/"
                  "target/" ];
    };
  };
  
  services = {
    mpd = {
      enable = true;
      dataDir = "/run/mpd";                  # Keep state on tmpfs

      # Keep music out of $HOME, but remember to: ln -s /home/Music ~
      musicDirectory = "/home/Music";
      playlistDirectory = "/home/Music/playlists";

      network.listenAddress = "127.0.0.1";
      extraConfig = ''
        log_file     "/run/log/mpd.log"
        pid_file     "/run/mpd/pid"
        user         "mpd"
        filesystem_charset "UTF-8"
        id3v1_encoding     "UTF-8"
        metadata_to_use "artist,album,title,track,name,date,composer,performer,disc"
        auto_update  "no"
        input {
          plugin "curl"
        }
        audio_output {
          type		"pulse"
          name		"MPD PulseAudio Output"
          server	"localhost"
          sink		"alsa_output"
        }
      '';
    };
  };

  # https://github.com/nix-community/home-manager#graphical-services
  xsession = {
    #enable = true;
  };
}
