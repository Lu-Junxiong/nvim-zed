local M = {}
local environments = {}

function M.project_root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == '' then return vim.fn.getcwd() end
  return vim.fs.root(path, { 'pyproject.toml', 'ty.toml', 'ruff.toml', '.ruff.toml', '.git' })
    or (vim.fs.relpath(vim.fn.getcwd(), path) and vim.fn.getcwd()) or vim.fs.dirname(path)
end

local function interpreter(path)
  path = vim.fn.fnamemodify(path, ':p'):gsub('/$', '')
  if vim.fn.isdirectory(path) == 1 then path = path .. '/bin/python' end
  if vim.fn.executable(path) == 1 then return path end
end

function M.resolve(root)
  root = root or M.project_root()
  if environments[root] then return environments[root] end
  local function remember(path, source, name)
    local env = { path = path, source = source, name = name, root = root }
    environments[root] = env
    return env
  end
  local candidates = {
    { vim.env.NVIM_ZED_PYTHON, 'NVIM_ZED_PYTHON', true },
    { vim.env.VIRTUAL_ENV, 'VIRTUAL_ENV', true },
    { vim.env.CONDA_DEFAULT_ENV ~= 'base' and vim.env.CONDA_PREFIX or nil, 'Conda' },
    { root .. '/.venv', 'project .venv' },
    { vim.env.CONDA_PREFIX, 'Conda base' },
  }
  for _, item in ipairs(candidates) do
    if item[1] and item[1] ~= '' then
      local path = interpreter(item[1])
      if path then
        local directory = vim.fs.dirname(vim.fs.dirname(path))
        return remember(path, item[2], vim.fs.basename(directory))
      end
      if item[3] then return nil, item[2] .. ' has no executable Python: ' .. item[1] end
    end
  end
  for _, command in ipairs({ 'python3', 'python' }) do
    for directory in (vim.env.NVIM_ZED_HOST_PATH or ''):gmatch('[^:]+') do
      local path = interpreter(directory .. '/' .. command)
      if path then return remember(path, 'PATH', command) end
    end
  end
  return nil, 'No Python interpreter found; set NVIM_ZED_PYTHON to an environment or executable'
end

function M.status()
  if vim.bo.filetype ~= 'python' then return '' end
  local env = M.resolve()
  return env and ('Py: ' .. env.name):gsub('%%', '%%%%') or 'Py: unavailable'
end

function M.info()
  local env, err = M.resolve()
  if not env then vim.notify(err, vim.log.levels.ERROR); return end
  vim.notify('Python: ' .. env.path .. '\nSource: ' .. env.source .. '\nProject: ' .. env.root
    .. '\nApplies to ty, data preview and nvitop; shell retains the launch environment.')
end

return M
