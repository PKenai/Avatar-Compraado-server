@echo off
chcp 65001 >nul 2>&1
title Buff Manager - Avatar Server
color 0A

echo.
echo  ╔══════════════════════════════════════════╗
echo  ║     BUFF MANAGER - Avatar Server        ║
echo  ╠══════════════════════════════════════════╣
echo  ║  [1] Adicionar novo buff                ║
echo  ║  [2] Listar buffs registrados           ║
echo  ║  [3] Remover buff                       ║
echo  ║  [4] Listar imagens disponiveis         ║
echo  ║  [5] Abrir pasta sources                ║
echo  ║  [S] Sair                               ║
echo  ╚══════════════════════════════════════════╝
echo.

REM Detectar caminho do script (Controles de uso/BUFFS/)
set "SCRIPT_DIR=%~dp0"
set "SERVER_ROOT=%SCRIPT_DIR%..\..\"

if not exist "%SERVER_ROOT%sources\buff.h" (
    echo  [ERRO] Nao encontrei sources\buff.h em %SERVER_ROOT%
    echo  Verifique a estrutura de pastas.
    echo.
    pause
    exit /b 1
)

set /p "choice=  Escolha uma opcao: "

if "%choice%"=="1" goto ADD
if "%choice%"=="2" goto LIST
if "%choice%"=="3" goto REMOVE
if "%choice%"=="4" goto ICONS
if "%choice%"=="5" goto OPEN
if /i "%choice%"=="S" goto EOF
echo.
echo  Opcao invalida!
timeout /t 2 >nul
goto EOF

:ADD
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%add_buff.ps1" -ServerRoot "%SERVER_ROOT%"
goto EOF

:LIST
echo.
powershell -ExecutionPolicy Bypass -NoProfile -Command "& '%SCRIPT_DIR%add_buff.ps1' -ListOnly -ServerRoot '%SERVER_ROOT%'"
goto EOF

:REMOVE
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%remove_buff.ps1" -ServerRoot "%SERVER_ROOT%"
goto EOF

:ICONS
echo.
powershell -ExecutionPolicy Bypass -NoProfile -Command "& '%SCRIPT_DIR%add_buff.ps1' -IconsOnly -ServerRoot '%SERVER_ROOT%'"
goto EOF

:OPEN
explorer "%SERVER_ROOT%sources"
goto EOF

:EOF
echo.
echo  Pressione qualquer tecla para fechar...
pause >nul
