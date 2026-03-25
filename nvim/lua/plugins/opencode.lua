return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  lazy = false, -- ensure config loads

  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {},
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
    -- -- ENV
    -- local openai_key = os.getenv("AZURE_OPENAI_API_KEY")
    -- local openai_url = os.getenv("AZURE_OPENAI_BASE_URL")

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- -- 🔌 Providers
      -- provider = {
      --   -- Local model (fast, default)
      --   ollama = {
      --     endpoint = "http://127.0.0.1:11434",
      --     model = "qwen2.5-coder:7b",
      --   },
      --
      --   -- OpenAI fallback (GPT-5)
      --   openai = {
      --     api_key = openai_key,
      --     base_url = openai_url,
      --     model = "gpt-5.4", -- change to "gpt-5-mini" if needed
      --   },
      -- },

      -- -- Routing
      -- default_provider = "ollama",
      -- fallback_provider = "openai",

      -- Optional tuning
      context = {
        max_tokens = 16000,
      },

      behavior = {
        auto_suggestions = true,
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

    -- -- =========================
    -- -- ⚡ Optional power keys
    -- -- =========================
    --
    -- -- Force GPT-5 (cloud)
    -- vim.keymap.set("n", "<leader>cog", function()
    --   require("opencode").ask("@this: deep analysis, use best reasoning", {
    --     provider = "openai",
    --     submit = true,
    --   })
    -- end, { desc = "Force GPT-5" })
    --
    -- -- Force local (Ollama)
    -- vim.keymap.set("n", "<leader>col", function()
    --   require("opencode").ask("@this: ", {
    --     provider = "ollama",
    --     submit = true,
    --   })
    -- end, { desc = "Force local model" })
  end,
}
