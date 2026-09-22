#!/usr/bin/env perl
# ============================================================================
# tools/spell_level_drift.pl
#
# Mede quanto o dano de cada vocacao cresce entre dois levels, para achar
# deriva na hierarquia.
#
# O problema: o balanceamento e' ajustado em UM level (o de calibracao). Se as
# magias de uma vocacao escalam mais rapido com o level que as de outra, a
# ordem se desfaz no endgame (foi o que aconteceu: o air alcancava o fire
# perto do level 400).
#
# Este script le' dois snapshots JSON do medidor e mostra, por elemento, a
# mediana do fator de crescimento (dano no level B / dano no level A) das
# magias presentes nos DOIS snapshots. Fatores diferentes = deriva. Fatores
# iguais = a hierarquia se mantem em qualquer level.
#
#     perl tools/spell_balance_report.pl --level 100 --mag 50 --json > /tmp/a.json
#     perl tools/spell_balance_report.pl --level 300 --mag 50 --json > /tmp/b.json
#     perl tools/spell_level_drift.pl /tmp/a.json /tmp/b.json
# ============================================================================

use strict;
use warnings;

binmode(STDOUT, ':utf8');

my ($fileA, $fileB) = @ARGV;
die "uso: perl tools/spell_level_drift.pl antes.json depois.json\n" unless $fileA && $fileB;

sub load_json {
    my ($path) = @_;
    open(my $fh, '<:raw', $path) or die "nao consegui ler $path: $!";
    local $/;
    my $txt = <$fh>;
    close($fh);
    my %map;
    while ($txt =~ /\{"spell":"([^"]+)","element":"([^"]+)","level":(\d+),.*?"danoCast":([\d.]+)/g) {
        $map{$1} = { element => $2, level => $3 + 0, cast => $4 + 0 };
    }
    return \%map;
}

my $snapA = load_json($fileA);
my $snapB = load_json($fileB);

sub median {
    my @vals = sort { $a <=> $b } @_;
    return @vals ? $vals[int(@vals / 2)] : undef;
}

my %ratios;
for my $key (sort keys %$snapA) {
    next unless $snapB->{$key};
    next unless $snapA->{$key}{cast} > 0;
    push @{ $ratios{ $snapA->{$key}{element} } },
        { key => $key, ratio => $snapB->{$key}{cast} / $snapA->{$key}{cast}, level => $snapA->{$key}{level} };
}

printf "crescimento do dano entre os dois snapshots (magias presentes nos dois):\n";
print "-" x 74, "\n";
printf "%-8s %6s %12s %12s %12s\n", 'elemento', 'magias', 'mediana x', 'menor x', 'maior x';
my %growth;
for my $el (sort keys %ratios) {
    my @rows = @{ $ratios{$el} };
    my @all  = sort { $a <=> $b } map { $_->{ratio} } @rows;
    $growth{$el} = median(@all);
    printf "%-8s %6d %12.2f %12.2f %12.2f\n", $el, scalar(@rows), $growth{$el}, $all[0], $all[-1];
}

print "\nderiva = quanto a mediana de cada vocacao se afasta do fire nesta janela:\n";
if (defined $growth{fire} && $growth{fire} > 0) {
    for my $el (sort { $growth{$b} <=> $growth{$a} } grep { $_ ne 'fire' } keys %growth) {
        printf "  %-6s cresce %.3fx fire  (%+.1f%%)\n", $el, $growth{$el} / $growth{fire},
            (($growth{$el} / $growth{fire}) - 1) * 100;
    }
    print "\n  quanto mais perto de 0%, menos a hierarquia se mexe com o level.\n";
} else {
    print "  (sem fire nos snapshots?)\n";
}
