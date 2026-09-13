# ============================================================================
#  creature_util.ps1 - Editores de criaturas (Avatar Server)
# ----------------------------------------------------------------------------
#  Modos (chamados pelo criaturas.bat):
#    list       lista / busca as criaturas cadastradas
#    show       ficha da criatura (vida, dano, loot, outfit, magia)
#    status     altera vida, xp, speed, armor, defense, strategy, targetdistance
#    damage     altera min/max/interval/chance de um ataque existente
#    loot       adiciona / remove loot
#    outfit     troca o look (type ou typeEx) e o corpse
#    rename     renomeia a criatura (xml + monsters.xml + spawns + livro de spells)
#    spell      adiciona / remove magia (lista pronta) e escreve o book
#    duplicate  cria uma criatura nova copiando outra
#
#  Todo arquivo alterado ganha um .bak antes da escrita.
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

$REGISTRY    = Join-Path $SERVER_ROOT "data\monster\monsters.xml"
$MONSTER_DIR = Join-Path $SERVER_ROOT "data\monster"
$WORLD_DIR   = Join-Path $SERVER_ROOT "data\world"
$BOOK        = Join-Path $SERVER_ROOT "data\lib\monsterSpellBook.lua"
$GEN         = Join-Path $SERVER_ROOT "tools\gen_monster_spells.py"

$script:UTF8 = New-Object System.Text.UTF8Encoding($false)

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
#  XML: ler / gravar atributos sem reformatar o arquivo
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

# Troca varios atributos de UMA tag de uma vez. Fazer um por vez com um
# padrao literal (o proprio texto da tag) quebra: depois da primeira troca o
# padrao antigo nao casa mais com o texto e as trocas seguintes sao perdidas.
function Set-TagAttrs([string]$text, [string]$tagPattern, $pairs) {
    $m = [regex]::Match($text, $tagPattern)
    if (-not $m.Success) { return $text }

    $tag = $m.Value
    foreach ($p in $pairs) {
        $attr = [string]$p[0]
        $value = [string]$p[1]
        $rx = '\b' + [regex]::Escape($attr) + '="[^"]*"'
        if ([regex]::IsMatch($tag, $rx)) {
            $repl = ($attr + '="' + $value + '"').Replace('$', '$$')
            $tag = (New-Object System.Text.RegularExpressions.Regex($rx)).Replace($tag, $repl, 1)
        } else {
            if ($tag.TrimEnd().EndsWith("/>")) {
                $tag = $tag.Substring(0, $tag.Length - 2) + " $attr=`"$value`"/>"
            } else {
                $tag = $tag.Substring(0, $tag.Length - 1) + " $attr=`"$value`">"
            }
        }
    }
    return $text.Remove($m.Index, $m.Length).Insert($m.Index, $tag)
}

function Set-TagAttr([string]$text, [string]$tagPattern, [string]$attr, [string]$value) {
    return Set-TagAttrs $text $tagPattern @(, @($attr, $value))
}

