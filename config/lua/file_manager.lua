local M = {}
local session

local function geometry()
  local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.9)))
  local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.85)))
  return { relative = 'editor', width = width, height = height,
    row = math.max(0, math.floor((vim.o.lines - height - 2) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)) }
end

local function finish(state, code)
  if state.finished then return end
  state.finished = true
  if session == state then session = nil end
  local files = {}
  if not state.cancelled and code == 0 and vim.fn.filereadable(state.chooser) == 1 then
    files = vim.fn.readfile(state.chooser)
  end
  local preview
  if not state.cancelled and code == 0 and vim.fn.filereadable(state.preview) == 1 then
    preview = table.concat(vim.fn.readfile(state.preview, 'b'), '\n')
  end
  vim.fn.delete(state.chooser)
  vim.fn.delete(state.preview)
  if vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_win_close(state.win, true) end
  if vim.api.nvim_buf_is_valid(state.buf) then vim.api.nvim_buf_delete(state.buf, { force = true }) end
  if vim.v.exiting ~= vim.NIL then return end
  vim.cmd.stopinsert()
  require('panels').editor()
  if preview and preview ~= '' then
    require('data_preview').open(preview)
    return
  end
  for index, path in ipairs(files) do
    -- Use API buffer names so spaces and Ex metacharacters remain literal.
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    vim.bo[buf].buflisted = true
    if index == 1 then vim.api.nvim_win_set_buf(0, buf) end
  end
  if not state.cancelled and code ~= 0 then
    vim.notify('Yazi exited with status ' .. code, vim.log.levels.ERROR)
  end
end

function M.close()
  local state = session
  if not state then return end
  state.cancelled = true
  if state.job then vim.fn.jobstop(state.job) end
  finish(state, 0)
end

function M.open()
  if session then
    vim.api.nvim_set_current_win(session.win)
    vim.cmd.startinsert()
    return
  end
  require('monitor').close()
  require('data_preview').close()
  require('panels').editor()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= '' or path == '' then path = vim.fn.getcwd() end
  if not vim.uv.fs_stat(path) then path = vim.fs.dirname(path) end
  local buf = vim.api.nvim_create_buf(false, true)
  local config = vim.tbl_extend('force', geometry(), { style = 'minimal', border = 'rounded', title = ' Yazi ', title_pos = 'center' })
  local state = { buf = buf, win = vim.api.nvim_open_win(buf, true, config),
    chooser = vim.fn.tempname(), preview = vim.fn.tempname() }
  session = state
  state.job = vim.fn.jobstart({ vim.env.NVIM_ZED_ROOT .. '/yazi/yazi', '--chooser-file', state.chooser, path }, {
    term = true,
    cwd = vim.fn.getcwd(),
    env = {
      YAZI_CONFIG_HOME = vim.env.NVIM_ZED_ROOT .. '/config/yazi' .. (MiniIcons.config.style == 'ascii' and '/ascii' or ''),
      PATH = vim.env.NVIM_ZED_ROOT .. '/yazi:' .. vim.env.PATH,
      NVIM_ZED_PREVIEW_FILE = state.preview,
    },
    on_exit = function(_, code) vim.schedule(function() finish(state, code) end) end,
  })
  assert(state.job > 0, 'Failed to start bundled Yazi')
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = 'zed_yazi'
  -- Keep Yazi's own terminal controls independent from the shell panel mappings.
  for _, key in ipairs({ '<C-h>', '<C-j>', '<C-k>', '<C-l>', '<Esc><Esc>' }) do
    vim.keymap.set('t', key, key, { buffer = buf })
  end
  vim.keymap.set({ 'n', 't' }, '<C-\\>', function()
    M.close()
    require('panels').toggle_terminal()
  end, { buffer = buf, desc = 'Open shell terminal' })
  vim.api.nvim_create_autocmd('WinClosed', { pattern = tostring(state.win), once = true,
    callback = function() vim.schedule(function()
      if state.finished then return end
      state.cancelled = true
      if state.job then vim.fn.jobstop(state.job) end
      finish(state, 0)
    end) end })
  vim.cmd.startinsert()
end

function M.toggle()
  if session then M.close() else M.open() end
end

vim.api.nvim_create_autocmd('VimResized', { callback = function()
  if session and vim.api.nvim_win_is_valid(session.win) then
    vim.api.nvim_win_set_config(session.win, geometry())
  end
end })

return M
