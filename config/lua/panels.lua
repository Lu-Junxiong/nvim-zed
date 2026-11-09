local M = {}
local terminal_buf
local terminal_running = false
local editor_win
local changing_layout = false

local function terminal_window()
  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    local win = vim.fn.bufwinid(terminal_buf)
    if win ~= -1 then return win end
  end
end

local function resize_terminal()
  local win = terminal_window()
  if win then
    local height = math.max(3, math.floor((vim.o.lines - vim.o.cmdheight - 2) / 4))
    vim.api.nvim_win_set_height(win, height)
  end
end

function M.editor()
  if editor_win and vim.api.nvim_win_is_valid(editor_win)
      and vim.api.nvim_win_get_tabpage(editor_win) == vim.api.nvim_get_current_tabpage()
      and vim.bo[vim.api.nvim_win_get_buf(editor_win)].buftype == '' then
    vim.api.nvim_set_current_win(editor_win)
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == '' and vim.api.nvim_win_get_config(win).relative == '' then
      vim.api.nvim_set_current_win(win)
      editor_win = win
      return
    end
  end
  vim.cmd('leftabove vnew')
  editor_win = vim.api.nvim_get_current_win()
end

local function show_terminal(focus)
  changing_layout = true
  M.editor()
  local return_win = vim.api.nvim_get_current_win()
  local win = terminal_window()
  if win then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd('botright split')
  end
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) or not terminal_running then
    local previous_buf = terminal_buf
    terminal_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, terminal_buf)
    local job = vim.fn.jobstart({ vim.env.NVIM_ZED_ROOT .. '/bin/shell' }, { term = true, cwd = vim.fn.getcwd() })
    assert(job > 0, 'Failed to start terminal shell: ' .. vim.o.shell)
    terminal_running = true
    vim.bo[terminal_buf].bufhidden = 'hide'
    vim.bo[terminal_buf].buflisted = false
    vim.api.nvim_create_autocmd('TermClose', {
      buffer = terminal_buf, once = true,
      callback = function() terminal_running = false end,
    })
    if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
      vim.api.nvim_buf_delete(previous_buf, { force = true })
    end
  else
    vim.api.nvim_win_set_buf(0, terminal_buf)
  end
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.winfixheight = true
  resize_terminal()
  if focus then
    vim.cmd.startinsert()
  else
    vim.api.nvim_set_current_win(return_win)
    vim.cmd.stopinsert()
  end
  changing_layout = false
end

function M.toggle_terminal()
  local win = terminal_window()
  if win and terminal_running then
    if #vim.api.nvim_tabpage_list_wins(0) == 1 then vim.cmd('vnew') end
    vim.api.nvim_win_close(win, false)
    M.editor()
    vim.cmd.stopinsert()
  else
    show_terminal(true)
  end
end

local function toggle_tree()
  changing_layout = true
  local tree = require('nvim-tree.api').tree
  if tree.is_visible() then
    tree.close()
    M.editor()
  else
    M.editor()
    tree.open()
  end
  -- Opening the tree can create a full-height split; keep the terminal below it.
  local win = terminal_window()
  if win then vim.api.nvim_win_call(win, function() vim.cmd('wincmd J') end) end
  resize_terminal()
  changing_layout = false
end

function M.setup()
  require('nvim-tree').setup({
    view = { side = 'right', width = 30 },
    actions = { open_file = { quit_on_open = false, resize_window = false } },
    update_focused_file = { enable = true },
    renderer = {
      highlight_git = 'name',
      icons = {
        show = { file = true, folder = true, folder_arrow = true, git = false, modified = false, diagnostics = false, bookmarks = false },
        glyphs = {
          default = MiniIcons.get('default', 'file'),
          folder = {
            default = MiniIcons.get('directory', ''),
            open = MiniIcons.get('directory', ''),
            empty = MiniIcons.get('directory', ''),
            empty_open = MiniIcons.get('directory', ''),
            symlink = MiniIcons.get('directory', ''),
            symlink_open = MiniIcons.get('directory', ''),
            arrow_closed = '>', arrow_open = 'v',
          },
        },
      },
    },
    on_attach = function(buf)
      local api = require('nvim-tree.api')
      api.config.mappings.default_on_attach(buf)
      vim.keymap.set('n', 'l', api.node.open.edit, { buffer = buf, desc = 'Open' })
      vim.keymap.set('n', 'h', api.node.navigate.parent_close, { buffer = buf, desc = 'Close folder' })
    end,
  })
  local map = vim.keymap.set
  map('n', '<leader>e', toggle_tree, { desc = 'Toggle file tree' })
  map('n', '<C-\\>', M.toggle_terminal, { desc = 'Toggle terminal' })
  map('t', '<C-\\>', [[<C-\><C-n><Cmd>lua require('panels').toggle_terminal()<CR>]], { desc = 'Toggle terminal' })
  map('t', '<Esc><Esc>', [[<C-\><C-n>]], { desc = 'Terminal normal mode' })
  for _, direction in ipairs({ 'h', 'j', 'l' }) do
    map('n', '<C-' .. direction .. '>', '<C-w>' .. direction, { desc = 'Move to panel' })
    map('t', '<C-' .. direction .. '>', [[<C-\><C-n><C-w>]] .. direction, { desc = 'Move to panel' })
  end
  map('t', '<C-k>', [[<C-\><C-n><Cmd>lua require('panels').editor()<CR>]], { desc = 'Return to editor' })
  map('n', '<C-k>', function()
    if vim.bo.buftype == 'terminal' then M.editor() else vim.cmd('wincmd k') end
  end, { desc = 'Move up to editor' })
  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      if changing_layout then return end
      if vim.bo.buftype == '' and vim.api.nvim_win_get_config(0).relative == '' then
        editor_win = vim.api.nvim_get_current_win()
      end
      if vim.bo.buftype == 'terminal' and terminal_running then vim.cmd.startinsert() end
    end,
  })
  vim.api.nvim_create_autocmd('VimResized', { callback = resize_terminal })
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      if #vim.api.nvim_list_uis() == 0 then return end
      vim.schedule(function()
        changing_layout = true
        M.editor()
        editor_win = vim.api.nvim_get_current_win()
        require('nvim-tree.api').tree.open()
        show_terminal(false)
      end)
    end,
  })
end
return M
