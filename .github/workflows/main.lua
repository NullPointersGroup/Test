local lfs = require("lfs")

OUTPUT_DIR = "Documentazione/output"
SRC_DIR = "Documentazione/src"
INDEX_HTML_PATH = "Documentazione/index.html"
SECTION_ORDER = { "PB", "RTB", "Candidatura", "Diario Di Bordo" }
MAX_DEPTH = 3 -- lua comincia a contare da 1...e non aggiungo altro

--#region Funzioni di servizio
local function split(str, sep)
	local t = {}
	for s in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(t, s)
	end
	return t
end

local function file_eds_with(file, patterns)
	for _, value in ipairs(patterns) do
		if string.match(file, "^.+%." .. value:lower() .. "$") then
			return true
		end
	end
	return false
end


local function scan_directory(target_dir, extensions)
	local result = {}
	local function scanner(path)
		for file in lfs.dir(path) do
			if file == "." or file == ".." then
				goto continue_scan
			end
			local current_dir = path .. "/" .. file
			local attr = lfs.attributes(current_dir)
			if attr.mode == "directory" then
				scanner(current_dir)
			elseif attr.mode == "file" then
				if (extensions and file_eds_with(file, extensions)) or not extensions then
					if not result[path] then
						result[path] = {}
					end
					table.insert(result[path], file)
				end
			end
			::continue_scan::
		end
	end
	scanner(target_dir)
    for k in pairs(result) do
        table.sort(result[k], function (a, b)
            if string.match(a, "^%d%d%d%d%-%d%d%-%d%d") then -- significa che anche b è una data, dato che le abbiamo tutte nelle stesse cartelle
                return a > b
            end
            -- se non è una data allora riordino in alfabetico crescente
           return a < b
        end)
    end
	return result
end

--#endregion

local function format_filename(filename)
	--[[
    Formatta il nome file secondo le regole specificate nel codice originale.

    - se il nome inizia con YYYY-MM-DD: mantiene la data come prefisso
    - aggiunge _VE se contiene "est" (verbale esterno), _VI se contiene "int" (verbale interno), DB se contiene "diario" (diario di bordo)
    - altrimenti restituisce il nome base (senza estensione)
    ]]
	local parts = split(filename, "_")
	local first = parts[1]
	if string.match(first, "^%d%d%d%d%-%d%d%-%d%d$") then
		local date = first
		local lower_name = string.lower(filename)
		local suffix = ""
		if string.match(lower_name, "est") then
			suffix = "_VE"
		elseif string.match(lower_name, "int") then
			suffix = "_VI"
		elseif string.match(lower_name, "diario") then
			suffix = "_DB"
		elseif string.match(lower_name, "rtb") then
			suffix = "_RTB"
		elseif string.match(lower_name, "pb") then
			suffix = "_PB"
		end
		return date .. suffix
	end
	return table.concat(parts, " ")
end

local function cleanup_source_pdf()
	--Rimuove file generati temporanei nella sorgente (.pdf, .log, .aux, ...).
	-- IMPORTANTE: le estensioni vanno SENZA il punto davanti, quello gli viene messo dopo dallo script
	local extensions =
		{ "pdf", "lof", "lot", "log", "aux", "fls", "out", "fdb_latexmk", "synctex.gz", "toc", "snm", "nav" }
	local all_files = scan_directory(SRC_DIR, extensions)
	for dir, files in pairs(all_files) do
		for _, file in ipairs(files) do
			os.remove(dir .. "/" .. file)
		end
	end
end

