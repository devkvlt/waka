local uv = require('luv')

local today = ''

local function set_interval(interval, callback)
  callback()

  local timer = uv.new_timer()

  local function on_timeout()
    callback(timer)
  end

  uv.timer_start(timer, interval, interval, on_timeout)

  return timer
end

local function update_wakatime()
  local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local function on_exit(code, signal)
    stdin:close()
    stdout:close()
    stderr:close()
  end

  uv.spawn('wakatime-cli', {
    args = {
      '--today',
    },
    stdio = {
      stdin,
      stdout,
      stderr,
    },
  }, on_exit)

  uv.read_start(stdout, function(err, data)
    if err then
      vim.notify('Error reading stdout: ' .. err, vim.log.levels.ERROR)
      return
    end

    if data then
      today = data
        :sub(1, #data - 1)
        :gsub(' secs', 's')
        :gsub(' hrs', 'h')
        :gsub(' mins', 'm')
        :gsub(' hr', 'h')
        :gsub(' min', 'm')
    end
  end)
end

-- Update every 5 minutes
set_interval(300000, update_wakatime)

return function()
  return today
end
