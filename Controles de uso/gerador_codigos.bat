@echo off
setlocal enabledelayedexpansion
title Gerenciador de Codigos - Avatar

rem ============================================================
rem  GERENCIADOR DE CODIGOS - AVATAR
rem
rem  [1] Gera um codigo novo (salva direto no servidor)
rem  [2] Lista todos os codigos ativos
rem  [3] Deleta um codigo
rem  [0] Sair
rem
rem  Arquivo de codigos: ..\data\lib\codes_data.lua
rem  O servidor rele esse arquivo a cada resgate, entao o codigo
rem  entra em vigor IMEDIATAMENTE, sem reiniciar.
rem
rem  Acentos sao aceitos (PROMOCAO == PROMOCAO): o codigo digitado
rem  e convertido para letras normais antes de salvar.
rem ============================================================

set "OUTFILE=%~dp0codigos_gerados.txt"
set "COUNTERFILE=%~dp0storage_counter.txt"
set "CODESFILE=%~dp0..\data\lib\codes_data.lua"
set "UTILPS=%~dp0codegen_util.ps1"
set "TMPIN=%TEMP%\codegen_in.txt"
set "TMPOUT=%TEMP%\codegen_fold.txt"
set "TMPEXPIRE=%TEMP%\codegen_expire.txt"
set "TMPDEL=%TEMP%\codegen_del.txt"
set "TMPSTORAGE=%TEMP%\codegen_storage.txt"

rem ---- proximo storage livre (evita repetir) ----
rem  Usa for /f (nao set /p < arquivo): ler arquivo com set /p <
rem  quebra as leituras de teclado seguintes no cmd.
set "STORAGE=920100"
if exist "%COUNTERFILE%" (
    for /f "usebackq delims=" %%s in ("%COUNTERFILE%") do set "STORAGE=%%s"
)
if "%STORAGE%"=="" set "STORAGE=920100"

rem ---- garante que o arquivo de codigos existe ----
if not exist "%CODESFILE%" (
    >  "%CODESFILE%" echo -- Arquivo de codigos - gerenciado pelo gerador_codigos.bat
    >> "%CODESFILE%" echo CodeRedeemData = {}
    >> "%CODESFILE%" echo.
)

:menu
echo.
echo ============================================
echo    GERENCIADOR DE CODIGOS - AVATAR
echo ============================================
echo  [1] Gerar novo codigo
echo  [2] Ver todos os codigos ativos
echo  [3] Deletar um codigo
echo  [0] Sair
echo.
set "OP="
set /p "OP=Escolha uma opcao: "
if "%OP%"=="1" goto novo_codigo
if "%OP%"=="2" goto ver_codigos
if "%OP%"=="3" goto deletar_codigo
if "%OP%"=="0" goto fim
echo  Opcao invalida.
goto menu

