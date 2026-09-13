@echo off
setlocal enabledelayedexpansion
title MARKET - Gerenciar ofertas da loja (game_shop)
cd /d "%~dp0..\.."

set "FILE=data\lib\shop_offers.lua"

if not exist "%FILE%" (
  > "%FILE%" echo ShopOffers = ShopOffers or {}
  >> "%FILE%" echo.
  >> "%FILE%" echo -- Arquivo criado pelo BAT de MARKET (adicionar_loja.bat)
)

:inicio
cls
set "TIPO="
set "ITEMID="
set "NOME="
set "QTD="
set "OIDM="
set "OIDF="
set "ADDONS="
set "EXTRA_LINE="
set "TIPO_LINE="
set "CLASSE="
set "CLASSE_VAL="
set "VALOR="
set "CATEG="
set "SKIP_CATEG="
set "DESC="
set "LINHA="
echo ==================================================
echo   GERENCIAR OFERTAS DA LOJA  (game_shop)
echo ==================================================
echo.
echo O que deseja fazer?
echo   [I] Adicionar Item
echo   [O] Adicionar Outfit
echo   [R] Remover ofertas
echo   [S] Sair
echo.
set /p "TIPO=> "
if /i "%TIPO%"=="S" goto fim
if /i "%TIPO%"=="I" goto item
if /i "%TIPO%"=="O" goto outfit
if /i "%TIPO%"=="R" goto remover
echo Opcao invalida. Use I, O, R ou S.
pause
goto inicio

:item
set /p "ITEMID=> ID do item (numero, ex: 2160): "
call :isnum ITEMID
if errorlevel 1 (
  echo ID invalido. Digite apenas numeros.
  pause
  goto inicio
)
set /p "NOME=> Nome do item (ex: Crystal Coin): "
if "%NOME%"=="" set "NOME=Item"
set /p "QTD=> Quantidade (padrao 1): "
if "%QTD%"=="" set "QTD=1"
call :isnum QTD
if errorlevel 1 (
  echo Quantidade invalida. Digite apenas numeros.
  pause
  goto inicio
)
set "TIPO_LINE=item"
set "EXTRA_LINE=itemId = %ITEMID%, count = %QTD%"
goto comum

:outfit
set /p "OIDM=> ID do outfit masculino (ex: 128): "
call :isnum OIDM
if errorlevel 1 (
  echo ID invalido. Digite apenas numeros.
  pause
  goto inicio
)
set /p "OIDF=> ID do outfit feminino (ex: 136): "
call :isnum OIDF
if errorlevel 1 (
  echo ID invalido. Digite apenas numeros.
  pause
  goto inicio
)
set /p "NOME=> Nome do outfit (ex: Warrior Outfit): "
if "%NOME%"=="" set "NOME=Outfit"
set /p "ADDONS=> Addons 0-3 (padrao 0): "
if "%ADDONS%"=="" set "ADDONS=0"
call :isnum ADDONS
if errorlevel 1 (
  echo Addons invalido. Digite apenas numeros.
  pause
  goto inicio
)
set "TIPO_LINE=outfit"
set "EXTRA_LINE=outfitMale = %OIDM%, outfitFemale = %OIDF%, addons = %ADDONS%"
rem -- outfit novo NAO pergunta categoria: vai direto pra aba Outfits
set "CATEG=Outfits"
set "SKIP_CATEG=1"
goto comum

:comum
echo.
echo Agora as informacoes gerais da oferta:
echo.
set /p "CLASSE=> Classe (T = todas / W = water / F = fire / A = air / E = earth): "
if /i "%CLASSE%"=="T" set "CLASSE_VAL=all"
if /i "%CLASSE%"=="W" set "CLASSE_VAL=water"
if /i "%CLASSE%"=="F" set "CLASSE_VAL=fire"
if /i "%CLASSE%"=="A" set "CLASSE_VAL=air"
if /i "%CLASSE%"=="E" set "CLASSE_VAL=earth"
if "%CLASSE_VAL%"=="" (
  echo Classe invalida. Use T, W, F, A ou E.
  pause
  goto inicio
)
set /p "VALOR=> Valor (premium_points): "
call :isnum VALOR
if errorlevel 1 (
  echo Valor invalido. Digite apenas numeros.
  pause
  goto inicio
)
rem -- IMPORTANTE: sem bloco ( ... ) aqui. Dentro de um bloco o cmd expande
rem    %CATEG% na hora de ler o bloco, entao o "if" abaixo testaria o valor
rem    antigo e sobrescreveria o que o usuario digitou.
if defined SKIP_CATEG goto categ_pronta
set /p "CATEG=> Categoria (se digitar uma nova, ela sera criada): "
if "%CATEG%"=="" set "CATEG=Geral"
goto categ_pronta_fim
:categ_pronta
echo.
echo Categoria  : %CATEG%   (automatica - outfit novo entra direto na aba Outfits)
:categ_pronta_fim
set /p "DESC=> Descricao (Enter = padrao): "
if "%DESC%"=="" set "DESC=Oferta da loja: %NOME%"

