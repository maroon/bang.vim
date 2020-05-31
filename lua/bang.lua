local api = vim.api

local function on_job_event(job_id, data, event)
end

local function cleanup_job(job_id)
end

local function start_job(command)
  api.nvim_command('echo "' .. command .. '"')
end

return {
  start_job = start_job
}
