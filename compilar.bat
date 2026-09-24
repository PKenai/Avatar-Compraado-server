@echo off
rem =====================================================================
rem  compilar.bat - compila o The Forgotten Server (Avatar) em RELEASE
rem                 e copia o exe + pdb + dlls para a raiz do servidor.
rem
rem  Uso:
rem    compilar.bat            compila (Release/Win32) e instala o build
rem    compilar.bat /vs        compila e depois abre a solucao no VS
rem    compilar.bat /ide       compila usando o proprio Visual Studio (devenv)
rem    compilar.bat /onlyvs    nao compila, so abre a solucao no Visual Studio
rem    compilar.bat /nopause   nao pausa no final (agendador de tarefas / CI)
rem    compilar.bat /force     mata o servidor se ele estiver travando o exe
rem    compilar.bat /clean     Rebuild - recompila tudo do zero
rem    compilar.bat /check     so confere o ambiente e os caminhos, nao compila
rem
rem  O script:
rem     1. acha sozinho a solucao, o MSBuild/Visual Studio, o Windows SDK
rem        e o vcpkg;
rem     2. ajusta os caminhos absolutos que o CMake gravou dentro dos
rem        .vcxproj (o projeto foi gerado em outra maquina);
rem     3. compila em Release/Win32 e loga tudo em build_log.txt;
rem     4. copia o exe/pdb/dlls para a raiz do servidor.
rem
rem  Se o vcpkg nao estiver em C:\vcpkg, mude VCPKG_ROOT abaixo.
rem =====================================================================

setlocal enabledelayedexpansion
set "PF86=%ProgramFiles(x86)%"
set "PF=%ProgramFiles%"
set "PSEXE=powershell -NoProfile -ExecutionPolicy Bypass"
set "LOG=%~dp0build_log.txt"

rem ------------------------ CONFIGURACAO ------------------------------
if not defined VCPKG_ROOT set "VCPKG_ROOT=C:\vcpkg"
set "CONFIG=Release"
set "PLATFORM=Win32"
set "TRIPLET=x86-windows"
set "VCPKG_LIBS=boost_thread-*.lib boost_filesystem-*.lib boost_chrono-*.lib boost_date_time-*.lib boost_container-*.lib boost_atomic-*.lib libxml2.lib libcrypto.lib libssl.lib zlib.lib lua51.lib gmp.lib libmysql.lib"
rem --------------------------------------------------------------------

set "OPEN_VS="
set "ONLY_VS="
set "IDE_BUILD="
set "DO_PAUSE=1"
set "FORCE_KILL="
set "CHECK_ONLY="
set "TARGET=Build"
set "DO_PATCH=1"

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="/vs"     set "OPEN_VS=1"
if /i "%~1"=="/onlyvs" set "OPEN_VS=1" & set "ONLY_VS=1"
if /i "%~1"=="/ide"    set "IDE_BUILD=1"
if /i "%~1"=="/nopause" set "DO_PAUSE="
if /i "%~1"=="/force"  set "FORCE_KILL=1"
if /i "%~1"=="/clean"  set "TARGET=Rebuild"
if /i "%~1"=="/check"  set "CHECK_ONLY=1"
shift
goto parse
:parsed

echo ============================================================
echo   COMPILADOR DO SERVIDOR - %CONFIG% / %PLATFORM%
echo ============================================================
echo.
echo [1/6] Procurando a solucao (theforgottenserver.sln)...
set "SLN="
for %%P in (
  "%~dp0theforgottenserver.sln"
  "%~dp0sources\build\theforgottenserver.sln"
  "%~dp0build\theforgottenserver.sln"
  "%~dp0..\sources\build\theforgottenserver.sln"
  "%~dp0..\build\theforgottenserver.sln"
  "%~dp0..\..\sources\build\theforgottenserver.sln"
) do if not defined SLN if exist "%%~fP" set "SLN=%%~fP"

if not defined SLN (
  echo    [ERRO] Nao achei a theforgottenserver.sln perto deste .bat.
  echo           Coloque o compilar.bat na raiz do servidor ^(a pasta que
  echo           tem "sources" e "data"^) e rode de novo.
  goto erro
)
for %%I in ("%SLN%") do set "SLN_DIR=%%~dpI"
echo    %SLN%

