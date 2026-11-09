local M = {}
local window

function M.close()
  if window then window.close(); window = nil end
end

local function render(path, env, data)
  local lines = {
    path, 'Python: ' .. env.path,
    string.format('显示 %d 行 / 最多 %d 行，%d / %d 列；q / Esc 关闭', #data.rows, data.row_limit, #data.columns, data.total_columns),
    'CSV 类型由前 50 行推断；只读取磁盘文件，不包含未保存修改。', '', '字段与类型：',
  }
  for i, column in ipairs(data.columns) do
    lines[#lines + 1] = string.format('%2d  %s : %s', i, column.name, column.type)
  end
  lines[#lines + 1] = ''
  lines[#lines + 1] = '样本（长单元格截断；左右滚动查看）：'
  local widths = {}
  for i, column in ipairs(data.columns) do widths[i] = vim.fn.strdisplaywidth(column.name) end
  for _, values in ipairs(data.rows) do
    for i, value in ipairs(values) do widths[i] = math.max(widths[i], vim.fn.strdisplaywidth(value)) end
  end
  local function row(values)
    local cells = {}
    for i, value in ipairs(values) do
      cells[i] = value .. string.rep(' ', math.max(0, widths[i] - vim.fn.strdisplaywidth(value)))
    end
    return table.concat(cells, ' | ')
  end
  local names = vim.tbl_map(function(column) return column.name end, data.columns)
  lines[#lines + 1] = row(names)
  for _, values in ipairs(data.rows) do lines[#lines + 1] = row(values) end
  return lines
end

function M.open(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if not path:lower():match('%.csv$') and not path:lower():match('%.tsv$') and not path:lower():match('%.parquet$') then
    vim.notify('请选择 CSV、TSV 或 Parquet 文件', vim.log.levels.WARN); return
  end
  local python = require('python_env')
  local env, err = python.resolve(python.project_root(path))
  if not env then vim.notify(err, vim.log.levels.ERROR); return end
  local command = { vim.env.NVIM_ZED_ROOT .. '/bin/user-env', env.path, '-B', vim.env.NVIM_ZED_ROOT .. '/tools/preview.py', path }
  require('monitor').close()
  require('file_manager').close()
  M.close()
  local state = require('tool_window').open('Polars 数据预览', 'zed_data')
  window = state
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { 'Polars 正在读取样本…' })
  vim.bo[state.buf].modifiable = false
  vim.bo[state.buf].readonly = true
  vim.bo[state.buf].modified = false
  state.job = vim.system(command, { text = true, timeout = 15000, cwd = env.root }, function(result)
    vim.schedule(function()
      if state.closed or not vim.api.nvim_buf_is_valid(state.buf) then return end
      local lines
      if result.code ~= 0 then
        lines = { result.code == 124 and '读取超时（15 秒）；q / Esc 关闭' or '预览失败；q / Esc 关闭',
          'Python: ' .. env.path, '' }
        vim.list_extend(lines, vim.split((result.stderr or ''):sub(1, 4000), '\n', { plain = true }))
      else
        local ok, data = pcall(vim.json.decode, result.stdout)
        lines = ok and render(path, env, data) or { '无法解析 Polars 输出', (result.stdout or ''):sub(1, 4000) }
      end
      vim.bo[state.buf].modifiable = true
      vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
      vim.bo[state.buf].modifiable = false
      vim.bo[state.buf].readonly = true
      vim.bo[state.buf].modified = false
    end)
  end)
end

return M
