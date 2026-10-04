<#
  subir_vps.ps1 - envia o servidor compilado aqui para a VPS, para a pasta do
  servidor que esta' no ar (a copia da Area de Trabalho do Administrador),
  substituindo os arquivos antigos e reiniciando o servidor.

  Normalmente voce nao chama este .ps1 direto: use o subir_vps.bat na raiz.

  O que ele envia:
    - theforgottenserver.exe e theforgottenserver.pdb (sempre)
    - as DLLs de runtime que estiverem faltando la
    - com -Data: os arquivos de data\ e mods\ que mudaram (compara tamanho
      e data de modificacao, entao nao reenvia os 170 MB toda vez)

  Senha da VPS: pega da variavel de ambiente VPS_PASS; se ela nao existir,
  usa um arquivo de credencial salvo pelo Windows (o primeiro uso pergunta e
  salva). A senha fica cifrada pelo seu usuario do Windows, nunca no projeto.
#>
[CmdletBinding()]
param(
    # Opcoes em texto, ex: "/check /data /norestart". O cmd manda tudo junto
    # porque o -File do PowerShell nao distribui argumentos soltos direito.
    [string]$Flags = '',
    [string]$Computer = '89.213.41.202',
    [string]$User = 'Administrador',
    # Pasta do servidor que esta' NO AR na VPS. O antigo C:\Avatar era uma copia
    # paralela que ninguem usava (foi apagada); o servidor de verdade sempre
    # rodou desta pasta da Area de Trabalho.
    [string]$Destino = 'C:\Users\Administrador\Desktop\Avatar-Compraado-server',
    [string]$Tarefa = 'Avatar Server',
    [int]$Porta = 9191
)

$Data = $false
$OnlyData = $false
$NoRestart = $false
$Check = $false
foreach ($flag in ($Flags -split '\s+')) {
    switch (($flag -replace '^[/-]+', '').ToLower()) {
        'data'      { $Data = $true }
        'onlydata'  { $OnlyData = $true }
        'norestart' { $NoRestart = $true }
        'check'     { $Check = $true }
        'nopause'   { }
        ''          { }
        default     { Write-Host ('   [AVISO] opcao ignorada: ' + $flag) -ForegroundColor Yellow }
    }
}

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$credFile = Join-Path $env:USERPROFILE '.avatar-vps-cred.xml'
$tmpTar = Join-Path $env:TEMP 'avatar_deploy.tar.gz'
$tmpLista = Join-Path $env:TEMP 'avatar_deploy_lista.txt'
$DLLS = @(
    'boost_filesystem-vc143-mt-x32-1_90.dll', 'boost_thread-vc143-mt-x32-1_90.dll',
    'iconv-2.dll', 'libcrypto-3.dll', 'libmariadb.dll', 'libmysql.dll',
    'libssl-3.dll', 'libxml2.dll', 'lua51.dll', 'zlib1.dll', 'zstd.dll'
)

function Passo($t) { Write-Host ''; Write-Host ('== ' + $t) -ForegroundColor Cyan }

# ---------------------------------------------------------------- credencial
Passo 'credencial da VPS'
if ($env:VPS_PASS) {
    $cred = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $env:VPS_PASS -AsPlainText -Force))
    Write-Host '   usando a variavel de ambiente VPS_PASS'
} elseif (Test-Path $credFile) {
    $cred = Import-Clixml $credFile
    Write-Host ('   usando a credencial salva em ' + $credFile)
} else {
    Write-Host '   primeira vez: informe a senha do usuario ' -NoNewline
    Write-Host $User -ForegroundColor Yellow
    $cred = Get-Credential -UserName $User -Message 'Senha do usuario ' + $User + ' na VPS ' + $Computer
    if (-not $cred) { Write-Host '   cancelado.'; exit 1 }
    $cred | Export-Clixml $credFile
    Write-Host ('   senha salva (cifrada pelo Windows) em ' + $credFile)
}

