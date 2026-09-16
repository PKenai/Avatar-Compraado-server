@echo off
chcp 65001 >nul 2>&1
title Bosses ALPHA - Avatar Server

set "SCRIPT_DIR=%~dp0"
set "SERVER_ROOT=%SCRIPT_DIR%..\.."
rem NAO passe a barra final no -ServerRoot: o comand line do Windows trata
rem \" como aspas escapadas e o caminho chega quebrado no PowerShell.
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%boss_util.ps1" -ServerRoot "%SERVER_ROOT%""

if not exist "%SERVER_ROOT%\data\lib\bossSystem.lua" goto semserver

:menu
cls
echo.
echo  ==================================================
echo    BOSSES ALPHA - Avatar Server
echo  ==================================================
echo.
echo    [1]  Listar bosses (meta, luva, % real de drop)
echo    [2]  Ver ficha do boss (stats, ataques, loot)
echo    [3]  Alterar status (vida, xp, speed, armor, defense)
echo    [4]  Loot (chance da luva / crystal coin)
echo    [5]  Multiplicadores do gerador (tuning)
echo    [6]  Metas de kills da task diaria
echo    [7]  Sorteio diario (incluir / excluir criaturas)
echo    [8]  Tile do portal (itemID / actionID)
echo    [9]  Regerar todos os bosses (roda o gerador)
echo    [10] Diagnostico do sistema
echo    [0]  Sair
echo.
set "OP="
set /p "OP=  Escolha uma opcao: "

if "%OP%"=="1" goto modolist
if "%OP%"=="2" goto modoshow
if "%OP%"=="3" goto modostatus
if "%OP%"=="4" goto modoloot
if "%OP%"=="5" goto modotuning
if "%OP%"=="6" goto modokills
if "%OP%"=="7" goto modopool
if "%OP%"=="8" goto modotiles
if "%OP%"=="9" goto modoregen
if "%OP%"=="10" goto mododiag
if "%OP%"=="0" goto fim
echo.
echo   Opcao invalida.
pause
goto menu

:modolist
%PS% -Mode list
goto volta
:modoshow
%PS% -Mode show
goto volta
:modostatus
%PS% -Mode status
goto volta
:modoloot
%PS% -Mode loot
goto volta
:modotuning
%PS% -Mode tuning
goto volta
:modokills
%PS% -Mode kills
goto volta
:modopool
%PS% -Mode pool
goto volta
:modotiles
%PS% -Mode tiles
goto volta
:modoregen
%PS% -Mode regen
goto volta
:mododiag
%PS% -Mode diag
goto volta

:volta
echo.
pause
goto menu

:semserver
echo.
echo   [ERRO] Nao encontrei data\lib\bossSystem.lua em:
echo   %SERVER_ROOT%
echo   Confira se a pasta Controles de uso esta dentro da pasta do server.
echo.
pause
exit /b 1

:fim
echo.
echo   Ate mais!
timeout /t 1 >nul
exit /b