function Remove-TagAttr([string]$tag, [string]$attr) {
    $rx = '\s+\b' + [regex]::Escape($attr) + '="[^"]*"'
    return [regex]::Replace($tag, $rx, "")
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

function Get-RootText([string]$text) {
    return (Get-Tag $text '(?s)<monster\b[^>]*>')
}

# ============================================================================
#  lista de criaturas (monsters.xml)
# ============================================================================
function Get-Creatures {
    $text = Read-Text $REGISTRY
    $out = New-Object System.Collections.ArrayList
    if (-not $text) { return $out }

    foreach ($m in [regex]::Matches($text, '<monster\s+name="([^"]+)"\s+file="([^"]+)"')) {
        $rel = $m.Groups[2].Value -replace '/', '\'
        [void]$out.Add([pscustomobject]@{
            Name = $m.Groups[1].Value
            Rel  = $m.Groups[2].Value
            Path = (Join-Path $MONSTER_DIR $rel)
        })
    }
    return $out
}

function Select-Creature {
    param([string]$Prompt = "Qual criatura quer editar?")
    $all = @(Get-Creatures)
    if ($all.Count -eq 0) {
        Say "Nenhuma criatura encontrada em $REGISTRY" "Red"
        return $null
    }

    Write-Host ""
    Say "$Prompt" "Cyan"
    Say "($($all.Count) criaturas cadastradas - digite parte do nome, ENTER = listar todas)" "DarkGray"
    $filter = Ask-Text "Busca"

    if ([string]::IsNullOrWhiteSpace($filter)) {
        $list = $all
    } else {
        # nome exato primeiro, depois quem comeca com o filtro, depois o resto
        $list = @($all | Where-Object { $_.Name -like "*$filter*" } |
            Sort-Object @{ Expression = { if ($_.Name -ieq $filter) { 0 } elseif ($_.Name -like "$filter*") { 1 } else { 2 } } }, Name)
    }

    if ($list.Count -eq 0) {
        Say "Nenhuma criatura com '$filter'." "Red"
        return $null
    }

    if ($list.Count -eq 1) {
        Say "Criatura: $($list[0].Name)" "Green"
        if (Ask-Yes "Confirmar?" "S") { return $list[0] }
        return $null
    }

    Write-Host ""
    $i = 1
    foreach ($c in $list) {
        Write-Host ("    [{0,3}] {1}" -f $i, $c.Name) -ForegroundColor White
        $i++
    }
    Write-Host ""
    $op = Ask-Int "Numero da criatura (0 = cancelar)" 0 $false
    if ($op -le 0 -or $op -gt $list.Count) { return $null }
    return $list[$op - 1]
}

function Confirm-Write([string]$path) {
    Save-Backup $path
    Say "Backup: $path.bak" "DarkGray"
}

# ============================================================================
#  list
# ============================================================================
function Show-CreatureList {
    Write-Head "CRIATURAS CADASTRADAS"
    $all = @(Get-Creatures)
    $filtro = Ask-Text "Filtrar por parte do nome (ENTER = todas)"
    if (-not [string]::IsNullOrWhiteSpace($filtro)) {
        $all = @($all | Where-Object { $_.Name -like "*$filtro*" })
    }
    Write-Host ""
    $i = 1
    foreach ($c in $all) {
        $exists = if (Test-Path -LiteralPath $c.Path) { " " } else { "!" }
        Write-Host ("    [{0,3}] {1}{2}" -f $i, $c.Name, $exists) -ForegroundColor White
        Write-Host ("          $($c.Rel)") -ForegroundColor DarkGray
        $i++
    }
    Write-Host ""
    Say "Total: $($all.Count)" "DarkGray"
    Say "( ! = arquivo do monstro nao encontrado )" "DarkGray"
}

# ============================================================================
#  show (ficha)
# ============================================================================
function Show-Ficha([object]$c) {
    $text = Read-Text $c.Path
    if (-not $text) { Say "Nao encontrei o xml: $($c.Path)" "Red"; return }

    $root = Get-RootText $text
    $health = Get-Tag $text '<health\b[^>]*/>'
    $look = Get-Tag $text '<look\b[^>]*/>'
    $strategy = Get-Tag $text '<strategy\b[^>]*/>'
    $defenses = Get-Tag $text '<defenses\b[^>]*/>'
    $target = Get-Tag $text '<targetchange\b[^>]*/>'

    Write-Head "FICHA: $($c.Name)"
    Say "Arquivo       : $($c.Path)"
    Say "Vida          : $(Get-Attr $health 'now') / $(Get-Attr $health 'max')"
    Say "Experiencia   : $(Get-Attr $root 'experience')"
    Say "Speed         : $(Get-Attr $root 'speed')"
    Say "Race          : $(Get-Attr $root 'race')"
    $lookDesc = "type=$(Get-Attr $look 'type')"
    if ((Get-Attr $look 'typeEx') -ne "") { $lookDesc += "  typeEx=$(Get-Attr $look 'typeEx')" }
    $lookDesc += "  corpse=$(Get-Attr $look 'corpse')"
    Say "Look          : $lookDesc"
    Say "Strategy      : attack=$(Get-Attr $strategy 'attack')  defense=$(Get-Attr $strategy 'defense')"
    Say "Defenses      : armor=$(Get-Attr $defenses 'armor')  defense=$(Get-Attr $defenses 'defense')"
    Say "Target change : interval=$(Get-Attr $target 'interval')  chance=$(Get-Attr $target 'chance')"
    Say "Flags         : attackable=$(Get-Attr (Get-Tag $text '<flag\s+attackable="[^"]*"\s*/>') 'attackable')  hostile=$(Get-Attr (Get-Tag $text '<flag\s+hostile="[^"]*"\s*/>') 'hostile')  targetdistance=$(Get-Attr (Get-Tag $text '<flag\s+targetdistance="[^"]*"\s*/>') 'targetdistance')  runonhealth=$(Get-Attr (Get-Tag $text '<flag\s+runonhealth="[^"]*"\s*/>') 'runonhealth')"

    Write-Host ""
    Say "-- Ataques --" "Cyan"
    $attacks = [regex]::Matches($text, '<attack\b[^>]*/>')
    if ($attacks.Count -eq 0) { Say "(nenhum)" "DarkGray" }
    $i = 1
    foreach ($a in $attacks) {
        $t = $a.Value
        Write-Host ("    [{0,2}] {1}  interval={2} chance={3} range={4} min={5} max={6}" -f $i, (Get-Attr $t 'name'), (Get-Attr $t 'interval'), (Get-Attr $t 'chance'), (Get-Attr $t 'range'), (Get-Attr $t 'min'), (Get-Attr $t 'max')) -ForegroundColor White
        $i++
    }

    Write-Host ""
    Say "-- Defesas (cura etc) --" "Cyan"
    $defs = [regex]::Matches($text, '<defense\b[^>]*/>')
    if ($defs.Count -eq 0) { Say "(nenhuma)" "DarkGray" }
    foreach ($d in $defs) {
        Write-Host ("         {0}  interval={1} chance={2} min={3} max={4}" -f (Get-Attr $d.Value 'name'), (Get-Attr $d.Value 'interval'), (Get-Attr $d.Value 'chance'), (Get-Attr $d.Value 'min'), (Get-Attr $d.Value 'max')) -ForegroundColor White
    }

    Write-Host ""
    Say "-- Loot --" "Cyan"
    $loot = [regex]::Match($text, '(?s)<loot>(.*?)</loot>')
    if ($loot.Success) {
        $items = [regex]::Matches($loot.Groups[1].Value, '<item\b[^>]*/>')
        Say "$($items.Count) item(ns)" "White"
        foreach ($it in $items) {
            $pct = [double](Get-Attr $it.Value 'chance') / 1000.0
            Write-Host ("         id={0} countmax={1} chance={2}%" -f (Get-Attr $it.Value 'id'), (Get-Attr $it.Value 'countmax'), $pct) -ForegroundColor White
        }
    } else {
        Say "(sem bloco de loot)" "DarkGray"
    }

    Write-Host ""
    Say "-- Magia assinatura (monsterSpellBook.lua) --" "Cyan"
    # NAO usar uma variavel chamada $book aqui: o PowerShell e' case-insensitive
    # e enxerga as variaveis do chamador (escopo dinamico), entao $book esconderia
    # a variavel $BOOK do script (o caminho do monsterSpellBook.lua).
    $bookEntry = Get-BookEntry $c.Name
    if ($bookEntry) { Say $bookEntry } else { Say "(nenhuma)" "DarkGray" }
}

# ============================================================================
#  status
# ============================================================================
function Edit-Status {
    $c = Select-Creature
    if (-not $c) { return }

    while ($true) {
        $text = Read-Text $c.Path
        if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }
        $root = Get-RootText $text
        $health = Get-Tag $text '<health\b[^>]*/>'
        $strategy = Get-Tag $text '<strategy\b[^>]*/>'
        $defenses = Get-Tag $text '<defenses\b[^>]*/>'

        Write-Head "STATUS: $($c.Name)"
        Say "[1] Vida            : $(Get-Attr $health 'now') / $(Get-Attr $health 'max')"
        Say "[2] Experiencia     : $(Get-Attr $root 'experience')"
        Say "[3] Speed           : $(Get-Attr $root 'speed')"
        Say "[4] Armadura        : $(Get-Attr $defenses 'armor')"
        Say "[5] Defesa          : $(Get-Attr $defenses 'defense')"
        Say "[6] Strategy attack : $(Get-Attr $strategy 'attack')"
        Say "[7] Target distance : $(Get-Attr (Get-Tag $text '<flag\s+targetdistance="[^"]*"\s*/>') 'targetdistance')"
        Say "[8] Run on health   : $(Get-Attr (Get-Tag $text '<flag\s+runonhealth="[^"]*"\s*/>') 'runonhealth')"
        Say "[0] Voltar" "DarkGray"
        Write-Host ""
        $op = Ask-Menu "Opcao"

        if ($op -eq "0" -or $op -eq "") { return }

        $changed = $false
        switch ($op) {
            "1" {
                $cur = To-Int (Get-Attr $health 'max')
                $v = Ask-Int "Nova vida (max e now)" $cur $false
                if ($v -gt 0) {
                    $text = Set-TagAttr $text '<health\b[^>]*/>' 'now' "$v"
                    $text = Set-TagAttr $text '<health\b[^>]*/>' 'max' "$v"
                    $changed = $true
                }
            }
            "2" {
                $cur = To-Int (Get-Attr $root 'experience')
                $v = Ask-Int "Nova experiencia" $cur $false
                $text = Set-TagAttr $text '(?s)<monster\b[^>]*>' 'experience' "$v"
                $changed = $true
            }
            "3" {
                $cur = To-Int (Get-Attr $root 'speed')
                $v = Ask-Int "Novo speed" $cur $false
                $text = Set-TagAttr $text '(?s)<monster\b[^>]*>' 'speed' "$v"
                $changed = $true
            }
            "4" {
                $cur = To-Int (Get-Attr $defenses 'armor')
                $v = Ask-Int "Nova armadura" $cur $true
                $text = Set-TagAttr $text '<defenses\b[^>]*/>' 'armor' "$v"
                $changed = $true
            }
            "5" {
                $cur = To-Int (Get-Attr $defenses 'defense')
                $v = Ask-Int "Nova defesa" $cur $true
                $text = Set-TagAttr $text '<defenses\b[^>]*/>' 'defense' "$v"
                $changed = $true
            }
            "6" {
                $cur = To-Int (Get-Attr $strategy 'attack')
                $v = Ask-Int "Novo strategy attack (0-100)" $cur $false
                $text = Set-TagAttr $text '<strategy\b[^>]*/>' 'attack' "$v"
                $changed = $true
            }
            "7" {
                $cur = To-Int (Get-Attr (Get-Tag $text '<flag\s+targetdistance="[^"]*"\s*/>') 'targetdistance')
                $v = Ask-Int "Nova targetdistance" $cur $false
                $text = Set-Flag $text 'targetdistance' "$v"
                $changed = $true
            }
            "8" {
                $cur = To-Int (Get-Attr (Get-Tag $text '<flag\s+runonhealth="[^"]*"\s*/>') 'runonhealth')
                $v = Ask-Int "Novo runonhealth" $cur $false
                $text = Set-Flag $text 'runonhealth' "$v"
                $changed = $true
            }
            default { Say "Opcao invalida." "Red" }
        }

        if ($changed) {
            Confirm-Write $c.Path
            Write-Text $c.Path $text
            Say "Salvo em $($c.Path)" "Green"
        }
        Write-Host ""
        if (-not (Ask-Yes "Alterar outro campo?" "S")) { return }
    }
}

# ============================================================================
#  damage
# ============================================================================
function Edit-Damage {
    $c = Select-Creature
    if (-not $c) { return }

    while ($true) {
        $text = Read-Text $c.Path
        if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }
        $matches = [regex]::Matches($text, '<attack\b[^>]*/>')
        Write-Head "DANO DOS ATAQUES: $($c.Name)"
        if ($matches.Count -eq 0) {
            Say "(a criatura nao tem nenhum <attack>)" "DarkGray"
            Say "Use o editor de MAGIAS para adicionar uma." "DarkGray"
            return
        }
        $i = 1
        foreach ($m in $matches) {
            $t = $m.Value
            Write-Host ("    [{0,2}] {1,10}  interval={2,5} chance={3,3} range={4,2} min={5,5} max={6,5}" -f $i, (Get-Attr $t 'name'), (Get-Attr $t 'interval'), (Get-Attr $t 'chance'), (Get-Attr $t 'range'), (Get-Attr $t 'min'), (Get-Attr $t 'max')) -ForegroundColor White
            $i++
        }
        Write-Host ""
        $n = Ask-Int "Numero do ataque (0 = voltar)" 0 $false
        if ($n -le 0 -or $n -gt $matches.Count) { return }

        $tag = $matches[$n - 1].Value
        Write-Host ""
        Say "Ataque selecionado: $tag" "DarkGray"
        $min = Ask-Int "Dano min (negativo, ex: -40)" (To-Int (Get-Attr $tag 'min')) $true
        $max = Ask-Int "Dano max (negativo, ex: -80)" (To-Int (Get-Attr $tag 'max')) $true
        $intv = Ask-Int "Interval (ms)" (To-Int (Get-Attr $tag 'interval')) $false
        $chance = Ask-Int "Chance (%)" (To-Int (Get-Attr $tag 'chance')) $false
        $range = Ask-Int "Range (sqm, 0 = melee)" (To-Int (Get-Attr $tag 'range')) $false

        $pairs = @()
        $pairs += , @('min', "$min")
        $pairs += , @('max', "$max")
        $pairs += , @('interval', "$intv")
        $pairs += , @('chance', "$chance")
        # so' mexe no range se o ataque ja tinha range ou se o usuario pediu > 0
        # (sem range = melee, e um range=0 no melee mudaria o comportamento)
        if ((Get-Attr $tag 'range') -ne "" -or $range -gt 0) {
            $pairs += , @('range', "$range")
        }
        $text = Set-TagAttrs $text ([regex]::Escape($tag)) $pairs

        Confirm-Write $c.Path
        Write-Text $c.Path $text
        Say "Salvo. min=$min max=$max interval=$intv chance=$chance range=$range" "Green"
        Write-Host ""
        if (-not (Ask-Yes "Editar outro ataque?" "S")) { return }
    }
}

# ============================================================================
#  loot
# ============================================================================
function Edit-Loot {
    $c = Select-Creature
    if (-not $c) { return }

    while ($true) {
        $text = Read-Text $c.Path
        if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }

        $lootBlock = [regex]::Match($text, '(?s)<loot>(.*?)</loot>')
        if (-not $lootBlock.Success) {
            Write-Head "LOOT: $($c.Name)"
            Say "A criatura nao tem bloco <loot>." "Red"
            Say "Adicione um <loot></loot> antes de </monster> no xml dela." "DarkGray"
            return
        }

        $items = [regex]::Matches($text, '<item\b[^>]*/>')
        Write-Head "LOOT: $($c.Name)"
        if ($items.Count -eq 0) {
            Say "(loot vazio)" "DarkGray"
        } else {
            $i = 1
            foreach ($it in $items) {
                $pct = [double](Get-Attr $it.Value 'chance') / 1000.0
                Write-Host ("    [{0,2}] id={1,6}  countmax={2,3}  chance={3}%" -f $i, (Get-Attr $it.Value 'id'), (Get-Attr $it.Value 'countmax'), $pct) -ForegroundColor White
                $i++
            }
        }

        Write-Host ""
        Say "[A] Adicionar item" "Cyan"
        Say "[R] Remover item" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"

        if ($op -eq "0" -or $op -eq "") { return }

        if ($op -eq "A") {
            $id = Ask-Int "ID do item (server)" 0 $false
            if ($id -le 0) { continue }
            $count = Ask-Int "Quantidade maxima (countmax)" 1 $false
            Write-Host "  Chance em % (ex: 24.5 | 100 = sempre)" -ForegroundColor Cyan
            $pctStr = Ask-Text "Chance (%)" "10"
            $pct = 0.0
            # aceita 12.5 e 12,5 (a cultura do console muda o separador)
            $pctStr = $pctStr.Trim().Replace(',', '.')
            $parsed = [double]::TryParse($pctStr, [System.Globalization.NumberStyles]::Float,
                [System.Globalization.CultureInfo]::InvariantCulture, [ref]$pct)
            if (-not $parsed) { Say "Chance invalida." "Red"; continue }
            if ($pct -lt 0) { $pct = 0 }
            if ($pct -gt 100) { $pct = 100 }
            $chance = [int][math]::Round($pct * 1000)

            $nl = Get-Nl $text
            # usa a mesma indentacao dos itens que ja existem no bloco
            $indent = "`t`t"
            if ($items.Count -gt 0) {
                $last = $items[$items.Count - 1]
                $lineStart = $text.LastIndexOf("`n", $last.Index)
                if ($lineStart -ge 0) {
                    $tmp = ""
                    for ($k = $lineStart + 1; $k -lt $text.Length; $k++) {
                        if ($text[$k] -eq "`t" -or $text[$k] -eq " ") { $tmp += $text[$k] } else { break }
                    }
                    if ($tmp -ne "") { $indent = $tmp }
                }
            }
            $line = $indent + "<item id=`"$id`" countmax=`"$count`" chance=`"$chance`"/>"
            if ($items.Count -gt 0) {
                # entra na linha seguinte ao ultimo item (nao no meio dela, senao
                # um comentario <!-- ... --> do item antigo ficaria colado no novo)
                # ($items foi casado no texto inteiro, entao o indice ja e' absoluto)
                $lastItem = $items[$items.Count - 1]
                $lineEnd = $text.IndexOf("`n", $lastItem.Index + $lastItem.Length)
                if ($lineEnd -ge 0) {
                    $text = $text.Insert($lineEnd + 1, $line + $nl)
                } else {
                    $text = $text.Insert($lastItem.Index + $lastItem.Length, $nl + $line)
                }
            } else {
                $open = [regex]::Match($text, '<loot>')
                $text = $text.Insert($open.Index + $open.Length, $nl + $line)
            }

            Confirm-Write $c.Path
            Write-Text $c.Path $text
            Say "Item $id adicionado (chance=$chance de 100000)." "Green"
            continue
        }

        if ($op -eq "R") {
            if ($items.Count -eq 0) { continue }
            $n = Ask-Int "Numero do item para remover" 0 $false
            if ($n -le 0 -or $n -gt $items.Count) { continue }
            $m = $items[$n - 1]
            $start = $text.LastIndexOf("`n", $m.Index)
            if ($start -lt 0) { $start = 0 } else { $start = $start + 1 }
            $end = $text.IndexOf("`n", $m.Index + $m.Length)
            if ($end -lt 0) { $end = $text.Length } else { $end = $end + 1 }
            $text = $text.Remove($start, $end - $start)

            Confirm-Write $c.Path
            Write-Text $c.Path $text
            Say "Item removido." "Green"
            continue
        }
        Say "Opcao invalida." "Red"
    }
}