# ------------------------------------------------------------------- sessao
Passo ('conectando em ' + $Computer)
$s = New-PSSession -ComputerName $Computer -Credential $cred -Authentication Negotiate
try {
    $destinoExiste = Invoke-Command -Session $s -ArgumentList $Destino -ScriptBlock { param($d) Test-Path $d }
    if (-not $destinoExiste) { throw ('A pasta ' + $Destino + ' nao existe na VPS.') }
    Write-Host ('   ok, ' + $Destino + ' encontrada')

    # ------------------------------------------------------- o que vai subir
    $enviar = New-Object System.Collections.Generic.List[string]
    $viaCopia = New-Object System.Collections.Generic.List[string]

    if (-not $OnlyData) {
        Passo 'arquivos de programa'
        foreach ($f in @('theforgottenserver.exe', 'theforgottenserver.pdb')) {
            $p = Join-Path $raiz $f
            if (Test-Path $p) {
                $enviar.Add($f)
                Write-Host ('   ' + $f + '  (' + [math]::Round((Get-Item $p).Length / 1MB, 2) + ' MB)')
            }
        }
        $faltando = Invoke-Command -Session $s -ArgumentList $Destino, $DLLS -ScriptBlock {
            param($d, $lista)
            ($lista | Where-Object { -not (Test-Path (Join-Path $d $_)) })
        }
        if ($faltando) {
            foreach ($d in $faltando) { $enviar.Add($d); Write-Host ('   ' + $d + '  (faltando na VPS)') }
        } else {
            Write-Host '   dlls: nenhuma faltando'
        }
    }

    if ($Data -or $OnlyData) {
        Passo 'dados alterados em data\ e mods\'
        $locais = @()
        foreach ($sub in 'data', 'mods') {
            $base = Join-Path $raiz $sub
            if (Test-Path $base) {
                $locais += Get-ChildItem $base -Recurse -File | ForEach-Object {
                    [pscustomobject]@{
                        Rel = $_.FullName.Substring($raiz.Length + 1).Replace('\', '/')
                        Tam = $_.Length
                        Mod = $_.LastWriteTimeUtc.Ticks
                        Cheio = $_.FullName
                    }
                }
            }
        }
        $remotos = Invoke-Command -Session $s -ArgumentList $Destino -ScriptBlock {
            param($d)
            $saida = @()
            foreach ($sub in 'data', 'mods') {
                $base = Join-Path $d $sub
                if (Test-Path $base) {
                    $saida += Get-ChildItem $base -Recurse -File | ForEach-Object {
                        $_.FullName.Substring($d.Length + 1).Replace('\', '/') + '|' + $_.Length + '|' + $_.LastWriteTimeUtc.Ticks
                    }
                }
            }
            $saida
        }
        # data\logs e' coisa que o servidor escreve NA VPS (log de console, crash).
        # Se eu mandasse a versao local por cima, eu apagaria o log de la.
        # *.vps.lua e' o espelho do tool de magias e *.bak sao backups: NUNCA vao
        # para a VPS. O engine carrega TODO *.lua de data/lib, e o
        # 201-spellsExausted.vps.lua sobrescreveria a tabela spellsInfo inteira la'.
        $locais = @($locais | Where-Object {
            $_.Rel -notlike 'data/logs/*' -and
            $_.Rel -notlike '*.vps.lua' -and
            $_.Rel -notlike '*.bak'
        })

        $mapa = @{}
        foreach ($linha in $remotos) {
            $partes = $linha -split '\|'
            $mapa[$partes[0]] = @{ Tam = [int64]$partes[1]; Mod = [int64]$partes[2] }
        }
        $mudados = @($locais | Where-Object {
            $r = $mapa[$_.Rel]
            (-not $r) -or ($r.Tam -ne $_.Tam) -or ([math]::Abs($r.Mod - $_.Mod) -gt 20000000)
        })
        Write-Host ('   ' + $locais.Count + ' arquivos locais, ' + $mudados.Count + ' com diferenca')
        foreach ($m in $mudados | Select-Object -First 15) {
            $marca = if ($mapa[$m.Rel]) { 'alterado' } else { 'novo    ' }
            Write-Host ('   ' + $marca + '  ' + $m.Rel)
        }
        if ($mudados.Count -gt 15) { Write-Host ('   ... e mais ' + ($mudados.Count - 15) + ' arquivo(s)') }

        foreach ($m in $mudados) {
            if ($m.Rel -match '^[\x20-\x7E]+$') { $enviar.Add($m.Rel) } else { $viaCopia.Add($m.Cheio) }
        }
    }

    # Se um espelho do tool subiu numa deploy antiga, o engine o carrega e a tabela
    # spellsInfo inteira passa a vir dele. Remove qualquer *.vps.lua de data/lib na
    # VPS (nunca deveria existir la').
    if (($Data -or $OnlyData) -and -not $Check) {
        $intrusos = Invoke-Command -Session $s -ArgumentList $Destino -ScriptBlock {
            param($d)
            $alvo = Join-Path $d 'data\lib'
            if (Test-Path $alvo) {
                Get-ChildItem $alvo -File -Filter '*.vps.lua' -ErrorAction SilentlyContinue |
                    ForEach-Object { $_.FullName }
            }
        }
        if ($intrusos) {
            Invoke-Command -Session $s -ArgumentList $intrusos -ScriptBlock {
                param($lista)
                foreach ($p in $lista) { Remove-Item $p -Force -ErrorAction SilentlyContinue }
            }
            foreach ($p in $intrusos) {
                Write-Host ('   removido na VPS (artefato do tool, nunca deve existir la): ' + $p) -ForegroundColor Yellow
            }
        }
    }

    if ($enviar.Count -eq 0 -and $viaCopia.Count -eq 0) {
        Write-Host ''
        Write-Host 'Nada para enviar - tudo igual.' -ForegroundColor Green
        exit 0
    }
    if ($Check) {
        Write-Host ''
        Write-Host ('[check] seriam enviados ' + $enviar.Count + ' arquivo(s)') -ForegroundColor Yellow
        exit 0
    }

    # ----------------------------------------------- empacota o que vai subir
    Passo 'empacotando'
    # A lista precisa ter quebra de linha simples (LF). Com CRLF o tar procura
    # por um arquivo chamado "nome.ext" + retorno de carro e nao acha nada.
    [IO.File]::WriteAllText($tmpLista, (($enviar -join "`n") + "`n"), [Text.Encoding]::ASCII)
    $tarExe = Join-Path $env:SystemRoot 'System32\tar.exe'
    Remove-Item $tmpTar -ErrorAction SilentlyContinue
    Push-Location $raiz
    try {
        & $tarExe -czf $tmpTar -T $tmpLista 2>&1 | Out-Null
    } finally {
        Pop-Location
    }
    if (-not (Test-Path $tmpTar)) { throw 'Falha ao criar o pacote (tar).' }
    $dentro = (& $tarExe -tzf $tmpTar | Measure-Object).Count
    Write-Host ('   ' + $dentro + ' arquivo(s) no pacote, ' + [math]::Round((Get-Item $tmpTar).Length / 1MB, 2) + ' MB')
    if ($dentro -lt $enviar.Count) { throw 'O pacote saiu incompleto - abortado por seguranca.' }

    # ---------------------------------------------------- para o servidor
    if (-not $NoRestart) {
        Passo 'parando o servidor'
        Invoke-Command -Session $s -ArgumentList $Tarefa -ScriptBlock {
            param($t)
            cmd /c ('schtasks /end /tn "' + $t + '"') | Out-Null
            Get-Process theforgottenserver -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 4
            '   processos ativos: ' + (@(Get-Process theforgottenserver -ErrorAction SilentlyContinue).Count)
        }
    }

    # -------------------------------------------------------------- envia
    Passo 'enviando'
    $relogio = [Diagnostics.Stopwatch]::StartNew()
    Copy-Item -Path $tmpTar -Destination ($Destino + '\_deploy.tar.gz') -ToSession $s
    foreach ($f in $viaCopia) {
        $rel = $f.Substring($raiz.Length + 1)
        $dirDest = Join-Path $Destino (Split-Path $rel -Parent)
        Invoke-Command -Session $s -ArgumentList $dirDest -ScriptBlock { param($d) New-Item -ItemType Directory -Force -Path $d | Out-Null }
        Copy-Item -Path $f -Destination (Join-Path $dirDest (Split-Path $rel -Leaf)) -ToSession $s
    }
    $relogio.Stop()
    Write-Host ('   transferido em ' + [math]::Round($relogio.Elapsed.TotalSeconds, 1) + ' s')

    Passo 'extraindo e conferindo'
    Invoke-Command -Session $s -ArgumentList $Destino -ScriptBlock {
        param($d)
        & 'C:\Windows\System32\tar.exe' -xzf (Join-Path $d '_deploy.tar.gz') -C $d
        if ($LASTEXITCODE -ne 0) { throw ('tar terminou com codigo ' + $LASTEXITCODE) }
        Remove-Item (Join-Path $d '_deploy.tar.gz') -Force
        $exe = Get-Item (Join-Path $d 'theforgottenserver.exe')
        '   exe na VPS: ' + [math]::Round($exe.Length / 1MB, 2) + ' MB  modificado ' + $exe.LastWriteTime.ToString('dd/MM HH:mm:ss')
    }

    # ----------------------------------------------------- sobe de novo
    if (-not $NoRestart) {
        Passo 'subindo o servidor'
        Invoke-Command -Session $s -ArgumentList $Tarefa -ScriptBlock { param($t) cmd /c ('schtasks /run /tn "' + $t + '"') | Out-Null }
        $ok = $false
        for ($i = 1; $i -le 30; $i++) {
            Start-Sleep -Seconds 6
            $escutando = Invoke-Command -Session $s -ArgumentList $Porta -ScriptBlock {
                param($p) [bool](Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq $p })
            }
            if ($escutando) { Write-Host ('   no ar depois de ' + ($i * 6) + ' s (porta ' + $Porta + ')'); $ok = $true; break }
        }
        if (-not $ok) {
            Write-Host '   [AVISO] o servidor nao abriu a porta a tempo; veja o log na VPS:' -ForegroundColor Yellow
            Write-Host ('           ' + $Destino + '\data\logs\output.log')
        }
        Invoke-Command -Session $s -ArgumentList $Destino -ScriptBlock {
            param($d) Get-Content (Join-Path $d 'data\logs\output.log') -Tail 3 -ErrorAction SilentlyContinue
        } | ForEach-Object { '   ' + $_ }
    }
}
finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
    Remove-Item $tmpTar, $tmpLista -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'Pronto.' -ForegroundColor Green
