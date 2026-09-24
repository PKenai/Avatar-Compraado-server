@echo off
rem =====================================================================
rem  subir_vps.bat - envia o servidor COMPILADO aqui para a VPS.
rem
rem  Fluxo normal:
rem    1. compila com o compilar.bat
rem    2. roda este aqui -> o exe novo (e o pdb) vao para C:\Avatar na VPS,
rem       o servidor e parado, os arquivos trocados e o servidor sobe de novo.
rem
rem  Uso:
rem    subir_vps.bat              exe + pdb + dlls que faltarem, reinicia
rem    subir_vps.bat /data        envia tambem data\ e mods\ que mudaram
rem    subir_vps.bat /onlydata    so os dados, sem mexer no exe
rem    subir_vps.bat /norestart   envia sem parar/reiniciar o servidor
rem    subir_vps.bat /check       so mostra o que seria enviado
rem    subir_vps.bat /nopause     nao espera tecla no final
rem
rem  Na primeira execucao ele pede a senha da VPS e guarda cifrada pelo
rem  Windows (nunca no projeto). Para trocar a senha, apague:
rem    %USERPROFILE%\.avatar-vps-cred.xml
rem =====================================================================

setlocal
set "PS1=%~dp0tools\subir_vps.ps1"
set "RC=0"
set "ARGS=%*"
set "PAUSA=1"

if /i "%~1"=="/?"      goto ajuda
if /i "%~1"=="-?"      goto ajuda
if /i "%~1"=="/h"      goto ajuda
if /i "%~1"=="-h"      goto ajuda
if /i "%~1"=="--help"  goto ajuda

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="/nopause" set "PAUSA="
if /i "%~1"=="-nopause" set "PAUSA="
shift
goto parse
:parsed

if not exist "%PS1%" (
  echo [ERRO] Nao encontrei o script:
  echo        %PS1%
  echo        Coloque este .bat na raiz do servidor, junto da pasta tools.
  if defined PAUSA pause
  exit /b 1
)

echo ============================================================
echo   ENVIAR O SERVIDOR COMPILADO PARA A VPS
echo ============================================================

if defined ARGS (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Flags "%ARGS%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
)
set "RC=%errorlevel%"

echo.
if not "%RC%"=="0" echo [ERRO] terminou com codigo %RC%
if defined PAUSA pause
exit /b %RC%

:ajuda
echo.
echo   subir_vps.bat              envia exe + pdb + dlls que faltarem e reinicia
echo   subir_vps.bat /data        envia tambem os arquivos de data e mods alterados
echo   subir_vps.bat /onlydata    envia so os dados, sem mexer no exe
echo   subir_vps.bat /norestart   envia sem parar ou reiniciar o servidor
echo   subir_vps.bat /check       so mostra o que seria enviado, nao envia nada
echo   subir_vps.bat /nopause     nao espera tecla no final (para automacao)
echo.
echo   Compile primeiro com o compilar.bat e depois rode este.
echo   Na primeira vez ele pede a senha da VPS e guarda cifrada no seu Windows.
echo.
pause
exit /b 0
