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

local function start_job(command)
  local buffer = api.nvim_create_buf(false, true)
  local stdout = loop.new_pipe(false)
  local stderr = loop.new_pipe(false)
  local handle = loop.spawn(command, {
    stdio = {nil, stdout, stderr}
  }, function(code, signal)
    cleanup_job(handle)
  end)

  loop.read_start(stdout, sync(function(err, data)
    api.nvim_buf_set_lines(buffer, -1, -1, false, {data})
  end))
  loop.read_start(stderr, sync(function(err, data)
    api.nvim_buf_set_lines(buffer, -1, -1, false, {data})
  end))

  api.nvim_set_current_buf(buffer)
  api.nvim_set_keymap('n', '<buffer><silent> <CR>', ':b#<CR>', {})
  api.nvim_buf_attach(buffer, false, {
    on_detach=function(b)
      cleanup_job(job_id)
    end
  })
end

return {
  start_job = start_job
}
