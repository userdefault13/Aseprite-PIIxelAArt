-- Utility functions for AI Pixel Sprites extension

-- Load .env file from extension directory
function loadEnvFile()
  local env = {}
  local extensionPath = app.fs.userConfigPath .. "/extensions/ai-pixel-sprites"
  local envPath = extensionPath .. "/.env"
  
  -- Also try current script directory
  local scriptPath = app.fs.filePath(SCRIPT_PATH)
  if scriptPath then
    envPath = scriptPath .. "/.env"
  end
  
  local file = io.open(envPath, "r")
  if not file then
    return env
  end
  
  for line in file:lines() do
    -- Skip comments and empty lines
    line = line:match("^%s*(.-)%s*$") -- trim
    if line and line ~= "" and not line:match("^#") then
      local key, value = line:match("^([^=]+)=(.+)$")
      if key and value then
        key = key:match("^%s*(.-)%s*$") -- trim key
        value = value:match("^%s*(.-)%s*$") -- trim value
        -- Remove quotes if present
        value = value:match("^[\"'](.+)[\"']$") or value
        env[key] = value
      end
    end
  end
  
  file:close()
  return env
end

-- Get API key from .env
function getApiKey(keyName)
  local env = loadEnvFile()
  return env[keyName] or ""
end

-- Base64 decoder for PNG data
function base64_decode(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = string.gsub(data, '[^'..b..'=]', '')
  
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
  end))
end

-- Error handling helper
function handleError(errorMsg, details)
  local fullMsg = errorMsg
  if details then
    fullMsg = fullMsg .. "\n\n" .. details
  end
  app.alert(fullMsg)
end

-- HTTP request helper
function httpRequest(method, url, headers, body)
  local result = http.request{
    method = method,
    url = url,
    headers = headers or {},
    body = body or ""
  }
  return result
end

