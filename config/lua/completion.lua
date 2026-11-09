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
    sorting = { comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      function(a, b)
        if a.source.name == 'buffer' and b.source.name == 'buffer' then
          return require('cmp_buffer'):compare_locality(a, b)
        end
      end,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.locality,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    } },
    sources = {
      { name = 'buffer', priority = 1000, keyword_length = 2, option = {
        get_bufnrs = function()
          local current = vim.api.nvim_get_current_buf()
          local buffers = { current }
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
                and vim.bo[buf].buftype == '' and vim.bo[buf].filetype == vim.bo[current].filetype then
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
