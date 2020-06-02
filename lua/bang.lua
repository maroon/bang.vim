local api = vim.api
local loop = vim.loop

local function cleanup_job(job_id)
  if api.jobwait({job_id}, 0)[1] == -1 then
    api.jobstop(job_id)
    api.print("Job killed.")
  end
end

local function start_job(command)
  local stdout = loop.new_pipe()
  local stderr = loop.new_pipe()
  local handle = loop.spawn(command, {
    stdio = {nil, stdout, stderr}
  }, function(code, signal)
    cleanup_job(handle)
  end)
  local buffer = api.nvim_create_buf(false, true)

  loop.read_start(stdout, function(err, data)
    api.nvim_buf_set_lines(buffer, -1, -1, false, data)
  end)
  loop.read_start(stderr, function(err, data)
    local message = ">> Press return to close the buffer"
    api.nvim_buf_set_lines(buffer, -1, -1, false, message)
  end)

  api.nvim_set_current_buf(buffer)
  api.nvim_set_keymap('no', '<buffer><silent>', '<CR>', ':b#<CR>')
  api.nvim_buf_attach(buffer, false, {
    on_detach=function(b)
      cleanup_job(job_id)
    end
  })
end

return {
  start_job = start_job
}
