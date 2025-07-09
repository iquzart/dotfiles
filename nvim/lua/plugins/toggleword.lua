local M = {}

M.toggles = {
  ["true"] = "false",
  ["false"] = "true",
  ["on"] = "off",
  ["off"] = "on",
  ["enabled"] = "disabled",
  ["disabled"] = "enabled",
  ["yes"] = "no",
  ["no"] = "yes",
  ["up"] = "down",
  ["down"] = "up",
}

function M.toggle_word()
  local word = vim.fn.expand("<cword>")
  local replacement = M.toggles[word]
  if replacement then
    vim.cmd("normal! ciw" .. replacement)
  else
    vim.notify("No toggle match for: " .. word, vim.log.levels.WARN)
  end
end

-- Keymap defined here
vim.keymap.set("n", "<leader>tt", function()
  M.toggle_word()
end, { desc = "Toggle word under cursor" })

return M
