local M = {}
local window

function M.close()
  if window then window.close(); window = nil end
end

function M.toggle()
  if window and not window.closed then M.close(); return end
  local env, err = require('python_env').resolve()
  if not env then vim.notify(err, vim.log.levels.ERROR); return end
  require('data_preview').close()
  require('file_manager').close()
  local root = vim.env.NVIM_ZED_ROOT
  local state = require('tool_window').open('nvitop · q / Esc 关闭', 'zed_monitor')
  window = state
  local command = { root .. '/bin/user-env', env.path, '-I', '-B', root .. '/tools/monitor.py', '--light' }
  if MiniIcons.config.style == 'ascii' then command[#command + 1] = '--ascii' end
  state.terminal = vim.fn.jobstart(command, {
    term = true, cwd = vim.fn.getcwd(),
    on_exit = function(_, code) vim.schedule(function()
      if state.closed then return end
      vim.cmd.stopinsert()
      if code == 0 then state.close()
      else vim.notify('nvitop exited (' .. code .. '); see monitor output. Requires Python 3.8+, curses and NVIDIA NVML.', vim.log.levels.ERROR) end
    end) end,
  })
  if state.terminal <= 0 then state.close(); error('Failed to start nvitop') end
  -- Preserve nvitop navigation instead of applying shell panel mappings.
  for _, key in ipairs({ '<C-h>', '<C-j>', '<C-k>', '<C-l>' }) do
    vim.keymap.set('t', key, key, { buffer = state.buf })
  end
  vim.cmd.startinsert()
end

return M
