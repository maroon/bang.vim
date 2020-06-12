local api = vim.api
local loop = vim.loop
local sync = vim.schedule_wrap

local function count(list)
  local count = 0
  for entry in pairs(list) do
    count = count + 1
  end
  return count
end

local function drop(str, char)
  local replacement, _ = string.gsub(str, char, '')
  return replacement
end

local function write(window, buffer, data)
  if data == nil or not api.nvim_buf_is_valid(buffer) then
    return
  end

  local lines = api.nvim_buf_line_count(buffer) - 1
  local value = vim.split(data, '\n')
  local offset = count(value) + lines
  api.nvim_buf_set_option(buffer, 'modifiable', true)
  api.nvim_buf_set_lines(buffer, lines, offset, false, value)
  api.nvim_buf_set_option(buffer, 'modifiable', false)
  api.nvim_win_set_cursor(window, {offset, 0})
end

local function cleanup_handle(handle, notify)
  if handle and not handle:is_closing() then
    handle:close()
    if notify then
      print('Job killed.')
    end
  end
end

local function cleanup_job(process, stdout, stderr, notify)
  stdout:read_stop()
  stderr:read_stop()
  cleanup_handle(stdout)
  cleanup_handle(stderr)
  cleanup_handle(process, notify)
end

local function start_job(args)
  local command, arguments = args[1], {unpack(args, 2)}
  local window = api.nvim_get_current_win()
  local buffer = api.nvim_create_buf(false, true)
  local stdout = loop.new_pipe(false)
  local stderr = loop.new_pipe(false)
  local process, _ = loop.spawn(command, {
    args = arguments,
    stdio = {nil, stdout, stderr}
  }, sync(function(code, signal)
    local message = '>> Press return to close the buffer <<'
    write(window, buffer, '\n\n')
    write(window, buffer, message)
    cleanup_job(process, stdout, stderr)
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
      cleanup_job(process, stdout, stderr, true)
    end
  })

  loop.read_start(stdout, sync(function(err, data)
    write(window, buffer, data)
  end))
  loop.read_start(stderr, sync(function(err, data)
    write(window, buffer, data)
  end))
end

return {
  start_job = start_job
}
