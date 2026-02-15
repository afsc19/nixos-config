# Home manager configuration and aliases.
# Inspired by diogotcorreia, which was inspired by EdSwordmith and luishfonseca.
{
  pkgs,
  options,
  config,
  lib,
  user,
  userFullName,
  ...
}:
let
  inherit (lib) mkAliasDefinitions mkOption types;

  mkOpt = type: default: mkOption { inherit type default; };
in
{
  options = {
    hm = mkOption { type = types.attrs; };
    usr = mkOption { type = types.attrs; };

    my = {
      homeDirectory = mkOpt types.path config.users.users.${user}.home;
      configHome = mkOpt types.path "${config.my.homeDirectory}/.config";
    };
  };

  config = {
    home-manager.users.${user} = mkAliasDefinitions options.hm;
    users.users.${user} = mkAliasDefinitions options.usr;
    users.mutableUsers = false;

    usr = {
      isNormalUser = true;
      createHome = true;
      description = userFullName;

      # Generate using: mkpasswd -m yescrypt
      hashedPassword = "$y$j9T$XP1FJbkdLdABy2zN51npy0$wt1a7R6A6s/habUfVh7.MNzLWMIb93CM3RqBc8bnkk6";
      
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
    };

    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    hm.home.username = user;
    hm.home.homeDirectory = config.my.homeDirectory;

    # Let Home Manager install and manage itself.
    hm.programs.home-manager.enable = true;

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    hm.home.stateVersion = config.system.stateVersion;
  };
}
