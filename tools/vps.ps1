<#
  vps.ps1 - roda um comando na VPS por WinRM (porta 5985) e devolve a saida.

  Uso:
    $env:VPS_PASS = 'senha da VPS'
    powershell -NoProfile -File tools\vps.ps1 "hostname"
    powershell -NoProfile -File tools\vps.ps1 "Get-Service | Where-Object Status -eq 'Running'"

  A senha NUNCA fica gravada aqui: ela e lida da variavel de ambiente VPS_PASS,
  que existe so na sessao do shell.
#>
param(
    [Parameter(Position = 0)][string]$Command = 'hostname',
    [string]$Computer = '89.213.41.202',
    [string]$User = 'Administrador'
)

$ErrorActionPreference = 'Stop'

if (-not $env:VPS_PASS) {
    Write-Host 'Defina a variavel de ambiente VPS_PASS antes de rodar.'
    exit 2
}

$sec  = ConvertTo-SecureString $env:VPS_PASS -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($User, $sec)

$sessao = New-PSSession -ComputerName $Computer -Credential $cred -Authentication Negotiate
try {
    Invoke-Command -Session $sessao -ScriptBlock ([scriptblock]::Create($Command))
}
finally {
    Remove-PSSession $sessao
}
