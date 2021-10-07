local M = {}

local json = require("deepl.json")
local a = vim.api
local uv = vim.loop

local config = {
  url = nil,
  authkey = nil,
}

local current_win

function M.close()
  if current_win then
    a.nvim_win_close(current_win.win, true)
    a.nvim_buf_delete(current_win.buf, { force = true })
    current_win = nil
  end
end

local function code_decision(num)
  if num < 127 then
    return true
  elseif num < 161 then
    return false
  elseif num < 224 then
    return true
  end
  return false
end

local function head(str)
  if str == "" then
    return "", nil, 0
  elseif #str == 1 then
    return str, nil, 1
  elseif code_decision(str:byte()) then
    return str:sub(1, 1), str:sub(2), 1
  end
  return str:sub(1, 3), str:sub(4), 2
end

local function cut(str, num)
  local res = { {} }
  local init, len = "", 0
  local c = 1
  repeat
    local width
    init, str, width = head(str)
    len = len + width
    if len > num then
      c = c + 1
      len = width
      res[c] = {}
    end
    table.insert(res[c], init)
  until str == nil
  for i = 1, #res do
    res[i] = table.concat(res[i], "")
  end
  return res, (c == 1 and len or num)
end

function M.create_window(lines, width)
  M.close()
  local buf = a.nvim_create_buf(false, true)
  a.nvim_buf_set_lines(buf, 0, -1, true, lines)
  local win = a.nvim_open_win(buf, false, {
    relative = "cursor",
    width = width,
    height = #lines,
    style = "minimal",
    row = 1,
    col = 1,
    border = "single",
  })
  return { win = win, buf = buf }
end

function M.translate(line1, line2, from, to, mode)
  if not (config.authkey and config.url) then
    return
  end
  local texts = a.nvim_buf_get_lines(0, line1 - 1, line2, true)
  local txt = table.concat(texts, " "):gsub("%s+", " ")

  local stdout = uv.new_pipe(false)

  local args = {
    config.url,
    "-d",
    "auth_key=" .. config.authkey,
    "-d",
    "text=" .. txt,
    "-d",
    "source_lang=" .. from,
    "-d",
    "target_lang=" .. to,
  }

  local response

  uv.spawn("curl", {
    stdio = { nil, stdout, nil },
    args = args,
  }, function(code, _)
    if code == 0 then
      print("Translate success")
      uv.read_start(stdout, function(err, data)
        assert(not err, err)
        if data then
          response = data
        end
      end)
    else
      print("Translate failed")
    end
  end)

  local timer = uv.new_timer()
  timer:start(
    0,
    500,
    vim.schedule_wrap(function()
      if response then
        response = json.decode(response)
        if response.translations and response.translations[1] and response.translations[1].text then
          local text = response.translations[1].text
          if mode == "r" then
            a.nvim_buf_set_lines(0, line1 - 1, line2, true, { text })
          elseif mode == "f" then
            local lines
            local width = math.floor(a.nvim_win_get_width(0) * 0.8)
            lines, width = cut(text, width)
            current_win = M.create_window(lines, width)
          end
        end
        timer:stop()
        timer:close()
      end
    end)
  )
end

function M.setup(opts)
  opts = opts or {}
  if opts.key then
    config.authkey = opts.key
  else
    print("Please set authkey")
    return
  end

  local url = "https://api%s.deepl.com/v2/translate"
  if opts.plan == "free" then
    config.url = url:format("-free")
  elseif opts.plan == "pro" then
    config.url = url:format("")
  else
    print("plan must be 'free' or 'pro'")
    return
  end
end

return M
