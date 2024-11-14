return {
  "jemag/telescope-diff.nvim",
  dependencies = {
    { "nvim-telescope/telescope.nvim" },
  },

  keys = function()
    return {
      { "<leader>fd", "<cmd>Telescope diff diff_files<cr>", desc = "Diff 2 files" },
      { "<leader>fD", "<cmd>Telescope diff diff_current<cr>", desc = "Diff file with current" },
    }
  end,

  config = function()
    require("telescope").load_extension("diff")
  end,
}
