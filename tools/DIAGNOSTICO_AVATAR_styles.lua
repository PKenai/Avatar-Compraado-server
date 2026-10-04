-- ===========================================================================
--  SONDA DE DIAGNOSTICO — Avatar Eclipse
--  Serve para descobrir por que a UI abre SEM NENHUM TEXTO na maquina do
--  jogador. Faz exatamente o que o styles.lua original faz (importa estilos,
--  fontes, particulas e cursores) e no final grava um relatorio.
--
--  COMO USAR:
--    1. na pasta do cliente, renomeie  modules\client_styles\styles.lua
--       para  modules\client_styles\styles.lua.bak
--    2. copie este arquivo como  modules\client_styles\styles.lua
--    3. abra o cliente normalmente e feche depois de entrar no jogo
--    4. mande de volta DOIS arquivos:
--         - %APPDATA%\AvatarEclipse\diagnostico_fontes.txt
--         - otclientv8.log (na pasta do cliente e/ou no %APPDATA% acima)
-- ===========================================================================

local rep = {}

local function add(s)
  rep[#rep + 1] = tostring(s)
  pcall(function() g_logger.info("[SONDA] " .. tostring(s)) end)
end

-- chama fn() protegido: mesmo se a API nao existir, o cliente continua
local function testar(nome, fn)
  local ok, res = pcall(fn)
  if ok then
    add(nome .. " = " .. tostring(res))
  else
    add(nome .. " = ERRO: " .. tostring(res))
  end
  return res
end

local function hexPrimeiros(bytes, n)
  local out = {}
  for i = 1, math.min(n, #bytes) do
    out[#out + 1] = string.format("%02x", string.byte(bytes, i))
  end
  return table.concat(out, " ")
end

function init()
  -- ---- comportamento original do styles.lua -------------------------------
  local files = g_resources.listDirectoryFiles('/styles')
  for _, file in pairs(files) do
    if g_resources.isFileType(file, 'otui') then
      pcall(function() g_ui.importStyle('/styles/' .. file) end)
    end
  end

  -- ======================= SONDA: ambiente =================================
  add("================ SONDA Avatar Eclipse ================")
  add("data/hora: " .. os.date("%Y-%m-%d %H:%M:%S"))
  testar("g_app.getVersion", function() return g_app.getVersion() end)
  testar("g_app.getBuildDate", function() return g_app.getBuildDate() end)
  testar("g_graphics.getVendor", function() return g_graphics.getVendor() end)
  testar("g_graphics.getRenderer", function() return g_graphics.getRenderer() end)
  testar("g_graphics.getVersion", function() return g_graphics.getVersion() end)
  testar("g_resources.getWriteDir", function() return g_resources.getWriteDir() end)
  testar("resolvePath('/fonts')", function() return g_resources.resolvePath('/fonts') end)
  -- o cliente procura nesta ordem: /fonts, /layouts/<layout>/fonts, /mods/fonts,
  -- /data/fonts, /modules/fonts. Uma pasta extra vazia em qualquer um dos primeiros
  -- lugares faz a listagem vir vazia e NENHUMA fonte ser importada (UI fica normal,
  -- sem nenhuma letra e sem erro no log).
  testar("directoryExists('/fonts')", function() return g_resources.directoryExists('/fonts') end)
  testar("directoryExists('/mods/fonts')", function() return g_resources.directoryExists('/mods/fonts') end)
  testar("directoryExists('/data/fonts')", function() return g_resources.directoryExists('/data/fonts') end)
  testar("directoryExists('/modules/fonts')", function() return g_resources.directoryExists('/modules/fonts') end)
  testar("atlas ANTES de carregar fonte", function() return g_atlas.getStats() end)

  -- ======================= SONDA: arquivos de fonte ========================
  local fontes = g_resources.listDirectoryFiles('/fonts')
  add("arquivos listados em /fonts: " .. tostring(#fontes))
  local otfonts, pngs, nomes = 0, 0, {}
  for _, file in pairs(fontes) do
    if g_resources.isFileType(file, 'otfont') then
      otfonts = otfonts + 1
      local ok, conteudo = pcall(function() return g_resources.readFileContents('/fonts/' .. file) end)
      if ok then
        local nome = string.match(conteudo, "name:%s*([^\r\n]+)")
        add(string.format("  %-34s %5d bytes | magic=%s | name=%s",
            file, #conteudo, hexPrimeiros(conteudo, 4), tostring(nome)))
        if nome then nomes[#nomes + 1] = nome end
      else
        add(string.format("  %-34s NAO CONSEGUI LER: %s", file, tostring(conteudo)))
      end
    elseif g_resources.isFileType(file, 'png') then
      pngs = pngs + 1
    end
  end
  add("total .otfont=" .. otfonts .. "  .png=" .. pngs)
  add("existe /data/fonts/verdana-new.png = " ..
      tostring(g_resources.fileExists('/data/fonts/verdana-new.png')))
  local okpng, png = pcall(function() return g_resources.readFileContents('/data/fonts/verdana-new.png') end)
  if okpng then
    add("magic do verdana-new.png = " .. hexPrimeiros(png, 8) .. " (" .. #png .. " bytes)")
  else
    add("verdana-new.png NAO LIDO: " .. tostring(png))
  end

  -- ======================= importa as fontes (como antes) ==================
  for _, file in pairs(fontes) do
    if g_resources.isFileType(file, 'otfont') then
      g_fonts.importFont('/fonts/' .. file)
    end
  end
  for _, nome in pairs(nomes) do
    testar("fonte carregada? '" .. nome .. "'", function() return g_fonts.fontExists(nome) end)
  end
  testar("atlas DEPOIS de carregar fonte", function() return g_atlas.getStats() end)

  -- ---- resto do styles.lua original --------------------------------------
  local parts = g_resources.listDirectoryFiles('/particles')
  for _, file in pairs(parts) do
    if g_resources.isFileType(file, 'otps') then
      pcall(function() g_particles.importParticle('/particles/' .. file) end)
    end
  end
  pcall(function() g_mouse.loadCursors('/cursors/cursors') end)

  add("================ FIM DA SONDA ================")

  -- grava o relatorio na pasta de escrita do cliente (%APPDATA%\AvatarEclipse)
  local texto = table.concat(rep, "\n") .. "\n"
  local ok, err = pcall(function() g_resources.writeFileContents("diagnostico_fontes.txt", texto) end)
  if not ok then
    pcall(function() g_logger.error("[SONDA] nao consegui gravar diagnostico_fontes.txt: " .. tostring(err)) end)
  end
end

function terminate()
end
