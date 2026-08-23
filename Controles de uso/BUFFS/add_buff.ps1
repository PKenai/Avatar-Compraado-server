# ============================================
# Buff Manager - Avatar Server
# ============================================

param(
    [switch]$ListOnly,
    [switch]$IconsOnly,
    [string]$ServerRoot = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
    $SERVER_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $SERVER_ROOT = $ServerRoot.TrimEnd('\') + '\'
}
$BUFF_H      = Join-Path $SERVER_ROOT "sources\buff.h"
$BUFF_LUA    = Join-Path $SERVER_ROOT "data\lib\300-buffs.lua"
$CLIENT_ROOT = "C:\Users\imfis\Desktop\Avatar-comprado-client"
$ICON_DIR    = Join-Path $CLIENT_ROOT "data\images\buffs"

# ============================================
# Listar imagens disponiveis
# ============================================
function Show-Icons {
    Write-Host ""
    Write-Host "  === IMAGENS DISPONIVEIS ===" -ForegroundColor Yellow
    Write-Host ""

    if (-not (Test-Path $ICON_DIR)) {
        Write-Host "  [ERRO] Pasta nao encontrada: $ICON_DIR" -ForegroundColor Red
        return
    }

    $allFiles = Get-ChildItem $ICON_DIR -Filter "*.png" | Sort-Object Name

    $icons = @()
    $borders = @()
    $others = @()

    foreach ($f in $allFiles) {
        $name = $f.BaseName
        if ($name -match "^frame-") {
            $borders += $name
        }
        elseif ($name -eq "background" -or $name -eq "rect") {
            $others += $name
        }
        else {
            $icons += $name
        }
    }

    Write-Host "  -- Icones de Buff/Debuff --" -ForegroundColor Cyan
    Write-Host ""
    $i = 1
    foreach ($icon in $icons) {
        $num = $i.ToString().PadLeft(3, ' ')
        Write-Host "    $num  $icon" -ForegroundColor White
        $i++
    }

    Write-Host ""
    Write-Host "  -- Bordas (frames) --" -ForegroundColor Cyan
    Write-Host ""
    foreach ($b in $borders) {
        $num = $i.ToString().PadLeft(3, ' ')
        Write-Host "    $num  $b" -ForegroundColor White
        $i++
    }

    if ($others.Count -gt 0) {
        Write-Host ""
        Write-Host "  -- Outros --" -ForegroundColor DarkGray
        foreach ($o in $others) {
            Write-Host "      $o" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Total: $($icons.Count) icones, $($borders.Count) bordas" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================
# Listar buffs registrados
# ============================================
function Show-RegisteredBuffs {
    Write-Host ""
    Write-Host "  === BUFFS REGISTRADOS ===" -ForegroundColor Yellow
    Write-Host ""

    $luaContent = Get-Content $BUFF_LUA -Raw
    $luaMatches = [regex]::Matches($luaContent, 'registerBuffType\((\d+),\s*"([^"]+)",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*(true|false),\s*(\d+),\s*(-?\d+),\s*(true|false)')

    foreach ($m in $luaMatches) {
        $id     = $m.Groups[1].Value
        $name   = $m.Groups[2].Value
        $icon   = $m.Groups[4].Value
        $border = $m.Groups[5].Value
        $debuff = $m.Groups[9].Value
        $ticks  = [int]$m.Groups[8].Value

        $tipo = if ($debuff -eq "true") { "DEBUFF" } else { "BUFF  " }
        $tipoColor = if ($debuff -eq "true") { "Red" } else { "Green" }

        if ($ticks -eq -1) {
            $dur = "Permanente"
        } else {
            $s = [math]::Floor($ticks / 1000)
            $h = [math]::Floor($s / 3600)
            $m2 = [math]::Floor(($s % 3600) / 60)
            $sec = $s % 60
            $parts = @()
            if ($h -gt 0) { $parts += "${h}h" }
            if ($m2 -gt 0) { $parts += "${m2}m" }
            if ($sec -gt 0 -or $parts.Count -eq 0) { $parts += "${sec}s" }
            $dur = $parts -join ""
        }

        Write-Host "  [" -NoNewline -ForegroundColor DarkGray
        Write-Host $id.PadLeft(2, ' ') -NoNewline -ForegroundColor White
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host $name -NoNewline -ForegroundColor White
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $tipo -NoNewline -ForegroundColor $tipoColor
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $icon -NoNewline -ForegroundColor Cyan
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $border -NoNewline -ForegroundColor DarkYellow
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $dur -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  Total: $($luaMatches.Count) buffs" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================
# Converter nome para enum C++
# ============================================
function ConvertTo-EnumName {
    param([string]$Name)
    $clean = $Name.ToUpper() -replace '[^A-Z0-9]', '_'
    $clean = $clean -replace '_+', '_'
    $clean = $clean.Trim('_')
    return "BUFF_$clean"
}

# ============================================
# Converter duracao para ticks (ms)
# ============================================
function ConvertTo-Ticks {
    param([string]$InputStr)

    $hours = 0; $mins = 0; $secs = 0

    if ($InputStr -match '(\d+)\s*h') { $hours = [int]$Matches[1] }
    if ($InputStr -match '(\d+)\s*m') { $mins = [int]$Matches[1] }
    if ($InputStr -match '(\d+)\s*s') { $secs = [int]$Matches[1] }

    if ($hours -gt 0 -or $mins -gt 0 -or $secs -gt 0) {
        return ($hours * 3600 + $mins * 60 + $secs) * 1000
    }
    elseif ($InputStr -match '^\s*(\d+)\s*$') {
        return [int]$Matches[1] * 1000
    }
    else {
        return 60000
    }
}

# ============================================
# Formatar ticks para leitura
# ============================================
function Format-Ticks {
    param([int]$Ticks)

    if ($Ticks -eq -1) { return "Permanente" }

    $s = [math]::Floor($Ticks / 1000)
    $h = [math]::Floor($s / 3600)
    $m = [math]::Floor(($s % 3600) / 60)
    $sec = $s % 60

    $parts = @()
    if ($h -gt 0) { $parts += "${h}h" }
    if ($m -gt 0) { $parts += "${m}m" }
    if ($sec -gt 0 -or $parts.Count -eq 0) { $parts += "${sec}s" }

    return ($parts -join "") + " ($($Ticks)ms)"
}

# ============================================
# Input com valor padrao
# ============================================
function Get-Input {
    param(
        [string]$Prompt,
        [string]$Default = "",
        [string[]]$Options = @()
    )

    if ($Options.Count -gt 0) {
        Write-Host "  $Prompt" -ForegroundColor Cyan
        $i = 1
        foreach ($opt in $Options) {
            $marker = if ($opt -eq $Default) { " *" } else { "  " }
            Write-Host "    [$i]$marker $opt" -ForegroundColor DarkGray
            $i++
        }
        Write-Host "  Opcao" -NoNewline -ForegroundColor Cyan
        if ($Default) {
            Write-Host " [$Default]" -NoNewline -ForegroundColor DarkGray
        }
        Write-Host ": " -NoNewline
    }
    else {
        if ($Default) {
            Write-Host "  $Prompt" -NoNewline -ForegroundColor Cyan
            Write-Host " [$Default]" -NoNewline -ForegroundColor DarkGray
            Write-Host ": " -NoNewline
        }
        else {
            Write-Host "  $Prompt`: " -NoNewline -ForegroundColor Cyan
        }
    }

    $input = Read-Host

    if ($Options.Count -gt 0 -and $input -match '^\d+$') {
        $idx = [int]$input - 1
        if ($idx -ge 0 -and $idx -lt $Options.Count) {
            return $Options[$idx]
        }
    }

    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    return $input
}

# ============================================
# OBTER PROXIMO ID
# ============================================
function Get-NextBuffId {
    $content = Get-Content $BUFF_H -Raw
    $matches = [regex]::Matches($content, 'BUFF_(\w+)\s*=\s*(\d+)')
    $maxId = 0
    foreach ($m in $matches) {
        $id = [int]$m.Groups[2].Value
        if ($id -gt $maxId) { $maxId = $id }
    }
    return $maxId + 1
}

# ============================================
# ADICIONAR NOVO BUFF
# ============================================
function Add-NewBuff {
    Write-Host ""
    Write-Host "  === ADICIONAR NOVO BUFF ===" -ForegroundColor Yellow
    Write-Host ""

    # Listar icones
    if (Test-Path $ICON_DIR) {
        $icons = Get-ChildItem $ICON_DIR -Filter "*.png" |
            Where-Object { $_.Name -notmatch "^(frame|background|rect)" } |
            ForEach-Object { $_.BaseName } | Sort-Object

        if ($icons.Count -gt 0) {
            Write-Host "  Icones disponiveis:" -ForegroundColor DarkGray
            $i = 1
            foreach ($icon in $icons) {
                $num = $i.ToString().PadLeft(3, ' ')
                Write-Host "    $num $icon" -ForegroundColor DarkGray
                $i++
            }
            Write-Host ""
        }
    }

    # Listar bordas
    if (Test-Path $ICON_DIR) {
        $borders = Get-ChildItem $ICON_DIR -Filter "frame-*.png" |
            ForEach-Object { $_.BaseName } | Sort-Object
        if ($borders.Count -gt 0) {
            Write-Host "  Bordas disponiveis:" -ForegroundColor DarkGray
            Write-Host "    $($borders -join ', ')" -ForegroundColor DarkGray
            Write-Host ""
        }
    }

    # === DADOS ===
    Write-Host "  -- Dados do Buff --" -ForegroundColor Cyan
    Write-Host ""

    $buffName = Get-Input "Nome do buff"
    if ([string]::IsNullOrWhiteSpace($buffName)) {
        Write-Host "  [ERRO] Nome e obrigatorio!" -ForegroundColor Red
        return
    }

    $buffDesc = Get-Input "Descricao" "A powerful buff"

    $buffIcon = Get-Input "Icone (nome sem .png)" "utani_hur"

    $buffBorder = Get-Input "Borda" "frame-2-gold"

    Write-Host ""
    Write-Host "  -- Tipo --" -ForegroundColor Cyan
    $debuffChoice = Get-Input "Tipo" "Buff" @("Buff", "Debuff")
    $isDebuff = $debuffChoice -eq "Debuff"

    Write-Host ""
    Write-Host "  -- Duracao --" -ForegroundColor Cyan
    Write-Host "  Formatos: 30s, 5m, 1h30m, -1 (permanente)" -ForegroundColor DarkGray
    $durationStr = Get-Input "Duracao" "60s"

    if ($durationStr -eq "-1") {
        $ticks = -1
    }
    else {
        $ticks = ConvertTo-Ticks $durationStr
    }

    Write-Host ""
    Write-Host "  -- Stacks --" -ForegroundColor Cyan
    $stackChoice = Get-Input "Empilhavel?" "Nao" @("Nao", "Sim")
    $isStacked = $stackChoice -eq "Sim"

    $maxStacks = 1
    if ($isStacked) {
        $maxStacks = [int](Get-Input "Max stacks" "5")
    }

    # === GERAR ===
    $nextId = Get-NextBuffId
    $enumName = ConvertTo-EnumName $buffName
    $durationFormatted = Format-Ticks $ticks

    # === CONFIRMACAO ===
    Write-Host ""
    Write-Host "  === CONFIRMACAO ===" -ForegroundColor Yellow
    Write-Host "  ID:         $nextId ($enumName)" -ForegroundColor White
    Write-Host "  Nome:       $buffName" -ForegroundColor White
    Write-Host "  Descricao:  $buffDesc" -ForegroundColor White
    Write-Host "  Icone:      $buffIcon" -ForegroundColor White
    Write-Host "  Borda:      $buffBorder" -ForegroundColor White
    if ($isDebuff) {
        Write-Host "  Tipo:       DEBUFF" -ForegroundColor Red
    } else {
        Write-Host "  Tipo:       BUFF" -ForegroundColor Green
    }
    Write-Host "  Duracao:    $durationFormatted" -ForegroundColor White
    if ($isStacked) {
        Write-Host "  Stacks:     Sim (max $maxStacks)" -ForegroundColor White
    } else {
        Write-Host "  Stacks:     Nao" -ForegroundColor White
    }
    Write-Host ""

    $confirm = Get-Input "Confirmar?" "S" @("Sim", "Nao")
    if ($confirm -eq "Nao") {
        Write-Host ""
        Write-Host "  Cancelado." -ForegroundColor Red
        return
    }

    # === ATUALIZAR buff.h ===
    Write-Host ""
    Write-Host "  [1/2] Atualizando sources\buff.h..." -ForegroundColor Cyan

    $buffHContent = Get-Content $BUFF_H -Raw
    $newEnumLine = "`t$enumName = $nextId,`n"
    $buffHContent = $buffHContent -replace "(\tBUFF_LAST)", "$newEnumLine`t`$1"
    [System.IO.File]::WriteAllText($BUFF_H, $buffHContent, [System.Text.Encoding]::UTF8)

    Write-Host "  [OK] Enum: $enumName = $nextId" -ForegroundColor Green

    # === ATUALIZAR 300-buffs.lua ===
    Write-Host "  [2/2] Atualizando data\lib\300-buffs.lua..." -ForegroundColor Cyan

    $escapedName  = $buffName  -replace '"', '\"'
    $escapedDesc  = $buffDesc  -replace '"', '\"'
    $escapedIcon  = $buffIcon  -replace '"', '\"'
    $escapedBorder = $buffBorder -replace '"', '\"'

    $stackBool = if ($isStacked) { "true" } else { "false" }
    $debuffBool = if ($isDebuff) { "true" } else { "false" }

    $luaEntry = "`n`n-- $buffName (id = $nextId)`n"
    $luaEntry += "registerBuffType($nextId, `"$escapedName`", `"$escapedDesc`", `"$escapedIcon`", `"$escapedBorder`", $stackBool, $maxStacks, $ticks, $debuffBool)"

    $luaContent = Get-Content $BUFF_LUA -Raw
    $luaContent = $luaContent.TrimEnd() + $luaEntry
    [System.IO.File]::WriteAllText($BUFF_LUA, $luaContent, [System.Text.Encoding]::UTF8)

    Write-Host "  [OK] registerBuffType($nextId, ...)" -ForegroundColor Green

    # === RESULTADO ===
    Write-Host ""
    Write-Host "  === BUFF ADICIONADO COM SUCESSO! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Proximos passos:" -ForegroundColor Yellow
    Write-Host "    1. Compile o servidor" -ForegroundColor White
    Write-Host "    2. Para aplicar no jogo:" -ForegroundColor White
    Write-Host ""
    Write-Host "       doCreatureAddBuff(cid, $nextId)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    3. Via spell/script:" -ForegroundColor White
    Write-Host '       doCreatureAddBuff(getCreatureByName("PlayerName"), ' + $nextId + ')' -ForegroundColor Cyan
    Write-Host ""
}

# ============================================
# MAIN
# ============================================
if ($ListOnly) {
    Show-RegisteredBuffs
}
elseif ($IconsOnly) {
    Show-Icons
}
else {
    Add-NewBuff
}
