return {
  {
    import = "nvchad.blink.lazyspec"
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true
      },
    },
  },

  { "nvzone/volt", lazy = true },

  { "nvzone/menu" , lazy = true },
}
