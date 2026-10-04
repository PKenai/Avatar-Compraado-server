<#
  vps_file.ps1 - leva/traz um arquivo da VPS por WinRM.

  E' o transporte usado pelo `--vps` do tools/spell_power_tool.py, mas serve
  para qualquer arquivo:

    powershell -NoProfile -File tools\vps_file.ps1 -Get  -Remote C:\Avatar\data\lib\201-spellsExausted.lua -Local C:\temp\magias.lua
    powershell -NoProfile -File tools\vps_file.ps1 -Put  -Local  C:\temp\magias.lua -Remote C:\Avatar\data\lib\201-spellsExausted.lua
    powershell -NoProfile -File tools\vps_file.ps1 -Size -Remote C:\Avatar\data\logs\spellPowerReload.log

  Saida: 'ok' (Get/Put) ou o tamanho em bytes (Size), -1 se o arquivo nao existir.

  Senha da VPS: variavel de ambiente VPS_PASS; se ela nao existir, usa a
  credencial cifrada salva pelo Windows em ~\.avatar-vps-cred.xml (a mesma que o
  subir_vps.bat usa).
#>
param(
    [switch]$Get,
    [switch]$Put,
    [switch]$Size,
    [Parameter(Mandatory = $true)][string]$Remote,
    [string]$Local,
    [string]$Computer = '89.213.41.202',
    [string]$User = 'Administrador'
)

$ErrorActionPreference = 'Stop'

$credFile = Join-Path $env:USERPROFILE '.avatar-vps-cred.xml'
if ($env:VPS_PASS) {
    $cred = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $env:VPS_PASS -AsPlainText -Force))
} elseif (Test-Path $credFile) {
    $cred = Import-Clixml $credFile
} else {
    Write-Error 'Sem VPS_PASS e sem credencial salva - rode o subir_vps.bat uma vez para salvar.'
    exit 2
}

if ($Get -or $Put) {
    if (-not $Local) { Write-Error 'informe -Local junto de -Get/-Put'; exit 2 }
}

$s = New-PSSession -ComputerName $Computer -Credential $cred -Authentication Negotiate
try {
    if ($Get) {
        Copy-Item -Path $Remote -Destination $Local -FromSession $s
        'ok'
    } elseif ($Put) {
        Copy-Item -Path $Local -Destination $Remote -ToSession $s
        'ok'
    } elseif ($Size) {
        Invoke-Command -Session $s -ArgumentList $Remote -ScriptBlock {
            param($p)
            if (Test-Path $p) { (Get-Item $p).Length } else { -1 }
        }
    } else {
        Write-Error 'informe -Get, -Put ou -Size'
        exit 2
    }
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
