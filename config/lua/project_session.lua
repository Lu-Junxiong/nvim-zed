local M = {}
local project

local function session_path()
  return vim.fn.stdpath('state') .. '/sessions/' .. vim.fn.sha256(project) .. '.vim'
end

function M.save(quiet)
  local has_file = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_win_get_config(win).relative == '' and vim.bo[buf].buftype == ''
        and vim.api.nvim_buf_get_name(buf) ~= '' then has_file = true; break end
  end
  -- Visiting only the home page must not overwrite a useful previous session.
  if not has_file then return end
  local path = session_path()
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  local descriptor, temporary = vim.uv.fs_mkstemp(path .. '.XXXXXX')
  if not descriptor then vim.notify('Session save failed: ' .. temporary, vim.log.levels.ERROR); return end
  vim.uv.fs_close(descriptor)
  local options = vim.o.sessionoptions
  vim.o.sessionoptions = 'buffers,curdir,folds,tabpages,winsize'
  local ok, err = pcall(vim.cmd.mksession, { args = { temporary }, bang = true })
  vim.o.sessionoptions = options
  if ok then
    local renamed, rename_error = vim.uv.fs_rename(temporary, path)
    ok, err = renamed, rename_error
  end
  if not ok then
    vim.uv.fs_unlink(temporary)
    vim.notify('Session save failed: ' .. tostring(err), vim.log.levels.ERROR)
  elseif not quiet then vim.notify('项目会话已保存（文件、光标和布局）') end
end

function M.restore()
  local path = session_path()
  if vim.fn.filereadable(path) ~= 1 then vim.notify('当前项目没有已保存会话'); return end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified or (vim.bo[buf].buftype == 'terminal' and vim.b[buf].terminal_job_id
        and vim.fn.jobwait({ vim.b[buf].terminal_job_id }, 0)[1] == -1) then
      vim.notify('请先保存修改并退出内置终端，再恢复会话', vim.log.levels.WARN); return
    end
  end
  require('data_preview').close()
  require('panels').editor()
  vim.cmd.source(vim.fn.fnameescape(path))
end

function M.setup()
  project = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.getcwd()
  vim.api.nvim_create_user_command('ZedSessionSave', function() M.save() end, {})
  vim.api.nvim_create_user_command('ZedSessionRestore', M.restore, {})
  vim.api.nvim_create_autocmd('VimLeavePre', { callback = function() M.save(true) end })
end

return M