rem -- remove caracteres que quebrariam o Lua
call :clean NOME
call :clean CATEG
call :clean DESC

rem -- monta e grava a linha Lua
set "LINHA=table.insert(ShopOffers, { category = "%CATEG%", type = "%TIPO_LINE%", title = "%NOME%", %EXTRA_LINE%, cost = %VALOR%, class = "%CLASSE_VAL%", description = "%DESC%" })"
>> "%FILE%" echo %LINHA%

echo.
echo Oferta adicionada com sucesso!
echo   Categoria : %CATEG%
echo   Nome      : %NOME%
echo   Classe    : %CLASSE_VAL%
echo   Valor     : %VALOR% pontos
echo   Arquivo   : %FILE%
echo.
echo Adicionar mais algo?
echo   [S] Sim
echo   [N] Nao (encerrar)
echo.
set /p "MAIS=> "
if /i "%MAIS%"=="S" goto inicio
goto fim

:remover
cls
echo ==================================================
echo   REMOVER OFERTAS DA LOJA  (game_shop)
echo ==================================================
if not exist "%FILE%" (
  echo Nenhuma oferta encontrada. Arquivo %FILE% nao existe.
  pause
  goto inicio
)

set "N=0"
echo.
echo Ofertas atuais:
echo.
for /f "usebackq delims=" %%L in ("%FILE%") do (
  echo(%%L| findstr /b /c:"table.insert(ShopOffers" >nul
  if not errorlevel 1 (
    set /a N+=1
    echo [!N!] %%L
  )
)
if %N% EQU 0 (
  echo.
  echo Nenhuma oferta encontrada no arquivo.
  pause
  goto inicio
)

echo.
set "REMOVER="
set /p "REMOVER=> Numeros para remover (ex: 2 5 7  ou  1-3)  [Enter = voltar]: "
if "%REMOVER%"=="" goto inicio

rem -- converte virgulas em espacos e expande faixas tipo 1-3
set "REMLIST="
for %%t in (%REMOVER:,= %) do (
  for /f "tokens=1,2 delims=-" %%a in ("%%t") do (
    if "%%b"=="" (
      set "REMLIST=!REMLIST! %%a"
    ) else (
      set /a RANGE_A=%%a
      set /a RANGE_B=%%b
      if !RANGE_A! GTR !RANGE_B! (set /a RANGE_A=%%b & set /a RANGE_B=%%a)
      for /l %%i in (!RANGE_A!,1,!RANGE_B!) do set "REMLIST=!REMLIST! %%i"
    )
  )
)

rem -- valida os numeros
set "VALID=1"
for %%x in (%REMLIST%) do (
  if %%x LSS 1 set "VALID=0"
  if %%x GTR %N% set "VALID=0"
)
if not "%VALID%"=="1" (
  echo Numero invalido. Use numeros de 1 a %N%.
  pause
  goto remover
)

echo.
echo Removendo as ofertas: %REMLIST%
set /p "CONF=> Confirmar? [S]im / [N]ao: "
if /i not "%CONF%"=="S" goto remover

rem -- backup antes de alterar
set "BAK=%FILE%.bak"
copy /y "%FILE%" "%BAK%" >nul

rem -- reescreve o arquivo sem as ofertas escolhidas
set "TMP=%TEMP%\market_offers_%RANDOM%.lua"
findstr /n "^" "%FILE%" > "%TMP%"
set "N=0"
set "REM_COUNT=0"
(for /f "usebackq tokens=1,* delims=:" %%a in ("%TMP%") do (
  echo(%%b| findstr /b /c:"table.insert(ShopOffers" >nul
  if errorlevel 1 (
    echo(%%b
  ) else (
    set /a N+=1
    set "REMOVER_ESTE="
    for %%x in (%REMLIST%) do if %%x EQU !N! set "REMOVER_ESTE=1"
    if defined REMOVER_ESTE (
      set /a REM_COUNT+=1
    ) else (
      echo(%%b
    )
  )
)) > "%FILE%"
del "%TMP%" >nul 2>nul

echo.
echo %REM_COUNT% oferta(s) removida(s) com sucesso!
echo Backup salvo em: %BAK%
echo.
echo Remover mais algo?
echo   [S] Sim
echo   [N] Nao (encerrar)
echo.
set /p "MAIS=> "
if /i "%MAIS%"=="S" goto remover
goto fim

:fim
echo.
echo Pronto! Reinicie o servidor para aplicar as novas ofertas.
echo As ofertas ficam em: %FILE%
pause
exit /b

:isnum
set "NUM=!%1!"
echo(!NUM!| findstr /r "^[0-9][0-9]*$" >nul
exit /b %errorlevel%

:clean
setlocal DisableDelayedExpansion
call set "V=%%%1%%"
set "V=%V:!=%"
set "V=%V:&=+%"
set "V=%V:|=%"
set "V=%V:<=%"
set "V=%V:>=%"
set "V=%V:^=%"
set "V=%V:(=%"
set "V=%V:)=%"
set "V=%V:"=%"
endlocal & set "%1=%V%"
exit /b
