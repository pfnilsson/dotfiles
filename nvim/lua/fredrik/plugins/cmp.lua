return {
    'saghen/blink.cmp',
    dependencies = 'rafamadriz/friendly-snippets',
    version = '*',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        keymap = {
            preset = 'default',
            ['<C-j>'] = { 'select_next', 'fallback' },
            ['<C-k>'] = { 'select_prev', 'fallback' },
            ['<C-u>'] = { 'select_and_accept', 'fallback' },
            ['<C-y>'] = {}
        },

        appearance = {
            nerd_font_variant = 'mono'
        },
        signature = { enabled = true }
    },
}
