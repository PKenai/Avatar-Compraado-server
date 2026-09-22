#!/usr/bin/env perl
# ============================================================================
# tools/apply_level_scaling.pl
#
# Tira o bend level (magLevel) de dentro das formulas de dano das magias.
#
# Modelo novo:
#   * o LEVEL escala o dano (a formula vira linear em level)
#   * o bend vira um bonus plano de +1% por ponto, aplicado em UM lugar so'
#     (data/lib/avatar lib.lua, dentro de remakeValue/remakeAirEarth)
#
# Substituicao: `magLevel` -> `(level * 0.5)`
#
# O 0.5 nao e' chute: o valor da formula fica IDENTICO ao de hoje em
# level 100 / bend 50, ou seja no ponto onde o balanceamento foi calibrado
# (tools/spell_balance_report.pl --level 100 --mag 50). A partir dali o dano
# cresce com o level em vez de crescer com o bend. Ex.: fire lightning
#
#     antes:  level + (magLevel/3)*5.2      -> em level 100/bend 50 = 186.7
#     depois: level + (level*0.5/3)*5.2     -> em level 100        = 186.7
#
# O que o script NAO toca:
#   * curam/regeneracao (nao usam a variavel magLevel: usam getPlayerMagLevel
#     direto e nao passam por remakeValue) - continuam escalando com o bend
#   * data/spells/scripts/monster/* (monstro nao roda esse callback)
#   * passivos de set de armadura (avatarAttack.lua / imuneable.lua), que nao
#     passam por remakeValue/remakeAirEarth
#   * comentarios (inclusive dentro de --[[ ]]) e qualquer coisa depois de --
#
# Uso:
#     perl tools/apply_level_scaling.pl --dry     # so' mostra o que mudaria
#     perl tools/apply_level_scaling.pl --apply   # grava
# ============================================================================

use strict;
use warnings;
use utf8;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

binmode(STDOUT, ':utf8');

my $SCRIPT = abs_path($0);
my $ROOT   = dirname(dirname($SCRIPT));
my $DIRS   = [map { File::Spec->catdir($ROOT, 'data', 'spells', 'scripts', $_) } qw(fire water air earth)];

my $APPLY = grep { $_ eq '--apply' } @ARGV;
my $DRY   = !$APPLY;

# Fator que faz o bend virar level: 50 (bend de referencia) / 100 (level de
# referencia) = 0.5. Mesmo numero serve para TODA formula, porque level e
# magLevel aparecem sempre somados (mudar o coeficiente de um nao muda o
# resultado no ponto de referencia).
my $BEND_TO_LEVEL = 0.5;
my $BEND_REF      = 50;
my $LEVEL_REF     = 100;

my @changes;
my @skipped;
my $saw_code_magLevel = 0;
my $line_already_ok = 0;   # linha que ja' esta no formato novo (nada a fazer)

# ---------------------------------------------------------------------------
# Separa codigo de comentario. Devolve ($code, $comment). Trata bloco --[[ ]]
# via a variavel de estado $in_block.
# ---------------------------------------------------------------------------
my $in_block = 0;
sub split_comment {
    my ($line) = @_;
    if($in_block) {
        # linha inteira e' comentario de bloco; so' procura o fechamento
        $in_block = 0 if $line =~ /\]\]/;
        return ('', $line);
    }
    # abertura de bloco sem fechamento na mesma linha
    if($line =~ /\-\-\[\[/ && $line !~ /\-\-\[\[[^\]]*\]\]/) {
        my $p = index($line, '--[[');
        $in_block = 1;
        return (substr($line, 0, $p), substr($line, $p));
    }
    my $pos = index($line, '--');
    return $pos >= 0 ? (substr($line, 0, $pos), substr($line, $pos)) : ($line, '');
}

