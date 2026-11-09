local M = {}

function M.setup_icons()
  local style = vim.env.NVIM_ZED_ICONS or 'glyph'
  assert(style == 'glyph' or style == 'ascii', 'NVIM_ZED_ICONS must be glyph or ascii')
  require('mini.icons').setup({ style = style })
end

function M.setup_clues()
  require('mini.clue').setup({
    triggers = { { mode = { 'n', 'x', 'o' }, keys = '<Leader>' } },
    clues = {
      { mode = 'n', keys = '<Leader>c', desc = '+代码操作' },
      { mode = 'n', keys = '<Leader>h', desc = '+Git 修改' },
      { mode = 'n', keys = '<Leader>r', desc = '+重命名' },
    },
    window = { delay = 300, config = { border = 'rounded', width = 38 } },
  })
end

return M
