local root = assert(vim.env.ZED_TEST_BUNDLE)
local project = vim.env.ZED_TEST_WORK .. '/review-project'
vim.fn.mkdir(project .. '/folder', 'p')
vim.fn.writefile({ '[project]', 'name="review-check"', 'version="0.0.0"' }, project .. '/pyproject.toml')
vim.fn.writefile({ 'plain text' }, project .. '/folder/note.txt')
vim.fn.writefile({ 'name,value', 'alpha,1' }, project .. '/sample.csv')
local child
local function start(file, python)
  local command = { root .. '/run', project, '--embed' }
  if python then
    vim.list_extend(command, { '--cmd', 'lua vim.notify=function(message) vim.g.review_notice=message end' })
  end
  if file then command[#command + 1] = file end
  child = vim.fn.jobstart(command, { rpc = true, env = { NVIM_ZED_PYTHON = python or '' } })
  assert(child > 0)
  vim.rpcrequest(child, 'nvim_set_option_value', 'more', false, {})
  vim.rpcrequest(child, 'nvim_ui_attach', 120, 40, { rgb = true })
end
local function call(code, ...) return vim.rpcrequest(child, 'nvim_exec_lua', code, { ... }) end
local function input(keys) vim.rpcrequest(child, 'nvim_input', keys) end
local function wait(code, label)
  assert(vim.wait(5000, function() return call(code) == true end, 20), label)
  print('PASS ' .. label)
end
local function stop()
  vim.fn.jobstop(child)
  vim.fn.jobwait({ child }, 3000)
end
local ok, err = pcall(function()
  start('invalid.py', '/missing/python')
  wait([[return vim.bo.filetype=='python']], 'invalid environment fixture ready')
  assert(call([[local activated=false; vim.lsp.config.ty.root_dir(0,function() activated=true end); return not activated]]),
    'invalid explicit Python must prevent ty auto discovery')
  wait([[return #vim.lsp.get_clients({name='ruff',bufnr=0})==1]], 'Ruff still starts without a usable Python')
  assert(call([[return #vim.lsp.get_clients({name='ty'})==0 and vim.g.review_notice:find('NVIM_ZED_PYTHON',1,true)~=nil]]))
  stop()
  start('sample.csv')
  wait([[return vim.bo.filetype=='csv']], 'preview fixture ready')
  assert(call([[local resolver=dofile(vim.env.NVIM_ZED_ROOT..'/config/lua/python_env.lua')
    local keys={'NVIM_ZED_PYTHON','VIRTUAL_ENV','CONDA_PREFIX','CONDA_DEFAULT_ENV'}; local saved={}
    for _,key in ipairs(keys) do saved[key]=vim.env[key]; vim.env[key]=nil end
    local before=assert(resolver.resolve()); local cwd=vim.fn.getcwd()
    vim.fn.mkdir(cwd..'/.venv/bin','p'); assert(vim.uv.fs_symlink(before.path,cwd..'/.venv/bin/python'))
    local after=assert(resolver.resolve())
    for _,key in ipairs(keys) do vim.env[key]=saved[key] end
    vim.fn.delete(cwd..'/.venv','rf')
    return before.path==after.path and before.source==after.source]]), 'Python selection must remain stable until restart')
  print('PASS Python selection remains stable after creating .venv')
  assert(call([[require('project_session').save(true); require('data_preview').open(); return not vim.bo.modifiable and vim.bo.readonly and not vim.bo.modified]]),
    'preview must be read-only while loading')
  call([[require('project_session').restore()]])
  wait([[return vim.bo.filetype=='csv' and #vim.api.nvim_list_wins()==1]], 'session restoration closes a loading preview safely')
  call([[vim.cmd.enew(); require('file_manager').open()]])
  wait([[return vim.bo.filetype=='zed_yazi' and vim.api.nvim_get_mode().mode=='t'
    and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),' '):find('folder',1,true)~=nil]], 'Yazi directory fixture ready')
  input('<C-p>')
  vim.wait(150)
  input('l')
  wait([[if vim.bo.filetype~='zed_yazi' then return false end
    local cwd=vim.uv.fs_readlink('/proc/'..vim.fn.jobpid(vim.b.terminal_job_id)..'/cwd')
    return cwd and cwd:match('/folder$')~=nil]],
    'directory preview leaves normal directory navigation available')
  input('<CR>')
  wait([[return vim.bo.buftype=='' and vim.api.nvim_buf_get_name(0):match('note.txt$')~=nil]],
    'Enter after directory preview opens ordinary files')
  stop()
end)
if not ok then
  print(err)
  print(vim.inspect(call([[return {file=vim.api.nvim_buf_get_name(0),filetype=vim.bo.filetype,
    mode=vim.api.nvim_get_mode(),lines=vim.api.nvim_buf_get_lines(0,0,-1,false),
    messages=vim.api.nvim_exec2('messages',{output=true}).output}]])))
  if child then stop() end
end
vim.cmd(ok and 'qa!' or 'cquit')
