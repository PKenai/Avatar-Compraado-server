@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0.."

set "LISTA=%~dp0lista_criaturas.txt"
set "RESP=%~dp0respostas_avatar.txt"
if not exist "%RESP%" type nul > "%RESP%"

echo ============================================================
echo   CRIADOR DE CRIATURAS AVATAR
echo   Responda uma criatura por vez. Nome vazio = pular.
echo   As respostas ja dadas nao sao perguntadas de novo.
echo ============================================================
echo.

for /f "usebackq tokens=1-7 delims=;" %%a in ("%LISTA%") do (
    set "lvl=%%a"
    set "guia=%%b"
    set "file=%%c"
    set "ghp=%%d"
    set "xph=%%e"
    set "goldh=%%f"
    set "nota=%%g"

    findstr /C:";%%c;" "%RESP%" >nul 2>&1
    if not errorlevel 1 (
        echo   [ja respondido] %%b
    ) else (
        echo ------------------------------------------------------------
        echo  Criatura: %%b   ^|  Nivel: %%a+   ^|  Vida no global: ~%%d
        if "%%e"=="0" (echo  Exp/hora: -- ) else (echo  Exp/hora: %%e )
        if "%%f"=="0-0" (echo  Gold/kill: -- ) else (echo  Gold/kill: %%f )
        if not "%%g"=="" echo  %%g
        echo ------------------------------------------------------------
        set "nome="
        set /p "nome=  Novo nome pro Avatar (Enter=vazio p/ pular): "
        if "!nome!"=="" (
            echo    ^(pulada - sem resposta^)
        ) else (
            set "lk="
            set /p "lk=  Looktype (id da aparencia, Enter=manter o atual): "
            echo !nome!;!lk!;%%c;>>"%RESP%"
            echo    - registrado: !nome!  (looktype: !lk!)
        )
        echo.
    )
)

echo.
echo ============================================================
echo  Gerando os monstros novos em data\monster\Oficial monsters avatar ...
echo ============================================================
python "%~dp0gerar_criaturas.py"
echo.
echo  Pronto! Confira o resumo acima. Para responder o restante,
echo  rode este .bat de novo (as ja respondidas serao puladas).
echo.
pause
