@echo off
rem ===========================================================================
rem  forca_das_magias.bat - forca das magias NO SERVIDOR DA VPS
rem ===========================================================================
rem
rem  Clique duas vezes neste arquivo: abre a lista de magias e o ajuste vai para
rem  o servidor que esta' rodando na VPS (a pasta da Area de Trabalho do
rem  Administrador). Voce edita daqui e o resultado aparece la'. O caminho e':
rem
rem    1. puxa o data\lib\201-spellsExausted.lua de la' -- ou seja, o que
rem       esta' valendo no ar agora;
rem    2. grava aqui no seu PC o novo atk (dano) ou heal (cura);
rem    3. devolve o arquivo para a VPS;
rem    4. o proprio servidor de la' recarrega as magias sozinho (globalevent
rem       SpellPowerHotReload) -- sem restart e sem parar o servidor.
rem
rem  Precisa da credencial da VPS (a mesma que o subir_vps.bat ja' salvou).
rem
rem  Por linha de comando aceita tudo o que o tool aceita:
rem    forca_das_magias.bat --list
rem    forca_das_magias.bat --spell "fire wave" --set 25
rem    forca_das_magias.bat --spell "air ball" --set -15
rem    forca_das_magias.bat --undo
rem
rem  --local volta ao comportamento antigo: mexe SO' no arquivo desta maquina e
rem  nao recarrega nada (aqui nao tem servidor rodando). Serve para preparar o
rem  datapack antes de subir com o subir_vps.bat:
rem    forca_das_magias.bat --local --list
rem
rem  Precisa de Python 3 no PATH (so' a biblioteca padrao, nada para instalar).
rem ===========================================================================

chcp 65001 >nul
setlocal

rem Alvo padrao: a VPS. Quem quiser so' o arquivo local passa --local.
set "MODO=--vps"
if not "%~1"=="" echo %* | findstr /i /c:"--local" >nul
if not "%~1"=="" if not errorlevel 1 set "MODO="

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

"%PY%" "%~dp0spell_power_tool.py" %MODO% %*
if errorlevel 1 pause
endlocal
