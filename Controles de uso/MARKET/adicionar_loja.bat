@echo off
setlocal enabledelayedexpansion
title MARKET - Ofertas da loja NOVA (game_store)
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
echo   GERENCIAR OFERTAS DA LOJA NOVA  (game_store)
echo ==================================================
echo.
echo O que deseja fazer?
echo   [I] Adicionar Item
echo   [O] Adicionar Outfit
echo   [P] Adicionar Pet
echo   [R] Remover ofertas
echo   [S] Sair
echo.
set /p "TIPO=> "
if /i "%TIPO%"=="S" goto fim
if /i "%TIPO%"=="I" goto item
if /i "%TIPO%"=="O" goto outfit
if /i "%TIPO%"=="P" goto pet
if /i "%TIPO%"=="R" goto remover
echo Opcao invalida. Use I, O, P, R ou S.
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

:pet
cls
echo ==================================================
echo   ADICIONAR PET  (data\XML\pets.xml)
echo ==================================================
echo.

set "PETSXML=data\XML\pets.xml"
if not exist "%PETSXML%" (
  echo Arquivo %PETSXML% nao encontrado.
  echo Crie o arquivo com os seus pets antes de usar esta opcao.
  pause
  goto inicio
)

rem -- lista os pets do XML (o pet_util.ps1 ignora os que estao comentados)
set "PSTMP=%TEMP%\market_pets_%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pet_util.ps1" -Action list > "%PSTMP%" 2>nul

set "PTOTAL=0"
if exist "%PSTMP%" for /f "usebackq tokens=1 delims=|" %%a in ("%PSTMP%") do set /a PTOTAL+=1
if %PTOTAL% EQU 0 goto pet_manual

echo Pets disponiveis:
echo.
for /f "usebackq tokens=1,2,3,* delims=|" %%a in ("%PSTMP%") do echo   [%%a] petId=%%b  clientid=%%c  - %%d
echo.

set "PSEL="
set "PETID="
set "PETNOME="
set /p "PSEL=> Numero do pet, ou N para cadastrar um novo (Enter = voltar): "
if "%PSEL%"=="" (
  del "%PSTMP%" >nul 2>nul
  goto inicio
)
if /i "%PSEL%"=="N" (
  del "%PSTMP%" >nul 2>nul
  goto pet_novo
)
call :isnum PSEL
if errorlevel 1 (
  echo Numero invalido. Digite apenas numeros.
  del "%PSTMP%" >nul 2>nul
  pause
  goto inicio
)

for /f "usebackq tokens=1,2,3,* delims=|" %%a in ("%PSTMP%") do (
  if "%%a"=="%PSEL%" (
    set "PETID=%%b"
    set "PETNOME=%%d"
  )
)
del "%PSTMP%" >nul 2>nul

if "%PETID%"=="" (
  echo Pet nao encontrado. Use um dos numeros da lista.
  pause
  goto inicio
)

echo.
echo Pet selecionado: %PETNOME%   (petId = %PETID%)
set /p "NOME=> Titulo na loja (Enter = %PETNOME%): "
if "%NOME%"=="" set "NOME=%PETNOME%"
set "TIPO_LINE=pet"
set "EXTRA_LINE=petId = %PETID%"
rem -- pet novo NAO pergunta categoria: vai direto pra aba Pets
set "CATEG=Pets"
set "SKIP_CATEG=1"
goto comum

:pet_novo
rem -- cadastra um pet novo no pets.xml e depois vende ele na loja
echo.
echo ==================================================
echo   CADASTRAR PET NOVO  (data\XML\pets.xml)
echo ==================================================
echo.
echo O clientid e' o sprite usado para desenhar o pet no client - o mesmo
echo numero usado em outfit / UICreature.
echo Exemplos que existem neste client: 1227, 1220, 1271, 1092.
echo.
set /p "PCLIENT=> clientid (sprite) do pet: "
call :isnum PCLIENT
if errorlevel 1 (
  echo clientid invalido. Digite apenas numeros.
  pause
  goto inicio
)
set /p "PNOME=> Nome do pet (ex: Air nomad hamster): "
if "%PNOME%"=="" (
  echo O nome e obrigatorio.
  pause
  goto inicio
)
set /p "PPREM=> Exige premium account? [S]im / [N]ao (Enter = Nao): "
set "PPREMV=0"
if /i "%PPREM%"=="S" set "PPREMV=1"

rem -- remove caracteres que quebrariam o XML / o Lua
call :clean PNOME

set "PETID="
for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pet_util.ps1" -Action add -ClientId %PCLIENT% -PetName "%PNOME%" -Premium %PPREMV%') do set "PETID=%%a"

if "%PETID%"=="" (
  echo.
  echo Nao foi possivel registrar o pet. Veja a mensagem de erro acima.
  pause
  goto inicio
)

echo.
echo Pet registrado no pets.xml:  id=%PETID%  clientid=%PCLIENT%  nome=%PNOME%
echo Use /reload pets no jogo, ou reinicie o servidor, para ele existir.
echo.
set /p "NOME=> Titulo na loja (Enter = %PNOME%): "
if "%NOME%"=="" set "NOME=%PNOME%"
set "PETNOME=%PNOME%"
set "TIPO_LINE=pet"
set "EXTRA_LINE=petId = %PETID%"
rem -- pet novo NAO pergunta categoria: vai direto pra aba Pets
set "CATEG=Pets"
set "SKIP_CATEG=1"
goto comum

:pet_manual
rem -- fallback: sem PowerShell, mostra o XML e deixa o usuario digitar o petId
del "%PSTMP%" >nul 2>nul
echo.
echo Nao foi possivel listar os pets automaticamente.
echo Pets encontrados no XML:
echo.
findstr /c:"<pet id=" "%PETSXML%"
echo.
echo Digite o petId do pet desejado.
set /p "PETID=> petId: "
call :isnum PETID
if errorlevel 1 (
  echo petId invalido. Digite apenas numeros.
  pause
  goto inicio
)
set /p "NOME=> Titulo na loja (Enter = Pet %PETID%): "
if "%NOME%"=="" set "NOME=Pet %PETID%"
set "TIPO_LINE=pet"
set "EXTRA_LINE=petId = %PETID%"
set "CATEG=Pets"
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
echo Categoria  : %CATEG%   (automatica para outfit e pet)
:categ_pronta_fim
set /p "DESC=> Descricao (Enter = padrao): "
if "%DESC%"=="" set "DESC=Oferta da loja: %NOME%"

rem -- remove caracteres que quebrariam o Lua
call :clean NOME
call :clean CATEG
call :clean DESC

rem -- monta e grava a linha Lua
rem -- linha de comentario com a categoria (so' organizacao: a loja ignora o
rem    que nao for table.insert). Mantem o arquivo legivel por categoria.
findstr /i /c:"category = %CATEG%" "%FILE%" >nul
if errorlevel 1 (
  >> "%FILE%" echo.
  >> "%FILE%" echo -- Categoria: %CATEG%
)

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
echo   REMOVER OFERTAS DA LOJA NOVA  (game_store)
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
echo Pronto! Reinicie o SERVIDOR para aplicar as novas ofertas (a loja nova,
rem  game_store, le este arquivo la na inicializacao - o client nao precisa
rem  ser reaberto).
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
set "V=%V:'=%"
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