local function compile_tex_to_pdf()
	local latexcmd = "latexmk -pdf -interaction=nonstopmode -f "
	lfs.mkdir(OUTPUT_DIR)

	local function rimuovi_ultime_n_cartelle_dal_path(path, n)
		n = n or 1
		local res = split(path, "/")
		local offset = 0
		if res[1] == "." then
			offset = 1 -- pk senno ./<folder> iniziale conta come 2
		end
		local profondita_path = #res - offset
		while profondita_path > MAX_DEPTH do
			table.remove(res, #res)
			profondita_path = #res - offset
		end
		return table.concat(res, "/")
	end

	for dir, files in pairs(scan_directory(SRC_DIR, { "tex" })) do
		if not string.match(dir, "content") then
			for _, file in ipairs(files) do
				local cmd = 'cd "' .. dir .. '" && ' .. latexcmd .. '"' .. file .. '"'
				local ok, reason, code = os.execute(cmd)
				-- esce da github-action se il comando ha avuto errori strani
				if not ok or code ~= 0 then
					print("Errore durante la compilazione di "..file.."\nPer il seguente motivo: "..reason)
					os.exit(1)
				end
				local filename_pdf = split(file, ".")[1] .. ".pdf"
				-- string.sub(dir, #SRC_DIR) rimuove "./src" da per esempio "./src/Candidatura/.."
				local destination_folder =
					rimuovi_ultime_n_cartelle_dal_path(OUTPUT_DIR .. string.sub(dir, #SRC_DIR + 1))
				local src_pdf = dir .. "/" .. filename_pdf
				local dest_pdf = destination_folder .. "/" .. filename_pdf

				-- crea la cartella di destinazione (se non esiste), con tutte le sottocartelle
				os.execute('mkdir -p "' .. destination_folder .. '"')
				os.execute('cp "' .. src_pdf .. '" "' .. dest_pdf .. '"')
			end
		end
	end

	cleanup_source_pdf()
end


local function generate_html(root_path, section_order)
    local nav_html, main_html = string.rep(" ", 12)..'<ul id="nav-navigation">\n', string.rep(" ", 8)..'<main>\n'
    local nav_indentazione_base =  16
	local main_indentazione_base = 12

    for _, sect in ipairs(section_order) do
	    if not pcall(lfs.dir, root_path.."/"..sect) then
			-- Cartella inesistente
			nav_html = nav_html..string.format('%s<!-- <li><a href="#%s">%s</a></li> -->\n',string.rep(" ",nav_indentazione_base + 4), string.lower(split(sect, " ")[1]), sect)
			goto cartella_inesistente
		end
		nav_html = nav_html..string.format('%s<li><a href="#%s">%s</a></li>\n', string.rep(" ",nav_indentazione_base + 4), string.lower(split(sect, " ")[1]), sect)

		main_html = main_html..string.format('%s<section id="%s">\n<h2>%s</h2>\n',string.rep(" ", main_indentazione_base), string.lower(split(sect, " ")[1]), sect)

        local result = scan_directory(root_path.."/"..sect)
		-- tabella ordine/priorità delle sezioni
        local ORDER_MAP = {}
        for i, name in ipairs(SECTION_ORDER) do
            ORDER_MAP[name] = i
        end
        -- Estrai chiavi per il sort
        local keys = {}
        for k in pairs(result) do
            table.insert(keys, k)
        end
        -- Ordina chiavi in base alla priorità messa in OrderMap
        table.sort(keys, function(a, b)
            local sa = split(a, "/")
            local sb = split(b, "/")
            local lastA = sa[#sa]
            local lastB = sb[#sb]
            local orderA = ORDER_MAP[lastA] or a
            local orderB = ORDER_MAP[lastB] or b
            -- se una delle due opzioni non è presente in ORDERMAP, ha la precedenza quella in cui lo è
            if orderA == a and orderB == ORDER_MAP[lastB] then
               return false
            elseif orderA == ORDER_MAP[lastA] and orderB == b then
                return true
            end
            return orderA < orderB
        end)

        for _, k in ipairs(keys) do
            local folder_struct, depth = split(k, "/"), #split(k, "/")
			if depth > 2 then
			    -- significa che sono in una sottocartella
			    main_html = main_html..string.format('%s<h%d>%s</h%d>\n',string.rep(" ", main_indentazione_base + 4), depth, folder_struct[depth], depth)
			end
            for _, file in ipairs(result[k]) do
                main_html = main_html..string.format('%s<h%d><a href="%s" target="_blank">%s</a></h%d>\n', string.rep(" ", main_indentazione_base + 4) ,depth + 1, k.."/"..file,format_filename(file),depth + 1)
            end
        end

		-- for dir, files in pairs(scan_directory(root_path.."/"..sect)) do
		--     local folder_struct, depth = split(dir, "/"), #split(dir, "/")
		-- 	if depth > 2 then
		-- 	    -- significa che sono in una sottocartella
		-- 	    main_html = main_html..string.format('<h%d>%s</h%d>\n', depth, folder_struct[depth], depth)
		-- 	end
  --           for _, file in ipairs(files) do
  --               main_html = main_html..string.format('<h%d><a href="%s" target="_blank">%s</a></h%d>\n',depth + 1, dir.."/"..file,format_filename(file),depth + 1)
  --           end
		-- end
		main_html = main_html..string.rep(" ", main_indentazione_base)..'</section>\n'
		::cartella_inesistente::
	end
	nav_html = nav_html..'<li><a href="#contatti">Contatti</a></li>\n<li><a href="./website/glossario/glossario.html">Glossario</a></li>\n</ul>'
	main_html = main_html..string.rep(" ", main_indentazione_base)..'<section id="contatti"'
    return nav_html, main_html
end

local function update_html()
	local file_r = io.open(INDEX_HTML_PATH, "r")
	if not file_r then
		print("NON HO APERTO IL FILE")
		return
	end
	local testo_file = file_r:read("a")
	-- tutta la regione di testo compresa nella ul nav-navigation
	local nav_start, nav_end, content_h = testo_file:find('<ul%s+id="nav%-navigation">(.-)</ul>')
	-- tutta la regione di testo compresa fra il main e la section contatti
	local main_start, main_end, content_m = testo_file:find('<main>(.-)<section%s+id="contatti"')

	file_r:close()
	local nav_html, main_html = generate_html(OUTPUT_DIR,SECTION_ORDER)
	local file_w = io.open(INDEX_HTML_PATH, "w")
	if not file_w then
	    print("non ho aperto il file")
	    return
	end
	-- scrive prima di una determinata stringa
	local da_scrivere = testo_file:sub(1, nav_start-1)..nav_html..testo_file:sub(nav_end + 1, main_start - 1)..main_html..testo_file:sub(main_end + 1)
	file_w:write(da_scrivere)
end

compile_tex_to_pdf()
update_html()
