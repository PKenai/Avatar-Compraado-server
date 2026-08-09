@echo off
setlocal enabledelayedexpansion
title MARKET - Adicionar ofertas na loja (game_shop)
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
set "DESC="
set "LINHA="
echo ==================================================
echo   ADICIONAR OFERTAS NA LOJA  (game_shop)
echo ==================================================
echo.
echo O que deseja adicionar?
echo   [I] Item
echo   [O] Outfit
echo   [S] Sair
echo.
set /p "TIPO=> "
if /i "%TIPO%"=="S" goto fim
if /i "%TIPO%"=="I" goto item
if /i "%TIPO%"=="O" goto outfit
echo Opcao invalida. Use I, O ou S.
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
set /p "CATEG=> Categoria (se digitar uma nova, ela sera criada): "
if "%CATEG%"=="" set "CATEG=Geral"
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
