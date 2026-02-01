---
-- Trans module: translate text to English using LibreTranslate
-- Provides the :Trans command which echoes the translated text.
---

local M = {}

-- Helper to perform HTTP POST via curl and return decoded JSON
local function post(url, data)
  local json_payload = vim.fn.json_encode(data)
  local cmd = {
    "curl",
    "-s",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-d",
    json_payload,
    url,
  }
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, "Curl error: " .. table.concat(out, "\n")
  end
  local ok, decoded = pcall(vim.fn.json_decode, table.concat(out, "\n"))
  if not ok then
    return nil, "Failed to decode JSON response"
  end
  return decoded, nil
end

--- Translate given text to English.
-- @param text string The text to translate.
-- @return string Translated text or error message.
function M.translate(text)
  if not text or text == "" then
    return "[Trans] No text provided"
  end
  local payload = {
    q = text,
    source = "auto",
    target = "en",
    format = "text",
  }
  local resp, err = post("https://libretranslate.com/translate", payload)
  if err then
    return "[Trans] Error: " .. err
  end
  if resp and resp.translatedText then
    return resp.translatedText
  else
    return "[Trans] Unexpected response"
  end
end

-- Register the user command
vim.api.nvim_create_user_command("Trans", function(opts)
  local text = nil
  -- If a visual range is provided, get those lines
  if opts.line1 and opts.line2 then
    local start_line = opts.line1 - 1 -- zero-index for API
    local end_line = opts.line2 -- exclusive
    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
    text = table.concat(lines, "\n")
  elseif opts.args and opts.args ~= "" then
    text = opts.args
  else
    -- No args or range: try to get visual selection via '<,'> marks if they exist
    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\x16" then -- visual, linewise, block
      local s = vim.fn.getpos("'<")
      local e = vim.fn.getpos("'>")
      local start_line = s[2] - 1
      local end_line = e[2]
      local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
      text = table.concat(lines, "\n")
    else
      vim.notify("[Trans] No text provided", vim.log.levels.WARN)
      return
    end
  end

  local result = M.translate(text)
  vim.notify(result, vim.log.levels.INFO)
end, { nargs = "*", range = true })

return M
