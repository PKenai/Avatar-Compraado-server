#!/usr/bin/perl
# Valida data/lib/201-spellsExausted.lua:
#  1) toda linha de entrada precisa terminar em ',' quando a proxima linha nao-vazia
#     for outra entrada ou o fechamento '}' (o erro real: "'}' expected ... near '['")
#  2) chaves/colchetes/parênteses balanceados
use strict;
use warnings;

my $file = shift @ARGV or die "uso: $0 <arquivo>\n";
open my $fh, '<:raw', $file or die "nao abriu $file: $!";
my $raw = do { local $/; <$fh> };
close $fh;

# Quebra CRLF, preservando o numero de linha
my @lines = split /\r\n|\n/, $raw, -1;

# Versao sem comentarios (linha e bloco), mantendo a contagem de linhas intacta
my $code = $raw;
$code =~ s/--\[\[.*?\]\]-?//gs;   # comentarios de bloco
$code =~ s/\r\n|\n/\n/g;
my @code = split /\n/, $code, -1;

# Remove comentario de linha (-- ...), respeitando strings
sub strip_line_comment {
    my ($s) = @_;
    my $in_str = 0; my $q = '';
    for my $i (0 .. length($s) - 1) {
        my $c = substr($s, $i, 1);
        if ($in_str) { $in_str = 0 if $c eq $q; next; }
        if ($c eq '"' || $c eq "'") { $in_str = 1; $q = $c; next; }
        return substr($s, 0, $i) if $c eq '-' && substr($s, $i + 1, 1) eq '-';
    }
    return $s;
}
my @nodash = map { strip_line_comment($_) } @code;

my $issues = 0;

# --- 1) virgulas ---
for my $i (0 .. $#nodash) {
    my $t = $nodash[$i];
    next unless $t =~ /^\s*\[".*"\]\s*=\s*/;   # linha de entrada
    $t =~ s/\s+$//;
    next if $t =~ /,$/;                        # ja tem virgula
    # so interessa quando o valor FECHA nesta linha (senao e' tabela multi-linha)
    next unless $t =~ /[}\]]\s*$/;
    my ($nxt) = grep { /\S/ } @nodash[$i + 1 .. $#nodash];
    next if !defined $nxt || $nxt =~ /^\s*\}/;  # ultima entrada da tabela: ok
    # proxima entrada de verdade (nao continuacao de valor multilinha)
    next unless $nxt =~ /^\s*\[/;
    printf "L%-4d FALTA VIRGULA -> %s\n", $i + 1, $lines[$i];
    $issues++;
}

# --- 2) balanceamento ---
my $joined = join("\n", @nodash);
my %pairs = ('{' => '}', '[' => ']', '(' => ')');
my @stack; my $in_str = 0; my $q = '';
for my $i (0 .. length($joined) - 1) {
    my $c = substr($joined, $i, 1);
    if ($in_str) { $in_str = 0 if $c eq $q; next; }
    if ($c eq '"' || $c eq "'") { $in_str = 1; $q = $c; next; }
    if (exists $pairs{$c}) { push @stack, [$c, $i]; }
    elsif ($c eq '}' || $c eq ']' || $c eq ')') {
        my $top = pop @stack;
        if (!$top || $pairs{$top->[0]} ne $c) {
            my $line = 1 + (substr($joined, 0, $i) =~ tr/\n//);
            print "L$line FECHA '$c' SEM ABRIR\n";
            $issues++;
        }
    }
}
for my $t (@stack) {
    my $line = 1 + (substr($joined, 0, $t->[1]) =~ tr/\n//);
    printf "L%-4d ABRE '%s' E NAO FECHA\n", $line, $t->[0];
    $issues++;
}

print $issues ? "\n$issues problema(s) encontrado(s)\n" : "OK: nenhuma virgula faltando, balanceamento integro\n";
print "arquivo: $file  linhas: ", scalar(@lines) - 1, "\n";
exit($issues ? 1 : 0);
