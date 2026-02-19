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
--   :Trans/i            – translate visual selection or current line, replacing it in-place
--   :Trans/<lang>/i     – translate to a specific language and replace in-place
--   :'<,'>Trans         – translate the selected range
--   :'<,'>Trans/i       – translate the selected range and replace it in-place
vim.api.nvim_create_user_command("Trans", function(opts)
  local text = nil
  local target_lang = "en"
  local inplace = false

  -- Parse flags from args: /i (in-place replacement) and /lang (target language).
  -- Flags can appear in any order, e.g. :Trans/es/i or :Trans/i/es.
  local args = opts.args or ""
  for flag in args:gmatch("/(%a+)") do
    if flag == "i" then
      inplace = true
    else
      target_lang = flag
    end
  end
  -- Strip all /flag tokens; whatever remains is treated as literal text to translate.
  args = (args:gsub("/%a+", "")):match("^%s*(.-)%s*$") or ""

  -- Track the source of text so we know what to replace when inplace=true.
  -- Possible values: "range", "visual", "line", "arg"
  local source = nil

  -- Determine text source (priority: range > args > visual selection > current line)
  if opts.range == 2 then
    -- Explicit line range (e.g. :'<,'>Trans)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    text = table.concat(lines, "\n")
    source = "range"
  elseif args ~= "" then
    text = args
    source = "arg"
  else
    -- Try last visual selection
    local vis = get_visual_selection()
    if vis and vis ~= "" then
      text = vis
      source = "visual"
    else
      -- Fall back to current line
      text = vim.api.nvim_get_current_line()
      source = "line"
    end
  end

  if not text or text:match("^%s*$") then
    vim.notify("[Trans] No text to translate", vim.log.levels.WARN)
    return
  end

  local result, err = M.translate(text, target_lang)
  if err then
    vim.notify("[Trans] Error: " .. err, vim.log.levels.ERROR)
    return
  end

  if inplace and source ~= "arg" then
    local new_lines = vim.split(result, "\n", { plain = true })
    if source == "range" then
      vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, new_lines)
    elseif source == "visual" then
      local s = vim.fn.getpos("'<")
      local e = vim.fn.getpos("'>")
      -- nvim_buf_set_text uses 0-based rows and byte columns; '>' col is inclusive.
      vim.api.nvim_buf_set_text(0, s[2] - 1, s[3] - 1, e[2] - 1, e[3], new_lines)
    elseif source == "line" then
      local row = vim.api.nvim_win_get_cursor(0)[1] - 1
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, new_lines)
    end
  else
    vim.notify(result, vim.log.levels.INFO)
  end
end, { nargs = "*", range = true, desc = "Translate text (or :Trans/<lang>, :Trans/i to replace in-place)" })

return M
