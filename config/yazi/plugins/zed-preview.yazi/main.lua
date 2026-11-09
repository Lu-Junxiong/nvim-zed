local hovered = ya.sync(function()
  local file = cx.active.current.hovered
  return file and not file.cha.is_dir and file.url or nil
end)

return {
  entry = function()
    local url = hovered()
    local path = url and tostring(url) or ''
    local extension = path:lower():match('%.([^./]+)$')
    if extension ~= 'csv' and extension ~= 'tsv' and extension ~= 'parquet' then
      ya.notify { title = 'Polars', content = 'Select a CSV, TSV or Parquet file', timeout = 3, level = 'warn' }
      return
    end
    local output = os.getenv('NVIM_ZED_PREVIEW_FILE')
    if not output then return end
    local ok, err = fs.write(Url(output), path)
    if not ok then
      ya.notify { title = 'Polars', content = tostring(err), timeout = 5, level = 'error' }
      return
    end
    ya.emit('quit', {})
  end,
}
