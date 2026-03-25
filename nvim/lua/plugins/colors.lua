return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      float = {
        transparent = false,
        solid = false,
      },
      term_colors = true,
      default_integrations = true,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
      },
      custom_highlights = function(colors)
        return {
          NormalFloat = { bg = colors.mantle },
          FloatBorder = { fg = colors.surface1, bg = colors.mantle },
          CursorLine = { bg = colors.surface0 },
          CursorLineNr = { fg = colors.mauve, style = { "bold" } },
          Pmenu = { bg = colors.mantle },
          PmenuSel = { bg = colors.surface0, fg = colors.text },
          TelescopeNormal = { bg = colors.mantle },
          TelescopeBorder = { fg = colors.surface1, bg = colors.mantle },
          TelescopePromptNormal = { bg = colors.crust },
          TelescopePromptBorder = { fg = colors.surface1, bg = colors.crust },
          TelescopeResultsNormal = { bg = colors.mantle },
          TelescopePreviewNormal = { bg = colors.mantle },
        }
      end,
      integrations = {
        cmp = true,
        gitsigns = true,
        mason = true,
        native_lsp = {
          enabled = true,
          inlay_hints = {
            background = true,
          },
        },
        telescope = {
          enabled = true,
        },
        treesitter = true,
      },
    })

    vim.o.background = "dark"
    vim.cmd.colorscheme("catppuccin-mocha")
  end,
}
