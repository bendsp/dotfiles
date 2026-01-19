return {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
        require("rose-pine").setup({
            variant = "main", -- auto, main, moon, or dawn
            dark_variant = "main", -- main, moon, or dawn
            dim_inactive_windows = false,
            extend_background_behind_borders = true,

            enable = {
                terminal = true,
                legacy_highlights = true, -- Soften the highlight groups
                migrations = true, -- Handle deprecated options
            },

            styles = {
                bold = true,
                italic = false,
                transparency = true,
            },
        })

        vim.cmd("colorscheme rose-pine")
    end
}
