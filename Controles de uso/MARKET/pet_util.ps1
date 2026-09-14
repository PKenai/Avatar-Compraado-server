<#
    pet_util.ps1 - utilidades de pets para o MARKET (adicionar_loja.bat).

    Le e escreve os pets em data\XML\pets.xml.

    Acoes:
      list -> imprime uma linha por pet, no formato:  indice|id|clientid|nome
      name -> imprime somente o nome do pet informado em -Id
      add  -> registra um pet novo no pets.xml e imprime o id criado

    Pets comentados no XML (dentro de <!-- -->) nao aparecem na listagem: o
    parser de XML ignora comentarios de proposito.

    A gravacao do 'add' e feita direto no texto do arquivo (inserindo a linha
    <pet ... /> antes de </pets>), para preservar os comentarios e a
    formatacao que voce ja tem no XML. Antes de gravar e salvo um backup em
    pets.xml.bak.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('list', 'name', 'add')]
    [string]$Action,

    [int]$Id = 0,
    [int]$ClientId = 0,
    [string]$PetName = '',
    [int]$Premium = 0
)

$ErrorActionPreference = 'Stop'

# Este script fica em <raiz do servidor>\Controles de uso\MARKET
$serverRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$petsXml = Join-Path $serverRoot 'data\XML\pets.xml'

if (-not (Test-Path -LiteralPath $petsXml)) {
    [Console]::Error.WriteLine("Arquivo nao encontrado: $petsXml")
    exit 1
}

try {
    $texto = [System.IO.File]::ReadAllText($petsXml)
    $doc = New-Object System.Xml.XmlDocument
    $doc.LoadXml($texto)
}
catch {
    [Console]::Error.WriteLine("Nao consegui ler o XML: $($_.Exception.Message)")
    exit 1
}

$pets = @($doc.pets.pet) | Where-Object { $_ -ne $null }

switch ($Action) {
    'list' {
        if ($pets.Count -eq 0) {
            [Console]::Error.WriteLine('Nenhum pet definido em data\XML\pets.xml')
            exit 2
        }

        $i = 0
        foreach ($pet in $pets) {
            $i++
            '{0}|{1}|{2}|{3}' -f $i, $pet.id, $pet.clientid, $pet.name
        }
    }

    'name' {
        $pet = $pets | Where-Object { [int]$_.id -eq $Id } | Select-Object -First 1
        if ($pet -eq $null) {
            exit 3
        }
        $pet.name
    }

    'add' {
        if ($ClientId -le 0) {
            [Console]::Error.WriteLine('clientid invalido: informe o sprite do pet no client.')
            exit 4
        }

        $nome = $PetName.Trim()
        if ([string]::IsNullOrWhiteSpace($nome)) {
            [Console]::Error.WriteLine('Informe o nome do pet.')
            exit 5
        }

        # nome repetido confunde a janela de escolha do pet
        $repetido = $pets | Where-Object { $_.name -ieq $nome } | Select-Object -First 1
        if ($repetido -ne $null) {
            [Console]::Error.WriteLine(('Ja existe um pet com esse nome: id={0}, clientid={1}' -f $repetido.id, $repetido.clientid))
            exit 6
        }

        # Proximo id livre. Olha o ARQUIVO INTEIRO (inclusive os pets comentados):
        # se um dia voce descomentar um deles, ele nao vai colidir de id.
        # O lookbehind evita casar com o "id" de dentro de clientid="...".
        $ids = @([regex]::Matches($texto, '(?<![A-Za-z])id\s*=\s*"(\d+)"') | ForEach-Object { [int]$_.Groups[1].Value })
        $novoId = 1
        if ($ids.Count -gt 0) {
            $novoId = ($ids | Measure-Object -Maximum).Maximum + 1
        }
        if ($novoId -gt 255) {
            [Console]::Error.WriteLine('Limite de 255 pets atingido (o id do pet e um byte).')
            exit 7
        }

        # texto seguro para o XML
        $nomeXml = $nome -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;'
        $atribPremium = ''
        if ($Premium -ne 0) {
            $atribPremium = ' premium="1"'
        }

        $quebra = "`n"
        if ($texto.Contains("`r`n")) {
            $quebra = "`r`n"
        }

        $fechamento = '</pets>'
        $pos = $texto.LastIndexOf($fechamento)
        if ($pos -lt 0) {
            [Console]::Error.WriteLine('O pets.xml nao tem a tag de fechamento </pets>.')
            exit 8
        }

        $novaLinha = '    <pet id="{0}" clientid="{1}" name="{2}"{3} />' -f $novoId, $ClientId, $nomeXml, $atribPremium
        $novoTexto = $texto.Substring(0, $pos) + $novaLinha + $quebra + $texto.Substring($pos)

        # valida antes de gravar (se eu montar um XML invalido, nada e escrito)
        try {
            $teste = New-Object System.Xml.XmlDocument
            $teste.LoadXml($novoTexto)
        }
        catch {
            [Console]::Error.WriteLine("Abortado: o XML ficaria invalido. Detalhe: $($_.Exception.Message)")
            exit 9
        }

        Copy-Item -LiteralPath $petsXml -Destination ($petsXml + '.bak') -Force
        [System.IO.File]::WriteAllText($petsXml, $novoTexto, (New-Object System.Text.UTF8Encoding($false)))

        $novoId
    }
}
