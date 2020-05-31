local api = vim.api
local buffers = {}

local function on_job_event(job_id, data, event)
  local buffer = buffers[job_id]
  if buffer == nil or not api.nvim_buf_is_loaded(buffer) then
    return
  end

  if event == 'stdout' or event == 'stderr' then
    api.nvim_buf_set_lines(buffer, -1, -1, false, data)
  elseif event == 'exit' then
    local message = ">> Press return to close the buffer"
    api.nvim_buf_set_lines(buffer, -1, -1, false, message)
  else
    return
  end
end

local function cleanup_job(job_id)
  buffers[job_id] = nil
  if api.jobwait({job_id}, 0)[1] == -1 then
    api.jobstop(job_id)
    api.print("Job killed.")
  end
end

local function start_job(command)
  local job_id = api.jobstart(command, {
    on_stdout = on_job_event,
    on_stderr = on_job_event,
    on_exit = on_job_event,
  })
  local buffer = api.nvim_create_buf(false, true)
  buffers[job_id] = buffer
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
