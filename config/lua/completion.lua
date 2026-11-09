local M = {}
function M.setup()
  local cmp = require('cmp')
  cmp.setup({
    preselect = cmp.PreselectMode.None,
    completion = { completeopt = 'menu,menuone,noselect' },
    snippet = { expand = function(args) vim.snippet.expand(args.body) end },
    mapping = {
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.confirm({ select = true }) else fallback() end
      end, { 'i', 's' }),
      ['<CR>'] = cmp.mapping(function(fallback) cmp.abort(); fallback() end, { 'i', 's' }),
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<C-Space>'] = cmp.mapping.complete(),
    },
    sources = {
      { name = 'buffer', priority = 1000, keyword_length = 2, option = {
        get_bufnrs = function()
          local buffers = {}
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == '' then
              buffers[#buffers + 1] = buf
            end
          end
          return buffers
        end,
      } },
      { name = 'path', priority = 900 },
      { name = 'nvim_lsp', priority = 700 },
    },
    formatting = { format = function(entry, item)
      item.menu = '[' .. ({ buffer = 'buf', path = 'path', nvim_lsp = 'ty' })[entry.source.name] .. ']'
      return item
    end },
    window = { documentation = cmp.config.window.bordered() },
  })
end
return M
