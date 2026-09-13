@echo off
chcp 65001 >nul 2>&1
title Criaturas - Avatar Server

set "SCRIPT_DIR=%~dp0"
set "SERVER_ROOT=%SCRIPT_DIR%..\.."
rem NAO passe a barra final no -ServerRoot: o comand line do Windows trata
rem \" como aspas escapadas e o caminho chega quebrado no PowerShell.
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%creature_util.ps1" -ServerRoot "%SERVER_ROOT%""

if not exist "%SERVER_ROOT%\data\monster\monsters.xml" goto semserver

:menu
cls
echo.
echo  ==================================================
echo    CRIATURAS - Avatar Server
echo  ==================================================
echo.
echo    [1] Listar / buscar criaturas
echo    [2] Ver ficha da criatura (vida, dano, loot, magia)
echo    [3] Alterar status (vida, xp, speed, armor, defense)
echo    [4] Alterar dano de um ataque existente
echo    [5] Loot (adicionar / remover item)
echo    [6] Outfit (trocar o look)
echo    [7] Magias (adicionar / remover / ver lista pronta)
echo    [8] Renomear criatura (xml + monsters.xml + spawns)
echo    [9] Duplicar criatura (criar uma nova a partir de outra)
echo    [0] Sair
echo.
set "OP="
set /p "OP=  Escolha uma opcao: "

if "%OP%"=="1" goto modolist
if "%OP%"=="2" goto modoshow
if "%OP%"=="3" goto modostatus
if "%OP%"=="4" goto mododamage
if "%OP%"=="5" goto modoloot
if "%OP%"=="6" goto modooutfit
if "%OP%"=="7" goto modospell
if "%OP%"=="8" goto modorename
if "%OP%"=="9" goto mododuplicate
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
:mododamage
%PS% -Mode damage
goto volta
:modoloot
%PS% -Mode loot
goto volta
:modooutfit
%PS% -Mode outfit
goto volta
:modospell
%PS% -Mode spell
goto volta
:modorename
%PS% -Mode rename
goto volta
:mododuplicate
%PS% -Mode duplicate
goto volta

:volta
echo.
pause
goto menu

:semserver
echo.
echo   [ERRO] Nao encontrei data\monster\monsters.xml em:
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
