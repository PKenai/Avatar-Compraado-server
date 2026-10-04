<#
  vps.ps1 - roda um comando na VPS por WinRM (porta 5985) e devolve a saida.

  Uso:
    powershell -NoProfile -File tools\vps.ps1 "hostname"
    powershell -NoProfile -File tools\vps.ps1 "Get-Service | Where-Object Status -eq 'Running'"

  A senha NUNCA fica gravada aqui: vem da variavel de ambiente VPS_PASS (que
  existe so na sessao do shell) ou, se ela nao estiver definida, da credencial
  cifrada em ~\.avatar-vps-cred.xml - a mesma que o subir_vps.bat salvou.
#>
param(
    [Parameter(Position = 0)][string]$Command = 'hostname',
    [string]$Computer = '89.213.41.202',
    [string]$User = 'Administrador'
)

$ErrorActionPreference = 'Stop'

$credFile = Join-Path $env:USERPROFILE '.avatar-vps-cred.xml'
if ($env:VPS_PASS) {
    $sec  = ConvertTo-SecureString $env:VPS_PASS -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($User, $sec)
} elseif (Test-Path $credFile) {
    $cred = Import-Clixml $credFile
} else {
    Write-Host 'Sem VPS_PASS e sem credencial salva - rode o subir_vps.bat uma vez para salvar.'
    exit 2
}

$sessao = New-PSSession -ComputerName $Computer -Credential $cred -Authentication Negotiate
try {
    Invoke-Command -Session $sessao -ScriptBlock ([scriptblock]::Create($Command))
}
finally {
    Remove-PSSession $sessao
}
