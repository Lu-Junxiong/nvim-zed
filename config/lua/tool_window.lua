local M = {}

local function geometry()
  local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.92)))
  local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.85)))
  return { relative = 'editor', width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)) }
end

function M.open(title, filetype)
  local state = { buf = vim.api.nvim_create_buf(false, true) }
  state.win = vim.api.nvim_open_win(state.buf, true,
    vim.tbl_extend('force', geometry(), { style = 'minimal', border = 'rounded', title = ' ' .. title .. ' ', title_pos = 'center' }))
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].filetype = filetype
  function state.close()
    if state.closed then return end
    state.closed = true
    if state.job then state.job:kill(15) end
    if state.terminal then vim.fn.jobstop(state.terminal) end
    if vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_win_close(state.win, true) end
    if vim.api.nvim_buf_is_valid(state.buf) then vim.api.nvim_buf_delete(state.buf, { force = true }) end
    if vim.v.exiting == vim.NIL then
      vim.cmd.stopinsert()
      require('panels').editor()
    end
  end
  vim.keymap.set({ 'n', 't' }, 'q', state.close, { buffer = state.buf, desc = 'Close tool' })
  vim.keymap.set({ 'n', 't' }, '<Esc>', state.close, { buffer = state.buf, desc = 'Close tool' })
  vim.keymap.set({ 'n', 't' }, '<C-\\>', function()
    state.close()
    require('panels').toggle_terminal()
  end, { buffer = state.buf, desc = 'Open shell terminal' })
  local resize = vim.api.nvim_create_autocmd('VimResized', { callback = function()
    if not state.closed then vim.api.nvim_win_set_config(state.win, geometry()) end
  end })
  vim.api.nvim_create_autocmd('WinClosed', { pattern = tostring(state.win), once = true, callback = function()
    vim.api.nvim_del_autocmd(resize)
    vim.schedule(state.close)
  end })
  return state
end

return M