rem ============================================================
rem  Dobra acentos e poe em maiusculas (PROMOCAO == PROMOCAO)
rem  Usa o codigo digitado em %COD% e devolve em %COD%
rem ============================================================
:fold_code
rem  O ps1 (codegen_util.ps1) detecta o codepage sozinho.
rem  echo(!COD! usa expansao tardia: escreve metacaracteres
rem  (& | ^ < > etc.) com seguranca no TMPIN - testado.
rem  NAO usar "for /f ... in ('comando')" aqui: o subshell
rem  do cmd drena o stdin e quebra os set /p seguintes.
rem  Apaga o TMPOUT ANTES do ps1: se o fold falhar, o for /f
rem  nao le um codigo antigo de outra execucao.
del "%TMPOUT%" 2>nul
> "%TMPIN%" echo(!COD!
powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILPS%" fold >nul
set "COD="
for /f "usebackq delims=" %%x in ("%TMPOUT%") do set "COD=%%x"
exit /b

rem ---- pausa portatil: funciona com console real e com pipe ----
:pausa
set "pausa_dummy="
set /p "pausa_dummy=Pressione ENTER para continuar... " <nul
set /p "pausa_dummy="
exit /b

rem ============================================================
rem  [1] GERAR NOVO CODIGO
rem ============================================================
:novo_codigo
echo.
echo --------------------------------------------
echo  GERAR NOVO CODIGO
echo --------------------------------------------
echo  Acentos sao aceitos e viram letras normais.
echo.
set "COD="
set /p "COD=Digite o codigo: "
if "%COD%"=="" goto menu

call :fold_code
if "%COD%"=="" (
    echo   Codigo invalido. Use letras, numeros e acentos.
    goto novo_codigo
)

rem ---- se o codigo ja existe, REUTILIZA o storage antigo ----
rem  (assim quem ja resgatou nao consegue resgatar de novo)
set "OLDSTORAGE="
del "%TMPSTORAGE%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILPS%" getstorage >nul 2>nul
if exist "%TMPSTORAGE%" for /f "usebackq delims=" %%g in ("%TMPSTORAGE%") do set "OLDSTORAGE=%%g"
if defined OLDSTORAGE (
    set "STORAGE=%OLDSTORAGE%"
    echo.
    echo   ATENCAO: ja existe um codigo [%COD%] no arquivo.
    echo   Vai SOBRESCREVER mantendo o MESMO storage,
    echo   entao quem ja resgatou continua impedido.
) else (
    findstr /c:"CodeRedeemData[%COD%]" "%CODESFILE%" >nul 2>nul
    if not errorlevel 1 (
        echo.
        echo   ATENCAO: ja existe um codigo [%COD%] no arquivo.
        echo   A versao nova vai SOBRESCREVER a anterior.
    )
)

:validade
echo.
echo Validade do codigo (0 para nao expirar):
set "DD="
set "HH="
set "MM="
set /p "DD=Dias (00D): "
set /p "HH=Horas (00H): "
set /p "MM=Minutos (00M): "
echo(!DD!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   Invalido. Digite apenas numeros.
    goto validade
)
echo(!HH!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   Invalido. Digite apenas numeros.
    goto validade
)
echo(!MM!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   Invalido. Digite apenas numeros.
    goto validade
)

rem ---- limite de uso (0 = sem limite) ----
:limite_uso
echo.
echo Limite de uso (quantas pessoas podem resgatar):
set "MAXUSES="
set /p "MAXUSES=Limite (0 = sem limite): "
echo(!MAXUSES!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   Invalido. Digite apenas numeros. Use 0 para sem limite.
    goto limite_uso
)

set /a "TOTAL=DD*86400 + HH*3600 + MM*60"

rem ---- calcula timestamp unix de expiracao (se houver) ----
rem  Grava num arquivo temp e le com for /f de ARQUIVO.
rem  "for /f in ('comando')" criaria um subshell que drena
rem  o stdin e quebraria os prompts de item abaixo.
set "EXPIRE="
if %TOTAL% GTR 0 (
    del "%TMPEXPIRE%" 2>nul
    powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + %TOTAL%" > "%TMPEXPIRE%" 2>nul
    for /f "usebackq delims=" %%e in ("%TMPEXPIRE%") do set "EXPIRE=%%e"
)

rem ---- itens / recompensas ----
set "ITEMS="
:item
echo.
set "IID="
set "QTD="
set /p "IID=ID do item: "
set /p "QTD=Quantidade: "
echo(!IID!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   ID invalido. Digite apenas numeros.
    goto item
)
if %IID%==0 (
    echo   ID deve ser maior que zero.
    goto item
)
echo(!QTD!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   Quantidade invalida. Digite apenas numeros.
    goto item
)
if %QTD%==0 (
    echo   Quantidade deve ser maior que zero.
    goto item
)
if defined ITEMS (
    set "ITEMS=!ITEMS!, {!IID!, !QTD!}"
) else (
    set "ITEMS={!IID!, !QTD!}"
)
set "MAIS="
set /p "MAIS=Deseja adicionar mais algo como recompensa? (S/N): "
if /i "%MAIS%"=="S" goto item
if /i "%MAIS%"=="Y" goto item
if /i "%MAIS%"=="N" goto gerar
goto item

:gerar
rem ---- overwrite: remove o bloco ANTIGO antes de gravar o novo ----
rem  (evita duplicata no arquivo e garante que o delete depois
rem  realmente apague o codigo)
rem  Usa o modo "overwrite" do ps1: remove o bloco mas MANTEM o
rem  contador de usos, entao o maxUses continua valendo de verdade
rem  (nao zera o limite ao regenerar o codigo).
if defined OLDSTORAGE (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILPS%" overwrite >nul 2>nul
    goto gravar
)

rem ---- garante storage unico: se ja existe no arquivo, avanca ----
:storage_unico
findstr /c:"storage = %STORAGE%," "%CODESFILE%" >nul 2>nul
if not errorlevel 1 (
    set /a STORAGE+=1
    goto storage_unico
)

:gravar

rem ---- salva DIRETO no servidor (codes_data.lua) ----
>> "%CODESFILE%" echo.
>> "%CODESFILE%" echo CodeRedeemData["%COD%"] = {
>> "%CODESFILE%" echo   storage = %STORAGE%,
if defined EXPIRE (
    >> "%CODESFILE%" echo   expire = %EXPIRE%,
)
if %MAXUSES% GTR 0 (
    >> "%CODESFILE%" echo   maxUses = %MAXUSES%,
)
>> "%CODESFILE%" echo   items = { %ITEMS% }
>> "%CODESFILE%" echo }

rem ---- registro legivel para conferencia ----
(
    echo     CodeRedeemData["%COD%"] = {
    echo       storage = %STORAGE%,
    if defined EXPIRE echo       expire = %EXPIRE%,
    if %MAXUSES% GTR 0 echo       maxUses = %MAXUSES%,
    echo       items = { %ITEMS% }
    echo     }
    echo.
)>> "%OUTFILE%"

rem ---- mostra o resultado ----
echo.
echo ============================================
echo  Codigo gerado e SALVO NO SERVIDOR:
echo.
echo     CodeRedeemData["%COD%"] = {
echo       storage = %STORAGE%,
if defined EXPIRE (
    echo       expire = %EXPIRE%,
)
if %MAXUSES% GTR 0 (
    echo       maxUses = %MAXUSES%,
)
echo       items = { %ITEMS% }
echo     }
echo.
echo  Arquivo: %CODESFILE%
echo  Ja esta ativo - o servidor rele o arquivo
echo  a cada resgate, sem reiniciar.
echo ============================================

rem ---- avanca o storage para o proximo codigo ----
set /a STORAGE+=1
> "%COUNTERFILE%" echo %STORAGE%

echo.
call :pausa
goto menu

rem ============================================================
rem  [2] VER TODOS OS CODIGOS ATIVOS
rem ============================================================
:ver_codigos
echo.
echo ============================================
echo        CODIGOS ATIVOS
echo ============================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILPS%" view
echo.
call :pausa
goto menu

rem ============================================================
rem  [3] DELETAR UM CODIGO
rem ============================================================
:deletar_codigo
echo.
echo --------------------------------------------
echo  DELETAR CODIGO
echo --------------------------------------------
set "COD="
set /p "COD=Digite o codigo a deletar (ENTER volta): "
if "%COD%"=="" goto menu

call :fold_code
if "%COD%"=="" (
    echo   Codigo invalido.
    goto menu
)

set "DELRES="
del "%TMPDEL%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%UTILPS%" delete > "%TMPDEL%" 2>nul
for /f "usebackq delims=" %%r in ("%TMPDEL%") do set "DELRES=%%r"
if "%DELRES%"=="DELETED" (
    echo   Codigo [%COD%] deletado do arquivo.
) else (
    echo   Codigo [%COD%] nao encontrado.
)
echo.
call :pausa
goto menu

:fim
del "%TMPIN%" "%TMPOUT%" "%TMPEXPIRE%" "%TMPDEL%" "%TMPSTORAGE%" 2>nul
echo.
echo  Ate mais!
endlocal
