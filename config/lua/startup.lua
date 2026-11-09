local M = {}

function M.setup()
  local starter = require('mini.starter')
  starter.setup({
    autoopen = false,
    evaluate_single = false,
    header = function() return 'nvim-zed\n' .. vim.fn.getcwd() end,
    footer = '方向键选择 · Enter 打开 · Ctrl-\\ 终端',
    items = {
      { name = 'f  查找文件     Ctrl-p', section = '开始', action = function() MiniPick.builtin.files({ tool = 'rg' }) end },
      { name = 'g  搜索文本     空格 /', section = '开始', action = function() MiniPick.builtin.grep_live({ tool = 'rg' }) end },
      { name = 'n  新建文件', section = '开始', action = 'enew' },
      { name = 'h  快捷键说明', section = '开始', action = function()
        vim.cmd.edit(vim.fn.fnameescape(vim.env.NVIM_ZED_ROOT .. '/README.md'))
      end },
      { name = 'q  退出', section = '开始', action = 'qa' },
      function()
        local items = starter.sections.recent_files(5, true, true)()
        for i, item in ipairs(items) do
          item.section = '最近项目文件'
          if item.action == '' then
            item.name = '暂无最近文件'
          else
            item.name = 'r' .. i .. '  ' .. item.name
          end
        end
        return items
      end,
    },
    content_hooks = { starter.gen_hook.adding_bullet('  '), starter.gen_hook.aligning('center', 'center') },
  })
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniStarterOpened',
    callback = function(args)
      vim.keymap.set('n', '<C-p>', function() MiniPick.builtin.files({ tool = 'rg' }) end,
        { buffer = args.buf, desc = 'Find files' })
    end,
  })
end

function M.open_if_empty()
  -- File arguments and stdin content take precedence over the home page.
  if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == '' and vim.bo.buftype == ''
      and not vim.bo.modified and vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { '' }) then
    MiniStarter.open()
  end
end

return M
