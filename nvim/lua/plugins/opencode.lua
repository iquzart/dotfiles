return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  lazy = false,

  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {}, -- Enhances `ask()`
        picker = {
          actions = {
            opencode_send = function(...)
              return require("opencode").snacks_picker_send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },

  config = function()
    -- OpenAI environment
    local openai_key = os.getenv("OPENAI_API_KEY")
    local openai_url = os.getenv("OPENAI_BASE_URL")

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        url = openai_url, -- OpenAI endpoint
        api_key = openai_key, -- OpenAI key
        model = "gpt-5.4", -- your deployed GPT-5 model
      },

      -- Optional tuning
      context = {
        max_tokens = 16000,
      },

      behavior = {
        auto_suggestions = true,
      },

      -- Always ask for permission before making edits
      permissions = {
        ask_before_edit = true,
      },
    }

    vim.o.autoread = true

    -- =========================
    -- Keymaps (leader = co)
    -- =========================

    -- Ask AI (current file / selection)
    vim.keymap.set({ "n", "x" }, "<leader>coa", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "OpenCode Ask" })

    -- Action picker
    vim.keymap.set({ "n", "x" }, "<leader>cox", function()
      require("opencode").select()
    end, { desc = "OpenCode Actions" })

    -- Toggle panel
    vim.keymap.set({ "n", "t" }, "<leader>cot", function()
      require("opencode").toggle()
    end, { desc = "OpenCode Toggle" })

    -- Operator (motion-based)
    vim.keymap.set({ "n", "x" }, "<leader>co", function()
      return require("opencode").operator("@this ")
    end, { expr = true, desc = "Send to OpenCode" })

    -- Current line
    vim.keymap.set("n", "<leader>coo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { expr = true, desc = "Send line to OpenCode" })

    -- Scroll OpenCode output
    vim.keymap.set("n", "<leader>cou", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "OpenCode Scroll Up" })

    vim.keymap.set("n", "<leader>cod", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "OpenCode Scroll Down" })
  end,
}
