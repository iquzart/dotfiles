return {
  {
    "iquzart/toggleword.nvim",

    keys = function()
      return {
        {
          "<leader>tt",
          function()
            require("toggleword").toggle_word()
          end,
          desc = "Toggle Word",
        },
      }
    end,
  },
}
