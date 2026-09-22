#!/usr/bin/env perl
# ============================================================================
# tools/spell_applications_report.pl
#
# Responde uma pergunta que o tools/spell_balance_report.pl NAO responde:
#   "quantas vezes por cast o dano desta magia cai no MESMO alvo?"
#
# Por que isso importa: o modelo de dano (AUDITORIA/VALIDACAO) calibra o `atk`
# de cada magia para o dano do CAST INTEIRO em um alvo. Se a magia aplica N
# vezes, cada aplicacao tem que valer orcamento/N. Magia de "sequencia" (air
# fan, air wings, air gust, air hurricane...) dispara N doCombat com o MESMO
# variant: e' N vezes o alvo. Sem contar isso, o cast entrega N x o orcamento.
#
# Como conta (estatico, lendo o proprio script):
#   1. acha as chamadas que aplicam dano   doCombat / sendCombat / doBurst /
#      doTargetCombatHealth / doAreaCombatHealth ...
#   2. sobe o arquivo contando os `for` que envolvem a chamada e resolve o
#      limite: numero fixo, `#nome` (conta as entradas da tabela `nome`) e
#      `#nome +/- k`;
#   3. para o padrao recursivo `f(..., times-1)` acha o `times` inicial
#      (o numero passado na primeira chamada dentro de onCastSpell ou na
#      chamada que o proprio cast agenda);
#   4. imprime, por magia, cada ponto de dano com o total resolvido, e marca
#      com '?' o que nao conseguiu resolver (revisar na mao).
#
# O numero de aplicacoes e' o MAXIMO de golpes no mesmo alvo (o pior caso, que
# e' o que a calibracao precisa): area/onda pode acertar menos se o alvo se
# mover no meio do cast.
#
# Uso:
#     perl tools/spell_applications_report.pl
#     perl tools/spell_applications_report.pl --only air
#     perl tools/spell_applications_report.pl --json          (para o emissor)
# ============================================================================

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use File::Spec;

binmode(STDOUT, ':utf8');

my $SCRIPT = abs_path($0);
my $ROOT   = dirname(dirname($SCRIPT));
my $SCRIPTS_DIR = File::Spec->catfile($ROOT, 'data', 'spells', 'scripts');

my %OPT = (only => undef, json => 0);
for my $arg (@ARGV) {
    if ($arg eq '--only') { $OPT{only} = lc(shift @ARGV); }
    elsif ($arg eq '--json') { $OPT{json} = 1; }
    else { die "opcao desconhecida: $arg\n"; }
}

my @ELEMENTS = qw(fire water air earth);

# A contagem OFICIAL mora em %APPLICATIONS (tools/spell_balance_report.pl): e' ela
# que o emissor de `atk` usa. O scanner daqui serve para achar magia de golpe
# multiplo que ainda NAO esta' na tabela (a coluna marca CANDIDATA).
my %APP;
{
    my $bal = File::Spec->catfile($ROOT, 'tools', 'spell_balance_report.pl');
    if (open(my $fh, '<', $bal)) {
        local $/;
        my $src = <$fh>;
        close($fh);
        if ($src =~ /my %APPLICATIONS = \((.*?)\n\);/s) {
            my $block = $1;
            while ($block =~ /'([^']+)'\s*=>\s*(\d+)/g) {
                $APP{$1} = $2;
            }
        }
    }
}

# Nomes que aplicam dano direto. `sendCombat`/`loopDamage`/`doBurst`/... sao
# helpers locais de cada script, entao a regra e' por PREFIXO conhecido.
my @DAMAGE_CALLS = qw(doCombat doTargetCombatHealth doAreaCombatHealth
                      sendCombat doBurst doHit loopDamage stormcallWork
                      doBomb doCharge doMelt doElectrify doDrown doBleed
                      tornadoWork windWork quakeWork posQuakeWork metalWorks
                      workGale workWind shardsWork doConflagration auraWork);

