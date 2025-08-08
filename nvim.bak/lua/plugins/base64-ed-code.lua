return {
  "deponian/nvim-base64",
  version = "*",
  keys = {
    -- Decode/encode selected sequence from/to base64
    -- (mnemonic: [b]ase64)
    {
      "<Leader>Bd",
      "<Plug>(FromBase64)",
      mode = "x",
      name = "Base64 Decode",
    },
    {
      "<Leader>Be",
      "<Plug>(ToBase64)",
      mode = "x",
      name = "Base64 Encode",
    },
  },
  config = function()
    require("nvim-base64").setup()
  end,
}
