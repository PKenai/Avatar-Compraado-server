@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=x86
msbuild "C:\Users\imfis\Desktop\Avatar-Compraado-server\sources\build\theforgottenserver.vcxproj" /p:Configuration=Release /p:Platform=Win32 /t:Build
if %errorlevel% equ 0 (
  echo BUILD SUCCEEDED
  copy /y "C:\Users\imfis\Desktop\Avatar-Compraado-server\sources\build\Release\theforgottenserver.exe" "C:\Users\imfis\Desktop\Avatar-Compraado-server\theforgottenserver.exe"
  echo COPIED to server root
) else (
  echo BUILD FAILED with errorlevel %errorlevel%
)
pause
