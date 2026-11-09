local M = {}
local terminal_buf
local editor_win

function M.editor()
  if editor_win and vim.api.nvim_win_is_valid(editor_win)
      and vim.bo[vim.api.nvim_win_get_buf(editor_win)].buftype == '' then
    vim.api.nvim_set_current_win(editor_win)
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == '' then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  vim.cmd('leftabove vnew')
end

function M.toggle_terminal()
  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    local win = vim.fn.bufwinid(terminal_buf)
    if win ~= -1 then
      if #vim.api.nvim_tabpage_list_wins(0) == 1 then vim.cmd('vnew') end
      vim.api.nvim_win_close(win, false)
      M.editor()
      return
    end
  end
  vim.cmd('botright 12split')
  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    vim.api.nvim_win_set_buf(0, terminal_buf)
  else
    terminal_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, terminal_buf)
    vim.fn.jobstart(vim.o.shell, { term = true, cwd = vim.fn.getcwd() })
    vim.bo[terminal_buf].bufhidden = 'hide'
    vim.bo[terminal_buf].buflisted = false
    vim.api.nvim_create_autocmd('TermClose', {
      buffer = terminal_buf, once = true,
      callback = function() terminal_buf = nil end,
    })
  end
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.cmd.startinsert()
end

function M.setup()
  require('nvim-tree').setup({
    view = { side = 'right', width = 30 },
    actions = { open_file = { quit_on_open = false, resize_window = false } },
    update_focused_file = { enable = true },
    renderer = {
      highlight_git = 'name',
      icons = { show = { file = false, folder = false, folder_arrow = false, git = false, modified = false, diagnostics = false, bookmarks = false } },
    },
    on_attach = function(buf)
      local api = require('nvim-tree.api')
      api.config.mappings.default_on_attach(buf)
      vim.keymap.set('n', 'l', api.node.open.edit, { buffer = buf, desc = 'Open' })
      vim.keymap.set('n', 'h', api.node.navigate.parent_close, { buffer = buf, desc = 'Close folder' })
    end,
  })
  local map = vim.keymap.set
  map('n', '<leader>e', function() require('nvim-tree.api').tree.toggle({ focus = true }) end, { desc = 'Toggle file tree' })
  map('n', '<C-\\>', M.toggle_terminal, { desc = 'Toggle terminal' })
  map('t', '<C-\\>', [[<C-\><C-n><Cmd>lua require('panels').toggle_terminal()<CR>]], { desc = 'Toggle terminal' })
  map('t', '<Esc><Esc>', [[<C-\><C-n>]], { desc = 'Terminal normal mode' })
  for _, direction in ipairs({ 'h', 'j', 'k', 'l' }) do
    map('n', '<C-' .. direction .. '>', '<C-w>' .. direction, { desc = 'Move to panel' })
    map('t', '<C-' .. direction .. '>', [[<C-\><C-n><C-w>]] .. direction, { desc = 'Move to panel' })
  end
  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      if vim.bo.buftype == '' then editor_win = vim.api.nvim_get_current_win() end
      if vim.bo.buftype == 'terminal' then vim.cmd.startinsert() end
    end,
  })
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      if #vim.api.nvim_list_uis() == 0 then return end
      editor_win = vim.api.nvim_get_current_win()
      require('nvim-tree.api').tree.open({ focus = false })
    end,
  })
end
return M
