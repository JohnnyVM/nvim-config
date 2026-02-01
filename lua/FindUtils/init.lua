local M = {}

-- ===== Utilidades =====
local function is_binary(path)
  -- 1) Try using the 'file' command if it exists
  local file_cmd = vim.fn.executable("file") == 1 and "file -b --mime " .. vim.fn.shellescape(path)
  if file_cmd then
    local output = vim.fn.systemlist(file_cmd)[1] or ""
    -- 'file' reports something like: "text/plain; charset=us-ascii" or "application/octet-stream"
    if output:match("^text/") then
      return false
    elseif output:match("^application/") or output:match("charset=binary") then
      return true
    end
    -- If it’s something unknown, fall through to the NUL-byte heuristic
  end

  -- 2) Fallback: read the first few KB and look for a NUL byte
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)  -- only the first chunk
  if not ok or not lines or not lines[1] then
    return false
  end
  local chunk = table.concat(lines, "\n")
  return chunk:find("\0", 1, true) ~= nil
end


local function escape_vim_regex(pat)
  -- \V = very nomagic; escapamos / para el delimitador del :vimgrep
  return "\\V" .. pat:gsub("/", "\\/")
end

local function is_file(path)
  -- Filtra directorios (y entradas no regulares)
  return vim.fn.isdirectory(path) == 0
end

local function fname(path) -- breve para fnameescape
  return vim.fn.fnameescape(path)
end

-- Añade items al quickfix (append)
local function qf_add_items(items)
  if #items > 0 then
    vim.fn.setqflist(items, "a")
  end
end

-- ===== Implementación principal =====
function M.find_all(pat)
  if not pat or pat == "" then
    vim.notify("Uso: :FindAll <pat>", vim.log.levels.WARN)
    return
  end

  -- --- FASE 1: buffers abiertos ---
  vim.cmd("cexpr []") -- limpia quickfix
  local vimgrep_pat = escape_vim_regex(pat)

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local f = vim.api.nvim_buf_get_name(bufnr)
      if f ~= "" then
        -- keepalt para no ensuciar el jumplist; silent! para evitar ruido
        vim.cmd(("silent! keepalt vimgrepadd /%s/g %s"):format(vimgrep_pat, fname(f)))
      end
    end
  end

  -- TODO This search in a lot useless folders like .cache and node_modules
  -- Fase 2: Búsqueda extendida en directorio con rg si está disponible...
  if vim.fn.executable("rg") == 1 then
    -- Aquí construimos el comando rg
    -- --vimgrep produce salida similar a: "file:line:col:match"
    -- --no-heading evita repetir el nombre de archivo y --hidden incluye archivos ocultos.
    -- La opción --glob '!.git/*' excluye el directorio .git.
	local rg_cmd = {
	  "rg",
	  "--vimgrep",
	  "--no-heading",
	  "--hidden",
	  "--glob", "!.git/*",
	  pat,
	  ".",
	}

	local out = vim.fn.systemlist(rg_cmd)  -- lista de líneas
	vim.fn.setqflist({}, "r", { lines = out })
	vim.cmd("copen")
    return
  end

  pcall(vim.cmd, "copen")

  -- ...si rg NO está disponible, volvemos al enfoque original
  -- Recolectamos una lista de archivos (incluye ocultos; excluye .git)
  -- true,true => devuelve lista (table) y incluye ocultos
  local all = vim.fn.glob("**/*", true, true)
  -- Filtra .git y directorios
  local files = {}
  for _, p in ipairs(all) do
    if p ~= ""
		and is_file(p)
		and not p:match("/%.git/")
		and not p:match("^%.git/")
		and not is_binary(p)
	then
      table.insert(files, p)
    end
  end

  if #files == 0 then
    vim.notify("No se encontraron archivos en el directorio de trabajo.", vim.log.levels.INFO)
    return
  end

  local i = 1
  local total = #files
  local CHUNK = 120        -- cuantos archivos por iteración
  local DEFER_MS = 15      -- pausa entre iteraciones (ms)
  local notify_every = 6   -- notificar cada N iteraciones (para no spamear)
  local iter = 0

  -- Para que las búsquedas masivas no rompan el rendimiento,
  -- no construimos qf items a mano: dejamos que vimgrepadd lo haga.
  local function step()
    if i > total then
      vim.notify("Búsqueda extendida terminada. Quickfix actualizado.", vim.log.levels.INFO)
      return
    end

    local j_end = math.min(i + CHUNK - 1, total)
    -- Ejecuta vimgrepadd sobre el bloque de archivos
    -- Usamos una sola “línea” por archivo (vimgrepadd expande internamente)
    for j = i, j_end do
      local f = files[j]
      vim.cmd(("silent! keepalt vimgrepadd /%s/g %s"):format(vimgrep_pat, fname(f)))
    end

    -- Progreso
    iter = iter + 1
    local done = j_end
    if iter % notify_every == 0 or done == total then
      vim.notify(("Progreso FindAll: %d/%d archivos"):format(done, total))
    end

    -- Siguiente bloque
    i = j_end + 1
    vim.defer_fn(step, DEFER_MS)
  end

  vim.notify(("Buscando en el directorio (%d archivos)…"):format(total))
  step()
end

-- Comando de usuario :FindAll <pat>
vim.api.nvim_create_user_command("FindAll", function(opts)
  M.find_all(opts.args)
end, { nargs = 1, complete = "file" })


-- Put this in your init.lua or a plugin file
vim.api.nvim_create_user_command("FindBuf", function(opts)
  local word = opts.args
  if word == "" then
    print("Usage: :FindBuf <word>")
    return
  end

  -- clear quickfix list
  vim.cmd("cexpr []")

  -- run vimgrepadd across all open buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local fname = vim.api.nvim_buf_get_name(bufnr)
      if fname ~= "" then
        vim.cmd("silent! vimgrepadd /" .. word .. "/g " .. vim.fn.fnameescape(fname))
      end
    end
  end

  -- open quickfix window
  vim.cmd("copen")
end, { nargs = 1 })
