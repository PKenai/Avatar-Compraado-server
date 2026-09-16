# ============================================================================
#  boss_util.ps1 - Editor do sistema ALPHA (bosses) - Avatar Server
# ----------------------------------------------------------------------------
#  Modos (chamados pelo bosses.bat):
#    list       lista os bosses ALPHA, a luva que dropam e a meta da task
#    show       ficha do boss (stats, flags, ataques, loot)
#    status     altera vida, xp, speed, armor, defense, strategy, targetdistance
#    loot       ve'/troca a chance da luva (mostra a % REAL, nao a do xml)
#    tuning     altera os multiplicadores do gerador e regera os bosses
#    kills      ve'/altera a meta de kills (task diaria) por criatura
#    pool       inclui/exclui criaturas do sorteio da task diaria
#    tiles      troca o itemID/actionID do tile de portal
#    regen      roda tools/generate_bosses.py (regera todos os bosses)
#    diag       diagnostico completo do sistema
#
#  Todo arquivo alterado ganha um .bak antes da escrita.
#  O gerador (tools/generate_bosses.py) e' a fonte de verdade dos bosses:
#  editar um xml de boss na mao funciona, mas o proximo "regen" sobrescreve.
# ============================================================================

param(
    [string]$Mode = "list",
    [string]$ServerRoot = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
    $SERVER_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $SERVER_ROOT = $ServerRoot.TrimEnd('\') + '\'
}

$CONFIG    = Join-Path $SERVER_ROOT "data\lib\bossConfig.lua"
$SYSTEM    = Join-Path $SERVER_ROOT "data\lib\bossSystem.lua"
$GEN       = Join-Path $SERVER_ROOT "tools\generate_bosses.py"
$BOSS_DIR  = Join-Path $SERVER_ROOT "data\monster\bosses"
$REGISTRY  = Join-Path $SERVER_ROOT "data\monster\monsters.xml"
$MOVES     = Join-Path $SERVER_ROOT "data\movements\movements.xml"
$ITEMS     = Join-Path $SERVER_ROOT "data\items\items.xml"
$SERVERCFG = Join-Path $SERVER_ROOT "config.lua"

$script:UTF8 = New-Object System.Text.UTF8Encoding($false)
$script:PctCache = @{}

# ============================================================================
#  utilidades de arquivo
# ============================================================================
function Read-Text([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Write-Text([string]$path, [string]$text) {
    [System.IO.File]::WriteAllText($path, $text, $script:UTF8)
}

function Get-Nl([string]$text) {
    if ($text -match "`r`n") { return "`r`n" }
    return "`n"
}

function Save-Backup([string]$path) {
    Copy-Item -LiteralPath $path -Destination "$path.bak" -Force
}

function Confirm-Write([string]$path) {
    Save-Backup $path
    Say "Backup: $path.bak" "DarkGray"
}

function Test-Xml([string]$path) {
    try { [void][xml](Get-Content -LiteralPath $path -Raw -Encoding UTF8); return $true }
    catch { return $false }
}

function Find-Python {
    foreach ($exe in @("python", "py", "python3")) {
        $cmd = Get-Command $exe -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

# ============================================================================
#  utilidades de tela
# ============================================================================
function Write-Head([string]$title) {
    Write-Host ""
    Write-Host "  ==================================================" -ForegroundColor Yellow
    Write-Host "   $title" -ForegroundColor Yellow
    Write-Host "  ==================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Say([string]$msg, [string]$color = "White") {
    Write-Host "  $msg" -ForegroundColor $color
}

function Ask-Text([string]$prompt, [string]$default = "") {
    if ($default -ne "") {
        Write-Host "  $prompt [$default]: " -NoNewline -ForegroundColor Cyan
    } else {
        Write-Host "  $prompt`: " -NoNewline -ForegroundColor Cyan
    }
    $v = Read-Host
    if ([string]::IsNullOrWhiteSpace($v)) { return $default }
    return $v.Trim()
}

function Ask-Int([string]$prompt, [int]$default, [bool]$allowNegative = $true) {
    while ($true) {
        Write-Host "  $prompt [$default]: " -NoNewline -ForegroundColor Cyan
        $v = Read-Host
        if ([string]::IsNullOrWhiteSpace($v)) { return $default }
        $n = 0
        if ([int]::TryParse($v.Trim(), [ref]$n)) {
            if ((-not $allowNegative) -and $n -lt 0) {
                Say "Valor nao pode ser negativo." "Red"
                continue
            }
            return $n
        }
        Say "Digite apenas numeros." "Red"
    }
}

function Ask-Double([string]$prompt, [double]$default) {
    while ($true) {
        Write-Host ("  {0} [{1}]: " -f $prompt, $default) -NoNewline -ForegroundColor Cyan
        $v = Read-Host
        if ([string]::IsNullOrWhiteSpace($v)) { return $default }
        $v = $v.Trim().Replace(',', '.')
        $d = 0.0
        $parsed = [double]::TryParse($v, [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d)
        if ($parsed) { return $d }
        Say "Digite apenas numeros (ex: 1.5)." "Red"
    }
}

function Ask-Yes([string]$prompt, [string]$default = "S") {
    Write-Host "  $prompt [$default]: " -NoNewline -ForegroundColor Cyan
    $v = Read-Host
    if ([string]::IsNullOrWhiteSpace($v)) { $v = $default }
    return ($v.Trim().ToUpper().StartsWith("S") -or $v.Trim().ToUpper().StartsWith("Y"))
}

function To-Int([string]$s, [int]$fallback = 0) {
    if ([string]::IsNullOrWhiteSpace($s)) { return $fallback }
    $n = 0
    if ([int]::TryParse($s.Trim(), [ref]$n)) { return $n }
    return $fallback
}

function Ask-Menu([string]$prompt) {
    Write-Host "  $prompt`: " -NoNewline -ForegroundColor Cyan
    $v = Read-Host
    if ($null -eq $v) { return "" }
    return $v.Trim().ToUpper()
}

# ============================================================================
#  XML: ler / trocar atributos sem reformatar o arquivo
# ============================================================================
function Get-Tag([string]$text, [string]$pattern) {
    $m = [regex]::Match($text, $pattern)
    if ($m.Success) { return $m.Value }
    return ""
}

function Get-Attr([string]$tag, [string]$attr) {
    if ([string]::IsNullOrEmpty($tag)) { return "" }
    $m = [regex]::Match($tag, '\b' + [regex]::Escape($attr) + '="([^"]*)"')
    if ($m.Success) { return $m.Groups[1].Value }
    return ""
}

# Troca o valor de UM atributo dentro da primeira tag que casa com o padrao.
# Se o atributo nao existir, ele e' criado (antes do "/>" ou do ">").
function Set-TagAttr([string]$text, [string]$tagPattern, [string]$attr, [string]$value) {
    $m = [regex]::Match($text, $tagPattern)
    if (-not $m.Success) { return $text }

    $tag = $m.Value
    $rx = '\b' + [regex]::Escape($attr) + '="[^"]*"'
    $repl = ($attr + '="' + $value + '"').Replace('$', '$$')
    if ([regex]::IsMatch($tag, $rx)) {
        $tag = (New-Object System.Text.RegularExpressions.Regex($rx)).Replace($tag, $repl, 1)
    } elseif ($tag.TrimEnd().EndsWith("/>")) {
        $tag = $tag.Substring(0, $tag.Length - 2) + " $attr=`"$value`"/>"
    } else {
        $tag = $tag.Substring(0, $tag.Length - 1) + " $attr=`"$value`">"
    }
    return $text.Remove($m.Index, $m.Length).Insert($m.Index, $tag)
}

# vida: now e max sempre juntos
function Set-Health([string]$text, [int]$value) {
    $text = Set-TagAttr $text '<health\b[^>]*/>' 'now' ([string]$value)
    return Set-TagAttr $text '<health\b[^>]*/>' 'max' ([string]$value)
}

function Set-Flag([string]$text, [string]$flag, [string]$value) {
    if ([regex]::IsMatch($text, '<flag\s+' + [regex]::Escape($flag) + '="[^"]*"\s*/>')) {
        return Set-TagAttr $text ('<flag\s+' + [regex]::Escape($flag) + '="[^"]*"\s*/>') $flag $value
    }
    $nl = Get-Nl $text
    $line = "`t`t<flag $flag=`"$value`"/>"
    $m = [regex]::Match($text, '<flags>')
    if (-not $m.Success) { return $text }
    $insertAt = $m.Index + $m.Length
    return $text.Substring(0, $insertAt) + $nl + $line + $text.Substring($insertAt)
}

# ============================================================================
#  chance de loot REAL (o chance= do xml nao e' a porcentagem final)
# ----------------------------------------------------------------------------
#  sources/monsters.cpp -> MonsterType::createLoot():
#     if (lootChance > 1 && lootChance < 10000 && !lootPercent)
#             lootChance = ceil(lootChance * 0.5)                 <- METADE
#     random = (uint16_t)ceil(random_range(0,100000) / rateLoot)  <- estoura 16 bits
#     if (random < lootChance) droppa
# ============================================================================
function Get-RateLoot {
    $text = Read-Text $SERVERCFG
    if (-not $text) { return 1.0 }
    $m = [regex]::Match($text, '(?m)^\s*rateLoot\s*=\s*([0-9.]+)')
    if (-not $m.Success) { return 1.0 }
    $d = 0.0
    if ([double]::TryParse($m.Groups[1].Value, [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d) -and $d -gt 0) {
        return $d
    }
    return 1.0
}

function Get-LootChance([int]$chance) {
    if ($chance -gt 1 -and $chance -lt 10000) { return [int][math]::Ceiling($chance * 0.5) }
    return $chance
}

# Tabela prefixada: table[L] = quantos dos 100001 sorteios caem abaixo de L.
# Montada uma unica vez por rateLoot e reaproveitada em todas as telas.
function Get-LootTable {
    if ($script:LootTable) { return $script:LootTable }
    $rate = Get-RateLoot
    $hist = New-Object 'int[]' 65536
    for ($r = 0; $r -le 100000; $r++) {
        $v = ([int][math]::Ceiling($r / $rate)) -band 0xFFFF
        $hist[$v]++
    }
    $prefix = New-Object 'int[]' 65537
    $run = 0
    for ($l = 0; $l -lt 65536; $l++) {
        $prefix[$l] = $run
        $run += $hist[$l]
    }
    $prefix[65536] = $run
    $script:LootTable = $prefix
    $script:LootRate = $rate
    return $prefix
}

function Get-LootPercent([int]$chance) {
    $key = [string]$chance
    if ($script:PctCache.ContainsKey($key)) { return $script:PctCache[$key] }
    $lootChance = Get-LootChance $chance
    if ($lootChance -ge 65536) { $pct = 100.0 }
    else { $pct = 100.0 * (Get-LootTable)[$lootChance] / 100001.0 }
    $script:PctCache[$key] = $pct
    return $pct
}

# Menor chance= do xml que atinge (ou passa) a % pedida.
# chance 2..9999 sofre o corte -> vale ceil(chance/2); a faixa efetiva 5001..9999
# e' inalcancavel, o proximo degrau depois de 5000 e' 10000 (que nao e' cortado).
function Get-ChanceForPercent([double]$pct) {
    if ($pct -le 0) { return 0 }
    if ($pct -ge 100) { return 65535 }
    $table = Get-LootTable
    $target = $pct * 100001.0 / 100.0
    $lo = 1
    $hi = 65536
    while ($lo -lt $hi) {
        $mid = [int](($lo + $hi) / 2)
        if ($table[$mid] -ge $target) { $hi = $mid } else { $lo = $mid + 1 }
    }
    $l = $lo
    if ($l -le 1) { return 1 }
    if ($l -le 5000) { return (2 * $l - 1) }
    if ($l -lt 10000) { return 10000 }
    return $l
}

# chance= da luva gravada no xml do boss (0 se nao houver)
function Get-BossGloveChance([object]$b) {
    if ($b.Glove -eq "nil") { return 0 }
    $text = Read-Text $b.XmlPath
    if (-not $text) { return 0 }
    $m = [regex]::Match($text, '<item\s+id="' + [regex]::Escape($b.Glove) + '"[^>]*chance="([0-9]+)"')
    if ($m.Success) { return [int]$m.Groups[1].Value }
    return 0
}

# Mostra qual chance= usar e avisa quando o corte do servidor obriga a
# passar bem acima do pedido (nao existe chance=6250 dando 10%).
function Say-ChancePlan([string]$label, [double]$wanted) {
    $chance = Get-ChanceForPercent $wanted
    if ($chance -le 0) { return 0 }
    $real = Get-LootPercent $chance
    Write-Host ""
    Say ("{0} = {1}   ->   real {2:N2}%   (pedido {3:N2}%)" -f $label, $chance, $real, $wanted) "Cyan"
    if ($real -gt ($wanted * 1.5 + 0.01)) {
        Warn ("o corte de 16 bits nao permite ~{0:N2}%: o degrau mais proximo acima e' {1:N2}%" -f $wanted, $real)
        Say "Se a ideia era dificultar, reduza o countmax ou use um item intermediario no lugar." "DarkGray"
    }
    return $chance
}

# ============================================================================
#  leitura da configuracao gerada
# ============================================================================
function Get-Bosses {
    $text = Read-Text $CONFIG
    $out = New-Object System.Collections.ArrayList
    if (-not $text) { return $out }

    $excluded = @{}
    $ex = [regex]::Match($text, '(?s)BossConfig\.dailyExcluded\s*=\s*\{(.*?)\n\}')
    if ($ex.Success) {
        foreach ($m in [regex]::Matches($ex.Groups[1].Value, '\["([^"]+)"\]')) {
            $excluded[$m.Groups[1].Value] = $true
        }
    }

    $block = [regex]::Match($text, '(?s)BossConfig\.monsters\s*=\s*\{(.*?)\n\}')
    if (-not $block.Success) { return $out }

    $rx = '\["([^"]+)"\]\s*=\s*\{\s*boss\s*=\s*"([^"]+)",\s*material\s*=\s*(nil|\d+),\s*glove\s*=\s*(nil|\d+),\s*kills\s*=\s*(\d+),\s*experience\s*=\s*(\d+)\s*\}'
    foreach ($m in [regex]::Matches($block.Groups[1].Value, $rx)) {
        $base = $m.Groups[1].Value
        [void]$out.Add([pscustomobject]@{
            Base     = $base
            Boss     = $m.Groups[2].Value
            Material = $m.Groups[3].Value
            Glove    = $m.Groups[4].Value
            Kills    = [int]$m.Groups[5].Value
            Exp      = [int]$m.Groups[6].Value
            Excluded = $excluded.ContainsKey($base)
            XmlPath  = (Join-Path $BOSS_DIR ($m.Groups[2].Value + ".xml"))
        })
    }
    return $out
}

function Select-Boss {
    param([string]$Prompt = "Qual boss quer editar?")
    $all = @(Get-Bosses)
    if ($all.Count -eq 0) {
        Say "Nao encontrei a tabela BossConfig.monsters em $CONFIG" "Red"
        return $null
    }

    Write-Host ""
    Say "$Prompt" "Cyan"
    Say "($($all.Count) bosses - digite parte do nome, ENTER = listar todos)" "DarkGray"
    $filter = Ask-Text "Busca"

    if ([string]::IsNullOrWhiteSpace($filter)) {
        $list = $all
    } else {
        $f = $filter.ToLower()
        $list = @($all | Where-Object { $_.Base.ToLower().Contains($f) -or $_.Boss.ToLower().Contains($f) } |
            Sort-Object Base)
    }

    if ($list.Count -eq 0) {
        Say "Nenhum boss com '$filter'." "Red"
        return $null
    }
    if ($list.Count -eq 1) {
        Say "Boss: $($list[0].Boss)" "Green"
        if (Ask-Yes "Confirmar?" "S") { return $list[0] }
        return $null
    }

    for ($i = 0; $i -lt $list.Count; $i++) {
        Write-Host ("    [{0,2}] {1}" -f ($i + 1), $list[$i].Boss) -ForegroundColor White
    }
    Write-Host ""
    $n = Ask-Int "Numero" 0 $false
    if ($n -lt 1 -or $n -gt $list.Count) { return $null }
    return $list[$n - 1]
}

function Get-GenConst([string]$name) {
    $text = Read-Text $GEN
    if (-not $text) { return "" }
    $m = [regex]::Match($text, '(?m)^' + [regex]::Escape($name) + '\s*=\s*(-?[0-9.]+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return ""
}

function Set-GenConst([string]$name, [string]$value) {
    $text = Read-Text $GEN
    if (-not $text) { Say "Nao encontrei $GEN" "Red"; return $false }
    $rx = '(?m)^(\s*' + [regex]::Escape($name) + '\s*=\s*)(-?[0-9]+(?:\.[0-9]+)?)(\b)'
    if (-not [regex]::IsMatch($text, $rx)) {
        Say "Nao achei a constante $name em $GEN" "Red"
        return $false
    }
    $new = [regex]::Replace($text, $rx, "`${1}$value`${3}", 1)
    Confirm-Write $GEN
    Write-Text $GEN $new
    return $true
}

# ============================================================================
#  list
# ============================================================================
function Show-BossList {
    $all = @(Get-Bosses)
    Write-Head "BOSSES ALPHA"
    if ($all.Count -eq 0) { Say "Nenhum boss em BossConfig.monsters." "Red"; return }

    $rate = Get-RateLoot
    Say "rateLoot do config.lua: $rate  (a % REAL de loot considera isso)" "DarkGray"
    Write-Host ""
    Write-Host ("   {0,-26} {1,6}  {2,7}  {3,9}  {4,8}  {5}" -f "CRIATURA BASE", "META", "LUVA", "LUVA %", "XP", "TASK") -ForegroundColor Yellow
    Write-Host ("   " + ("-" * 78)) -ForegroundColor DarkGray

    foreach ($b in ($all | Sort-Object Base)) {
        $gloveText = "sem luva"
        $pctText = "-"
        if ($b.Glove -ne "nil") {
            $gloveText = $b.Glove
            $pctText = ("{0:N2}%" -f (Get-LootPercent (Get-BossGloveChance $b)))
        }
        $task = "sim"
        if ($b.Excluded) { $task = "EXCLUIDA" }
        $color = "White"
        if ($b.Excluded) { $color = "DarkGray" }
        Write-Host ("   {0,-26} {1,6}  {2,7}  {3,9}  {4,8}  {5}" -f $b.Base, $b.Kills, $gloveText, $pctText, $b.Exp, $task) -ForegroundColor $color
    }
    Write-Host ""
    Say "META = kills da task diaria para liberar o boss (maximo 1000)." "DarkGray"
    Say "TASK = EXCLUIDA -> a criatura tem boss mas nao entra no sorteio diario." "DarkGray"
}

# ============================================================================
#  show
# ============================================================================
function Show-FichaBoss([object]$b) {
    $text = Read-Text $b.XmlPath
    Write-Head ("FICHA: " + $b.Boss)
    if (-not $text) {
        Say "Nao encontrei o xml: $($b.XmlPath)" "Red"
        Say "Rode o modo [R] Regen ou crie o arquivo." "DarkGray"
        return
    }

    $root = Get-Tag $text '(?s)<monster\b[^>]*>'
    $health = Get-Tag $text '<health\b[^>]*/>'
    $look = Get-Tag $text '<look\b[^>]*/>'
    $def = Get-Tag $text '<defenses\b[^>]*/>'
    $strategy = Get-Tag $text '<strategy\b[^>]*/>'
    $targetdist = Get-Tag $text '<flag\s+targetdistance="[^"]*"\s*/>'
    $runon = Get-Tag $text '<flag\s+runonhealth="[^"]*"\s*/>'
    $hostile = Get-Tag $text '<flag\s+hostile="[^"]*"\s*/>'

    Say "Criatura base : $($b.Base)"
    Say "Monstro ALPHA : $($b.Boss)"
    Say "Arquivo       : $($b.XmlPath)"
    Say "Material      : $($b.Material)   (drop da criatura base)"
    Say "Luva          : $($b.Glove)"
    Say "Meta da task  : $($b.Kills) kills"
    Say "No sorteio    : $(if ($b.Excluded) { 'NAO (excluida)' } else { 'sim' })"
    Write-Host ""
    Say "--- status ---" "Yellow"
    Say ("experience = {0}   speed = {1}" -f (Get-Attr $root 'experience'), (Get-Attr $root 'speed'))
    Say ("health     = {0} / {1}" -f (Get-Attr $health 'now'), (Get-Attr $health 'max'))
    Say ("armor      = {0}   defense = {1}" -f (Get-Attr $def 'armor'), (Get-Attr $def 'defense'))
    Say ("strategy   = attack {0} / defense {1}" -f (Get-Attr $strategy 'attack'), (Get-Attr $strategy 'defense'))
    Say ("targetdist = {0}   runonhealth = {1}   hostile = {2}" -f `
        (Get-Attr $targetdist 'targetdistance'), (Get-Attr $runon  'runonhealth'), (Get-Attr $hostile 'hostile'))
    Say ("look       = type {0} corpse {1}" -f (Get-Attr $look 'type'), (Get-Attr $look 'corpse'))

    Write-Host ""
    Say "--- ataques ---" "Yellow"
    $attacks = [regex]::Matches($text, '<attack\b[^>]*/>')
    if ($attacks.Count -eq 0) { Say "(sem ataques no xml - usa a magia assinatura)" "DarkGray" }
    foreach ($a in $attacks) {
        $min = Get-Attr $a.Value 'min'
        $max = Get-Attr $a.Value 'max'
        Write-Host ("    {0,-16} interval={1,-6} chance={2,-4} range={3,-3} min={4,-6} max={5}" -f `
                (Get-Attr $a.Value 'name'), (Get-Attr $a.Value 'interval'), (Get-Attr $a.Value 'chance'), `
                (Get-Attr $a.Value 'range'), $min, $max) -ForegroundColor White
    }

    Write-Host ""
    Say "--- loot ---" "Yellow"
    $lootBlock = [regex]::Match($text, '(?s)<loot>(.*?)</loot>')
    if (-not $lootBlock.Success) { Say "(sem loot)" "DarkGray" }
    else {
        $items = [regex]::Matches($lootBlock.Groups[1].Value, '<item\b[^>]*/>')
        $total = 0.0
        foreach ($it in $items) {
            $id = Get-Attr $it.Value 'id'
            $chance = To-Int (Get-Attr $it.Value 'chance') 0
            $pct = Get-LootPercent $chance
            $total += $pct
            $tagGlove = ""
            if ($b.Glove -ne "nil" -and $id -eq $b.Glove) { $tagGlove = "  <- LUVA" }
            Write-Host ("    id={0,6}  countmax={1,4}  chance={2,6}  ({3,6:N2}% real){4}" -f `
                    $id, (Get-Attr $it.Value 'countmax'), $chance, $pct, $tagGlove) -ForegroundColor White
        }
        Write-Host ""
        Say ("chance total de pelo menos 1 item por kill: ~{0:N1}%" -f $total) "DarkGray"
    }
}

# ============================================================================
#  status
# ============================================================================
function Edit-StatusBoss {
    $b = Select-Boss
    if (-not $b) { return }

    while ($true) {
        $text = Read-Text $b.XmlPath
        if (-not $text) { Say "Nao encontrei $($b.XmlPath)" "Red"; return }

        $root = Get-Tag $text '(?s)<monster\b[^>]*>'
        $health = Get-Tag $text '<health\b[^>]*/>'
        $def = Get-Tag $text '<defenses\b[^>]*/>'
        $strategy = Get-Tag $text '<strategy\b[^>]*/>'
        $targetdist = Get-Tag $text '<flag\s+targetdistance="[^"]*"\s*/>'
        $runon = Get-Tag $text '<flag\s+runonhealth="[^"]*"\s*/>'

        Write-Head ("STATUS: " + $b.Boss)
        Say "[1] Vida             (hoje: $((Get-Attr $health 'max')))" "Cyan"
        Say "[2] Experiencia      (hoje: $((Get-Attr $root 'experience')))" "Cyan"
        Say "[3] Speed            (hoje: $((Get-Attr $root 'speed')))" "Cyan"
        Say "[4] Armor            (hoje: $((Get-Attr $def 'armor')))" "Cyan"
        Say "[5] Defense          (hoje: $((Get-Attr $def 'defense')))" "Cyan"
        Say "[6] Strategy attack  (hoje: $((Get-Attr $strategy 'attack')))" "Cyan"
        Say "[7] Target distance  (hoje: $((Get-Attr $targetdist 'targetdistance')))" "Cyan"
        Say "[8] Run on health    (hoje: $((Get-Attr $runon 'runonhealth')))" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"
        if ($op -eq "0" -or $op -eq "") { return }

        $newText = $null
        switch ($op) {
            "1" {
                $max = Ask-Int "Vida (max)" (To-Int (Get-Attr $health 'max') 1) $false
                $newText = Set-Health $text $max
            }
            "2" {
                $v = Ask-Int "Experiencia" (To-Int (Get-Attr $root 'experience') 0) $false
                $newText = Set-TagAttr $text '(?s)<monster\b[^>]*>' 'experience' ([string]$v)
            }
            "3" {
                $v = Ask-Int "Speed" (To-Int (Get-Attr $root 'speed') 0) $false
                $newText = Set-TagAttr $text '(?s)<monster\b[^>]*>' 'speed' ([string]$v)
            }
            "4" {
                $v = Ask-Int "Armor" (To-Int (Get-Attr $def 'armor') 0) $false
                $newText = Set-TagAttr $text '<defenses\b[^>]*/>' 'armor' ([string]$v)
            }
            "5" {
                $v = Ask-Int "Defense" (To-Int (Get-Attr $def 'defense') 0) $false
                $newText = Set-TagAttr $text '<defenses\b[^>]*/>' 'defense' ([string]$v)
            }
            "6" {
                $v = Ask-Int "Strategy attack" (To-Int (Get-Attr $strategy 'attack') 0) $false
                $newText = Set-TagAttr $text '<strategy\b[^>]*/>' 'attack' ([string]$v)
            }
            "7" {
                $v = Ask-Int "Target distance" (To-Int (Get-Attr $targetdist 'targetdistance') 1) $false
                $newText = Set-Flag $text 'targetdistance' ([string]$v)
            }
            "8" {
                $v = Ask-Int "Run on health" (To-Int (Get-Attr $runon 'runonhealth') 0) $false
                $newText = Set-Flag $text 'runonhealth' ([string]$v)
            }
            default { Say "Opcao invalida." "Red"; continue }
        }

        if ($newText -eq $null) { continue }
        Confirm-Write $b.XmlPath
        Write-Text $b.XmlPath $newText
        Say "Salvo. Reinicie o servidor (monstros sao lidos no boot)." "Green"
    }
}

# ============================================================================
#  loot
# ============================================================================
function Edit-LootBoss {
    $b = Select-Boss
    if (-not $b) { return }

    while ($true) {
        $text = Read-Text $b.XmlPath
        if (-not $text) { Say "Nao encontrei $($b.XmlPath)" "Red"; return }

        Write-Head ("LOOT: " + $b.Boss)
        Say "rateLoot = $(Get-RateLoot)   (a coluna 'real' ja' considera o corte do servidor)" "DarkGray"
        Write-Host ""
        $items = [regex]::Matches($text, '<item\b[^>]*/>')
        if ($items.Count -eq 0) { Say "(loot vazio)" "DarkGray" }
        $i = 1
        foreach ($it in $items) {
            $chance = To-Int (Get-Attr $it.Value 'chance') 0
            $pct = Get-LootPercent $chance
            Write-Host ("    [{0,2}] id={1,6}  countmax={2,4}  chance={3,6}  real={4,6:N2}%" -f `
                    $i, (Get-Attr $it.Value 'id'), (Get-Attr $it.Value 'countmax'), $chance, $pct) -ForegroundColor White
            $i++
        }

        Write-Host ""
        Say "Gerador: GLOVE_CHANCE = $(Get-GenConst 'GLOVE_CHANCE')  ->  $(('{0:N2}%' -f (Get-LootPercent (To-Int (Get-GenConst 'GLOVE_CHANCE') 4000)))) real" "Cyan"
        if ($b.Glove -ne "nil") {
            Say "Luva deste boss: $($b.Glove) (material $($b.Material) - 1)" "Cyan"
        } else {
            Say "Esta criatura nao tem material de craft -> o boss dela nao dropa luva." "DarkGray"
        }

        Write-Host ""
        Say "[1] Trocar a chance da LUVA (so' os bosses, imediato)" "Cyan"
        Say "[2] Trocar GLOVE_CHANCE no gerador (regen depois)" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"
        if ($op -eq "0" -or $op -eq "") { return }

        if ($op -eq "1") {
            if ($b.Glove -eq "nil") { Say "Nao ha luva para ajustar." "Red"; continue }
            $old = Get-BossGloveChance $b
            Write-Host ""
            Say "A % REAL nao e' o numero do xml: o servidor corta a chance pela metade" "DarkGray"
            Say "e o sorteio estoura 16 bits (depende do rateLoot). Exemplos:" "DarkGray"
            foreach ($c in @(2000, 3000, 4000, 5000, 9999, 10000, 12500, 25000)) {
                Say ("   chance={0,6}  ->  real ~{1:N2}%" -f $c, (Get-LootPercent $c)) "DarkGray"
            }
            Write-Host ""
            $pct = Ask-Double "Porcentagem REAL desejada (%)" (Get-LootPercent $old)
            $chance = Say-ChancePlan "chance" $pct
            if ($chance -le 0) { Say "Nao consegui calcular." "Red"; continue }

            $rx = '<item\s+id="' + [regex]::Escape($b.Glove) + '"[^>]*/>'
            if (-not [regex]::IsMatch($text, $rx)) {
                Say "Nao achei o item da luva ($($b.Glove)) no loot deste boss." "Red"
                continue
            }
            $newText = Set-TagAttr $text $rx 'chance' ([string]$chance)
            Confirm-Write $b.XmlPath
            Write-Text $b.XmlPath $newText
            Say "Salvo (chance=$chance)." "Green"
            continue
        }

        if ($op -eq "2") {
            $pct = Ask-Double "Porcentagem REAL desejada (%)" 4.0
            $chance = Say-ChancePlan "GLOVE_CHANCE" $pct
            if ($chance -le 0) { Say "Nao consegui calcular." "Red"; continue }
            if (Ask-Yes "Gravar no gerador?" "S") {
                if (Set-GenConst "GLOVE_CHANCE" ([string]$chance)) {
                    Say "Gerador atualizado. Use a opcao [9] Regerar do menu para aplicar em todos os bosses." "Green"
                }
            }
            continue
        }
        Say "Opcao invalida." "Red"
    }
}

# ============================================================================
#  tuning
# ============================================================================
function Edit-Tuning {
    while ($true) {
        Write-Head "MULTIPLICADORES DO GERADOR"
        Say "Estes valores valem para TODOS os bosses. Depois use a opcao [9] Regerar." "DarkGray"
        Write-Host ""
        Say ("[1]  HP_MULT             = {0}   (vida do boss)" -f (Get-GenConst "HP_MULT")) "Cyan"
        Say ("[2]  EXP_MULT            = {0}   (experiencia)" -f (Get-GenConst "EXP_MULT")) "Cyan"
        Say ("[3]  SPEED_MULT          = {0}   (velocidade)" -f (Get-GenConst "SPEED_MULT")) "Cyan"
        Say ("[4]  MELEE_MULT          = {0}   (skill/attack do melee)" -f (Get-GenConst "MELEE_MULT")) "Cyan"
        Say ("[5]  ELEM_MULT           = {0}   (min/max das magias)" -f (Get-GenConst "ELEM_MULT")) "Cyan"
        Say ("[6]  DEF_MULT            = {0}   (armor/defense)" -f (Get-GenConst "DEF_MULT")) "Cyan"
        Say ("[7]  GOLD_MULT           = {0}   (countmax do ouro)" -f (Get-GenConst "GOLD_MULT")) "Cyan"
        Say ("[8]  GLOVE_CHANCE        = {0}   ({1:N2}% real)" -f (Get-GenConst "GLOVE_CHANCE"), (Get-LootPercent (To-Int (Get-GenConst "GLOVE_CHANCE") 4000))) "Cyan"
        $crystalChance = To-Int (Get-GenConst "CRYSTAL_CHANCE") 4000
        $crystalNote = ("{0:N2}% real" -f (Get-LootPercent $crystalChance))
        if ($crystalChance -ge 65536) { $crystalNote = "SEMPRE dropa 1 a " + (Get-GenConst "CRYSTAL_COUNTMAX") + " moedas" }
        Say ("[9]  CRYSTAL_CHANCE      = {0}   ({1})" -f (Get-GenConst "CRYSTAL_CHANCE"), $crystalNote) "Cyan"
        Say ("[10] MIN_KILLS           = {0}   (meta minima da task)" -f (Get-GenConst "MIN_KILLS")) "Cyan"
        Say ("[11] MAX_KILLS           = {0}   (meta maxima - teto 1000)" -f (Get-GenConst "MAX_KILLS")) "Cyan"
        Say ("[12] EXP_FOR_MAX_KILLS   = {0}   (exp que ja' pede o teto)" -f (Get-GenConst "EXP_FOR_MAX_KILLS")) "Cyan"
        Say "[0]  Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"
        if ($op -eq "0" -or $op -eq "") { return }

        $map = @{
            "1"  = "HP_MULT"; "2" = "EXP_MULT"; "3" = "SPEED_MULT"; "4" = "MELEE_MULT"
            "5"  = "ELEM_MULT"; "6" = "DEF_MULT"; "7" = "GOLD_MULT"
            "10" = "MIN_KILLS"; "11" = "MAX_KILLS"; "12" = "EXP_FOR_MAX_KILLS"
        }
        if ($op -eq "8" -or $op -eq "9") {
            $name = "GLOVE_CHANCE"
            $def = 4.0
            if ($op -eq "9") {
                $name = "CRYSTAL_CHANCE"
                $cc = To-Int (Get-GenConst "CRYSTAL_CHANCE") 4000
                if ($cc -ge 65536) {
                    # modo "sempre dropa": edita o countmax (1 a N moedas)
                    $cur = To-Int (Get-GenConst "CRYSTAL_COUNTMAX") 3
                    $v = Ask-Int "Quantas moedas no maximo (1 a N por kill)" $cur $false
                    if ($v -ge 1 -and (Ask-Yes "Gravar CRYSTAL_COUNTMAX = $v?" "S")) { [void](Set-GenConst "CRYSTAL_COUNTMAX" ([string]$v)) }
                    continue
                }
            }
            $current = Get-LootPercent (To-Int (Get-GenConst $name) 4000)
            $pct = Ask-Double "Porcentagem REAL desejada (%)" $current
            $chance = Say-ChancePlan $name $pct
            if ($chance -le 0) { Say "Nao consegui calcular." "Red"; continue }
            if (Ask-Yes "Gravar?" "S") { [void](Set-GenConst $name ([string]$chance)) }
            continue
        }

        if (-not $map.ContainsKey($op)) { Say "Opcao invalida." "Red"; continue }
        $const = $map[$op]
        $cur = Get-GenConst $const
        if ($op -in @("10", "11", "12")) {
            $v = Ask-Int "$const" (To-Int $cur 50) $false
        } else {
            $v = Ask-Double "$const" ([double]$cur)
        }
        if (Ask-Yes "Gravar $const = $v?" "S") { [void](Set-GenConst $const ([string]$v)) }
    }
}

# ============================================================================
#  kills (meta da task diaria por criatura)
# ============================================================================
function Edit-Kills {
    $all = @(Get-Bosses)
    while ($true) {
        Write-Head "METAS DA TASK DIARIA"
        Say "Quanto maior a criatura, mais kills. Teto do design: 1000." "DarkGray"
        Say "A curva padrao sai das constantes MIN_KILLS/MAX_KILLS/EXP_FOR_MAX_KILLS." "DarkGray"
        Write-Host ""
        $i = 1
        foreach ($b in ($all | Sort-Object Base)) {
            Write-Host ("    [{0,3}] {1,-28} {2,6} kills   (exp {3})" -f $i, $b.Base, $b.Kills, $b.Exp) -ForegroundColor White
            $i++
        }
        Write-Host ""
        Say "[N] Alterar a meta de UMA criatura" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"
        if ($op -eq "0" -or $op -eq "") { return }
        if ($op -ne "N") { Say "Opcao invalida." "Red"; continue }

        $sorted = @($all | Sort-Object Base)
        $n = Ask-Int "Numero da criatura" 0 $false
        if ($n -lt 1 -or $n -gt $sorted.Count) { continue }
        $b = $sorted[$n - 1]
        $new = Ask-Int "Meta de kills para $($b.Base)" $b.Kills $false
        if ($new -lt 1) { continue }
        if ($new -gt 1000 -and -not (Ask-Yes "O design pede teto de 1000. Usar $new mesmo assim?" "N")) { continue }

        $text = Read-Text $CONFIG
        $rx = '(\["' + [regex]::Escape($b.Base) + '"\][^\n]*kills = )(\d+)'
        if (-not [regex]::IsMatch($text, $rx)) {
            Say "Nao achei a linha de $($b.Base) em bossConfig.lua" "Red"
            continue
        }
        $newText = [regex]::Replace($text, $rx, "`${1}$new", 1)
        Confirm-Write $CONFIG
        Write-Text $CONFIG $newText
        Say "Salvo: $($b.Base) = $new kills." "Green"
        Say "Atencao: a opcao [9] Regerar recalcula esta tabela pela curva do gerador." "DarkGray"
    }
}

# ============================================================================
#  pool (quem entra no sorteio diario)
# ============================================================================
function Edit-Pool {
    while ($true) {
        $all = @(Get-Bosses)
        Write-Head "SORTEIO DA TASK DIARIA"
        Say "Criaturas EXCLUIDAS tem boss, mas nao caem na lista diaria." "DarkGray"
        Say "A fonte e' a lista DAILY_EXCLUDED em tools\generate_bosses.py." "DarkGray"
        Write-Host ""

        $i = 1
        foreach ($b in ($all | Sort-Object Base)) {
            $tag = "no sorteio"
            $color = "White"
            if ($b.Excluded) { $tag = "EXCLUIDA"; $color = "DarkGray" }
            if ($b.Exp -le 0) { $tag = "EXCLUIDA (exp 0)"; $color = "DarkGray" }
            Write-Host ("    [{0,3}] {1,-28} {2}" -f $i, $b.Base, $tag) -ForegroundColor $color
            $i++
        }

        $excludedCount = @($all | Where-Object { $_.Excluded }).Count
        Write-Host ""
        Say ("No sorteio: {0}   excluidas: {1}" -f ($all.Count - $excludedCount), $excludedCount) "Cyan"
        Write-Host ""
        Say "[N] Incluir / excluir uma criatura" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"
        if ($op -eq "0" -or $op -eq "") { return }
        if ($op -ne "N") { Say "Opcao invalida." "Red"; continue }

        $sorted = @($all | Sort-Object Base)
        $n = Ask-Int "Numero da criatura" 0 $false
        if ($n -lt 1 -or $n -gt $sorted.Count) { continue }
        $b = $sorted[$n - 1]

        $text = Read-Text $GEN
        $m = [regex]::Match($text, '(?s)DAILY_EXCLUDED\s*=\s*\[(.*?)\]')
        if (-not $m.Success) { Say "Nao achei DAILY_EXCLUDED em $GEN" "Red"; return }

        $names = New-Object System.Collections.ArrayList
        foreach ($nm in [regex]::Matches($m.Groups[1].Value, '"([^"]+)"')) {
            [void]$names.Add($nm.Groups[1].Value)
        }

        if ($names -contains $b.Base) {
            [void]$names.Remove($b.Base)
            Say "$($b.Base) VOLTOU para o sorteio diario." "Green"
        } else {
            [void]$names.Add($b.Base)
            Say "$($b.Base) saiu do sorteio diario (continua com boss)." "Yellow"
        }

        $nl = Get-Nl $text
        $lines = New-Object System.Collections.ArrayList
        [void]$lines.Add("DAILY_EXCLUDED = [")
        foreach ($nm in ($names | Sort-Object)) {
            [void]$lines.Add("    `"$nm`",")
        }
        [void]$lines.Add("]")
        $block = ($lines -join $nl)

        $newText = $text.Remove($m.Index, $m.Length).Insert($m.Index, $block)
        Confirm-Write $GEN
        Write-Text $GEN $newText
        Say "Gerador atualizado. Use a opcao [9] Regerar do menu para aplicar." "Green"
    }
}

# ============================================================================
#  tiles (portal do boss)
# ============================================================================
function Get-SystemConst([string]$name) {
    $text = Read-Text $SYSTEM
    if (-not $text) { return "" }
    $m = [regex]::Match($text, '(?m)^\s*' + [regex]::Escape($name) + '\s*=\s*(\d+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return ""
}

# Le uma lista de inteiros do bossSystem.lua: TILE_ITEM_IDS = { 19333, 19334 }
function Get-SystemList([string]$name) {
    $text = Read-Text $SYSTEM
    if (-not $text) { return @() }
    $m = [regex]::Match($text, '\b' + [regex]::Escape($name) + '\s*=\s*\{([^}]*)\}')
    if (-not $m.Success) { return @() }
    $vals = @()
    foreach ($mm in [regex]::Matches($m.Groups[1].Value, '\d+')) { $vals += [int]$mm.Value }
    return $vals
}

# Troca o numero de indice $index (1-based) de uma lista em bossSystem.lua
function Set-SystemListValue([string]$name, [int]$index, [int]$value) {
    $text = Read-Text $SYSTEM
    if (-not $text) { return $false }
    $m = [regex]::Match($text, '\b' + [regex]::Escape($name) + '\s*=\s*\{([^}]*)\}')
    if (-not $m.Success) { return $false }
    $nums = [regex]::Matches($m.Groups[1].Value, '\d+')
    if ($index -lt 1 -or $index -gt $nums.Count) { return $false }
    $num = $nums[$index - 1]
    $before = $text.Substring(0, $m.Groups[1].Index + $num.Index)
    $after  = $text.Substring($m.Groups[1].Index + $num.Index + $num.Length)
    Confirm-Write $SYSTEM
    Write-Text $SYSTEM ($before + [string]$value + $after)
    return $true
}

function Edit-Tiles {
    while ($true) {
        $tiles = Get-SystemList "TILE_ITEM_IDS"
        $itemId = ""; $itemId2 = ""
        if ($tiles.Count -ge 1) { $itemId = [string]$tiles[0] }
        if ($tiles.Count -ge 2) { $itemId2 = [string]$tiles[1] }
        $actionId = Get-SystemConst "TILE_ACTION_ID"
        Write-Head "TILE DO PORTAL (invocacao do boss)"
        Say "Pisar neste tile com uma task concluida invoca o boss ALPHA ao lado." "DarkGray"
        Write-Host ""
        Say "ItemID do tile 1 : $itemId" "Cyan"
        Say "ItemID do tile 2 : $itemId2  (versao 2, mesma funcao)" "Cyan"
        Say "ActionID altern. : $actionId  (funciona em QUALQUER item)" "Cyan"
        Write-Host ""
        $itemsText = Read-Text $ITEMS
        if (-not $itemsText) { $itemsText = "" }
        $hasItem = [regex]::IsMatch($itemsText, '<item\s+id="' + [regex]::Escape($itemId) + '"\s')
        if ($hasItem) {
            Say "ItemID $itemId existe no items.xml." "Green"
        } else {
            Say "ItemID $itemId NAO esta no items.xml." "Yellow"
            Say "Se ele tambem nao existir no items.otb/RME, use o ActionID em outro item." "DarkGray"
        }
        $hasItem2 = [regex]::IsMatch($itemsText, '<item\s+id="' + [regex]::Escape($itemId2) + '"\s')
        if ($hasItem2) {
            Say "ItemID $itemId2 existe no items.xml." "Green"
        } else {
            Say "ItemID $itemId2 NAO esta no items.xml." "Yellow"
        }
        Say "Registrado em movements.xml: $(if ([regex]::IsMatch((Read-Text $MOVES), 'bossPortal\.lua')) { 'sim' } else { 'NAO - use a opcao [3] abaixo' })" "Cyan"
        Write-Host ""
        Say "[1] Trocar o itemID do tile 1" "Cyan"
        Say "[2] Trocar o itemID do tile 2 (versao 2)" "Cyan"
        Say "[3] Trocar o actionID do tile" "Cyan"
        Say "[4] Garantir os registros no movements.xml" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"
        if ($op -eq "0" -or $op -eq "") { return }

        if ($op -eq "1" -or $op -eq "2" -or $op -eq "3") {
            $name = "TILE_ITEM_ID";  $cur = $itemId;  $mirrorName = "tileItemId"
            if ($op -eq "2") { $name = "TILE_ITEM_ID2"; $cur = $itemId2; $mirrorName = "tileItemId2" }
            if ($op -eq "3") { $name = "TILE_ACTION_ID"; $cur = $actionId; $mirrorName = "tileActionId" }
            $v = Ask-Int "$name" (To-Int $cur 0) $false
            if ($v -le 0) { continue }

            if ($op -eq "1" -or $op -eq "2") {
                # os tiles vivem na lista TILE_ITEM_IDS = { 19333, 19334 }
                $idx = 1; if ($op -eq "2") { $idx = 2 }
                if (-not (Set-SystemListValue "TILE_ITEM_IDS" $idx $v)) { Say "Nao achei TILE_ITEM_IDS em bossSystem.lua" "Red"; continue }
            } else {
                $text = Read-Text $SYSTEM
                $rx = '(?m)^(\s*' + [regex]::Escape($name) + '\s*=\s*)(\d+)'
                if (-not [regex]::IsMatch($text, $rx)) { Say "Nao achei $name em bossSystem.lua" "Red"; continue }
                $newText = [regex]::Replace($text, $rx, "`${1}$v", 1)
                Confirm-Write $SYSTEM
                Write-Text $SYSTEM $newText
            }

            # mantem o espelho em bossConfig.lua em sincronia
            $cfg = Read-Text $CONFIG
            if ($cfg) {
                $mrx = '(?m)^(BossConfig\.' + [regex]::Escape($mirrorName) + '\s*=\s*)(\d+)'
                if ([regex]::IsMatch($cfg, $mrx)) {
                    Confirm-Write $CONFIG
                    Write-Text $CONFIG ([regex]::Replace($cfg, $mrx, "`${1}$v", 1))
                }
            }

            # mantem o movements.xml em sincronia
            $mv = Read-Text $MOVES
            if ($mv) {
                if ($op -eq "3") {
                    $mv = [regex]::Replace($mv, '(<movevent type="StepIn" actionid=")\d+(" script="bossPortal\.lua"/>)', "`${1}$v`${2}")
                } elseif ($op -eq "1") {
                    # apenas a PRIMEIRA linha itemid (a segunda pertence ao tile 2)
                    $mv = ([regex]'(<movevent type="StepIn" itemid=")\d+(" script="bossPortal\.lua"/>)').Replace($mv, "`${1}$v`${2}", 1)
                } else {
                    # SEGUNDA linha itemid (tile 2); se nao existir, insere apos a primeira
                    $rxPair = '(<movevent type="StepIn" itemid="\d+" script="bossPortal\.lua"/>\s*<movevent type="StepIn" itemid=")\d+(" script="bossPortal\.lua"/>)'
                    if ([regex]::IsMatch($mv, $rxPair)) {
                        $mv = [regex]::Replace($mv, $rxPair, "`${1}$v`${2}")
                    } else {
                        $m = [regex]::Match($mv, '<movevent type="StepIn" itemid="\d+" script="bossPortal\.lua"/>')
                        if ($m.Success) {
                            $nl = Get-Nl $mv
                            $at = $m.Index + $m.Length
                            $insert = $nl + "`t" + '<movevent type="StepIn" itemid="' + $v + '" script="bossPortal.lua"/>'
                            $mv = $mv.Substring(0, $at) + $insert + $mv.Substring($at)
                        }
                    }
                }
                Confirm-Write $MOVES
                Write-Text $MOVES $mv
            }
            Say "Salvo." "Green"
            continue
        }

        if ($op -eq "4") {
            $mv = Read-Text $MOVES
            if (-not $mv) { Say "Nao encontrei $MOVES" "Red"; continue }
            $nl = Get-Nl $mv

            # espelho em bossConfig.lua
            $cfg = Read-Text $CONFIG
            if ($cfg) {
                $cfg = [regex]::Replace($cfg, '(?m)^(BossConfig\.tileItemId\s*=\s*)\d+', "`${1}$itemId")
                $cfg = [regex]::Replace($cfg, '(?m)^(BossConfig\.tileItemId2\s*=\s*)\d+', "`${1}$itemId2")
                $cfg = [regex]::Replace($cfg, '(?m)^(BossConfig\.tileActionId\s*=\s*)\d+', "`${1}$actionId")
                Confirm-Write $CONFIG
                Write-Text $CONFIG $cfg
            }

            if ($mv -notmatch 'bossPortal\.lua') {
                $block = "`t<movevent type=`"StepIn`" itemid=`"$itemId`" script=`"bossPortal.lua`"/>$nl" +
                         "`t<movevent type=`"StepIn`" itemid=`"$itemId2`" script=`"bossPortal.lua`"/>$nl" +
                         "`t<movevent type=`"StepIn`" actionid=`"$actionId`" script=`"bossPortal.lua`"/>$nl"
                $m = [regex]::Match($mv, '<movements>')
                if (-not $m.Success) { Say "movements.xml sem <movements>" "Red"; continue }
                $at = $m.Index + $m.Length
                $mv = $mv.Substring(0, $at) + $nl + $block + $mv.Substring($at)
                Confirm-Write $MOVES
                Write-Text $MOVES $mv
                Say "Registros criados." "Green"
            } else {
                $mv = ([regex]'(<movevent type="StepIn" itemid=")\d+(" script="bossPortal\.lua"/>)').Replace($mv, "`${1}$itemId`${2}", 1)
                $rxPair = '(<movevent type="StepIn" itemid="\d+" script="bossPortal\.lua"/>\s*<movevent type="StepIn" itemid=")\d+(" script="bossPortal\.lua"/>)'
                if ([regex]::IsMatch($mv, $rxPair)) {
                    $mv = [regex]::Replace($mv, $rxPair, "`${1}$itemId2`${2}")
                } else {
                    $m = [regex]::Match($mv, '<movevent type="StepIn" itemid="\d+" script="bossPortal\.lua"/>')
                    if ($m.Success) {
                        $at = $m.Index + $m.Length
                        $insert = $nl + "`t" + '<movevent type="StepIn" itemid="' + $itemId2 + '" script="bossPortal.lua"/>'
                        $mv = $mv.Substring(0, $at) + $insert + $mv.Substring($at)
                    }
                }
                $mv = [regex]::Replace($mv, '(<movevent type="StepIn" actionid=")\d+(" script="bossPortal\.lua"/>)', "`${1}$actionId`${2}")
                Confirm-Write $MOVES
                Write-Text $MOVES $mv
                Say "Registros sincronizados." "Green"
            }
            if (-not (Test-Xml $MOVES)) { Say "ATENCAO: movements.xml nao e' um xml valido - restaure o .bak!" "Red" }
            continue
        }
        Say "Opcao invalida." "Red"
    }
}

# ============================================================================
#  regen
# ============================================================================
function Invoke-Regen {
    Write-Head "REGERAR TODOS OS BOSSES"
    Say "Roda tools\generate_bosses.py e reescreve:" "DarkGray"
    Say "  data\monster\bosses\*.xml   (todos os bosses ALPHA)" "DarkGray"
    Say "  data\monster\bosses\bosses.xml" "DarkGray"
    Say "  data\monster\monsters.xml   (bloco <!-- ALPHA BOSSES -->)" "DarkGray"
    Say "  data\lib\bossConfig.lua     (tabela de ligacao)" "DarkGray"
    Write-Host ""

    $python = Find-Python
    if (-not $python) {
        Say "Python nao encontrado no PATH. Instale o Python ou rode o script na mao." "Red"
        return
    }
    Say "Python: $python" "DarkGray"

    if (-not (Test-Path -LiteralPath $GEN)) { Say "Nao encontrei $GEN" "Red"; return }

    if (-not (Ask-Yes "Confirma a regeracao? (qualquer edicao manual nos xml de boss sera perdida)" "N")) {
        Say "Cancelado." "DarkGray"
        return
    }

    # backup: copia a pasta inteira dos bosses + os dois arquivos gerados
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $bakDir = "$BOSS_DIR.bak_$stamp"
    if (Test-Path -LiteralPath $BOSS_DIR) {
        Copy-Item -LiteralPath $BOSS_DIR -Destination $bakDir -Recurse -Force
        Say "Backup da pasta: $bakDir" "DarkGray"
    }
    if (Test-Path -LiteralPath $REGISTRY) { Copy-Item -LiteralPath $REGISTRY -Destination "$REGISTRY.bak" -Force }
    if (Test-Path -LiteralPath $CONFIG)   { Copy-Item -LiteralPath $CONFIG   -Destination "$CONFIG.bak" -Force }

    Push-Location $SERVER_ROOT
    try {
        Write-Host ""
        & $python "tools\generate_bosses.py"
        $code = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    Write-Host ""
    if ($code -ne 0) {
        Say "O gerador saiu com codigo $code - confira a mensagem acima." "Red"
        return
    }
    Say "Regerado." "Green"
    Test-BossFiles
}

# ============================================================================
#  diag
# ============================================================================
$script:Problems = 0
function Problem([string]$msg) {
    $script:Problems++
    Say "[!] $msg" "Red"
}
function Warn([string]$msg) { Say "[~] $msg" "Yellow" }
function Ok([string]$msg) { Say "[ok] $msg" "Green" }

function Test-BossFiles {
    $all = @(Get-Bosses)
    if ($all.Count -eq 0) { Problem "BossConfig.monsters vazio"; return }

    $registry = Read-Text $REGISTRY
    $registered = @{}
    foreach ($m in [regex]::Matches($registry, '<monster\s+name="([^"]+)"\s+file="([^"]+)"')) {
        $registered[$m.Groups[1].Value] = $m.Groups[2].Value
    }

    $folderBosses = @()
    if (Test-Path -LiteralPath $BOSS_DIR) {
        $folderBosses = @(Get-ChildItem -LiteralPath $BOSS_DIR -Filter "*.xml" |
            Where-Object { $_.Name -ne "bosses.xml" } | ForEach-Object { $_.BaseName })
    }

    $missingFile = 0; $badXml = 0; $notRegistered = 0; $notHostile = 0
    foreach ($b in $all) {
        if (-not (Test-Path -LiteralPath $b.XmlPath)) { Problem "sem arquivo: $($b.Boss).xml"; $missingFile++; continue }
        if (-not (Test-Xml $b.XmlPath)) { Problem "xml invalido: $($b.Boss).xml"; $badXml++; continue }
        if (-not $registered.ContainsKey($b.Boss)) { Problem "nao registrado em monsters.xml: $($b.Boss)"; $notRegistered++ }
        $txt = Read-Text $b.XmlPath
        if ($txt -notmatch '<flag\s+hostile="1"\s*/>') { Problem "boss sem hostile=1: $($b.Boss)"; $notHostile++ }
    }
    if ($missingFile -eq 0 -and $badXml -eq 0 -and $notRegistered -eq 0 -and $notHostile -eq 0) {
        Ok "$($all.Count) bosses com arquivo, xml valido, registrados e hostis"
    }

    $bossNames = @($all | ForEach-Object { $_.Boss })
    $orphan = @($folderBosses | Where-Object { $bossNames -notcontains $_ })
    if ($orphan.Count -gt 0) {
        Warn "$($orphan.Count) xml na pasta bosses sem entrada no config: $(($orphan | Select-Object -First 3) -join ', ')"
    }
}

function Invoke-Diag {
    $script:Problems = 0
    Write-Head "DIAGNOSTICO DO SISTEMA ALPHA"

    $all = @(Get-Bosses)
    Ok "$($all.Count) bosses na tabela BossConfig.monsters"

    # 1) arquivos + registro
    Test-BossFiles

    # 2) storage keys (player_storage.key e' VARCHAR(32))
    $longKeys = @()
    foreach ($b in $all) {
        $key = "Boss_" + ($b.Base -replace '[^A-Za-z0-9]', '_')
        if ($key.Length -gt 32) { $longKeys += "$key ($($key.Length))" }
    }
    if ($longKeys.Count -gt 0) { Problem "chave de storage maior que 32 chars: $($longKeys -join ', ')" }
    else { Ok "todas as chaves Boss_<criatura> cabem em VARCHAR(32)" }

    # 3) luvas existem no items.xml
    $items = Read-Text $ITEMS
    if (-not $items) { $items = "" }
    $missingGloves = @()
    foreach ($b in $all) {
        if ($b.Glove -eq "nil") { continue }
        if ($items -notmatch '<item\s+id="' + [regex]::Escape($b.Glove) + '"\s') {
            $missingGloves += $b.Glove
        }
    }
    if ($missingGloves.Count -gt 0) { Problem "luvas sem entrada no items.xml: $($missingGloves -join ', ')" }
    else { Ok "todas as luvas do config existem no items.xml" }

    # 4) tile do portal
    $tilesDiag = Get-SystemList "TILE_ITEM_IDS"
    $tileItem = ""; $tileItem2 = ""
    if ($tilesDiag.Count -ge 1) { $tileItem = [string]$tilesDiag[0] }
    if ($tilesDiag.Count -ge 2) { $tileItem2 = [string]$tilesDiag[1] }
    $tileAction = Get-SystemConst "TILE_ACTION_ID"
    $moves = Read-Text $MOVES
    if ($moves -match 'bossPortal\.lua') {
        if ($moves -match ('itemid="' + [regex]::Escape($tileItem) + '"\s+script="bossPortal\.lua"')) {
            Ok "movements.xml: StepIn itemid=$tileItem -> bossPortal"
        } else {
            Problem "movements.xml nao tem StepIn itemid=$tileItem para o bossPortal"
        }
        if ($moves -match ('itemid="' + [regex]::Escape($tileItem2) + '"\s+script="bossPortal\.lua"')) {
            Ok "movements.xml: StepIn itemid=$tileItem2 -> bossPortal (versao 2)"
        } else {
            Problem "movements.xml nao tem StepIn itemid=$tileItem2 para o bossPortal (versao 2)"
        }
        if ($moves -match ('actionid="' + [regex]::Escape($tileAction) + '"\s+script="bossPortal\.lua"')) {
            Ok "movements.xml: StepIn actionid=$tileAction -> bossPortal (alternativa)"
        } else {
            Warn "movements.xml sem o StepIn por actionid=$tileAction (a alternativa vai faltar)"
        }
    } else {
        Problem "movements.xml nao registra bossPortal.lua"
    }
    if ($items -match '<item\s+id="' + [regex]::Escape($tileItem) + '"\s') {
        Ok "itemID $tileItem esta no items.xml"
    } else {
        Warn "itemID $tileItem NAO esta no items.xml - se tambem nao existir no items.otb, use o actionID $tileAction em outro item"
    }
    if ($items -match '<item\s+id="' + [regex]::Escape($tileItem2) + '"\s') {
        Ok "itemID $tileItem2 esta no items.xml"
    } else {
        Warn "itemID $tileItem2 NAO esta no items.xml - se tambem nao existir no items.otb, use o actionID $tileAction em outro item"
    }

    # 5) loot
    $rate = Get-RateLoot
    $gloveChance = To-Int (Get-GenConst "GLOVE_CHANCE") 0
    $glovePct = Get-LootPercent $gloveChance
    Say ""
    Say "rateLoot = $rate" "Cyan"
    Say ("GLOVE_CHANCE = {0}  ->  {1:N2}% real de dropar a luva" -f $gloveChance, $glovePct) "Cyan"
    Say "(o chance= do xml e' cortado pela metade e o sorteio estoura 16 bits - ver comentario no gerador)" "DarkGray"
    if ([math]::Abs($glovePct - 4.0) -gt 0.25) {
        Warn ("a luva esta em {0:N2}% e nao nos 4% do design - use a opcao [4] Loot ou [5] Tuning" -f $glovePct)
    } else {
        Ok "chance da luva perto dos 4% do design"
    }

    # crystal coin: design atual = TODOS os bosses dropam sempre 1 a N moedas
    $crystalChance = To-Int (Get-GenConst "CRYSTAL_CHANCE") 0
    $crystalCount = To-Int (Get-GenConst "CRYSTAL_COUNTMAX") 3
    if ($crystalChance -ge 65536) {
        Say ("CRYSTAL = chance {0} (sempre), countmax {1} (1 a {1} moedas)" -f $crystalChance, $crystalCount) "Cyan"
    } else {
        Warn ("CRYSTAL_CHANCE = {0} fora do modo 'sempre' do design (precisa >= 65536)" -f $crystalChance)
    }
    $badCrystal = 0
    foreach ($b in $all) {
        $txt = Read-Text $b.XmlPath
        if (-not $txt) { continue }
        $tag = [regex]::Match($txt, '<item\s+id="2160"[^>]*>').Value
        if (-not $tag) { $badCrystal++; continue }
        $cm = To-Int (Get-Attr $tag "countmax") 0
        $ch = To-Int (Get-Attr $tag "chance") 0
        if ($cm -ne $crystalCount -or $ch -lt 65536) { $badCrystal++ }
    }
    if ($badCrystal -gt 0) {
        Problem "$badCrystal bosses sem o crystal garantido (countmax=$crystalCount e chance>=65536) - use a opcao [9] Regerar"
    } else {
        Ok "todos os bosses dropam 1 a $crystalCount crystal coins (sempre)"
    }

    # xml fora de sincronia com o gerador?
    $outOfSync = 0
    foreach ($b in ($all | Where-Object { $_.Glove -ne "nil" })) {
        $txt = Read-Text $b.XmlPath
        if (-not $txt) { continue }
        $rx = '<item\s+id="' + [regex]::Escape($b.Glove) + '"[^>]*chance="([0-9]+)"'
        $m = [regex]::Match($txt, $rx)
        if (-not $m.Success) { $outOfSync++ }
        elseif ([int]$m.Groups[1].Value -ne $gloveChance) { $outOfSync++ }
    }
    if ($outOfSync -gt 0) { Warn "$outOfSync bosses com chance de luva diferente do gerador - use a opcao [9] Regerar" }

    # 6) pool diario
    $pool = @($all | Where-Object { -not $_.Excluded -and $_.Exp -gt 0 })
    $excluded = @($all | Where-Object { $_.Excluded -or $_.Exp -le 0 })
    Say ""
    if ($pool.Count -lt 5) { Problem "sorteio diario com menos de 5 criaturas ($($pool.Count)) - o re-roll vai faltar opcao" }
    else { Ok "sorteio diario com $($pool.Count) criaturas ($($excluded.Count) fora)" }

    $metaMin = ($pool | Measure-Object -Property Kills -Minimum).Minimum
    $metaMax = ($pool | Measure-Object -Property Kills -Maximum).Maximum
    if ($null -ne $metaMin) {
        Say ("metas do sorteio: {0} ate {1} kills" -f $metaMin, $metaMax) "Cyan"
        if ($metaMax -gt 1000) { Problem "existe meta acima de 1000 kills (teto do design)" }
    }

    # 7) dailyHunt / bossSystem presentes
    $task = Read-Text (Join-Path $SERVER_ROOT "data\lib\dailyHunt.lua")
    if ($task -and $task -match 'BossSystem\.grantAccess') { Ok "dailyHunt.lua concede o boss ao completar a task" }
    else { Problem "dailyHunt.lua nao chama BossSystem.grantAccess" }
    if ($task -and $task -match 'DailyHunt\.reroll') { Ok "dailyHunt.lua tem o botao de re-roll" }
    else { Problem "dailyHunt.lua sem rotina de re-roll" }

    $portal = Join-Path $SERVER_ROOT "data\movements\scripts\bossPortal.lua"
    if (Test-Path -LiteralPath $portal) { Ok "data\movements\scripts\bossPortal.lua existe" }
    else { Problem "falta data\movements\scripts\bossPortal.lua" }

    $think = Read-Text (Join-Path $SERVER_ROOT "data\globalevents\globalevents.xml")
    if ($think -and $think -match 'value="bossSystem\.lua"') { Ok "globalevent bossSystem.lua registrado (despawn/limpeza)" }
    else { Warn "globalevent bossSystem.lua nao registrado em globalevents.xml" }

    # 8) gerador x config (quem esta mais novo)
    if ((Test-Path -LiteralPath $GEN) -and (Test-Path -LiteralPath $CONFIG)) {
        $genTime = (Get-Item -LiteralPath $GEN).LastWriteTime
        $cfgTime = (Get-Item -LiteralPath $CONFIG).LastWriteTime
        if ($genTime -gt $cfgTime) {
            Warn "o gerador foi editado depois do bossConfig.lua - use a opcao [9] Regerar para aplicar"
        } else {
            Ok "bossConfig.lua esta mais novo que o gerador (em sincronia)"
        }
    }

    $python = Find-Python
    if ($python) { Ok "Python encontrado: $python" }
    else { Warn "Python nao encontrado no PATH - o modo Regen nao vai rodar" }

    Write-Host ""
    if ($script:Problems -eq 0) { Say "NENHUM PROBLEMA BLOQUEANTE." "Green" }
    else { Say "$($script:Problems) PROBLEMA(S) - veja os [x] acima." "Red" }
}

# ============================================================================
#  dispatch
# ============================================================================
switch ($Mode.ToLower()) {
    "list"    { Show-BossList }
    "show"    { $b = Select-Boss; if ($b) { Show-FichaBoss $b } }
    "status"  { Edit-StatusBoss }
    "loot"    { Edit-LootBoss }
    "tuning"  { Edit-Tuning }
    "kills"   { Edit-Kills }
    "pool"    { Edit-Pool }
    "tiles"   { Edit-Tiles }
    "regen"   { Invoke-Regen }
    "diag"    { Invoke-Diag }
    "test"    { Test-BossFiles }
    default   { Say "Modo desconhecido: $Mode" "Red" }
}
