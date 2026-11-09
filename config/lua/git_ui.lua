local M = {}
function M.setup()
  local gs = require('gitsigns')
  gs.setup({
    signs = { add = { text = '+' }, change = { text = '~' }, delete = { text = '_' }, topdelete = { text = '-' }, changedelete = { text = '~' } },
    on_attach = function(buf)
      local function map(key, action, desc) vim.keymap.set('n', key, action, { buffer = buf, desc = desc }) end
      map(']c', function() gs.nav_hunk('next') end, 'Next change')
      map('[c', function() gs.nav_hunk('prev') end, 'Previous change')
      map('<leader>hp', gs.preview_hunk, 'Preview change')
      map('<leader>hd', function()
        vim.cmd('tab split')
        vim.t.zed_diff = true
        gs.diffthis()
      end, 'Diff against index')
    end,
  })
  vim.keymap.set('n', '<leader>hq', function()
    if vim.t.zed_diff then vim.cmd.tabclose() end
  end, { desc = 'Close diff tab' })
end
return M
