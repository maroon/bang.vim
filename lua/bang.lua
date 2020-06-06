local api = vim.api
local loop = vim.loop
local sync = vim.schedule_wrap

local function count(table)
  local count = 0
  for entry in pairs(table) do
    count = count + 1
  end
  return count
end

local function drop(str, char)
  local replacement, _ = string.gsub(str, char, '')
  return replacement
end

local function parse(args)
  local args = vim.split(args, ',', true)
  local values = {}
  for _, arg in ipairs(args) do
    table.insert(values, drop(arg, '"'))
  end
  return values[1], {unpack(values, 2)}
end

local function write(buffer, data)
  if data == nil or not api.nvim_buf_is_valid(buffer) then
    return
  end

  local lines = api.nvim_buf_line_count(buffer)
  local offset = lines - 1
  local value = table.concat(vim.split(data, '\n'))
  api.nvim_buf_set_option(buffer, 'modifiable', true)
  api.nvim_buf_set_lines(buffer, offset, offset, false, {value})
  api.nvim_buf_set_option(buffer, 'modifiable', false)
end

local function cleanup_job(handle, stdout, stderr)
  if not handle or not loop.is_active(handle) then
    return
  end
  stdout:read_stop()
  stdout:close()
  stderr:read_stop()
  stderr:close()
  handle:close()
  print('Job killed.')
end

local function start_job(args)
  local command, arguments = parse(args)
  local buffer = api.nvim_create_buf(false, true)
  local stdout = loop.new_pipe(false)
  local stderr = loop.new_pipe(false)
  local handle, _ = loop.spawn(command, {
    args = arguments,
    stdio = {nil, stdout, stderr}
  }, sync(function(code, signal)
    local message = '>> Press return to close the buffer <<'
    write(buffer, message)
    cleanup_job(handle, stdout, stderr)
  end))

  api.nvim_set_current_buf(buffer)
  api.nvim_buf_set_keymap(buffer, 'n', '<CR>', ':b#<CR>', {
    silent = true
  })
  api.nvim_buf_set_option(buffer, 'modifiable', false)
  api.nvim_buf_set_option(buffer, 'buftype', 'nofile')
  api.nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
  api.nvim_buf_attach(buffer, false, {
    on_detach=function(buffer)
      cleanup_job(handle, stdout, stderr)
    end
  })

  loop.read_start(stdout, sync(function(err, data)
    write(buffer, data)
  end))
  loop.read_start(stderr, sync(function(err, data)
    write(buffer, data)
  end))
end

return {
  start_job = start_job
}
