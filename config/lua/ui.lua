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

function M.statusline()
  local line = MiniStatusline
  local mode, highlight = line.section_mode({ trunc_width = 120 })
  return line.combine_groups({
    { hl = highlight, strings = { mode } },
    { hl = 'MiniStatuslineDevinfo', strings = {
      line.section_git({ trunc_width = 40 }), line.section_diff({ trunc_width = 75 }),
      line.section_diagnostics({ trunc_width = 75 }), line.section_lsp({ trunc_width = 75 }),
    } },
    '%<',
    { hl = 'MiniStatuslineFilename', strings = { line.section_filename({ trunc_width = 140 }) } },
    '%=',
    { hl = 'MiniStatuslineFileinfo', strings = {
      require('python_env').status(), line.section_fileinfo({ trunc_width = 120 }),
    } },
    { hl = highlight, strings = { line.section_searchcount({ trunc_width = 75 }), line.section_location({ trunc_width = 75 }) } },
  })
end

return M
