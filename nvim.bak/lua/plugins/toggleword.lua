return {
  "iquzart/toggleword.nvim",
  config = function()
    require("toggleword").setup({
      key = "<leader>tt", -- optional, defaults to <leader>tt
    })
  end,
}
