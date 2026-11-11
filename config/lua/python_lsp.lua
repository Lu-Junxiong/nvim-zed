local M = {}
function M.setup()
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  local ty_settings = { ty = { disableLanguageServices = false, diagnosticMode = 'off' } }
  local function root_dir(buf, on_dir)
    on_dir(require('python_env').project_root(vim.api.nvim_buf_get_name(buf)))
  end
  vim.lsp.config('ty', {
    cmd = { 'ty', 'server' }, filetypes = { 'python' },
    root_dir = function(buf, on_dir)
      local python = require('python_env')
      local root = python.project_root(vim.api.nvim_buf_get_name(buf))
      local env, err = python.resolve(root)
      if not env then vim.notify(err, vim.log.levels.ERROR); return end
      on_dir(root)
    end,
    capabilities = capabilities, settings = ty_settings,
    before_init = function(_, config)
      local env = assert(require('python_env').resolve(config.root_dir))
      config.settings.ty.configuration = { environment = { python = env.path } }
    end,
  })
  vim.lsp.config('ruff', {
    cmd = { 'ruff', 'server' }, filetypes = { 'python' }, root_dir = root_dir,
    capabilities = capabilities,
    on_attach = function(client) client.server_capabilities.hoverProvider = false end,
  })
  vim.lsp.enable({ 'ty', 'ruff' })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    callback = function(args)
      local opts = function(desc) return { buffer = args.buf, desc = desc } end
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts('Find references'))
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts('Hover'))
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts('Rename'))
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts('Code action'))
      vim.keymap.set('n', '<leader>f', function()
        vim.lsp.buf.format({ name = 'ruff', async = false, timeout_ms = 5000 })
      end, opts('Format with Ruff'))
      vim.keymap.set('n', '<leader>ci', function()
        vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' }, diagnostics = {} }, apply = true })
      end, opts('Organize imports'))
    end,
  })
  vim.api.nvim_create_user_command('ZedInfo', function()
    local info = { 'Bundle: ' .. vim.env.NVIM_ZED_ROOT, 'Project: ' .. vim.fn.getcwd() }
    for _, tool in ipairs({ 'ty', 'ruff', 'rg', 'git' }) do
      local result = vim.system({ tool, '--version' }, { text = true }):wait()
      info[#info + 1] = vim.fn.exepath(tool) .. ': ' .. vim.trim(result.stdout or result.stderr or '')
    end
    local env, err = require('python_env').resolve()
    info[#info + 1] = env and ('Python: ' .. env.path .. ' / ' .. env.source) or err
    info[#info + 1] = 'VIRTUAL_ENV: ' .. (vim.env.VIRTUAL_ENV or '(unset)')
    info[#info + 1] = 'CONDA_PREFIX: ' .. (vim.env.CONDA_PREFIX or '(unset)')
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      info[#info + 1] = 'LSP: ' .. client.name .. ' / ' .. (client.root_dir or '')
    end
    vim.notify(table.concat(info, '\n'))
  end, {})
end
return M
