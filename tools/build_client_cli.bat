@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ===========================================================================
rem  build_client_cli.bat - compila o OTClient v8 SEM ABRIR O VISUAL STUDIO
rem ===========================================================================
rem
rem  Para onde copiar este arquivo:
rem    o script espera rodar de dentro da pasta do CLIENT, do lado do vc16\
rem    (ex.: C:\...\Avatar-comprado-client\  ->  copie para ...\build_client_cli.bat)
rem    Se preferir, pode chamar de qualquer lugar passando a pasta do client.
rem
rem  Uso:
rem    build_client_cli.bat check                 -> so' diagnostica, nao compila
rem    build_client_cli.bat build                 -> compila OpenGL x64
rem    build_client_cli.bat build "C:\caminho"    -> client em outra pasta
rem
rem  O que ele faz no build:
rem    1) acha o MSBuild/VsDevCmd (Visual Studio OU Build Tools, sem IDE)
rem    2) joga include/lib do vcpkg (x64-windows-static) no INCLUDE/LIB
rem    3) msbuild vc16\otclient.vcxproj /p:Configuration=OpenGL /p:Platform=x64
rem    4) confere se otclient_gl.exe saiu, com data e tamanho
rem
rem  ---------------------------------------------------------------------------
rem  O QUE PRECISA ESTAR INSTALADO (uma vez, na maquina que tem o fonte)
rem  ---------------------------------------------------------------------------
rem  a) "Build Tools for Visual Studio 2022" com a carga "Desenvolvimento para
rem     desktop com C++" (MSVC v143 + Windows 10/11 SDK). NAO precisa da IDE.
rem     https://aka.ms/vs/17/release/vs_BuildTools.exe
rem     Linha de comando (admin, PowerShell):
rem       vs_BuildTools.exe --quiet --wait --norestart ^
rem         --add Microsoft.VisualStudio.Workload.VCTools ^
rem         --includeRecommended
rem     Toolset do projeto: v143 (PlatformToolset no vcxproj).
rem
rem  b) vcpkg com as libs estaticas x64 (triplet x64-windows-static):
rem       git clone https://github.com/microsoft/vcpkg C:\vcpkg
rem       C:\vcpkg\bootstrap-vcpkg.bat
rem       C:\vcpkg\vcpkg install openssl physfs glew openal-soft libzip ^
rem         libvorbis libogg zlib bzip2 liblzma --triplet x64-windows-static
rem     Nao precisa do "vcpkg integrate install": o script injeta INCLUDE/LIB.
rem     Se o vcpkg estiver em outro lugar: set VCPKG_ROOT=C:\onde\esta
rem
rem  c) lua51.lib e SDL2.lib:
rem     - SDL2.lib ja' vem em vc16\SDL2\lib\x64 (SDL2-devel x64)
rem     - Ultralight*.lib ja' vem em vc16\ultralight-sdk\lib
rem     - lua51.lib NAO existe nos ports do vcpkg (o port "lua" gera lua.lib,
rem       que e' 5.4). O client espera lua51: confirme no repo do client de
rem       onde ele vem hoje, ou compile o Lua 5.1.5 (uma linha com cl).
rem
rem  d) o FONTE do client: o vcxproj compila ..\src\client\*.cpp e
rem     ..\src\framework\*.cpp (157 arquivos). Sem a pasta src\ nao ha' o que
rem     compilar - este script avisa isso no check.
rem  ---------------------------------------------------------------------------

set "MODE=%~1"
set "CLIENT=%~2"

rem aceita tambem "build_client_cli.bat C:\pasta do client" sem modo
if /i not "%MODE%"=="check" if /i not "%MODE%"=="build" (
    if not "%MODE%"=="" set "CLIENT=%MODE%"
    set "MODE=check"
)

if not defined MODE set "MODE=check"
if not defined CLIENT if exist "%~dp0vc16\otclient.vcxproj" set "CLIENT=%~dp0."
if not defined CLIENT set "CLIENT=%USERPROFILE%\Desktop\Client pra jogar com tonto"

set "VCX=%CLIENT%\vc16\otclient.vcxproj"
set "LOG=%CLIENT%\vc16\build_cli.log"

echo ===========================================================================
echo   BUILD DO CLIENT SEM VISUAL STUDIO  ^|  modo: %MODE%
echo ===========================================================================
echo   client: %CLIENT%
echo.

