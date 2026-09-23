@echo off
rem ===========================================================================
rem  forca_das_magias.bat - abre a interface de ajuste de forca das magias
rem ===========================================================================
rem
rem  Clique duas vezes neste arquivo para abrir a lista de magias. Ele chama
rem  tools/spell_power_tool.py, que grava o atk da magia escolhida em
rem  data/lib/201-spellsExausted.lua, e o servidor recarrega as magias sozinho
rem  (globalevent SpellPowerHotReload, sem restart).
rem
rem  Tambem funciona por linha de comando, passando os parametros adiante:
rem    forca_das_magias.bat --list
rem    forca_das_magias.bat --spell "fire whip" --set 25
rem    forca_das_magias.bat --spell "air ball" --set -15
rem    forca_das_magias.bat --undo
rem
rem  Precisa de Python 3 no PATH (so' a biblioteca padrao, nada para instalar).
rem
chcp 65001 >nul
setlocal

set "PY="
where python >nul 2>nul
if not errorlevel 1 set "PY=python"
if not defined PY (
    where py >nul 2>nul
    if not errorlevel 1 set "PY=py"
)
if not defined PY (
    echo Python 3 nao encontrado no PATH.
    echo Instale o Python 3 marcando "Add python.exe to PATH" e abra de novo.
    pause
    exit /b 1
)

"%PY%" "%~dp0spell_power_tool.py" %*
if errorlevel 1 pause
endlocal
