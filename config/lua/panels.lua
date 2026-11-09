local M = {}
local terminal_buf
local terminal_running = false
local editor_win
local changing_layout = false

local function is_editor_window(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.api.nvim_win_get_config(win).relative == ''
    and (vim.bo[buf].buftype == '' or vim.bo[buf].filetype == 'ministarter')
end

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
      and is_editor_window(editor_win) then
    vim.api.nvim_set_current_win(editor_win)
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_window(win) then
      vim.api.nvim_set_current_win(win)
      editor_win = win
      return
    end
  end
  vim.cmd('leftabove vnew')
  editor_win = vim.api.nvim_get_current_win()
end

local function show_terminal()
  changing_layout = true
  M.editor()
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
  vim.cmd.startinsert()
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
    show_terminal()
  end
end

function M.setup()
  local map = vim.keymap.set
  map('n', '<leader>e', function() require('file_manager').toggle() end, { desc = 'Yazi file browser' })
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
      if is_editor_window(vim.api.nvim_get_current_win()) then
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
        require('startup').open_if_empty()
        M.editor()
        vim.cmd.stopinsert()
        changing_layout = false
      end)
    end,
  })
end
return M
