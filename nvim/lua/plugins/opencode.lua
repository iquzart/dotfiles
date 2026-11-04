return {
  "nickjvandyke/opencode.nvim",
  -- Pin the cached V2-compatible revision; stable releases still target V1.
  branch = "main",
  commit = "4d3580a0ebb060cfdd41fa93784a046706a728cf",
  lazy = false,

  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = {},
        picker = {
          actions = {
            opencode_send = function(picker)
              local items = vim.tbl_map(function(item)
                return item.file
                    and require("opencode").format({ path = item.file, from = item.pos, to = item.end_pos })
                  or item.text
              end, picker:selected({ fallback = true }))
              require("opencode").prompt(table.concat(items, ", ") .. " ")
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = {
                  "opencode_send",
                  mode = { "n", "i" },
                },
              },
            },
          },
        },
      },
    },
  },

  config = function()
    local opencode_cmd = "opencode"

    -- V2 has no HTTP TUI-control API. Bind deterministic scroll keys only in
    -- this terminal, preserving any other inherited inline CLI settings.
    local inline_config = vim.env.OPENCODE_CLI_CONFIG_CONTENT
    local cli_config = vim.json.decode(inline_config and inline_config ~= "" and inline_config or "{}")
    cli_config.keybinds = vim.tbl_extend("force", cli_config.keybinds or {}, {
      ["session.half.page.up"] = "ctrl+alt+u",
      ["session.half.page.down"] = "ctrl+alt+d",
    })

    ---@type snacks.terminal.Opts
    local terminal_opts = {
      env = { OPENCODE_CLI_CONFIG_CONTENT = vim.json.encode(cli_config) },
      win = {
        position = "right",
        enter = false,
        width = 0.40,
      },
    }

    local function scroll(keys)
      local terminal = require("snacks.terminal").get(
        opencode_cmd,
        vim.tbl_extend("force", terminal_opts, { create = false })
      )
      local job = terminal and vim.api.nvim_buf_is_valid(terminal.buf) and vim.b[terminal.buf].terminal_job_id
      if not job or vim.fn.jobwait({ job }, 0)[1] ~= -1 then
        vim.notify("Open the OpenCode terminal with <leader>cot before scrolling", vim.log.levels.WARN)
        return
      end
      terminal:show()
      vim.api.nvim_chan_send(job, keys)
    end

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = function()
          require("snacks.terminal").open(opencode_cmd, terminal_opts)
        end,
      },
    }

    vim.o.autoread = true

    -- Ask AI (current file / selection)
    vim.keymap.set({ "n", "x" }, "<leader>coa", function()
      require("opencode").ask("@this: ")
    end, { desc = "OpenCode Ask" })

    -- Action picker
    vim.keymap.set({ "n", "x" }, "<leader>cox", function()
      require("opencode").select()
    end, { desc = "OpenCode Actions" })

    -- Toggle visible terminal
    vim.keymap.set({ "n", "t" }, "<leader>cot", function()
      require("snacks.terminal").toggle(opencode_cmd, terminal_opts)
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
      scroll("\27\21") -- Alt+Ctrl+U
    end, { desc = "OpenCode Scroll Up" })

    vim.keymap.set("n", "<leader>cod", function()
      scroll("\27\4") -- Alt+Ctrl+D
    end, { desc = "OpenCode Scroll Down" })
  end,
}
