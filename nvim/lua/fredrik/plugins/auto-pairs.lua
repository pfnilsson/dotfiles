return {
    "windwp/nvim-autopairs",
    dependencies = {
        "nvim-treesitter/nvim-treesitter", -- Ensure Treesitter is installed for enhanced functionality
        "hrsh7th/nvim-cmp",                -- Optional: If you're using nvim-cmp for autocompletion
    },
    config = function()
        -- Setup nvim-autopairs with desired configurations
        require('nvim-autopairs').setup {
            check_ts = true,               -- Enable Treesitter integration for smarter pairing
            disable_filetype = { "vim" },  -- Disable autopairs in specific filetypes
            map_bs = true,                 -- Enable mapping for backspace to delete pairs intelligently
            map_cr = true,                 -- Enable mapping for Enter key to handle newline pairs
            disable_in_macro = true,       -- Disable autopairs when recording macros
            disable_in_visualblock = true, -- Disable autopairs in visual block mode
            -- You can add more configuration options here as needed
        }

        -- Treesitter integration for nvim-autopairs (Optional)
        local npairs = require('nvim-autopairs')
        require('nvim-autopairs.ts-conds')

        npairs.setup {
            check_ts = true,
            ts_config = {
                lua = { "string", "source" },       -- Don't add pairs in Lua strings and sources
                javascript = { "template_string" }, -- Don't add pairs in JavaScript template strings
                python = { "string", "comment" },   -- Customize for Python
                -- Add more language-specific configurations as needed
            },
        }

        -- Integrate with nvim-cmp for autocompletion (Optional)
        local cmp_ok, cmp = pcall(require, 'cmp')
        if cmp_ok then
            local cmp_autopairs = require('nvim-autopairs.completion.cmp')
            cmp.event:on(
                'confirm_done',
                cmp_autopairs.on_confirm_done()
            )
        end

        -- Add custom rules (Optional)
        local Rule = require('nvim-autopairs.rule')
        npairs.add_rules({
            Rule('<', '>', 'html'), -- Automatically insert <> in HTML
            -- Add more custom rules as needed
        })
    end,
}
