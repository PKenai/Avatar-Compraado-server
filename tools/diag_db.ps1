<#
  diag_db.ps1 - diagnostico SOMENTE LEITURA do banco na VPS.

  Verifica:
    - qual servidor MySQL/MariaDB esta rodando e com qual datadir;
    - se a pasta C:\xampp\mysql\data\avatar existe (e desde quando);
    - o que o log de erro do MySQL diz (crash, corrupcao, restart);
    - quais bancos existem de fato (show databases);
    - onde existe backup: backup do XAMPP, dumps .sql, Lixeira, shadow copies;
    - o que o servidor (theforgottenserver) esta reclamando sobre o banco.

  Nao altera nada: nenhum REPAIR, nenhum start/stop, nenhuma escrita.

  Uso:
    powershell -NoProfile -File tools\diag_db.ps1
#>
param(
    [string]$Computer = '89.213.41.202',
    [string]$User = 'Administrador'
)

$ErrorActionPreference = 'Continue'
$credFile = Join-Path $env:USERPROFILE '.avatar-vps-cred.xml'

if ($env:VPS_PASS) {
    $cred = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $env:VPS_PASS -AsPlainText -Force))
} elseif (Test-Path $credFile) {
    $cred = Import-Clixml $credFile
} else {
    Write-Host 'Sem VPS_PASS e sem credencial salva.'; exit 2
}

