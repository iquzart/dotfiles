-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>dc", function()
  local comment = vim.bo.commentstring:match("^(.-)%%s")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local kept = {}

  for _, line in ipairs(lines) do
    local is_blank = line:match("^%s*$")
    local is_comment = comment and comment ~= "" and line:match("^%s*" .. vim.pesc(comment))

    if not is_blank and not is_comment then
      table.insert(kept, line)
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, kept)
end, { desc = "Delete comment and blank lines" })