# ============================================================================
#  outfit
# ============================================================================
function Edit-Outfit {
    $c = Select-Creature
    if (-not $c) { return }

    $text = Read-Text $c.Path
    if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }
    $look = Get-Tag $text '<look\b[^>]*/>'
    if ([string]::IsNullOrEmpty($look)) { Say "A criatura nao tem tag <look>." "Red"; return }

    Write-Head "OUTFIT: $($c.Name)"
    Say "Atual: $look"
    if ((Get-Attr $look 'type') -ne "") { Say "(type = outfit de criatura)" "DarkGray" }
    if ((Get-Attr $look 'typeEx') -ne "") { Say "(typeEx = item, ex: estatuas/dummy)" "DarkGray" }
    Write-Host ""

    $id = Ask-Int "Novo ID (outfit ou item)" (To-Int (Get-Attr $look 'type')) $false
    if ($id -le 0) { return }
    $asItem = Ask-Yes "Usar como ITEM (typeEx)? Se nao, vira outfit (type)" "N"

    $newLook = $look
    if ($asItem) {
        $newLook = Remove-TagAttr $newLook 'type'
        if ((Get-Attr $newLook 'typeEx') -ne "") {
            $newLook = [regex]::Replace($newLook, '\btypeEx="[^"]*"', "typeEx=`"$id`"")
        } else {
            $newLook = $newLook.Substring(0, $newLook.Length - 2) + " typeEx=`"$id`"/>"
        }
    } else {
        $newLook = Remove-TagAttr $newLook 'typeEx'
        if ((Get-Attr $newLook 'type') -ne "") {
            $newLook = [regex]::Replace($newLook, '\btype="[^"]*"', "type=`"$id`"")
        } else {
            $newLook = $newLook.Substring(0, $newLook.Length - 2) + " type=`"$id`"/>"
        }
    }

    $corpse = Ask-Int "Corpse (id do item, 0 = manter)" 0 $false
    if ($corpse -gt 0) {
        if ((Get-Attr $newLook 'corpse') -ne "") {
            $newLook = [regex]::Replace($newLook, '\bcorpse="[^"]*"', "corpse=`"$corpse`"")
        } else {
            $newLook = $newLook.Substring(0, $newLook.Length - 2) + " corpse=`"$corpse`"/>"
        }
    }

    Say "Novo : $newLook" "Green"
    if (-not (Ask-Yes "Salvar?" "S")) { return }

    $lookMatch = [regex]::Match($text, '<look\b[^>]*/>')
    $text = $text.Remove($lookMatch.Index, $lookMatch.Length).Insert($lookMatch.Index, $newLook)
    Confirm-Write $c.Path
    Write-Text $c.Path $text
    Say "Outfit salvo." "Green"
}

# ============================================================================
#  livro de spells (monsterSpellBook.lua)
# ============================================================================
function Get-BookBlock([string]$monster) {
    $text = Read-Text $BOOK
    if (-not $text) { return "" }
    $m = [regex]::Match($text, '(?s)\["' + [regex]::Escape($monster) + '"\]\s*=\s*\{.*?\}')
    if ($m.Success) { return $m.Value }
    return ""
}

function Get-BookEntry([string]$monster) {
    $b = Get-BookBlock $monster
    if ($b -eq "") { return "" }
    return ($b -replace "`r?`n", " " -replace "\s+", " ")
}

function Get-BookParamsText($sp) {
    $parts = @()
    if ($sp.Radius -gt 0) { $parts += "radius = $($sp.Radius)" }
    if ($sp.Length -gt 0) { $parts += "length = $($sp.Length)" }
    if ($sp.Shape -eq "wave" -or $sp.Shape -eq "beam" -or $sp.Shape -eq "breath") {
        $parts += "width = $($sp.Width)"
    }
    if ($sp.Count -gt 0) { $parts += "count = $($sp.Count)" }
    if ($sp.Cond -ne "") { $parts += "cond = `"$($sp.Cond)`"" }
    return ($parts -join ", ")
}

function Set-BookEntry([object]$c, $sp) {
    $text = Read-Text $BOOK
    if (-not $text) { Say "Nao encontrei $BOOK" "Red"; return }
    $nl = Get-Nl $text

    $line = "    spell = `"$($sp.Spell)`", element = `"$($sp.Element)`", shape = `"$($sp.Shape)`""
    $extra = Get-BookParamsText $sp
    if ($extra -ne "") { $line += ", " + $extra }
    $entry = "  [`"$($c.Name)`"] = {" + $nl + $line + $nl + "  },"

    $rx = New-Object System.Text.RegularExpressions.Regex('(\s*\["' + [regex]::Escape($c.Name) + '"\]\s*=\s*\{.*?\},)', 'Singleline')
    if ($rx.IsMatch($text)) {
        $repl = $nl + $entry
        $text = $rx.Replace($text, $repl, 1)
    } else {
        # mantem a lista em ordem alfabetica: entra antes da primeira chave maior
        $insertAt = -1
        foreach ($km in [regex]::Matches($text, '(?m)^[ \t]*\["([^"]+)"\]\s*=')) {
            if ([string]::CompareOrdinal($km.Groups[1].Value, $c.Name) -gt 0) {
                $insertAt = $km.Index
                break
            }
        }
        if ($insertAt -ge 0) {
            $text = $text.Insert($insertAt, $entry + $nl)
        } else {
            $idx = $text.LastIndexOf("}")
            if ($idx -lt 0) { Say "monsterSpellBook.lua estranho - nao achei o fechamento." "Red"; return }
            $head = $text.Substring(0, $idx).TrimEnd()
            $tail = $text.Substring($idx)
            $text = $head + $nl + $entry + $nl + $tail
        }
    }

    Confirm-Write $BOOK
    Write-Text $BOOK $text
    Say "monsterSpellBook.lua atualizado (chave: $($c.Name))." "Green"
}

function Get-ReadySpells {
    $lines = $null
    if (Test-Path -LiteralPath $GEN) {
        $lines = [System.IO.File]::ReadAllLines($GEN, [System.Text.Encoding]::UTF8)
    }
    $out = New-Object System.Collections.ArrayList
    if (-not $lines) { return $out }

    $inSpec = $false
    $buf = $null
    $name = $null
    foreach ($ln in $lines) {
        $t = $ln.Trim()
        if (-not $inSpec) {
            if ($t -match '^SPELLS\s*=\s*\{$') { $inSpec = $true }
            continue
        }
        if ($t -eq "}") { break }

        if ($null -eq $buf) {
            $m = [regex]::Match($t, '^"([^"]+)":\s*dict\($')
            if (-not $m.Success) { continue }
            $name = $m.Groups[1].Value
            $buf = ""
            continue
        }

        $buf += " " + $t
        if ($t.EndsWith("),") -or ($t.EndsWith(")") -and $buf -match 'desc=')) {
            $sp = New-SpellSpec $name $buf
            if ($sp.Spell -ne "") { [void]$out.Add($sp) }
            $buf = $null
            $name = $null
        }
    }
    return $out
}

function New-SpellSpec([string]$monster, [string]$body) {
    $o = [pscustomobject]@{
        Monster = $monster; Spell = ""; Element = ""; Shape = ""
        Radius = 0; Length = 0; Width = 0; Count = 0; Cond = ""
        DmgMin = 0; DmgMax = 0; Interval = 0; Chance = 0; Range = 0; Desc = ""
    }
    $o.Spell   = (Get-Attr $body 'spell')
    $o.Element = (Get-Attr $body 'element')
    $o.Shape   = (Get-Attr $body 'shape')
    $o.Cond    = (Get-Attr $body 'cond')
    $o.Desc    = (Get-Attr $body 'desc')
    foreach ($k in @("radius", "length", "width", "count", "interval", "chance", "range")) {
        $m = [regex]::Match($body, "\b$k=(\d+)")
        if ($m.Success) {
            $v = [int]$m.Groups[1].Value
            if ($k -eq "radius") { $o.Radius = $v }
            elseif ($k -eq "length") { $o.Length = $v }
            elseif ($k -eq "width") { $o.Width = $v }
            elseif ($k -eq "count") { $o.Count = $v }
            elseif ($k -eq "interval") { $o.Interval = $v }
            elseif ($k -eq "chance") { $o.Chance = $v }
            elseif ($k -eq "range") { $o.Range = $v }
        }
    }
    $m = [regex]::Match($body, 'dmg=\((-?\d+),\s*(-?\d+)\)')
    if ($m.Success) {
        $o.DmgMin = [int]$m.Groups[1].Value
        $o.DmgMax = [int]$m.Groups[2].Value
    }
    if ($o.Interval -le 0) { $o.Interval = 3000 }
    if ($o.Chance -le 0) { $o.Chance = 20 }
    if ($o.Range -le 0) { $o.Range = 4 }
    return $o
}

# ============================================================================
#  spell (adicionar / remover / listar)
# ============================================================================
function Show-ReadySpells {
    $specs = @(Get-ReadySpells)
    Write-Head "MAGIAS PRONTAS (tools/gen_monster_spells.py)"
    if ($specs.Count -eq 0) {
        Say "Nao consegui ler a lista em $GEN" "Red"
        return
    }
    $i = 1
    foreach ($sp in $specs) {
        $forma = $sp.Shape
        if ($sp.Radius -gt 0) { $forma += " r$($sp.Radius)" }
        if ($sp.Length -gt 0) { $forma += " c$($sp.Length)" }
        if ($sp.Count -gt 0) { $forma += " x$($sp.Count)" }
        Write-Host ("    [{0,2}] {1,-26} {2,-8} {3,-12} dmg {4}..{5}" -f $i, $sp.Spell, $sp.Element, $forma, $sp.DmgMin, $sp.DmgMax) -ForegroundColor White
        $i++
    }
    Write-Host ""
    Say "1 = ataque elementar simples" "DarkGray"
    Say "Todas usam o motor data/spells/scripts/monster/monsterSpell.lua" "DarkGray"
    Say "e precisam da chave no monsterSpellBook.lua (o editor faz isso)." "DarkGray"
}

function Get-SimpleAttacks {
    return @(
        [pscustomobject]@{ Name = "physical";  Desc = "fisico puro (ignora armadura? nao, bate normal)" }
        [pscustomobject]@{ Name = "fire";      Desc = "fogo" }
        [pscustomobject]@{ Name = "energy";    Desc = "energia" }
        [pscustomobject]@{ Name = "water";     Desc = "agua / afogamento" }
        [pscustomobject]@{ Name = "earth";     Desc = "terra" }
        [pscustomobject]@{ Name = "air";       Desc = "ar" }
        [pscustomobject]@{ Name = "ice";       Desc = "gelo" }
        [pscustomobject]@{ Name = "poison";    Desc = "veneno (condicao)" }
        [pscustomobject]@{ Name = "death";     Desc = "morte" }
        [pscustomobject]@{ Name = "holy";      Desc = "sagrado" }
        [pscustomobject]@{ Name = "lifedrain"; Desc = "drena vida (cura o bicho)" }
        [pscustomobject]@{ Name = "manadrain"; Desc = "drena mana" }
        [pscustomobject]@{ Name = "bleed";     Desc = "sangramento fisico" }
    )
}

function Get-SupportAttacks {
    return @(
        [pscustomobject]@{ Name = "HealSupp";       Desc = "cura em area (spell registrada no spells.xml)" }
        [pscustomobject]@{ Name = "Regen Monster";  Desc = "regeneracao do monstro (script regen.lua)" }
        [pscustomobject]@{ Name = "Mass Blood";     Desc = "explosao de sangue em area" }
        [pscustomobject]@{ Name = "speed";          Desc = "deixa o alvo lento" }
        [pscustomobject]@{ Name = "invisible";      Desc = "o bicho fica invisivel" }
        [pscustomobject]@{ Name = "drunk";          Desc = "deixa o alvo tonto" }
    )
}

function Add-AttackLine([string]$text, [string]$line) {
    $nl = Get-Nl $text

    # 1) ja' existe bloco <attacks> com ataques: entra depois do ultimo
    $block = [regex]::Match($text, '(?s)<attacks>(.*?)</attacks>')
    if ($block.Success) {
        $inner = $block.Groups[1].Value
        $attacks = [regex]::Matches($inner, '<attack\b[^>]*/>')
        if ($attacks.Count -gt 0) {
            $last = $attacks[$attacks.Count - 1]
            # indentacao da linha do ultimo ataque
            $indent = "`t`t"
            $lineStart = $inner.LastIndexOf("`n", $last.Index)
            if ($lineStart -ge 0) {
                $tmp = ""
                for ($k = $lineStart + 1; $k -lt $inner.Length; $k++) {
                    if ($inner[$k] -eq "`t" -or $inner[$k] -eq " ") { $tmp += $inner[$k] } else { break }
                }
                if ($tmp -ne "") { $indent = $tmp }
            }
            # linha seguinte ao ultimo ataque
            $lineEnd = $inner.IndexOf("`n", $last.Index + $last.Length)
            if ($lineEnd -ge 0) {
                return $text.Insert($block.Groups[1].Index + $lineEnd + 1, $indent + $line + $nl)
            }
            return $text.Insert($block.Groups[1].Index + $last.Index + $last.Length, $nl + $indent + $line)
        }
        # bloco existe mas vazio: abre em varias linhas
        $empty = [regex]::Match($text, '(?s)<attacks>\s*</attacks>')
        if ($empty.Success) {
            $newBlock = "<attacks>" + $nl + "`t`t" + $line + $nl + "`t</attacks>"
            return $text.Remove($empty.Index, $empty.Length).Insert($empty.Index, $newBlock)
        }
        $open = [regex]::Match($text, '<attacks>')
        return $text.Insert($open.Index + $open.Length, $nl + "`t`t" + $line)
    }

    # 2) nao existe bloco: cria depois de </flags>
    $flags = [regex]::Match($text, '</flags>')
    if ($flags.Success) {
        $at = $flags.Index + $flags.Length
        $newBlock = $nl + "`t<attacks>" + $nl + "`t`t" + $line + $nl + "`t</attacks>"
        return $text.Substring(0, $at) + $newBlock + $text.Substring($at)
    }
    return $text
}

function Edit-Spells {
    $c = Select-Creature
    if (-not $c) { return }

    while ($true) {
        $text = Read-Text $c.Path
        if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }

        Write-Head "MAGIAS: $($c.Name)"
        $attacks = [regex]::Matches($text, '<attack\b[^>]*/>')
        $i = 1
        foreach ($m in $attacks) {
            Write-Host ("    [{0,2}] {1,-26} min={2,6} max={3,6} interval={4,5} chance={5,3}" -f $i, (Get-Attr $m.Value 'name'), (Get-Attr $m.Value 'min'), (Get-Attr $m.Value 'max'), (Get-Attr $m.Value 'interval'), (Get-Attr $m.Value 'chance')) -ForegroundColor White
            $i++
        }
        Write-Host ""
        $bookEntry = Get-BookEntry $c.Name
        if ($bookEntry -eq "") { Say "monsterSpellBook : (nenhuma entrada para esta criatura)" "DarkGray" }
        else { Say "monsterSpellBook : $bookEntry" "DarkGray" }

        Write-Host ""
        Say "[A] Adicionar magia" "Cyan"
        Say "[R] Remover um ataque" "Cyan"
        Say "[L] Ver a lista de magias prontas" "Cyan"
        Say "[B] Trocar so' a entrada do monsterSpellBook" "Cyan"
        Say "[0] Voltar" "DarkGray"
        $op = Ask-Menu "Opcao"

        if ($op -eq "0" -or $op -eq "") { return }

        if ($op -eq "L") { Show-ReadySpells; continue }

        if ($op -eq "R") {
            if ($attacks.Count -eq 0) { Say "Nao ha ataque para remover." "Red"; continue }
            $n = Ask-Int "Numero do ataque para remover" 0 $false
            if ($n -le 0 -or $n -gt $attacks.Count) { continue }
            $m = $attacks[$n - 1]
            $start = $text.LastIndexOf("`n", $m.Index)
            if ($start -lt 0) { $start = 0 } else { $start = $start + 1 }
            $end = $text.IndexOf("`n", $m.Index + $m.Length)
            if ($end -lt 0) { $end = $text.Length } else { $end = $end + 1 }
            $text = $text.Remove($start, $end - $start)
            Confirm-Write $c.Path
            Write-Text $c.Path $text
            Say "Ataque removido." "Green"
            continue
        }

        if ($op -eq "B") {
            $specs = @(Get-ReadySpells)
            if ($specs.Count -eq 0) { continue }
            Show-ReadySpells
            $n = Ask-Int "Numero da magia" 0 $false
            if ($n -le 0 -or $n -gt $specs.Count) { continue }
            Set-BookEntry $c $specs[$n - 1]
            continue
        }

        if ($op -eq "A") {
            Write-Host ""
            Say "[1] Magia assinatura (a lista pronta - tem formato de area)" "Cyan"
            Say "[2] Ataque elementar simples (sem formato de area)" "Cyan"
            Say "[3] Suporte (cura, regen, speed...)" "Cyan"
            Say "[0] Voltar" "DarkGray"
            $grp = Ask-Menu "Grupo"

            if ($grp -eq "0") { continue }

            $spellName = ""
            $spec = $null

            if ($grp -eq "1") {
                $specs = @(Get-ReadySpells)
                if ($specs.Count -eq 0) { continue }
                Write-Host ""
                $j = 1
                foreach ($sp in $specs) {
                    $forma = $sp.Shape
                    if ($sp.Radius -gt 0) { $forma += " r$($sp.Radius)" }
                    if ($sp.Length -gt 0) { $forma += " c$($sp.Length)" }
                    if ($sp.Count -gt 0) { $forma += " x$($sp.Count)" }
                    Write-Host ("    [{0,2}] {1,-26} {2,-8} {3,-12} dmg {4}..{5}" -f $j, $sp.Spell, $sp.Element, $forma, $sp.DmgMin, $sp.DmgMax) -ForegroundColor White
                    $j++
                }
                Write-Host ""
                $n = Ask-Int "Numero da magia (0 = voltar)" 0 $false
                if ($n -le 0 -or $n -gt $specs.Count) { continue }
                $spec = $specs[$n - 1]
                $spellName = $spec.Spell

                $defaultAvg = [int]((([math]::Abs($spec.DmgMin) + [math]::Abs($spec.DmgMax)) / 2))
                Write-Host ""
                Say "A magia vira <attack name=`"$spellName`" min=-X max=-Y/> no xml." "DarkGray"
                Say "O servidor tira o dano desse min/max (a media vira 80% e 120%)." "DarkGray"
                $avg = Ask-Int "Dano medio por acerto" $defaultAvg $false
                if ($avg -le 0) { continue }
                $min = [int][math]::Floor($avg * 0.8)
                $max = [int][math]::Ceiling($avg * 1.2)

                $intv = Ask-Int "Interval (ms)" $spec.Interval $false
                $chance = Ask-Int "Chance (%)" $spec.Chance $false
                $range = Ask-Int "Range (sqm)" $spec.Range $false

                Write-Host ""
                Say "Magia    : $spellName ($($spec.Element) / $($spec.Shape))" "Green"
                Say "Dano     : min=-$min max=-$max (media $avg)" "Green"
                Say "Interval : $intv   Chance: $chance%   Range: $range" "Green"
                if (-not (Ask-Yes "Aplicar?" "S")) { continue }

                $line = "<attack name=`"$spellName`" interval=`"$intv`" chance=`"$chance`" range=`"$range`" min=`"-$min`" max=`"-$max`"/>"
                $text = Add-AttackLine $text $line
                Confirm-Write $c.Path
                Write-Text $c.Path $text
                Say "Attack adicionado." "Green"

                $old = Get-BookEntry $c.Name
                if ($old -ne "") {
                    Write-Host ""
                    Say "ATENCAO: esta criatura ja tinha entrada no monsterSpellBook:" "Yellow"
                    Say $old "DarkGray"
                    Say "O motor usa UMA entrada por criatura (o formato vale para todas as" "Yellow"
                    Say "magias dela que usam o monsterSpell.lua). Ela sera substituida." "Yellow"
                    if (-not (Ask-Yes "Substituir a entrada?" "S")) { continue }
                }
                Set-BookEntry $c $spec
                continue
            }

            if ($grp -eq "2" -or $grp -eq "3") {
                $list = if ($grp -eq "2") { @(Get-SimpleAttacks) } else { @(Get-SupportAttacks) }
                Write-Host ""
                $j = 1
                foreach ($s in $list) {
                    Write-Host ("    [{0,2}] {1,-14} {2}" -f $j, $s.Name, $s.Desc) -ForegroundColor White
                    $j++
                }
                Write-Host ""
                $n = Ask-Int "Numero (0 = voltar)" 0 $false
                if ($n -le 0 -or $n -gt $list.Count) { continue }
                $spellName = $list[$n - 1].Name

                $avg = Ask-Int "Dano medio (positivo = cura, ex: healing)" 50 $true
                $min = [int][math]::Floor($avg * 0.8)
                $max = [int][math]::Ceiling($avg * 1.2)
                $intv = Ask-Int "Interval (ms)" 3000 $false
                $chance = Ask-Int "Chance (%)" 20 $false
                $range = Ask-Int "Range (sqm, 0 = melee)" 1 $false

                $extra = ""
                if ($spellName -eq "healing") { $extra = " self=`"1`"" }
                if ($spellName -eq "speed") { $extra = " duration=`"10000`"" }
                # cura usa valor positivo; o resto usa negativo
                if ($spellName -eq "healing" -or $spellName -eq "HealSupp") {
                    $line = "<attack name=`"$spellName`" interval=`"$intv`" chance=`"$chance`" min=`"$min`" max=`"$max`"$extra/>"
                } else {
                    $line = "<attack name=`"$spellName`" interval=`"$intv`" chance=`"$chance`" range=`"$range`" min=`"-$min`" max=`"-$max`"$extra/>"
                }

                Say "Linha: $line" "Green"
                if (-not (Ask-Yes "Aplicar?" "S")) { continue }
                $text = Add-AttackLine $text $line
                Confirm-Write $c.Path
                Write-Text $c.Path $text
                Say "Attack adicionado." "Green"
                continue
            }

            Say "Opcao invalida." "Red"
            continue
        }

        Say "Opcao invalida." "Red"
    }
}

# ============================================================================
#  rename
# ============================================================================
function Rename-Creature {
    $c = Select-Creature
    if (-not $c) { return }

    Write-Head "RENOMEAR: $($c.Name)"
    $new = Ask-Text "Novo nome"
    if ([string]::IsNullOrWhiteSpace($new)) { return }
    if ($new -match '["<>]') { Say "O nome nao pode ter aspas nem < >." "Red"; return }

    $all = @(Get-Creatures)
    if ($all | Where-Object { $_.Name -eq $new }) { Say "Ja existe uma criatura chamada '$new'." "Red"; return }

    # quantas vezes aparece nos spawns?
    $spawnFiles = @(Get-ChildItem -LiteralPath $WORLD_DIR -Filter "*.xml" -File)
    $spawnHits = 0
    foreach ($f in $spawnFiles) {
        $t = Read-Text $f.FullName
        if ($t) { $spawnHits += [regex]::Matches($t, '<monster\s+name="' + [regex]::Escape($c.Name) + '"').Count }
    }

    Write-Host ""
    Say "Renomear  : $($c.Name)  ->  $new" "Green"
    Say "Xml       : $($c.Rel) -> $(Split-Path -Leaf ($c.Rel.Replace($c.Name, $new)))"
    Say "Spawns    : $spawnHits entrada(s) em $($spawnFiles.Count) arquivo(s)" "Green"
    if ((Get-BookEntry $c.Name) -ne "") { Say "Livro     : a chave [$($c.Name)] sera renomeada" "Green" }
    Write-Host ""
    if (-not (Ask-Yes "Confirmar renome?" "S")) { return }

    # 1. xml da criatura
    $text = Read-Text $c.Path
    if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }
    $text = Set-TagAttr $text '(?s)<monster\b[^>]*>' 'name' $new
    Confirm-Write $c.Path
    Write-Text $c.Path $text

    # 2. renomeia o arquivo
    $newFile = Join-Path (Split-Path -Parent $c.Path) "$new.xml"
    if (Test-Path -LiteralPath $newFile) {
        Say "Ja existe um arquivo $new.xml nesta pasta - o arquivo NAO foi renomeado." "Yellow"
    } else {
        Move-Item -LiteralPath $c.Path -Destination $newFile
        Say "Arquivo renomeado: $newFile" "Green"
    }
    # monsters.xml usa / como separador de pasta - mantenha o padrao
    $newRel = (Split-Path -Parent $c.Rel).Replace("\", "/") + "/" + "$new.xml"
    if ((Split-Path -Parent $c.Rel) -eq "") { $newRel = "$new.xml" }

    # 3. monsters.xml
    $reg = Read-Text $REGISTRY
    $oldLine = '<monster name="' + $c.Name + '" file="' + $c.Rel + '"/>'
    $newLine = '<monster name="' + $new + '" file="' + $newRel + '"/>'
    if ($reg -match [regex]::Escape($oldLine)) {
        Confirm-Write $REGISTRY
        $reg = [regex]::Replace($reg, [regex]::Escape($oldLine), { param($mm) $newLine }, 1)
        Write-Text $REGISTRY $reg
        Say "monsters.xml atualizado." "Green"
    } else {
        Say "ATENCAO: nao achei a linha exata em monsters.xml (edite na mao)." "Yellow"
        Say $oldLine "DarkGray"
    }

    # 4. spawns
    $total = 0
    foreach ($f in $spawnFiles) {
        $t = Read-Text $f.FullName
        if (-not $t) { continue }
        $n = [regex]::Matches($t, '<monster\s+name="' + [regex]::Escape($c.Name) + '"').Count
        if ($n -gt 0) {
            $newT = [regex]::Replace($t, '<monster(\s+)name="' + [regex]::Escape($c.Name) + '"', { param($mm) '<monster' + $mm.Groups[1].Value + 'name="' + $new + '"' })
            Confirm-Write $f.FullName
            Write-Text $f.FullName $newT
            $total += $n
            Say "  $($f.Name): $n entrada(s)" "Green"
        }
    }
    Say "Spawns atualizados: $total" "Green"

    # 5. livro de spells
    $bookText = Read-Text $BOOK
    if ($bookText -match ('\["' + [regex]::Escape($c.Name) + '"\]')) {
        Confirm-Write $BOOK
        $bookText = [regex]::Replace($bookText, '\["' + [regex]::Escape($c.Name) + '"\]', '["' + $new + '"]', 1)
        Write-Text $BOOK $bookText
        Say "monsterSpellBook.lua atualizado." "Green"
    }

    # 6. outras referencias (aviso)
    Write-Host ""
    Say "Procurando outras referencias a '$($c.Name)' em data\... (pode demorar)" "DarkGray"
    $hits = @()
    try {
        $search = Get-ChildItem -LiteralPath (Join-Path $SERVER_ROOT "data") -Recurse -Include *.lua -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -ne ".bak" -and -not $_.Name.EndsWith(".bak") } |
            Select-String -SimpleMatch $c.Name -List -ErrorAction SilentlyContinue
        $hits = @($search | Select-Object -First 10)
    } catch { }

    if ($hits.Count -eq 0) {
        Say "Nenhuma outra referencia encontrada." "Green"
    } else {
        Say "Ainda existem referencias (busca simples por pedaco do nome -" "Yellow"
        Say "pode ser so' 'Mud Bee' batendo com 'Bee'):" "Yellow"
        foreach ($h in $hits) { Say "  $($h.Path)" "DarkGray" }
    }
}