$s = New-PSSession -ComputerName $Computer -Credential $cred -Authentication Negotiate
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'

        '========================================================='
        ' HORA NA VPS: ' + (Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
        '========================================================='

        '### 1) processo mysql/mariadb e seu datadir'
        $procs = Get-CimInstance Win32_Process -Filter "Name='mysqld.exe'" -ErrorAction SilentlyContinue
        if (-not $procs) { '   nenhum mysqld.exe rodando' }
        foreach ($p in $procs) {
            '   PID        : ' + $p.ProcessId
            '   iniciado em: ' + $p.CreationDate
            '   executavel : ' + $p.ExecutablePath
            '   linha cmd  : ' + $p.CommandLine
        }

        ''
        '### 2) conteudo de C:\xampp\mysql\data (pastas = bancos)'
        if (Test-Path 'C:\xampp\mysql\data') {
            $d = Get-ChildItem 'C:\xampp\mysql\data' -Force -ErrorAction SilentlyContinue
            ($d | Sort-Object LastWriteTime -Descending | Select-Object Mode, LastWriteTime, @{n='MB';e={[math]::Round($_.Length/1MB,2)}}, Name | Format-Table -AutoSize | Out-String)
        } else {
            '   NAO EXISTE C:\xampp\mysql\data'
        }

        ''
        '### 3) o banco avatar (pasta + arquivos)'
        $av = 'C:\xampp\mysql\data\avatar'
        if (Test-Path $av) {
            $arq = Get-ChildItem $av -Recurse -Force -ErrorAction SilentlyContinue
            '   PASTA EXISTE: ' + $av
            '   arquivos    : ' + $arq.Count
            '   tamanho     : ' + [math]::Round((($arq | Measure-Object Length -Sum).Sum / 1MB), 2) + ' MB'
            $ord = $arq | Sort-Object LastWriteTime
            if ($og = $ord | Select-Object -First 1) { '   mais antigo : ' + $og.Name + '  ' + $og.LastWriteTime }
            if ($no = $ord | Select-Object -Last 1)  { '   mais recente: ' + $no.Name + '  ' + $no.LastWriteTime }
            '   pasta mtime : ' + (Get-Item $av).LastWriteTime
            ($arq | Select-Object -First 20 Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String)
        } else {
            '   >>> A PASTA DO BANCO avatar NAO EXISTE MAIS <<<'
        }

        ''
        '### 4) data / hora dos arquivos-chave do MySQL (mostra se foi recriado)'
        foreach ($f in 'ibdata1','aria_log_control','mysql_error.log','ib_logfile0','ibtmp1') {
            $p = 'C:\xampp\mysql\data\' + $f
            if (Test-Path $p) {
                $i = Get-Item $p
                '   {0,-20} {1,12} bytes   {2}' -f $f, $i.Length, $i.LastWriteTime
            } else { '   {0,-20} NAO EXISTE' -f $f }
        }
        $mysqldir = 'C:\xampp\mysql\data\mysql'
        if (Test-Path $mysqldir) {
            '   pasta mysql\ (tabelas de sistema) mtime: ' + (Get-Item $mysqldir).LastWriteTime
        }

        ''
        '### 5) log de erro do MySQL (ultimas 60 linhas)'
        $log = 'C:\xampp\mysql\data\mysql_error.log'
        if (Test-Path $log) {
            '   arquivo: ' + $log + '  (' + [math]::Round((Get-Item $log).Length/1KB,1) + ' KB)'
            ('   ' + ((Get-Content $log -Tail 60 -ErrorAction SilentlyContinue) -join "`n   "))
        } else { '   sem mysql_error.log' }

        ''
        '### 6) quais bancos existem agora (mysql.exe - show databases)'
        $my = 'C:\xampp\mysql\bin\mysql.exe'
        if (Test-Path $my) {
            try {
                $r = & $my -u root -e "show databases;" 2>&1
                ('   ' + (($r | Out-String).Trim() -replace "`n", "`n   "))
            } catch { '   falhou ao consultar: ' + $_.Exception.Message }
            ''
            '   --- tabelas do banco avatar (se existir) ---'
            try {
                $r2 = & $my -u root -D avatar -e "show tables;" 2>&1
                $t = ($r2 | Out-String).Trim()
                if ($t -match 'Unknown database') { '   Unknown database: o servidor MySQL ativo NAO enxerga o banco avatar' }
                else { $linhas = ($t -split "`n").Count - 1; '   tabelas encontradas: ' + $linhas; ('   ' + (($r2 | Select-Object -First 25) -join "`n   ")) }
            } catch { '   falhou: ' + $_.Exception.Message }
        } else { '   mysql.exe nao encontrado em ' + $my }

        ''
        '### 7) backup do XAMPP e outros dados MySQL no disco'
        foreach ($p in 'C:\xampp\mysql\backup','C:\xampp\mysql\backup\data','C:\xampp\mysql\backup\data\avatar','C:\xampp\mysql\data_old','C:\xampp\mysqldata','C:\mysql\data') {
            if (Test-Path $p) { '   EXISTE: ' + $p + '   (' + (Get-Item $p).LastWriteTime + ')' } else { '   nao tem: ' + $p }
        }

        ''
        '### 8) dumps .sql / .zip / .gz de banco espalhados pelo disco'
        $raizes = @('C:\','C:\xampp','C:\Avatar','C:\Users\Administrador','C:\Users\Administrador\Desktop','C:\ProgramData','C:\Temp')
        foreach ($r in $raizes) {
            if (-not (Test-Path $r)) { continue }
            $achados = Get-ChildItem $r -File -Include '*.sql','*.sql.gz','*avatar*.zip','*avatar*.gz','*avatar*.sql' -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.Length -gt 1KB } | Select-Object -First 12
            foreach ($a in $achados) {
                '   {0}  ({1} MB, {2})' -f $a.FullName, [math]::Round($a.Length/1MB,2), $a.LastWriteTime
            }
        }

        ''
        '### 9) Lixeira (caso a pasta do banco tenha sido apagada pelo Explorer)'
        $lix = 'C:\$Recycle.Bin'
        if (Test-Path $lix) {
            $achou = Get-ChildItem $lix -Recurse -Force -File -ErrorAction SilentlyContinue |
                     Where-Object { $_.Length -gt 100KB } | Sort-Object Length -Descending | Select-Object -First 15
            if ($achou) {
                ($achou | Select-Object @{n='MB';e={[math]::Round($_.Length/1MB,2)}}, LastWriteTime, FullName | Format-Table -AutoSize | Out-String)
            } else { '   lixeira vazia ou sem arquivo grande' }
        }

        ''
        '### 10) shadow copies / pontos de restauracao (backup do Windows)'
        $vss = & vssadmin list shadows 2>&1 | Out-String
        if ($vss -match 'No items found|Nenhum item|not found') { '   nenhuma shadow copy' }
        else { ('   ' + (($vss -split "`n" | Select-Object -First 25) -join "`n   ")) }

        ''
        '### 11) eventos do Windows em volta do horario da queda (23:00 - 00:30)'
        try {
            $ev = Get-WinEvent -FilterHashtable @{ LogName='Application'; StartTime=(Get-Date).AddHours(-3); EndTime=(Get-Date).AddMinutes(1) } -ErrorAction SilentlyContinue |
                  Where-Object { $_.Message -match 'mysql|mariadb|memory|memory|Application Error|crash' -or $_.LevelDisplayName -eq 'Error' } |
                  Select-Object -First 20 TimeCreated, ProviderName, LevelDisplayName, @{n='Msg';e={ ($_.Message -split "`n")[0] }}
            if ($ev) { ($ev | Format-Table -AutoSize | Out-String) } else { '   nada relevante no log de aplicativo' }
        } catch { '   falha ao ler eventos: ' + $_.Exception.Message }

        ''
        '### 12) espaco em disco e memoria agora'
        Get-PSDrive C | ForEach-Object { '   C: livre {0:N2} GB de {1:N2} GB' -f ($_.Free/1GB), (($_.Free + $_.Used)/1GB) }
        $os = Get-CimInstance Win32_OperatingSystem
        '   RAM livre: {0:N2} GB de {1:N1} GB' -f ($os.FreePhysicalMemory/1MB), ($os.TotalVisibleMemorySize/1MB)

        ''
        '### 13) o que o servidor esta dizendo sobre o banco'
        $saida = 'C:\Avatar\data\logs\output.log'
        if (Test-Path $saida) {
            $lines = Get-Content $saida -ErrorAction SilentlyContinue | Where-Object { $_ -match 'database|MYSQL|Unknown database|reconnect|avatar' } | Select-Object -Last 15
            if ($lines) { ('   ' + ($lines -join "`n   ")) } else { '   nenhuma linha sobre banco no log do servidor' }
        }

        ''
        '### 14) outros MySQL/MariaDB instalados na maquina (2 bancos = confusao)'
        foreach ($p in 'C:\Program Files\MariaDB 10.11','C:\Program Files\MariaDB 10.4','C:\Program Files\MySQL','C:\Program Files (x86)\MySQL','C:\MariaDB') {
            if (Test-Path $p) { '   EXISTE: ' + $p }
        }
        Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'maria|mysql' } |
            ForEach-Object { '   servico: ' + $_.Name + '  ' + $_.Status + '  ' + $_.DisplayName }
    }
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