echo.
echo [2/6] Procurando a raiz do servidor ^(onde fica o config.lua^)...
set "SERVER_ROOT="
if exist "%SLN_DIR%..\..\config.lua" set "SERVER_ROOT=%SLN_DIR%..\.."
if not defined SERVER_ROOT if exist "%SLN_DIR%..\config.lua" set "SERVER_ROOT=%SLN_DIR%.."
if not defined SERVER_ROOT if exist "%~dp0config.lua" set "SERVER_ROOT=%~dp0"
if not defined SERVER_ROOT set "SERVER_ROOT=%~dp0"
for %%I in ("%SERVER_ROOT%") do set "SERVER_ROOT=%%~fI"
if not exist "%SERVER_ROOT%\config.lua" (
  echo    [AVISO] Nao achei config.lua em %SERVER_ROOT%
  echo            O exe sera copiado de qualquer forma para essa pasta.
)
echo    %SERVER_ROOT%

echo.
echo [3/6] Procurando o Visual Studio / MSBuild...
set "VS_PATH="
set "MSBUILD="
set "VSWHERE=%PF86%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "!VSWHERE!" (
  for /f "usebackq delims=" %%I in (`"!VSWHERE!" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -property installationPath`) do if not defined VS_PATH set "VS_PATH=%%I"
  for /f "usebackq delims=" %%I in (`"!VSWHERE!" -latest -prerelease -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do if not defined MSBUILD set "MSBUILD=%%I"
)
if not defined MSBUILD (
  rem plano B: varre as pastas conhecidas do Visual Studio, de 2017 a 2026
  for %%V in (18 2022 2019 2017) do (
    for %%E in (Enterprise Professional Community BuildTools Preview Insiders) do (
      if not defined MSBUILD if exist "!PF!\Microsoft Visual Studio\%%V\%%E\MSBuild\Current\Bin\MSBuild.exe" set "MSBUILD=!PF!\Microsoft Visual Studio\%%V\%%E\MSBuild\Current\Bin\MSBuild.exe"
      if not defined MSBUILD if exist "!PF!\Microsoft Visual Studio\%%V\%%E\MSBuild\15.0\Bin\MSBuild.exe" set "MSBUILD=!PF!\Microsoft Visual Studio\%%V\%%E\MSBuild\15.0\Bin\MSBuild.exe"
    )
  )
)
if not defined MSBUILD for /f "delims=" %%I in ('where msbuild 2^>nul') do if not defined MSBUILD set "MSBUILD=%%I"

if not defined MSBUILD (
  echo    [ERRO] Nao encontrei o MSBuild nenhum lugar.
  echo.
  echo    Instale o Visual Studio 2022 ou 2026 com estas cargas de trabalho:
  echo      - Desenvolvimento para desktop com C++
  echo      - Ferramentas de build do MSVC v143 - VS 2022 C++ x64/x86
  echo      - SDK do Windows 10 ^(10.0.26100.0 ou mais novo^)
  echo    Download: https://visualstudio.microsoft.com/pt-br/downloads/
  echo.
  echo    Obs: na VPS use sempre o instalador completo; nao de pra compilar
  echo         sem o toolset C++ nem sem o Windows SDK.
  goto erro
)
if not defined VS_PATH (
  set "VS_PATH=!MSBUILD!"
  set "VS_PATH=!VS_PATH:\MSBuild\Current\Bin\MSBuild.exe=!"
  set "VS_PATH=!VS_PATH:\MSBuild\15.0\Bin\MSBuild.exe=!"
)
echo    VS      : !VS_PATH!
echo    MSBuild : !MSBUILD!

echo.
echo [4/6] Checando o Windows SDK...
set "SDK_WANTED="
for /f "tokens=2 delims=<>" %%V in ('findstr /i "WindowsTargetPlatformVersion" "!SLN_DIR!theforgottenserver.vcxproj"') do if not defined SDK_WANTED set "SDK_WANTED=%%V"
set "SDK_ARGS="
if defined SDK_WANTED if not exist "!PF86!\Windows Kits\10\Include\!SDK_WANTED!" (
  set "SDK_USE="
  for /f "delims=" %%D in ('dir /b /o-n "!PF86!\Windows Kits\10\Include" 2^>nul') do if not defined SDK_USE set "SDK_USE=%%D"
  if defined SDK_USE (
    echo    [AVISO] O projeto pede o SDK !SDK_WANTED! mas ele nao esta instalado.
    echo            Vou compilar com o SDK !SDK_USE!.
    set "SDK_ARGS=-p:WindowsTargetPlatformVersion=!SDK_USE!"
  ) else (
    echo    [ERRO] Nenhum Windows SDK 10 encontrado. Instale o "SDK do Windows 10" pelo
    echo           Visual Studio Installer e rode de novo.
    goto erro
  )
) else (
  if defined SDK_WANTED (echo    SDK !SDK_WANTED! [ok]) else (echo    Nao li a versao no vcxproj, sigo com a padrao.)
)

echo.
echo [5/6] Checando o vcpkg ^(bibliotecas de terceiros^)...
set "VCPKG_LIB_DIR=!VCPKG_ROOT!\installed\!TRIPLET!\lib"
set "VCPKG_INC_DIR=!VCPKG_ROOT!\installed\!TRIPLET!\include"
set "MISSING="
if not exist "!VCPKG_LIB_DIR!" (
  set "MISSING=todas as bibliotecas"
) else (
  for %%L in (!VCPKG_LIBS!) do if not exist "!VCPKG_LIB_DIR!\%%L" set "MISSING=!MISSING! %%L"
  for %%D in (mysql libxml2) do if not exist "!VCPKG_INC_DIR!\%%D" set "MISSING=!MISSING! include/%%D"
)
if defined MISSING (
  echo    [ERRO] Falta coisa no vcpkg em !VCPKG_ROOT!:
  echo           !MISSING!
  echo.
  echo    O jeito mais garantido: copie a pasta C:\vcpkg da sua maquina para a
  echo    VPS no mesmo caminho ^(ela tem os .lib/.dll/.cmake que o projeto usa^).
  echo    Se preferir instalar na VPS:
  echo      git clone https://github.com/microsoft/vcpkg C:\vcpkg
  echo      C:\vcpkg\bootstrap-vcpkg.bat
  echo      C:\vcpkg\vcpkg install boost-filesystem boost-thread boost-chrono boost-date-time boost-container boost-atomic libxml2 openssl zlib lua gmp libmysql --triplet x86-windows
  echo.
  echo    Se o vcpkg estiver em outro caminho, mude a variavel VCPKG_ROOT
  echo    no comeco deste .bat ^(ou defina a variavel de ambiente VCPKG_ROOT^).
  goto erro
)
echo    vcpkg : !VCPKG_ROOT! [!TRIPLET! ok]

echo.
echo [6/6] Ajustando caminhos absolutos gravados pelo CMake...
rem O .vcxproj foi gerado em outra maquina e tem caminhos fixos
rem (C:\Users\imfis\..., C:\vcpkg, ...\Visual Studio\2022\Community\...cmake.exe).
rem Sem isso o build quebra com MSB3073 no "Building Custom Rule".
if defined DO_PATCH (
  set "PATCHPS=$d='!SLN_DIR!';$newRoot='!SERVER_ROOT!';$newVS='!VS_PATH!';$newVP='!VCPKG_ROOT!';foreach($f in (Get-ChildItem -LiteralPath $d -Filter *.vcxproj -File)){ $t=[IO.File]::ReadAllText($f.FullName); $o=$t; $m=[regex]::Match($t,'([A-Za-z]:[\\/][^;<>|]*?)[\\/]sources[\\/]CMakeLists\.txt'); if($m.Success){$a=$m.Groups[1].Value; if($a -ne $newRoot){ $t=$t.Replace($a,$newRoot); $t=$t.Replace($a.Replace('\','/'),$newRoot.Replace('\','/')); Write-Host ('    raiz do projeto : '+$a+'  ->  '+$newRoot) }}; $m=[regex]::Match($t,'([A-Za-z]:[\\/][^<>|]*?)[\\/]Common7[\\/]IDE[\\/]CommonExtensions[\\/]Microsoft[\\/]CMake[\\/]CMake[\\/]bin[\\/]cmake\.exe'); if($m.Success){$a=$m.Groups[1].Value; if($a -ne $newVS){ $t=$t.Replace($a,$newVS); $t=$t.Replace($a.Replace('\','/'),$newVS.Replace('\','/')); Write-Host ('    Visual Studio   : '+$a+'  ->  '+$newVS) }}; $m=[regex]::Match($t,'([A-Za-z]:[\\/][^;<>|]*?)[\\/]installed[\\/]x86-windows'); if($m.Success){$a=$m.Groups[1].Value; if($a -ne $newVP){ $t=$t.Replace($a,$newVP); $t=$t.Replace($a.Replace('\','/'),$newVP.Replace('\','/')); Write-Host ('    vcpkg           : '+$a+'  ->  '+$newVP) }}; if($t -ne $o){ Copy-Item -LiteralPath $f.FullName -Destination ($f.FullName+'.bak-portable') -Force; [IO.File]::WriteAllText($f.FullName,$t,(New-Object System.Text.UTF8Encoding($true))); Write-Host ('    atualizado      : '+$f.Name) } }"
  rem ^<nul evita que o PowerShell fique esperando entrada se algo der errado
  %PSEXE% -Command "!PATCHPS!" <nul
  if errorlevel 1 echo    [AVISO] Nao consegui rodar o ajuste de caminhos. Sigo tentando compilar.
  rem marca os stamps do CMake como atualizados, senao o MSBuild tenta
  rem reconfigurar o projeto chamando o cmake da instalacao antiga.
  if exist "!SLN_DIR!CMakeFiles" (
    if not exist "!SLN_DIR!CMakeFiles\generate.stamp" type nul > "!SLN_DIR!CMakeFiles\generate.stamp"
    copy /b "!SLN_DIR!CMakeFiles\generate.stamp"+,, >nul 2>&1
  )
)

if defined CHECK_ONLY (
  echo.
  echo ------------------------------------------------------------
  echo Tudo que o build precisa esta no lugar. Nada foi compilado
  echo porque voce passou /check.
  goto fim
)

echo.
echo ------------------------------------------------------------
if defined ONLY_VS (
  echo Pulando a compilacao ^(/onlyvs^).
  goto abrir_vs
)

set "DEVENV=!VS_PATH!\Common7\IDE\devenv.exe"
set "DEVENVCOM=!VS_PATH!\Common7\IDE\devenv.com"
if defined IDE_BUILD if not exist "!DEVENVCOM!" (
  echo [AVISO] Nao achei o devenv.com em !VS_PATH!; vou usar o MSBuild.
  set "IDE_BUILD="
)

echo Compilando %CONFIG% / %PLATFORM% ... ^(pode demorar alguns minutos^)
echo A saida esta sendo gravada em: %LOG%
echo Para acompanhar ao vivo, abra outro prompt e rode: type "%LOG%"
echo.
if defined IDE_BUILD (
  "!DEVENVCOM!" "!SLN!" /Build "%CONFIG%|%PLATFORM%" > "%LOG%" 2>&1
) else (
  "!MSBUILD!" "!SLN!" /t:%TARGET% /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% !SDK_ARGS! /m /nologo /v:minimal > "%LOG%" 2>&1
)
set "ERRO=!errorlevel!"
echo ------------------------------------------------------------
type "%LOG%"
echo ------------------------------------------------------------

if not "!ERRO!"=="0" (
  echo.
  echo ------------------------------------------------------------
  echo    [ERRO] O build falhou ^(codigo !ERRO!^).
  echo    Abra o log e procure por "error":
  echo      %LOG%
  rem tentativa extra: se o erro foi o toolset v143 nao instalado,
  rem tenta o toolset mais novo do proprio Visual Studio, o v144.
  findstr /i /c:"MSB8020" "%LOG%" >nul 2>&1
  if not errorlevel 1 if not defined IDE_BUILD (
    echo.
    echo    Toolset v143 ausente - tentando novamente com PlatformToolset=v144...
    "!MSBUILD!" "!SLN!" /t:%TARGET% /p:Configuration=%CONFIG% /p:Platform=%PLATFORM% /p:PlatformToolset=v144 !SDK_ARGS! /m /nologo /v:minimal > "%LOG%" 2>&1
    set "ERRO=!errorlevel!"
    type "%LOG%"
  )
  if not "!ERRO!"=="0" goto erro
)

set "BUILD_EXE=!SLN_DIR!Release\theforgottenserver.exe"
if not exist "!BUILD_EXE!" set "BUILD_EXE=!SLN_DIR!%CONFIG%\theforgottenserver.exe"
if not exist "!BUILD_EXE!" (
  echo    [ERRO] O build terminou mas nao achei o exe em !SLN_DIR!Release\
  echo           Confira o OutDir dentro do theforgottenserver.vcxproj.
  goto erro
)

echo.
echo ------------------------------------------------------------
echo BUILD OK
echo    exe : !BUILD_EXE!
for %%I in ("!BUILD_EXE!") do echo          %%~zI bytes   %%~tI

rem ------------------- instala na raiz do servidor -------------------
set "SERVER_EXE=%SERVER_ROOT%\theforgottenserver.exe"
set "RUNNING="
tasklist /fi "imagename eq theforgottenserver.exe" 2>nul | findstr /i "theforgottenserver.exe" >nul 2>&1
if not errorlevel 1 set "RUNNING=1"

if defined RUNNING (
  echo.
  echo    [AVISO] O servidor esta rodando ^(theforgottenserver.exe^).
  if defined FORCE_KILL (
    echo            /force informado: fechando o processo agora...
    taskkill /im theforgottenserver.exe /f >nul 2>&1
    ping -n 4 127.0.0.1 >nul
  ) else (
    echo            Nao vou mexer nele. Se o exe estiver travado, o novo
    echo            build sera salvo como theforgottenserver_NOVO.exe e voce
    echo            troca na mao ^(ou rode de novo com /force^).
  )
)

set "COPIOU="
copy /y "!BUILD_EXE!" "!SERVER_EXE!" >nul 2>&1
if not errorlevel 1 set "COPIOU=1"

if defined COPIOU (
  echo    copiado para: !SERVER_EXE!
) else (
  set "SERVER_EXE=!SERVER_ROOT!\theforgottenserver_NOVO.exe"
  copy /y "!BUILD_EXE!" "!SERVER_EXE!" >nul 2>&1
  if errorlevel 1 (
    echo    [ERRO] Nao consegui copiar o exe para !SERVER_ROOT!
    echo           ^(arquivo em uso ou sem permissao^)
  ) else (
    echo    [AVISO] Exe em uso: salvei como !SERVER_EXE!
    echo            Pare o servidor, apague o theforgottenserver.exe e renomeie
    echo            o _NOVO.exe no lugar dele.
  )
)

set "BUILD_PDB=!SLN_DIR!Release\theforgottenserver.pdb"
if exist "!BUILD_PDB!" (
  copy /y "!BUILD_PDB!" "!SERVER_ROOT!\theforgottenserver.pdb" >nul 2>&1
  if not errorlevel 1 echo    pdb copiado    ^(mostra as funcoes no stack trace^)
)

rem dlls de runtime que o exe precisa: copia as que faltam na raiz
set "DLLS=0"
if exist "!SLN_DIR!Release\*.dll" (
  for %%D in ("!SLN_DIR!Release\*.dll") do (
    if not exist "!SERVER_ROOT!\%%~nxD" (
      copy /y "%%~fD" "!SERVER_ROOT!" >nul 2>&1
      echo    dll copiada    : %%~nxD
      set /a DLLS+=1
    )
  )
)
if "!DLLS!"=="0" echo    dlls           : nenhuma faltando

echo ------------------------------------------------------------
echo Tudo pronto.

:abrir_vs
if defined OPEN_VS (
  set "DEVENV=!VS_PATH!\Common7\IDE\devenv.exe"
  if exist "!DEVENV!" (
    echo Abrindo a solucao no Visual Studio...
    start "" "!DEVENV!" "!SLN!"
  ) else (
    echo    [AVISO] Nao achei o devenv.exe em !VS_PATH!.
  )
)

:fim
if defined DO_PAUSE (
  echo.
  pause
)
exit /b 0

:erro
echo.
echo Compilacao interrompida.
if defined DO_PAUSE pause
exit /b 1
