# Neovim configuration (diogotcorreia)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.editor.neovim.base;
in
{
  options.modules.graphical.editor.neovim.base.enable = mkEnableOption "neovim base";

  config = mkIf cfg.enable {
    home-manager.sharedModules = [
      inputs.nixvim.homeModules.default
    ];

    hm.programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      enablePrintInit = false;
      enableMan = false;

      colorschemes.base16 = {
        enable = true;
        colorscheme = "nord";
      };

      opts = {
        # show invisible whitespace characters
        list = true;
        listchars = {
          tab = ">-";
          trail = "~";
          extends = ">";
          precedes = "<";
        };

        # keep undo history over different sessions
        undofile = true;
        undodir = "/tmp//";

        # don't include character under cursor in selection
        selection = "exclusive";
        # enable mouse functionality
        mouse = "a";

        # do not wrap lines by default (<leader>w to toggle)
        wrap = false;

        # keep a line offset around cursor
        scrolloff = 12;

        # when splitting, split below and to the right
        splitbelow = true;
        splitright = true;

        # show (relative) line numbers
        number = true;
        relativenumber = true;

        # use smart case on searches: if it's all lowercase, search is case insensitive;
        # if there's a upper case character, search is case sensitive
        ignorecase = true;
        smartcase = true;

        # expand sign column if needed
        signcolumn = "auto:9";

        # disable audible bell for sanity reasons
        belloff = "all";
      };

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
  };
}
