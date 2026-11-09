local M = {}
local languages = { json = 'json', jsonc = 'json', yaml = 'yaml' }

local function field(node, name) return node:field(name)[1] end
local function compact(text) return text:gsub('[\r\n]+', ' ') end

local function append_key(parent, key, json)
  local bare = json and key:sub(2, -2) or key
  if bare:match('^[%a_][%w_]*$') then
    return parent == '' and bare or parent .. '.' .. bare
  end
  return parent .. '[' .. key .. ']'
end

local function tree_items(buf, language)
  local parser = vim.treesitter.get_parser(buf, language)
  local root = parser:parse()[1]:root()
  local items = {}
  local function add(node, path, depth)
    local row, col = node:start()
    items[#items + 1] = { bufnr = buf, lnum = row + 1, col = col + 1, text = string.rep('  ', depth) .. compact(path) }
  end
  local walk
  walk = function(node, path, depth)
    local kind = node:type()
    if kind == 'pair' or kind == 'block_mapping_pair' or kind == 'flow_pair' then
      local key = field(node, 'key')
      if key and not key:missing() and not key:has_error() then
        local text = vim.treesitter.get_node_text(key, buf)
        if text ~= '' then
          local next_path = append_key(path, text, language == 'json')
          add(key, next_path, depth)
          local value = field(node, 'value')
          if value then walk(value, next_path, depth + 1) end
        end
      end
    elseif kind == 'array' or kind == 'block_sequence' or kind == 'flow_sequence' then
      local index = 0
      for child in node:iter_children() do
        if child:named() and child:type() ~= 'comment' then
          local next_path = path .. '[' .. index .. ']'
          add(child, next_path, depth)
          walk(child, next_path, depth + 1)
          index = index + 1
        end
      end
    else
      for child in node:iter_children() do
        if child:named() then walk(child, path, depth) end
      end
    end
  end
  local documents = {}
  if language == 'yaml' then
    for child in root:iter_children() do
      if child:type() == 'document' then documents[#documents + 1] = child end
    end
  end
  if #documents > 1 then
    local index = 0
    for _, child in ipairs(documents) do
      index = index + 1
      local path = 'doc' .. index
      add(child, path, 0)
      walk(child, path, 1)
    end
  else
    walk(root, '', 0)
  end
  return items, root:has_error()
end

local function ini_items(buf)
  local items, section, key_indent = {}, '', nil
  for index, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local indentation = #line:match('^%s*')
    -- More deeply indented lines belong to the preceding INI value.
    if not line:match('^%s*[;#]') and (not key_indent or indentation <= key_indent) then
      local name, rest = line:match('^%s*%[([^%]]+)%]%s*(.*)$')
      if name and (rest == '' or rest:match('^[;#]')) then
        section, key_indent = '[' .. vim.trim(name) .. ']', nil
        items[#items + 1] = { bufnr = buf, lnum = index, col = line:find('[', 1, true), text = section }
      else
        local indent, key = line:match('^(%s*)([^=:]+)[=:]')
        if key and (not key_indent or #indent <= key_indent) then
          key = vim.trim(key)
          if key ~= '' then
            key_indent = #indent
            items[#items + 1] = { bufnr = buf, lnum = index, col = #indent + 1,
              text = section == '' and key or '  ' .. section .. '.' .. key }
          end
        end
      end
    end
  end
  return items, false
end

function M.items(buf)
  local language = languages[vim.bo[buf].filetype]
  if language then return tree_items(buf, language) end
  if vim.bo[buf].filetype == 'dosini' or vim.bo[buf].filetype == 'ini' or vim.bo[buf].filetype == 'cfg' then return ini_items(buf) end
end

function M.open()
  require('panels').editor()
  local items, incomplete = M.items(vim.api.nvim_get_current_buf())
  if items then
    if incomplete then vim.notify('文件有未完成的语法，显示已识别的结构。', vim.log.levels.WARN) end
    if #items == 0 then
      vim.notify('当前文件没有可显示的结构。')
      return
    end
    MiniPick.start({ source = { name = 'Outline', items = items } })
  elseif #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/documentSymbol' }) > 0 then
    MiniExtra.pickers.lsp({ scope = 'document_symbol' }, { source = { name = 'Outline' } })
  else
    vim.notify('当前文件的大纲服务尚未就绪或不支持此文件类型。', vim.log.levels.WARN)
  end
end

return M
