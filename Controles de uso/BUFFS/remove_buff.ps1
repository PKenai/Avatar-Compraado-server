# ============================================
# Remover Buff - Avatar Server
# ============================================

param(
    [string]$ServerRoot = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
    $SERVER_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $SERVER_ROOT = $ServerRoot.TrimEnd('\') + '\'
}
$BUFF_H   = Join-Path $SERVER_ROOT "sources\buff.h"
$BUFF_LUA = Join-Path $SERVER_ROOT "data\lib\300-buffs.lua"

# ============================================
# Listar buffs registrados
# ============================================
function Show-Buffs {
    $luaContent = Get-Content $BUFF_LUA -Raw
    $matches = [regex]::Matches($luaContent, 'registerBuffType\((\d+),\s*"([^"]+)",\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)",\s*(true|false),\s*(\d+),\s*(-?\d+),\s*(true|false)')

    Write-Host ""
    Write-Host "  === BUFFS REGISTRADOS ===" -ForegroundColor Yellow
    Write-Host ""

    foreach ($m in $matches) {
        $id     = $m.Groups[1].Value
        $name   = $m.Groups[2].Value
        $icon   = $m.Groups[4].Value
        $debuff = $m.Groups[9].Value
        $tipo   = if ($debuff -eq "true") { "DEBUFF" } else { "BUFF  " }
        $color  = if ($debuff -eq "true") { "Red" } else { "Green" }

        Write-Host "  [" -NoNewline -ForegroundColor DarkGray
        Write-Host $id.PadLeft(2, ' ') -NoNewline -ForegroundColor White
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host $name -NoNewline -ForegroundColor White
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $tipo -NoNewline -ForegroundColor $color
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $icon -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "  Total: $($matches.Count) buffs" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================
# MAIN
# ============================================
Write-Host ""
Write-Host "  === REMOVER BUFF ===" -ForegroundColor Yellow
Write-Host ""

Show-Buffs

Write-Host "  ID do buff para remover: " -NoNewline -ForegroundColor Cyan
$removeId = Read-Host

if (-not ($removeId -match '^\d+$')) {
    Write-Host ""
    Write-Host "  [ERRO] ID invalido!" -ForegroundColor Red
    return
}

$removeId = [int]$removeId

# Ler buff.h
$buffHContent = Get-Content $BUFF_H -Raw
$enumMatch = [regex]::Match($buffHContent, "BUFF_(\w+)\s*=\s*$removeId")

if (-not $enumMatch.Success) {
    Write-Host ""
    Write-Host "  [ERRO] ID $removeId nao encontrado no buff.h!" -ForegroundColor Red
    return
}

$enumName = $enumMatch.Groups[1].Value
Write-Host ""
Write-Host "  Encontrado: BUFF_$enumName = $removeId" -ForegroundColor White

# Ler lua
$luaContent = Get-Content $BUFF_LUA -Raw
$luaMatch = [regex]::Match($luaContent, "(--[^\n]*\n)?registerBuffType\($removeId,.*")

if ($luaMatch.Success) {
    Write-Host "  Lua: $($luaMatch.Value.Trim())" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Tem certeza que deseja remover? (S/N): " -NoNewline -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Host ""
    Write-Host "  Cancelado." -ForegroundColor Red
    return
}

# Remover do buff.h
$buffHContent = $buffHContent -replace "\r?\n`tBUFF_$enumName\s*=\s*$removeId,?", ""
[System.IO.File]::WriteAllText($BUFF_H, $buffHContent, [System.Text.Encoding]::UTF8)
Write-Host ""
Write-Host "  [OK] Removido do buff.h: BUFF_$enumName" -ForegroundColor Green

# Remover do lua
$luaContent = $luaContent -replace "(?m)^--[^\n]*\nregisterBuffType\($removeId,.*\r?\n?", ""
[System.IO.File]::WriteAllText($BUFF_LUA, $luaContent, [System.Text.Encoding]::UTF8)
Write-Host "  [OK] Removido do 300-buffs.lua" -ForegroundColor Green

Write-Host ""
Write-Host "  === BUFF REMOVIDO! ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Compile o servidor para aplicar." -ForegroundColor Yellow
Write-Host ""
