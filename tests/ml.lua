local root = assert(vim.env.ZED_TEST_BUNDLE)
local project = vim.env.ZED_TEST_WORK .. '/ml-project'
local python = assert(vim.env.ZED_TEST_PYTHON, 'Set ZED_TEST_PYTHON to a Python with Polars')
local child
local function start(directory, file)
  local command = { root .. '/run', directory, '--embed' }
  if file then command[#command + 1] = file end
  child = vim.fn.jobstart(command, { rpc = true, env = { NVIM_ZED_PYTHON = python },
    on_stderr = function(_, lines) print(table.concat(lines, '\n')) end })
  vim.rpcrequest(child, 'nvim_set_option_value', 'more', false, {})
  vim.rpcrequest(child, 'nvim_ui_attach', 120, 40, { rgb = true })
end
local function call(code, ...) return vim.rpcrequest(child, 'nvim_exec_lua', code, { ... }) end
local function input(keys) vim.rpcrequest(child, 'nvim_input', keys) end
local function wait(code, label, ...)
  local arguments = { ... }
  assert(vim.wait(8000, function() return call(code, unpack(arguments)) == true end, 25), label)
  print('PASS ' .. label)
end
local function stop()
  input('<Esc>')
  wait([[return vim.api.nvim_get_mode().mode=='n']], 'normal mode before exit')
  input(':qa!<CR>')
  local status = vim.fn.jobwait({ child }, 5000)[1]
  assert(status == 0, 'child exit status: ' .. status)
end
local ok, err = pcall(function()
  vim.fn.mkdir(project, 'p')
  vim.fn.writefile({ 'alpha' }, project .. '/a.txt')
  vim.fn.writefile({ 'beta' }, project .. '/b.txt')
  vim.fn.writefile({ 'x = 1' }, project .. '/example.py')
  vim.fn.writefile({ '[project]', 'name="ml-check"', 'version="0.0.0"' }, project .. '/pyproject.toml')
  vim.fn.writefile({ 'name,value', 'alpha,1', 'beta,2' }, project .. '/sample [1].csv')
  start(project, 'example.py')
  wait([[return vim.bo.filetype=='python']], 'Python file ready')
  assert(call([[local expected=...; local env=require('python_env').resolve(); return env.path==expected and env.source=='NVIM_ZED_PYTHON']], python))
  wait([[return vim.api.nvim_eval_statusline(vim.o.statusline,{maxwidth=200}).str:find('Py:',1,true)~=nil]], 'Python environment visible in statusline')
  wait([[local clients=vim.lsp.get_clients({name='ty',bufnr=0}); return #clients==1 and clients[1].config.settings.ty.configuration.environment.python==...]], 'ty uses chosen interpreter', python)
  call([[local resolver=dofile(vim.env.NVIM_ZED_ROOT..'/config/lua/python_env.lua'); local explicit=vim.env.NVIM_ZED_PYTHON; vim.env.NVIM_ZED_PYTHON='/missing/python'; local env,err=resolver.resolve(); vim.env.NVIM_ZED_PYTHON=explicit; assert(env==nil and err:find('NVIM_ZED_PYTHON'))]])
  print('PASS invalid interpreter is reported')
  call([[local path=...; local function resolve() return dofile(vim.env.NVIM_ZED_ROOT..'/config/lua/python_env.lua').resolve() end; local original={}
    local keys={'NVIM_ZED_PYTHON','VIRTUAL_ENV','CONDA_PREFIX','CONDA_DEFAULT_ENV'}
    for _,key in ipairs(keys) do original[key]=vim.env[key]; vim.env[key]=nil end
    local project=vim.fn.getcwd(); vim.fn.mkdir(project..'/.venv/bin','p')
    assert(vim.uv.fs_symlink(path,project..'/.venv/bin/python'))
    vim.env.CONDA_PREFIX=vim.fs.dirname(vim.fs.dirname(path)); vim.env.CONDA_DEFAULT_ENV='base'
    local chosen=resolve(); local base_ok=chosen.source=='project .venv'
    vim.env.CONDA_DEFAULT_ENV='research'; chosen=resolve(); local conda_ok=chosen.source=='Conda'
    vim.env.VIRTUAL_ENV=project..'/.venv'; chosen=resolve(); local virtualenv_ok=chosen.source=='VIRTUAL_ENV'
    for _,key in ipairs(keys) do vim.env[key]=original[key] end
    vim.fn.delete(project..'/.venv','rf')
    assert(base_ok and conda_ok and virtualenv_ok)]], python)
  print('PASS virtualenv, Conda and project .venv precedence')
  call([[vim.cmd('edit a.txt'); vim.cmd('vsplit b.txt'); require('panels').toggle_terminal()]])
  wait([[return vim.api.nvim_get_mode().mode=='t']], 'shell running before session save')
  input('<C-k>')
  wait([[return vim.bo.buftype=='' and vim.api.nvim_get_mode().mode=='n']], 'return to normal editor before save')
  call([[vim.api.nvim_win_set_cursor(0,{1,2}); require('project_session').save(true)]])
  print('PASS session saved with live shell')
  stop()
  start(project)
  wait([[return vim.bo.filetype=='ministarter' and #vim.api.nvim_list_wins()==1]], 'saved session does not replace startup page')
  input('s<CR>')
  wait([[return #vim.api.nvim_list_wins()==2 and vim.api.nvim_buf_get_name(0):match('b.txt$')~=nil and vim.api.nvim_win_get_cursor(0)[2]==2]], 'home restores split layout and cursor')
  assert(call([[for _,buf in ipairs(vim.api.nvim_list_bufs()) do if vim.bo[buf].buftype=='terminal' then return false end end; return true]]), 'session never restarts shell')
  call([[vim.api.nvim_buf_set_lines(0,0,1,false,{'unsaved'}); require('project_session').restore(); assert(vim.api.nvim_get_current_line()=='unsaved'); vim.bo.modified=false]])
  call([[require('data_preview').open(vim.fn.getcwd() .. '/sample [1].csv')]])
  wait([[return vim.bo.filetype=='zed_data' and not vim.bo.modifiable and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),' '):find('alpha',1,true)~=nil]], 'Polars renders a read-only preview')
  input('q')
  wait([[return vim.bo.buftype=='' and #vim.api.nvim_list_wins()==2]], 'preview closes without replacing editor')
  call([[require('data_preview').open(vim.fn.getcwd() .. '/sample [1].csv'); vim.cmd.close()]])
  wait([[return vim.bo.buftype=='' and #vim.api.nvim_list_wins()==2]], 'closing a loading preview cancels it safely')
  call([[vim.cmd('edit ' .. vim.fn.fnameescape(vim.fn.getcwd() .. '/sample [1].csv')); require('file_manager').open()]])
  wait([[return vim.bo.filetype=='zed_yazi' and vim.api.nvim_get_mode().mode=='t' and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),' '):find('sample [1].csv',1,true)~=nil]], 'Yazi ready for direct data preview')
  input('<C-p>')
  wait([[return vim.bo.filetype=='zed_data' and not vim.bo.modifiable and table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),' '):find('alpha',1,true)~=nil]], 'Yazi Ctrl-p opens Polars preview')
  input('<C-Tab>')
  wait([[return vim.bo.buftype=='' and #vim.api.nvim_list_wins()==2]], 'Ctrl-Tab closes preview and switches file')
  call([[require('monitor').toggle()]])
  wait([[return vim.bo.filetype=='zed_monitor']], 'monitor owns an independent floating terminal')
  if vim.env.ZED_TEST_GPU_NAME then
    wait([[local expected=...; return table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),' '):find(expected,1,true)~=nil]],
      'interactive monitor renders actual NVIDIA GPU', vim.env.ZED_TEST_GPU_NAME)
  end
  input('<Esc>')
  wait([[return vim.bo.buftype=='' and #vim.api.nvim_list_wins()==2]], 'monitor closes without creating a shell panel')
  stop()
  vim.fn.mkdir(project .. '-session-other', 'p')
  start(project .. '-session-other')
  wait([[return vim.bo.filetype=='ministarter']], 'second project opens home')
  input('s<CR>')
  wait([[return vim.bo.filetype=='ministarter' and #vim.api.nvim_list_wins()==1]], 'sessions are isolated by project')
  stop()
end)
if not ok then
  print(vim.inspect(err))
  if child then vim.fn.jobstop(child) end
end
vim.cmd(ok and 'qa!' or 'cquit')