# ============================================================================
#  duplicate
# ============================================================================
function Copy-Creature {
    $c = Select-Creature
    if (-not $c) { return }

    Write-Head "DUPLICAR: $($c.Name)"
    $new = Ask-Text "Nome da nova criatura"
    if ([string]::IsNullOrWhiteSpace($new)) { return }
    if ($new -match '["<>]') { Say "O nome nao pode ter aspas nem < >." "Red"; return }

    $all = @(Get-Creatures)
    if ($all | Where-Object { $_.Name -eq $new }) { Say "Ja existe '$new'." "Red"; return }

    $folder = Split-Path -Parent $c.Rel
    $newRel = if ($folder -eq "") { "$new.xml" } else { "$folder/$new.xml" }
    $newPath = Join-Path $MONSTER_DIR ($newRel -replace '/', '\')

    if (Test-Path -LiteralPath $newPath) { Say "Ja existe o arquivo $newPath" "Red"; return }

    $text = Read-Text $c.Path
    if (-not $text) { Say "Nao encontrei $($c.Path)" "Red"; return }
    $text = Set-TagAttr $text '(?s)<monster\b[^>]*>' 'name' $new
    Write-Text $newPath $text
    Say "Criado: $newPath" "Green"

    $reg = Read-Text $REGISTRY
    $nl = Get-Nl $reg
    $oldLine = '<monster name="' + $c.Name + '" file="' + $c.Rel + '"/>'
    $newLine = '<monster name="' + $new + '" file="' + $newRel + '"/>'
    if ($reg -match [regex]::Escape($oldLine)) {
        Confirm-Write $REGISTRY
        $reg = [regex]::Replace($reg, [regex]::Escape($oldLine), { param($mm) $oldLine + $nl + "  " + $newLine }, 1)
        Write-Text $REGISTRY $reg
        Say "monsters.xml atualizado." "Green"
    } else {
        Say "ATENCAO: nao achei a linha em monsters.xml - adicione na mao:" "Yellow"
        Say "  $newLine" "DarkGray"
    }

    $bookText = Read-Text $BOOK
    if ($bookText -match ('\["' + [regex]::Escape($c.Name) + '"\]')) {
        $block = Get-BookBlock $c.Name
        $copy = $block -replace ('\["' + [regex]::Escape($c.Name) + '"\]'), ('["' + $new + '"]')
        $idx = $bookText.LastIndexOf("}")
        $bookText = $bookText.Substring(0, $idx).TrimEnd() + $nl + "  " + $copy.Trim() + $nl + $bookText.Substring($idx)
        Confirm-Write $BOOK
        Write-Text $BOOK $bookText
        Say "monsterSpellBook.lua: entrada copiada." "Green"
    }

    Say "Nao esqueca de por a criatura em algum spawn (ou use /m $new como GM)." "DarkGray"
}

# ============================================================================
#  main
# ============================================================================
if (-not (Test-Path -LiteralPath $REGISTRY)) {
    Say "Nao encontrei $REGISTRY" "Red"
    Say "Confira se a pasta do server esta correta." "Red"
    exit 1
}

switch ($Mode.ToLower()) {
    "list"      { Show-CreatureList }
    "show"      { $c = Select-Creature; if ($c) { Show-Ficha $c } }
    "status"    { Edit-Status }
    "damage"    { Edit-Damage }
    "loot"      { Edit-Loot }
    "outfit"    { Edit-Outfit }
    "rename"    { Rename-Creature }
    "spell"     { Edit-Spells }
    "duplicate" { Copy-Creature }
    "spells"    { Show-ReadySpells }
    default     { Show-CreatureList }
}
