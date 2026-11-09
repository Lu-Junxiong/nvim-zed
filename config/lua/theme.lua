-- Atom One Light palette; keep UI components on the same palette.
require('onedarkpro').setup({
  caching = false,
  colors = {
    onelight = {
      bg = '#fafafa', fg = '#383a42',
      red = '#e45649', orange = '#986801', yellow = '#c18401',
      green = '#50a14f', cyan = '#0184bc', blue = '#4078f2',
      purple = '#a626a4', white = '#fafafa', black = '#383a42',
      gray = '#a0a1a7', comment = '#a0a1a7',
    },
  },
  options = { cursorline = true, terminal_colors = true },
  highlights = {
    MiniTablineCurrent = { fg = '${blue}', bg = '${bg}', bold = true },
    MiniTablineModifiedCurrent = { fg = '${orange}', bg = '${bg}', bold = true },
    MiniTablineVisible = { fg = '${fg}', bg = '${bg_statusline}' },
    MiniTablineHidden = { fg = '${comment}', bg = '${bg_statusline}' },
    MiniTablineModifiedVisible = { fg = '${orange}', bg = '${bg_statusline}' },
    MiniTablineModifiedHidden = { fg = '${orange}', bg = '${bg_statusline}' },
    MiniTablineFill = { bg = '${bg_statusline}' },
    MiniStatuslineModeNormal = { fg = '${white}', bg = '${blue}', bold = true },
    MiniStatuslineModeInsert = { fg = '${white}', bg = '${green}', bold = true },
    MiniStatuslineModeVisual = { fg = '${white}', bg = '${purple}', bold = true },
    MiniStatuslineModeReplace = { fg = '${white}', bg = '${red}', bold = true },
    MiniStatuslineModeCommand = { fg = '${white}', bg = '${orange}', bold = true },
    MiniStatuslineModeOther = { fg = '${white}', bg = '${cyan}', bold = true },
    MiniStatuslineDevinfo = { fg = '${fg}', bg = '${bg_statusline}' },
    MiniStatuslineFilename = { fg = '${fg}', bg = '${bg}' },
    MiniStatuslineFileinfo = { fg = '${fg}', bg = '${bg_statusline}' },
    MiniStatuslineInactive = { fg = '${comment}', bg = '${bg_statusline}' },
    MiniPickNormal = { link = 'NormalFloat' },
    MiniPickBorder = { link = 'FloatBorder' },
    MiniPickMatchCurrent = { link = 'PmenuSel' },
    MiniPickMatchRanges = { fg = '${blue}', bold = true },
  },
})
vim.cmd.colorscheme('onelight')
