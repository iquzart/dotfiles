-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function keymap(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

local wk = require("which-key")

vim.o.timeoutlen = 250

wk.setup({
  show_help = false,
  show_keys = false,
  key_labels = { ["<leader>"] = "SPC" },
})

-- go to beginning and end
keymap("i", "<C-b>", "<ESC>^i", { desc = "Beginning of line" })
keymap("i", "<C-e>", "<End>", { desc = "End of line" })

-- better moving keys
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

-- keymap("n", "<C-;>", "<cmd>tabnext<CR>")
-- keymap("n", "<C-.>", "<cmd>tabprevious<CR>")

keymap("t", "<ESC>", "<C-\\><C-n>")

keymap("n", "<C-s>", "<cmd> w <CR>")

keymap("i", "<C-z>", "<C-O>u")

-- nitpicky stuff
keymap("n", "J", "mzJ`z")
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")

-- better indentation
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- better moving lines
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- undotree

-- resizing
keymap("n", "<C-Up>", ":resize -2<CR>")
keymap("n", "<C-Down>", ":resize +2<CR>")
keymap("n", "<C-Left>", ":vertical resize -2<CR>")
keymap("n", "<C-Right>", ":vertical resize +2<CR>")

-- U = redo
keymap("n", "U", "<C-r>")

-- lsp
keymap("n", "K", ":lua vim.lsp.buf.hover()<CR>")

keymap("t", "<C-h>", "<cmd>wincmd h<CR>")
keymap("t", "<C-j>", "<cmd>wincmd j<CR>")
keymap("t", "<C-k>", "<cmd>wincmd k<CR>")
keymap("t", "<C-l>", "<cmd>wincmd l<CR>")

keymap("t", "<C-Up>", "<cmd>resize -2<CR>")
keymap("t", "<C-Down>", "<cmd>resize +2<CR>")
keymap("t", "<C-Left>", "<cmd>vertical resize -2<CR>")
keymap("t", "<C-Right>", "<cmd>vertical resize +2<CR>")

local leader = {
  ["f"] = {
    name = "+telescope",
    ["f"] = { "<cmd> Telescope find_files <CR>", "Find Files" },
    ["a"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find All Files" },
    ["w"] = { "<cmd> Telescope live_grep <CR>", "Live Grep" },
    ["b"] = { "<cmd> Telescope buffers <CR>", "Buffers" },
    ["h"] = { "<cmd> Telescope help_tags <CR>", "Help Tags" },
    ["o"] = { "<cmd> Telescope oldfiles <CR>", "Old Files" },
    ["c"] = { "<cmd> Telescope colorscheme <CR>", "Colorschemes" },
  },
  ["<TAB>"] = {
    name = "+tab",
    ["<tab>"] = { "<cmd>tabnew<CR>", "New Tab" },
    ["n"] = { "<cmd>tabnext<CR>", "Next" },
    ["d"] = { "<cmd>tabclose<CR>", "Close" },
    ["p"] = { "<cmd>tabprevious<CR>", "Previous" },
  },
  ["b"] = {
    name = "+buffer",
    ["d"] = { "<cmd>bd<CR>", "Delete Buffer" },
    ["n"] = { "<cmd>BufferLineCycleNext<CR>", "Next Buffer" },
    ["p"] = { "<cmd>BufferLineCyclePrev<CR>", "Prev Buffer" },
    ["c"] = { "<cmd>BufferLinePickClose<CR>", "Close Buffer" },
    ["m"] = {
      name = "+move",
      ["n"] = { "<cmd>BufferLineMoveNext<CR>", "Next Buffer" },
      ["p"] = { "<cmd>BufferLineMovePrev<CR>", "Prev Buffer" },
    },
  },
  ["o"] = {
    name = "+open",
    ["t"] = { "<cmd> ToggleTerm size=20<CR>", "Terminal" },
    ["f"] = { "<cmd> NvimTreeToggle<CR>", "File Explorer" },
    ["d"] = { "<cmd> DiffviewOpen<CR>", "DiffView" },
    ["g"] = { "<cmd> Neogit<CR>", "Neogit" },
  },
  ["u"] = { "<cmd> UndotreeToggle<CR>", "Undo Tree" },
  ["g"] = {
    name = "+goto",
    ["d"] = { "<cmd> Telescope lsp_definitions<CR>", "Definition" },
    ["i"] = { "<cmd> Telescope lsp_implementation<CR>", "Implementation" },
    ["r"] = { "<cmd> Telescope lsp_references<CR>", "References" },
  },
  ["c"] = {
    name = "+code",
    ["r"] = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename" },
    ["f"] = { "<cmd> FormatWrite<CR>", "Format Document" },
  },
}

wk.register(leader, { prefix = "<leader>" })