sub read_file {
    my ($path) = @_;
    open(my $fh, '<:encoding(UTF-8)', $path) or die "nao consegui abrir $path: $!";
    local $/;
    my $txt = <$fh>;
    close($fh);
    return $txt;
}

# Tamanho de uma tabela `Nome = { a, b, c }` / `Nome = { {..}, {..} }`
sub table_size {
    my ($txt, $name) = @_;
    my $q = quotemeta($name);
    # `Nome = {` no mesmo arquivo
    return undef unless $txt =~ /\b$q\s*=\s*\{/;
    my $start = pos($txt) - 1;
    my $rest  = substr($txt, $start);
    my $depth = 0;
    my $body;
    my $i = 0;
    for my $ch (split //, $rest) {
        $depth++ if $ch eq '{';
        $depth-- if $ch eq '}';
        $i++;
        if ($depth == 0) { $body = substr($rest, 1, $i - 2); last; }
    }
    return undef unless defined $body;
    # conta os grupos de nivel 1 separados por virgula
    my $d = 0;
    my $count = 0;
    my $has = 0;
    for my $ch (split //, $body) {
        if ($ch eq '{' || $ch eq '(') { $d++; $has = 1 if $d == 1 && $ch eq '{'; }
        elsif ($ch eq '}' || $ch eq ')') { $d--; }
        elsif ($ch eq ',' && $d == 0) { $count++ if $has || 1; }
    }
    $count++ if $body =~ /\S/;               # ultimo item
    return $count;
}

# Resolve um limite de `for` devolvendo o numero de iteracoes (ou undef).
sub resolve_bound {
    my ($txt, $expr) = @_;
    return undef unless defined $expr;
    $expr =~ s/^\s+|\s+$//g;
    return $1 + 0 if $expr =~ /^(\d+)$/;
    if ($expr =~ /^#(\w+)\s*$/) {
        my $n = table_size($txt, $1);
        return $n;
    }
    if ($expr =~ /^#(\w+)\s*([-+])\s*(\d+)$/) {
        my $n = table_size($txt, $1);
        return undef unless defined $n;
        return $2 eq '-' ? $n - $3 : $n + $3;
    }
    if ($expr =~ /^math\.(floor|ceil)\(\s*#(\w+)\s*\/\s*(\d+)\s*\)$/) {
        my $n = table_size($txt, $2);
        return undef unless defined $n;
        return $1 eq 'floor' ? int($n / $3) : int(($n + $3 - 1) / $3);
    }
    return undef;   # variavel, range, etc.
}

# Mapa linha -> lista de loops que a contem: { var, from, to_expr }
sub loop_map {
    my ($txt) = @_;
    my @lines = split /\n/, $txt;
    my @open;      # pilha de { var, from, to, start_line }
    my %by_line;   # linha -> [ listas de bounds ]
    my @stack_of_stacks;  # para casar `end` com o loop certo
    for my $i (0 .. $#lines) {
        my $ln = $lines[$i];
        while ($ln =~ /\bfor\s+(\w+)\s*=\s*([^,]+),\s*([^\s]+)\s*(?:,\s*[^\s]+)?\s*do\b/g) {
            push @open, { var => $1, from => $2, to => $3, line => $i + 1 };
        }
        if (@open) {
            $by_line{$i + 1} = [ map { { var => $_->{var}, from => $_->{from}, to => $_->{to} } } @open ];
        }
        # fecha loops: cada `end` fecha o ultimo for aberto (heuristica simples)
        my $ends = () = $ln =~ /\bend\b/g;
        while ($ends-- > 0 && @open) { pop @open; }
    }
    return \%by_line;
}

my @spells;
for my $el (@ELEMENTS) {
    next if defined $OPT{only} && $el ne $OPT{only};
    my $dir = File::Spec->catdir($SCRIPTS_DIR, $el);
    next unless -d $dir;
    opendir(my $dh, $dir) or next;
    for my $file (sort readdir($dh)) {
        next unless $file =~ /\.lua$/;
        next if $file =~ /\.bak/;
        next if $file =~ /\bold\b/i;      # scripts antigos, fora do spells.xml
        push @spells, { element => $el, file => File::Spec->catfile($dir, $file) };
    }
    closedir($dh);
}

my @out;
for my $sp (@spells) {
    my $txt = read_file($sp->{file});
    my $key = lc(basename($sp->{file}, '.lua'));
    my %loops = %{ loop_map($txt) };
    my @lines = split /\n/, $txt;
    my @points;
    my $unresolved = 0;

    for my $i (0 .. $#lines) {
        my $ln = $lines[$i];
        my $call;
        for my $fn (@DAMAGE_CALLS) {
            if ($ln =~ /\b\Q$fn\E\s*\(/) { $call = $fn; last; }
        }
        next unless $call;
        # a chamada precisa mandar dano: leva um combat/var na lista de args
        my $n = $i + 1;
        my $bounds = $loops{$n} // [];
        my $mult = 1;
        my @desc;
        for my $b (@$bounds) {
            my $r = resolve_bound($txt, $b->{to});
            if (defined $r) {
                my $from = ($b->{from} =~ /^(\d+)$/) ? $1 + 0 : 0;
                my $iters = $r - $from + 1;
                $iters = 1 if $iters < 1;
                $mult *= $iters;
                push @desc, "$b->{var}:$iters";
            } else {
                $unresolved = 1;
                push @desc, "$b->{var}:?";
            }
        }
        push @points, { line => $n, call => $call, mult => $mult, desc => join('/', @desc) };
    }

    my $total = 0;
    $total += $_->{mult} for @points;
    $total = 1 if $total < 1;
    push @out, {
        element => $sp->{element}, key => $key,
        points  => \@points, total => $total, unresolved => $unresolved,
    };
}

if ($OPT{json}) {
    my @j;
    for my $o (@out) {
        push @j, sprintf('{"spell":"%s %s","applications":%d,"unresolved":%s}',
            $o->{element}, $o->{key}, $o->{total}, $o->{unresolved} ? 'true' : 'false');
    }
    print "[\n  " . join(",\n  ", @j) . "\n]\n";
    exit 0;
}

printf "%-26s %8s  %s\n", 'magia', 'aplic.', 'pontos de dano (linha: chamada x multiplicador de loops)';
print '-' x 104, "\n";
for my $o (sort { ($a->{element} cmp $b->{element}) || ($a->{key} cmp $b->{key}) } @out) {
    my $full  = "$o->{element} $o->{key}";
    my $app   = $APP{$full};
    my $shown = defined $app ? $app : $o->{total};
    my $flag  = '';
    if (defined $app) {
        $flag = '  (tabela)';
        $flag .= " scanner=$o->{total}" if $o->{total} != $app;
    } elsif ($o->{total} > 1) {
        $flag = '  <== CANDIDATA (scanner achou mais de 1; conferir e lancar em %APPLICATIONS)';
    }
    $flag .= '  <== REVISAR (loop nao resolvido)' if $o->{unresolved};
    printf "%-26s %8d  %s%s\n", $full, $shown,
        join(' | ', map { sprintf('L%d %s x%d%s', $_->{line}, $_->{call}, $_->{mult},
                                  $_->{desc} ? " ($_->{desc})" : '') } @{ $o->{points} }),
        $flag;
}
print "\n(coluna 'aplic.' = %APPLICATIONS de tools/spell_balance_report.pl, a contagem\n";
print " oficial que o emissor de atk usa; onde aparece 'scanner=N' o scanner bruto\n";
print " discorda e o numero do scanner e' so' pista. `atk` de magia com N aplicacoes\n";
print " vale 1/N do orcamento da classe; magia fora da tabela vale 1 e entrega N x o\n";
print " orcamento -- foi o caso de air fan (15x) e air wings (10x), ver AUDITORIA secao 15)\n";
