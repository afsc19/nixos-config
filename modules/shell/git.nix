# Git configuration.
{
  lib,
  config,
  configDir,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.git;
in
{
  options.modules.shell.git.enable = mkEnableOption "git";

  config.hm = mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;

      # Global config
      userName = "afsc19";
      userEmail = "71138696+afsc19@users.noreply.github.com";

      # Extra settings for better defaults
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;                    # rebase on pull to avoid merge commits
        push.autoSetupRemote = true;           # auto-track remote branch on first push
        rebase.autoStash = true;               # stash/unstash automatically during rebase
        credential.helper = "cache --timeout=3600"; # cache credentials for 1h (gh can override)
        core.editor = "vim";                   # fallback editor
      };

      # Aliases for convenience
      aliases = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status -sb";
        last = "log -1 HEAD";
        unstage = "reset HEAD --";
        lg = "log --graph --oneline --decorate --all";
      };

      # Delta (better diff viewer)
      delta = {
        enable = true;
        options = {
          navigate = true;
          line-numbers = true;
          side-by-side = false;
        };
      };
    };

    # GitHub CLI for authentication and API access
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "https";  # or "ssh" if you prefer git@github.com URLs
        editor = "vim";
        prompt = "enabled";
      };
    };
  };
}