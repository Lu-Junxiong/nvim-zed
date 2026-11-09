local root = assert(vim.env.NVIM_ZED_ROOT, 'Start with ./run')
vim.opt.runtimepath = { root .. '/config', vim.env.VIMRUNTIME, root .. '/neovim/lib/nvim' }
vim.opt.packpath = {}
for _, path in ipairs(vim.fn.glob(root .. '/plugins/*', false, true)) do
  vim.opt.runtimepath:append(path)
  if vim.fn.isdirectory(path .. '/after') == 1 then vim.opt.runtimepath:append(path .. '/after') end
end
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.opt.shell = '"' .. vim.fn.escape(root .. '/bin/shell', '\\"') .. '"'
vim.opt.termguicolors = true
vim.opt.background = 'light'
require('theme')
vim.opt.number = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.mouse = 'a'
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.showtabline = 2
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.timeoutlen = 400
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.exrc = false
vim.opt.modeline = false
vim.opt.shortmess:append('I')
vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  signs = { text = { [1] = 'E', [2] = 'W', [3] = 'I', [4] = 'H' } },
  severity_sort = true,
  float = { border = 'rounded', source = true },
})

require('ui').setup_icons()
require('mini.tabline').setup({ show_icons = true, tabpage_section = 'right' })
require('mini.statusline').setup({ use_icons = false, content = { active = require('ui').statusline } })
require('mini.pick').setup({ source = { show = function(buf, items, query) MiniPick.default_show(buf, items, query, { show_icons = true }) end } })
require('mini.extra').setup()
require('mini.bufremove').setup()
require('project_session').setup()
require('startup').setup()
require('panels').setup()
require('completion').setup()
require('python_lsp').setup()
require('git_ui').setup()
require('flash').setup({
  modes = { char = { enabled = false }, search = { enabled = false } },
  search = { exclude = {
    function(win) return vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= '' or not vim.api.nvim_win_get_config(win).focusable end,
  } },
})

local map = vim.keymap.set
map({ 'n', 'x', 'o' }, '<leader>j', function() require('flash').jump() end, { desc = 'Flash jump' })
map('i', 'jk', '<Esc>', { desc = 'Normal mode' })
map('n', '<C-p>', function() require('panels').editor(); MiniPick.builtin.files({ tool = 'rg' }) end, { desc = 'Find files' })
map('n', '<leader>/', function() require('panels').editor(); MiniPick.builtin.grep_live({ tool = 'rg' }) end, { desc = 'Search project' })
map('n', '<leader>b', function() require('panels').editor(); MiniPick.builtin.buffers() end, { desc = 'Find buffers' })
map('n', '<leader>s', function() require('panels').editor(); MiniExtra.pickers.buf_lines({ scope = 'current' }) end, { desc = 'Search buffer' })
map('n', '<leader>o', function() require('outline').open() end, { desc = 'File outline' })
map('n', '<leader>v', function() require('python_env').info() end, { desc = 'Python 环境信息' })
map('n', '<leader>m', function() require('monitor').toggle() end, { desc = 'nvitop GPU / 进程监控' })
map('n', '<leader>p', function() require('data_preview').open() end, { desc = 'Polars 数据预览' })
vim.api.nvim_create_user_command('ZedPreview', function(args)
  require('data_preview').open(args.args ~= '' and vim.fn.fnamemodify(args.args, ':p') or nil)
end, { nargs = '?', complete = 'file' })
map('n', '[b', function() require('buffers').cycle(-1) end, { desc = 'Previous file' })
map('n', ']b', function() require('buffers').cycle(1) end, { desc = 'Next file' })
map('n', '<leader>x', function() require('panels').editor(); MiniBufremove.delete() end, { desc = 'Close file' })
map('n', '<leader>w', function() require('panels').editor(); vim.cmd.write() end, { desc = 'Save' })
map('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = 'Previous diagnostic' })
map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Next diagnostic' })
map('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', '<leader>?', function() require('panels').editor(); vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/README.md')) end, { desc = 'Help' })
map('n', '<leader>q', function()
  require('panels').editor()
  MiniExtra.pickers.diagnostic({ scope = 'all', sort_by = 'severity' }, { source = { name = 'Diagnostics' } })
end, { desc = '诊断列表' })
require('ui').setup_clues()
require('buffers').setup()
