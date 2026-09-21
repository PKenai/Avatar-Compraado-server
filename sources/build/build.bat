@echo off
set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
echo Compilando o servidor...
%MSBUILD% "%~dp0theforgottenserver.sln" /t:Build /p:Configuration=Release /p:Platform=Win32 /m /v:minimal /nologo
if %errorlevel% neq 0 (
  echo BUILD FAILED
  exit /b 1
)
echo.
echo OK! Copiando para a raiz do servidor...
copy /y "%~dp0Release\theforgottenserver.exe" "%~dp0..\..\"
rem o .pdb precisa ficar do lado do .exe: e' ele que da' nome as funcoes no
rem stack trace do [COND-TRACE] e do server_crash.txt
copy /y "%~dp0Release\theforgottenserver.pdb" "%~dp0..\..\"
echo Feito!
dir "%~dp0..\..\theforgottenserver.exe"
