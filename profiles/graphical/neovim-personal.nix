{
  profiles,
  config,
  ...
}:
{
  modules.graphical.editor.neovim = {
    base.enable = true;
    completion.enable = true;
    lsp.enable = true;
    telescope.enable = true;
  };

  hm.programs.nixvim = {
    opts = {
      # enable spell checker
      spell = true;
      spelllang = [
        "en"
        "pt"
        "sv"
      ];
    };

    plugins.colorizer = {
      enable = true;
      settings.user_default_options.names = false;
    };

    plugins.comment = {
      enable = true;
      settings = {
        toggler = {
          line = "<leader>cc";
          block = "<leader>C";
        };
        mappings = {
          extra = false;
        };
      };
    };

    plugins.gitsigns = {
      enable = true;
      settings = {
        # Make the staged and unstaged add signs different
        signs.add.text = "+";
        on_attach = # lua
          ''
            function(bufnr)
              local gs = package.loaded.gitsigns
              local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
              end
              map('n', '<leader>gb', gs.toggle_current_line_blame)
            end
          '';
      };
    };

    plugins.indent-blankline = {
      enable = true;
      settings = {
        indent.char = "¦";
        scope.include.node_type.nix = [
          "attrset_expression"
          "list_expression"
        ];
      };
    };

    plugins.marks = {
      enable = true;
      settings.sign_priority = 1;
    };

    plugins.nvim-autopairs.enable = true;
  };
}
