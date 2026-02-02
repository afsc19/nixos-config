# Neovim configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.editor.neovim;
in
{
  options.modules.graphical.editor.neovim.enable = mkEnableOption "neovim";

  config = mkIf cfg.enable {
    hm.programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # These packages are required by LazyVim and its default plugins
      extraPackages = with pkgs; [
        # Build tools for tree-sitter & plugins
        git
        gcc
        gnumake
        unzip

        # Search tools for Telescope
        ripgrep
        fd

        # Essential LSPs and formatters
        lua-language-server
        stylua # lua formatter
        nixd # nix lsp
        nixpkgs-fmt # nix formatter

        # Common dependencies for LazyVim extras
        pyright # Python LSP
        black # Python formatter
        shfmt # Shell formatter
        shellcheck # Shell linter
        hadolint # Docker linter
      ];
    };

    # TODO Clone LazyVim starter manually after config deployment
  };
}
