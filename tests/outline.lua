local root = assert(vim.env.ZED_TEST_BUNDLE)
local project = vim.env.ZED_TEST_WORK .. '/project'
local child = vim.fn.jobstart({ root .. '/run', project, '--embed', 'a.txt' }, { rpc = true })
local function call(code, ...) return vim.rpcrequest(child, 'nvim_exec_lua', code, { ... }) end
local function input(keys) vim.rpcrequest(child, 'nvim_input', keys) end
local function wait(code, label)
  assert(vim.wait(5000, function() return call(code) == true end, 20), label)
  print('PASS ' .. label)
end
local function collect(filename, lines)
  call([[local filename,lines=...; vim.bo.modified=false; vim.cmd.edit(vim.fn.fnameescape(filename)); vim.api.nvim_buf_set_lines(0,0,-1,false,lines)]], project .. '/' .. filename, lines)
  return call([[local items,incomplete=require('outline').items(vim.api.nvim_get_current_buf()); local result={}; for _,item in ipairs(items) do result[#result+1]={vim.trim(item.text),item.lnum,item.col} end; return {items=result,incomplete=incomplete}]])
end
local function check(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ': ' .. vim.inspect(actual))
  print('PASS ' .. label)
end
local ok, err = pcall(function()
  vim.rpcrequest(child, 'nvim_ui_attach', 120, 40, { rgb = true })
  wait([[return #vim.api.nvim_list_wins()==1 and vim.bo.buftype=='']], 'outline fixture editor ready')
  local json = collect('config.json', {
    '{', '  "model": {"rate": 1},', '  "items": [', '    {"name": "one"},', '    {"name": "two"}', '  ],', '  "a.b": {"x": true},', '  "escaped\\\"key": 2', '}',
  })
  check(json.items, {
    {'model',2,3}, {'model.rate',2,13}, {'items',3,3}, {'items[0]',4,5}, {'items[0].name',4,6},
    {'items[1]',5,5}, {'items[1].name',5,6}, {'["a.b"]',7,3}, {'["a.b"].x',7,11}, {'["escaped\\\"key"]',8,3},
  }, 'JSON nested paths, arrays, special keys and exact positions')
  check(json.incomplete, false, 'valid JSON')
  input(' o')
  wait('return MiniPick.is_picker_active()', 'JSON outline opens without a language server')
  input("'items[1].name")
  wait([[local m=MiniPick.get_picker_matches(); return m~=nil and #m.all==1]], 'JSON outline filtering')
  vim.wait(100, function() return false end)
  input('<CR>')
  wait([[return not MiniPick.is_picker_active() and vim.api.nvim_win_get_cursor(0)[1]==5 and vim.api.nvim_win_get_cursor(0)[2]==5]], 'JSON outline jumps in unsaved buffer')
  local jsonc = collect('comments.jsonc', {'{', ' // "fake": {"ignored": true}', ' "real": [1, 2]', '}'})
  check(jsonc.items, {{'real',3,2},{'real[0]',3,11},{'real[1]',3,14}}, 'JSONC ignores comments')
  local partial = collect('partial.json', {'{"good": 1, "unfinished": '})
  assert(partial.incomplete and partial.items[1][1]=='good', 'incomplete JSON retains readable structure')
  print('PASS incomplete JSON')
  local yaml = collect('config.yaml', {
    '# fake: comment', 'model:', '  rate: 1', 'items:', '  - name: one', '  - {name: two}',
    'text: |', '  fake: block text', '"a:b": {nested: yes}', 'base: &base {enabled: true}', 'copy: *base',
  })
  check(yaml.items, {
    {'model',2,1},{'model.rate',3,3},{'items',4,1},{'items[0]',5,3},{'items[0].name',5,5},
    {'items[1]',6,3},{'items[1].name',6,6},{'text',7,1},{'["a:b"]',9,1},{'["a:b"].nested',9,9},
    {'base',10,1},{'base.enabled',10,14},{'copy',11,1},
  }, 'YAML block/flow structures, strings, anchors and aliases')
  check(yaml.incomplete, false, 'valid YAML with leading comment stays in one document')
  input(' o')
  wait('return MiniPick.is_picker_active()', 'YAML outline opens')
  input("'model.rate")
  wait([[local m=MiniPick.get_picker_matches(); return m~=nil and #m.all==1]], 'YAML filtering')
  vim.wait(100, function() return false end); input('<CR>')
  wait([[return not MiniPick.is_picker_active() and vim.api.nvim_win_get_cursor(0)[1]==3]], 'YAML jump')
  local partial_yaml = collect('partial.yaml', {'good: 1', 'unfinished: ['})
  assert(partial_yaml.incomplete and partial_yaml.items[1][1]=='good', 'incomplete YAML retains readable structure')
  print('PASS incomplete YAML')
  check(collect('docs.yml', {'---','key: one','---','key: two'}).items, {{'doc1',1,1},{'doc1.key',2,1},{'doc2',3,1},{'doc2.key',4,1}}, 'YAML multi-document paths')
  local ini = collect('settings.ini', {
    '; fake=value', 'global=yes', '[database] ; comment', 'host = localhost', 'port: 5432', 'message = first',
    '  fake = continued value', '  [not_a_section]', '# ignored=true', '[other]', 'host=elsewhere',
  })
  check(ini.items, {{'global',2,1},{'[database]',3,1},{'[database].host',4,1},{'[database].port',5,1},{'[database].message',6,1},{'[other]',10,1},{'[other].host',11,1}}, 'INI sections, keys, comments and multiline values')
  input(' o')
  wait('return MiniPick.is_picker_active()', 'INI outline opens')
  input("'[other].host")
  wait([[local m=MiniPick.get_picker_matches(); return m~=nil and #m.all==1]], 'INI filtering')
  vim.wait(100, function() return false end); input('<CR>')
  wait([[return not MiniPick.is_picker_active() and vim.api.nvim_win_get_cursor(0)[1]==11]], 'INI jump')
  check(collect('settings.cfg', {'[section]','key=value'}).items, {{'[section]',1,1},{'[section].key',2,1}}, 'CFG INI-style outline')
  check(collect('empty.json', {'{}'}).items, {}, 'empty JSON object')
  input(' o')
  wait([[return not MiniPick.is_picker_active() and vim.api.nvim_exec2('messages',{output=true}).output:find('没有可显示',1,true)~=nil]], 'empty structure feedback')
end)
if not ok then print(err) end
vim.fn.jobstop(child)
vim.cmd(ok and 'qa!' or 'cquit')
