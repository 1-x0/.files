{ pkgs, const, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.graphics.enable = true;

  users.mutableUsers = false;

  networking.hostName = const.HOSTNAME;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  time.timeZone = const.TIMEZONE;
  i18n.defaultLocale = const.LOCALE;

  users.users.${const.USERNAME} = {
    isNormalUser = true;
    hashedPassword = "";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.persistence."/nix/persist/.system" = {
    hideMounts = true;
    directories = [ "/var/lib/nixos" ];
    files = [ "/etc/machine-id" ];
  };

  services.displayManager = {
    cosmic-greeter.enable = true;
    autoLogin = {
      enable = true;
      user = const.USERNAME;
    };
  };

  services.desktopManager.cosmic = {
    enable = true;
    showExcludedPkgsWarning = false;
  };

  services.system76-scheduler.enable = true;
  environment.cosmic.excludePackages = [ pkgs.cosmic-initial-setup ];

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = const.STATE_VERSION;
}
