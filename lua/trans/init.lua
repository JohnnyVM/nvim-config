---
-- Trans module: translate text using Google Translate
-- Provides the :Trans [target_lang] command which echoes the translated text.
-- By default translates from any language to English.
---

local M = {}

--- Translate given text using Google Translate.
-- @param text string The text to translate.
-- @param target_lang string|nil Target language code (default: "en").
-- @return string|nil, string|nil Translated text or nil, error message or nil.
function M.translate(text, target_lang)
  if not text or text == "" then
    return nil, "No text provided"
  end
  target_lang = target_lang or "en"

  local cmd = {
    "curl",
    "-s",
    "-G",
    "https://translate.googleapis.com/translate_a/single",
    "--data-urlencode", "q=" .. text,
    "-d", "client=gtx",
    "-d", "sl=auto",
    "-d", "tl=" .. target_lang,
    "-d", "dt=t",
  }

  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, "Curl error: " .. table.concat(out, "\n")
  end

  local ok, decoded = pcall(vim.fn.json_decode, table.concat(out, "\n"))
  if not ok or type(decoded) ~= "table" then
    return nil, "Failed to decode JSON response"
  end

  -- Response format: [[["translated","original",...], ...], null, "detected_lang", ...]
  local segments = decoded[1]
  if type(segments) ~= "table" then
    return nil, "Unexpected response format"
  end

  local parts = {}
  for _, seg in ipairs(segments) do
    if type(seg) == "table" and seg[1] then
      table.insert(parts, seg[1])
    end
  end

  if #parts == 0 then
    return nil, "No translation returned"
  end

  return table.concat(parts, ""), nil
end

--- Get text from the current visual selection.
-- @return string|nil
local function get_visual_selection()
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s[2] - 1, e[2], false)
  if #lines == 0 then return nil end
  -- Trim the last line to the column of '>'
  if #lines == 1 then
    lines[1] = lines[1]:sub(s[3], e[3])
  else
    lines[1] = lines[1]:sub(s[3])
    lines[#lines] = lines[#lines]:sub(1, e[3])
  end
  return table.concat(lines, "\n")
end

-- Register the user command:
--   :Trans              – translate visual selection or current line
--   :Trans <text>       – translate the given text
--   :Trans/<lang>       – translate to a specific language (e.g. :Trans/es)
--   :'<,'>Trans         – translate the selected range
vim.api.nvim_create_user_command("Trans", function(opts)
  local text = nil
  local target_lang = "en"

  -- Parse optional language suffix: Trans/es
  local args = opts.args or ""
  local lang_override = args:match("^/(%a+)%s*$")
  if lang_override then
    target_lang = lang_override
    args = ""
  end

  -- Determine text source (priority: range > args > visual selection > current line)
  if opts.range == 2 then
    -- Explicit line range (e.g. :'<,'>Trans)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    text = table.concat(lines, "\n")
  elseif args ~= "" then
    text = args
  else
    -- Try last visual selection
    local vis = get_visual_selection()
    if vis and vis ~= "" then
      text = vis
    else
      -- Fall back to current line
      text = vim.api.nvim_get_current_line()
    end
  end

  if not text or text:match("^%s*$") then
    vim.notify("[Trans] No text to translate", vim.log.levels.WARN)
    return
  end

  local result, err = M.translate(text, target_lang)
  if err then
    vim.notify("[Trans] Error: " .. err, vim.log.levels.ERROR)
  else
    vim.notify(result, vim.log.levels.INFO)
  end
end, { nargs = "*", range = true, desc = "Translate text to English (or :Trans/<lang>)" })

return M
