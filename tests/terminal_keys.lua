local root = assert(vim.env.ZED_TEST_BUNDLE)
local project = vim.env.ZED_TEST_WORK .. '/project'
local address = vim.env.ZED_TEST_WORK .. '/keys.sock'
local output = {}
local job = vim.fn.jobstart({ root .. '/run', project, '--listen', address, 'a.txt' }, {
  pty = true, width = 120, height = 40, on_stdout = function(_, data) for _,line in ipairs(data) do output[#output+1]=line end end,
})
assert(job > 0)
local channel
local function call(code) return vim.rpcrequest(channel, 'nvim_exec_lua', code, {}) end
local function wait(code, label)
  assert(vim.wait(5000, function() return call(code) == true end, 25), label)
  print('PASS ' .. label)
end
local ok, err = pcall(function()
  assert(vim.wait(5000, function() return vim.uv.fs_stat(address) ~= nil end, 25), 'socket created')
  channel = vim.fn.sockconnect('pipe', address, { rpc = true })
  assert(channel > 0)
  wait([[return vim.api.nvim_buf_get_name(0):match('a.txt$')~=nil and #vim.api.nvim_list_wins()==1]], 'native terminal startup')
  call([[vim.cmd('badd b.txt')]])
  vim.fn.chansend(job, '\27[9;5u')
  wait([[return vim.api.nvim_buf_get_name(0):match('b.txt$')~=nil]], 'native CSI-u Ctrl-Tab')
  vim.fn.chansend(job, '\27[9;6u')
  wait([[return vim.api.nvim_buf_get_name(0):match('a.txt$')~=nil]], 'native CSI-u Ctrl-Shift-Tab')
  vim.fn.chansend(job, 'i')
  wait([[return vim.api.nvim_get_mode().mode=='i']], 'native insert mode')
  vim.fn.chansend(job, '\27[9;5u')
  wait([[return vim.api.nvim_buf_get_name(0):match('b.txt$')~=nil and vim.api.nvim_get_mode().mode=='i']], 'native insert-mode Ctrl-Tab')
  vim.fn.chansend(job, '\t')
  wait([[return vim.api.nvim_get_current_line():match('^    ')~=nil]], 'native unmodified Tab stays independent')
end)
if not ok then print(err); print(table.concat(output, " ")); print(vim.inspect(vim.fn.jobwait({job},0))) end
vim.fn.jobstop(job)
if channel and channel > 0 then vim.fn.chanclose(channel) end
vim.cmd(ok and 'qa!' or 'cquit')
