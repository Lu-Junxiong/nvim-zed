local M = {}

function M.cycle(direction, insert)
  require('file_manager').close()
  require('panels').editor()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == ''
        and (vim.api.nvim_buf_get_name(buf) ~= '' or vim.bo[buf].modified) then
      buffers[#buffers + 1] = buf
    end
  end
  local current, index = vim.api.nvim_get_current_buf(), nil
  for i, buf in ipairs(buffers) do if buf == current then index = i; break end end
  if #buffers > 0 then
    index = index and ((index - 1 + direction) % #buffers + 1) or (direction > 0 and 1 or #buffers)
    vim.api.nvim_win_set_buf(0, buffers[index])
  end
  if insert then vim.cmd.startinsert() end
end

function M.setup()
  for key, direction in pairs({ ['<C-Tab>'] = 1, ['<C-S-Tab>'] = -1 }) do
    local opts = { desc = direction == 1 and 'Next file' or 'Previous file' }
    vim.keymap.set('n', key, function() M.cycle(direction) end, opts)
    vim.keymap.set('i', key, [[<C-\><C-n><Cmd>lua require('buffers').cycle(]] .. direction .. [[, true)<CR>]], opts)
    vim.keymap.set('t', key, [[<C-\><C-n><Cmd>lua require('buffers').cycle(]] .. direction .. [[)<CR>]], opts)
  end
end

return M