# ---------------------------------------------------------------------------
# Uma linha. Devolve (nova_linha, descricao_da_regra) ou undef se nao muda.
# ---------------------------------------------------------------------------
sub convert {
    my ($line) = @_;
    return undef unless $line =~ /magLevel/;

    my ($code, $comment) = split_comment($line);
    $saw_code_magLevel = 1 if $code =~ /\bmagLevel\b/;
    return undef unless $code =~ /\bmagLevel\b/;

    # Regras que mexem no VALOR da variavel (o local continua existindo, agora
    # valendo level*0.5). Elas tem prioridade e a linha nao passa pela regra 5,
    # senao o lado esquerdo da atribuicao viraria expressao.
    if($code =~ /^(\s*)local\s+magLevel\s*=\s*.*$/s) {
        my $novo = "$1local magLevel = level * $BEND_TO_LEVEL";
        return ["$novo$comment", "local magLevel = level * $BEND_TO_LEVEL"];
    }

    if($code =~ /\blevel\s*,\s*magLevel\s*=\s*50\s*,\s*30\b/) {
        my $novo = $code;
        $novo =~ s/\blevel\s*,\s*magLevel\s*=\s*50\s*,\s*30\b/level, magLevel = 50, 50 * $BEND_TO_LEVEL/;
        return ["$novo$comment", "default 50/30 -> 50/25 (50*sem o par)"];
    }

    if($code =~ /\blevel\s*,\s*magLevel\s*=\s*([^,]+),\s*getPlayerMagLevel\s*\(\s*(\w+)\s*\)/) {
        my ($lv, $cid) = ($1, $2);
        my $novo = $code;
        $novo =~ s/\blevel\s*,\s*magLevel\s*=\s*([^,]+),\s*getPlayerMagLevel\s*\(\s*\w+\s*\)/level, magLevel = $lv, ($lv) * $BEND_TO_LEVEL/;
        return ["$novo$comment", "getPlayerMagLevel vira o proprio level"];
    }

    # Assinatura de funcao: o parametro RECEBIDO do C++ nao e' mais usado, mas
    # precisa continuar existindo para a funcao aceitar os 3 argumentos.
    if($code =~ /(function[^()]*\([^()]*?)\bmagLevel\b/) {
        my $novo = $code;
        $novo =~ s/(function[^()]*\([^()]*?)\bmagLevel\b/${1}magLevelUnused/g;
        return ["$novo$comment", "parametro magLevel -> magLevelUnused (nao usado)"];
    }

    # Atribuicao ("local level, magLevel = ..."): aqui o magLevel e' o alvo da
    # atribuicao, nunca pode virar expressao. Quem cuida desse formato sao as
    # regras acima; se sobrou alguma, e' sinal de caso novo -> nao mexe.
    if($code =~ /\bmagLevel\s*=\s*(.*)$/) {
        my $rhs = $1;
        # ja' convertido: o lado direito e' o proprio level (ou o fator dele)
        $line_already_ok = 1 if $rhs =~ /\blevel\b/ || $rhs =~ /\*\s*\Q$BEND_TO_LEVEL\E/;
        return undef;
    }

    # Uso normal dentro da formula.
    my $novo = $code;
    my $n = ($novo =~ s/\bmagLevel\b/(level * $BEND_TO_LEVEL)/g);
    return undef unless $n;
    return ["$novo$comment", "$n uso(s) na formula -> (level * $BEND_TO_LEVEL)"];
}

# ---------------------------------------------------------------------------

my @files;
my $changed_files = 0;
for my $dir (@$DIRS) {
    opendir(my $dh, $dir) or die "sem $dir: $!";
    for my $f (sort readdir($dh)) {
        next unless $f =~ /\.lua\z/;
        push @files, File::Spec->catfile($dir, $f);
    }
    close($dh);
}

for my $file (@files) {
    open(my $in, '<:raw', $file) or die "leitura $file: $!";
    my @lines = <$in>;
    close($in);

    $in_block = 0;
    my @out;
    my $touched = 0;
    for my $i (0 .. $#lines) {
        my $line = $lines[$i];
        my $cr = ($line =~ s/\r\n\z/\n/) ? 1 : 0;   # preserva CRLF

        $saw_code_magLevel = 0;
        $line_already_ok = 0;
        my $res = convert($line);
        if($res) {
            my ($nova, $why) = @$res;
            $nova =~ s/\n\z//;
            $nova .= "\r\n" if $cr;
            # idempotencia: rodar de novo em cima do resultado nao reporta nada
            if($nova eq $lines[$i]) { push @out, $line; next; }
            push @out, $nova;
            push @changes, sprintf("%s:%d: %s | %s", rel($file), $i + 1, $why, trim($lines[$i]));
            $touched = 1;
        }
        else {
            push @out, $line;
            push @skipped, sprintf("%s:%d: NAO MEXIDO | %s", rel($file), $i + 1, trim($line))
                if $saw_code_magLevel && !$line_already_ok;
        }
    }

    next unless $touched;
    ++$changed_files;
    if($APPLY) {
        open(my $out, '>:raw', $file) or die "escrita $file: $!";
        print $out @out;
        close($out);
    }
}

sub rel { my $p = shift; $p =~ s/^\Q$ROOT\E[\\\/]//; return $p; }
sub trim { my $s = shift; $s =~ s/[\r\n]+\z//; $s =~ s/^\s+//; return $s; }

print(($APPLY ? "APLICADO" : "DRY-RUN (nada gravado)"), " | bend->level fator $BEND_TO_LEVEL",
    " (referencia: level $LEVEL_REF / bend $BEND_REF)\n\n");
print scalar(@changes), " linhas alteradas em $changed_files de ", scalar(@files), " arquivos varridos\n\n";
print "$_\n" for @changes;
if(@skipped) {
    print "\n", scalar(@skipped), " linha(s) com magLevel que NAO foram mexidas (conferir):\n";
    print "$_\n" for @skipped;
}