if not exist "%VCX%" (
    echo [ERRO] nao achei o projeto:
    echo        %VCX%
    echo        passe a pasta do client como argumento.
    exit /b 2
)

rem ---------------------------------------------------------------------------
rem 1) toolchain
rem ---------------------------------------------------------------------------
set "VSWHERE="
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not defined VSWHERE if exist "%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"

rem Build Tools 2022 instala em "Program Files (x86)" por padrao, VS completo em
rem "Program Files": a busca cobre os dois.
set "PF86=%ProgramFiles(x86)%"
set "PF64=%ProgramFiles%"

set "VSPATH="
if defined VSWHERE (
    for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -prerelease -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2^>nul`) do set "VSPATH=%%i"
)
if not defined VSPATH (
    for %%p in (
        "%PF86%\Microsoft Visual Studio\2022\BuildTools"
        "%PF64%\Microsoft Visual Studio\2022\BuildTools"
        "%PF86%\Microsoft Visual Studio\2022\Community"
        "%PF64%\Microsoft Visual Studio\2022\Community"
        "%PF86%\Microsoft Visual Studio\2022\Professional"
        "%PF64%\Microsoft Visual Studio\2022\Professional"
        "%PF86%\Microsoft Visual Studio\2022\Enterprise"
        "%PF64%\Microsoft Visual Studio\2022\Enterprise"
        "%PF86%\Microsoft Visual Studio\2019\BuildTools"
        "%PF64%\Microsoft Visual Studio\2019\BuildTools"
    ) do (
        if not defined VSPATH if exist "%%~p\Common7\Tools\VsDevCmd.bat" set "VSPATH=%%~p"
    )
)
set "VSDEVCMD="
if defined VSPATH set "VSDEVCMD=%VSPATH%\Common7\Tools\VsDevCmd.bat"

echo [1] TOOLCHAIN
if defined VSPATH (
    echo       OK    %VSPATH%
) else (
    echo       FALTA nenhum MSBuild/VsDevCmd encontrado - instale o Build Tools 2022
    echo             com a carga "Desktop development with C++"
)

if not defined VCPKG_ROOT (
    for %%v in ("C:\vcpkg" "C:\dev\vcpkg" "C:\tools\vcpkg" "%USERPROFILE%\vcpkg" "C:\src\vcpkg") do (
        if not defined VCPKG_ROOT if exist "%%~v\vcpkg.exe" set "VCPKG_ROOT=%%~v"
    )
)
set "VCPKG_LIB="
if defined VCPKG_ROOT if exist "%VCPKG_ROOT%\installed\x64-windows-static\lib" set "VCPKG_LIB=%VCPKG_ROOT%\installed\x64-windows-static\lib"

echo.
echo [2] VCPKG ^(libs estaticas x64^)
if defined VCPKG_LIB (
    echo       OK    %VCPKG_LIB%
) else (
    echo       FALTA nao achei ^<vcpkg^>\installed\x64-windows-static\lib
    echo             clone/bootstrap o vcpkg e rode:
    echo             vcpkg install openssl physfs glew openal-soft libzip libvorbis libogg zlib bzip2 liblzma --triplet x64-windows-static
    echo             ^(ou set VCPKG_ROOT=C:\caminho\do\vcpkg^)
)

rem ---------------------------------------------------------------------------
rem 3) fontes e libs exigidas pelo link
rem ---------------------------------------------------------------------------
echo.
echo [3] FONTE ^(vcxproj compila ..\src\**^)
set "SRCCOUNT=0"
rem contagem NAO recursiva de proposito: dir /s dentro de uma juncao ^(\src -> outra
rem pasta^) trava, e o que importa e' saber se as fontes do projeto estao no lugar.
if exist "%CLIENT%\src\client\client.cpp" (
    rem %SystemRoot% de proposito: se o .bat rodar de um terminal com coreutils no
    rem PATH (Git Bash), "find" seria o find do MSYS e sairia varrendo o disco.
    for /f %%c in ('dir /b "%CLIENT%\src\client\*.cpp" 2^>nul ^| "%SystemRoot%\System32\find.exe" /c ".cpp"') do set "SRCCOUNT=%%c"
)
if %SRCCOUNT% GTR 0 (
    echo       OK    src\ no lugar ^(%SRCCOUNT% .cpp em src\client^)
) else (
    echo       FALTA a pasta src\ nao existe / nao tem .cpp
    echo             o vcxproj espera ..\src\client\*.cpp e ..\src\framework\*.cpp
    echo             sem o fonte nao ha' o que compilar: traga o repo do client
)
set "MISSINGLIBS="
set "MISSINGCOUNT=0"

echo.
echo [4] LIBS DO LINK
for %%L in (
    SDL2.lib
    Ultralight.lib UltralightCore.lib WebCore.lib AppCore.lib
    libssl.lib libcrypto.lib
    physfs-static.lib
    lua51.lib
    libglew32.lib
    OpenAL32.lib
    zip.lib
    vorbis.lib vorbisfile.lib ogg.lib
) do (
    set "HIT="
    for %%D in ("%CLIENT%\vc16\SDL2\lib\x64" "%CLIENT%\vc16\ultralight-sdk\lib" "%CLIENT%\vc16\lib") do (
        if not defined HIT if exist "%%~D\%%L" set "HIT=%%~D\%%L"
    )
    if not defined HIT if defined VCPKG_LIB if exist "%VCPKG_LIB%\%%L" set "HIT=%VCPKG_LIB%\%%L"
    if defined HIT (
        echo       OK    %%L
    ) else (
        set /a MISSINGCOUNT+=1
        set "MISSINGLIBS=!MISSINGLIBS! %%L"
        echo       FALTA %%L
    )
)

rem ---------------------------------------------------------------------------
rem 4) veredito do check
rem ---------------------------------------------------------------------------
if /i "%MODE%"=="check" (
    echo.
    echo ===========================================================================
    set "BLOCKERS=0"
    if not defined VSPATH set /a BLOCKERS+=1
    if not defined VCPKG_LIB set /a BLOCKERS+=1
    if %SRCCOUNT% LEQ 0 set /a BLOCKERS+=1
    if !MISSINGCOUNT! GTR 0 set /a BLOCKERS+=1
    if !BLOCKERS! EQU 0 (
        echo   VEREDITO: PRONTO PARA COMPILAR
        echo              rode: %~nx0 build
    ) else (
        echo   VEREDITO: FALTAM !BLOCKERS! bloco^(s^) para compilar.
        echo              itens faltando:!MISSINGLIBS!
        echo              detalhes do que instalar no cabecalho deste .bat
    )
    echo ===========================================================================
    exit /b 0
)

rem ---------------------------------------------------------------------------
rem 5) build
rem ---------------------------------------------------------------------------
if not defined VSDEVCMD (
    echo [ERRO] sem MSBuild/VsDevCmd: instale o Build Tools 2022 antes.
    exit /b 3
)

echo.
echo [5] BUILD OpenGL ^| x64
call "%VSDEVCMD%" -arch=amd64 -host_arch=amd64 -no_logo
if errorlevel 1 (
    echo [ERRO] VsDevCmd falhou
    exit /b 4
)

if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\installed\x64-windows-static\include" set "INCLUDE=%VCPKG_ROOT%\installed\x64-windows-static\include;%INCLUDE%"
    if defined VCPKG_LIB set "LIB=%VCPKG_LIB%;%LIB%"
)

rem o settings.props joga os .obj/.tlog para C:\otc-build (evita MSB6003)
if not exist "C:\otc-build" md "C:\otc-build" 2>nul

pushd "%CLIENT%"
msbuild "vc16\otclient.vcxproj" /nologo /m /v:minimal ^
    /p:Configuration=OpenGL /p:Platform=x64 /p:VcpkgTriplet=x64-windows-static ^
    /fl /flp:logfile="%LOG%"
set "BUILDRC=%ERRORLEVEL%"
popd

echo.
if "%BUILDRC%"=="0" (
    echo       msbuild OK
) else (
    echo       msbuild FALHOU ^(exit %BUILDRC%^) - erros no log:
    echo       %LOG%
    "%SystemRoot%\System32\findstr.exe" /n /c:" error " /c:" error C" /c:"LNK" "%LOG%" 2>nul
)

echo.
echo ===========================================================================
if exist "%CLIENT%\otclient_gl.exe" (
    echo   EXE: %CLIENT%\otclient_gl.exe
    for %%F in ("%CLIENT%\otclient_gl.exe") do echo        %%~zF bytes  ^|  %%~tF
    echo   ^(o nome final do seu client e' o "Avatar Eclipse.exe": renomeie depois^)
) else (
    echo   EXE: otclient_gl.exe NAO foi gerado
)
echo ===========================================================================
exit /b %BUILDRC%
