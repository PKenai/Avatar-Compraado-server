@echo off
rem ===========================================================================
rem  iniciar_servidor.bat - sobe o servidor que esta' NESTA pasta.
rem ===========================================================================
rem
rem  E' o alvo da tarefa agendada "Avatar Server" na VPS (/sc onstart, usuario
rem  SYSTEM), e tambem serve para subir na mao (duplo clique) quando precisar.
rem
rem  Usa %~dp0 (a pasta DESTE arquivo) em vez de um caminho fixo: assim o mesmo
rem  arquivo funciona na VPS, no PC ou em qualquer copia do servidor, sem
rem  precisar editar nada. E' por isso que a tarefa agendada nao tem mais um
rem  C:\... cravado dentro dela.
rem
rem  --log=... faz o servidor escrever a saida do console em
rem  data\logs\output.log. Sem isso, ao rodar como SYSTEM (sessao 0) o console
rem  nao existe e a saida se perde -- foi o que deixou o output.log com 186
rem  bytes enquanto o servidor rodava havia horas.
rem ===========================================================================

cd /d "%~dp0"

if not exist "%~dp0theforgottenserver.exe" (
    echo Nao achei theforgottenserver.exe em:
    echo   %~dp0
    echo Compile antes com o compilar.bat ou suba o build com o subir_vps.bat.
    exit /b 1
)

echo Subindo o servidor de %~dp0
"%~dp0theforgottenserver.exe" --log="%~dp0data\logs\output.log"
