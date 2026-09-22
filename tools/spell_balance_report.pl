#!/usr/bin/env perl
# ============================================================================
# tools/spell_balance_report.pl
#
# Mede o dano estimado de TODAS as magias de player (fire/water/air/earth) para
# auditar a hierarquia de dano das vocacoes:
#
#     fire  >  air (~10% menos)  >  earth  >  water (menos dano, mais suporte)
#
# Nada e' chutado: o numero sai da propria fonte do jogo.
#
#   * o "atk" de cada magia vem de data/lib/201-spellsExausted.lua (spellsInfo)
#   * a formula vem do callback onGetPlayerMinMaxValues do script da magia
#     (data/spells/scripts/<elemento>/<magia>.lua)
#   * level/mana/cooldown vem de data/spells/spells.xml
#   * o bend level e' um bonus plano de +1% por ponto, aplicado dentro de
#     remakeValue/remakeAirEarth; o coluna "dano" ja' inclui esse bonus, o
#     --emit NAO (o atk entra antes dele na conta)
#   * o multiplicador por elemento da camada nova (data/lib/avatar lib.lua,
#     bloco SPELL_BALANCE) e o bonus de bend level
#     entra no fim, para o relatorio mostrar o dano final que o jogador ve.
#
# O callback e' interpretado, nao executado: as expressoes Lua viram expressoes
# aritmeticas depois de trocar level/magLevel/atk/cf.*/spellsInfo[...] por
# numeros. Se a expressao tiver algo que o interpretador nao entende, a magia
# e' listada como "manual" em vez de inventar um numero.
#
# Uso:
#     perl tools/spell_balance_report.pl
#     perl tools/spell_balance_report.pl --level 50 --mag 25
#     perl tools/spell_balance_report.pl --level 200 --only fire
#     perl tools/spell_balance_report.pl --dobras 22 --json
# ============================================================================

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use File::Spec;

binmode(STDOUT, ':utf8');

my $SCRIPT = abs_path($0);
my $ROOT   = dirname(dirname($SCRIPT));

my $SPELLS_XML   = File::Spec->catfile($ROOT, 'data', 'spells', 'spells.xml');
my $SPELLS_INFO  = File::Spec->catfile($ROOT, 'data', 'lib', '201-spellsExausted.lua');
my $BALANCE_LIB  = File::Spec->catfile($ROOT, 'data', 'lib', 'avatar lib.lua');
my $SCRIPTS_DIR  = File::Spec->catfile($ROOT, 'data', 'spells', 'scripts');

# ============================================================================
# ALVO DE DANO (usado no --emit)
#
# Dano alvo de UM cast em UM alvo, antes do fator por elemento:
#
#     alvo(level, shape) = (BASE + POR_LEVEL * level) * SHAPE{shape}
#
# shape vem do proprio spells.xml:
#   target = needtarget   (alvo unico)
#   beam   = direction    (cone/leque na direcao olhada)
#   self   = selftarget   (area em volta do conjurador)
#   area   = sem area declarada (area generica)
# ============================================================================
my $TARGET_BASE     = 300;
my $TARGET_PER_LEVEL = 3.0;
my %SHAPE_FACTOR = (
    target => 1.00,
    beam   => 0.95,
    area   => 0.85,
    self   => 0.75,
);

# Magias que aplicam dano mais de uma vez por cast (DoT, pulsos, ondas,
# hits divididos, bomba com fuse). Nelas o medidor conta SO' uma aplicacao,
# entao o reajuste e' conservador: nunca sobe mais que 25%.
my %MULTI_APPLICATION = map { $_ => 1 } (
    'fire cinder', 'fire star', 'fire thunderstorm', 'fire discharge', 'fire conflagration',
    'water shards', 'water flow', 'water blizzard', 'water tsunami', 'water clock', 'water bloodbending',
    'air vortex', 'air suffocation', 'air bomb', 'air stormcall', 'air windstorm', 'air doom', 'air trap',
    'earth crush', 'earth quake', 'earth aura', 'earth lavaball', 'earth leech', 'earth cataclysm',
);

# level/mag(bend)/dobras de referencia usados na medicao
# bonus de +1% por ponto de bend - carregado de data/lib/avatar lib.lua
my $BEND_PER_POINT = 0.01;
my %OPT = (level => 100, mag => 50, dobras => 10, only => undef, json => 0, debug => 0,
           emit => 0, apply => 0);

my @ELEMENTS = qw(fire water air earth);

# Golpes por cast das magias multi-hit (o resto e' 1 aplicacao por cast).
my %HITS_OVERRIDE = (
    'fire thunderstorm' => 6,     # for j=1,2 x 3 areas
    'fire star'         => 8,     # a magia divide o dano em 8 hits
    'air vortex'        => 32,    # 16 pulsos x 2 areas
    'earth crush'       => 3,     # 3 ondas (4 no elite)
);

# Magias cujo dano nao passa por remakeValue/remakeAirEarth (portanto ficam de
# fora do multiplicador por elemento da camada nova).
my %NO_ELEMENT_FACTOR = map { $_ => 1 } ();

sub opt { my $k = shift; return $OPT{$k}; }

# ----------------------------------------------------------------------------
# Leitura das fontes
# ----------------------------------------------------------------------------

sub read_file {
    my ($path) = @_;
    open(my $fh, '<:encoding(UTF-8)', $path) or die "nao consegui abrir $path: $!";
    local $/;
    my $txt = <$fh>;
    close($fh);
    return $txt;
}

sub load_spells_info {
    my $txt = read_file($SPELLS_INFO);
    my $idx = index($txt, 'spellsInfo');
    $txt = substr($txt, $idx) if $idx > 0;
    my %out;
    while ($txt =~ /\["([^"]+)"\]\s*=\s*\{([^}]*)\}/g) {
        my ($name, $body) = (lc($1), $2);
        my %fields;
        while ($body =~ /(\w+)\s*=\s*(-?[\d.]+)/g) {
            $fields{$1} = $2 + 0;
        }
        $out{$name} = \%fields;
    }
    return \%out;
}

sub load_exausted {
    my $txt = read_file($SPELLS_INFO);
    my %out;
    for my $el (@ELEMENTS) {
        my $re = qr/${el}Exausted\s*=\s*\{(.*?)\n\}/s;
        next unless $txt =~ $re;
        my $body = $1;
        while ($body =~ /(\w+)\]?\s*=\s*(\d+)/g) {
            $out{$el}{lc($1)} = $2 + 0;
        }
    }
    return \%out;
}

sub load_balance {
    my %table = map { $_ => 1.0 } @ELEMENTS;
    return \%table unless -f $BALANCE_LIB;
    my $txt = read_file($BALANCE_LIB);
    if ($txt =~ /SPELL_BALANCE\s*=\s*\{(.*?)\n\}/s or $txt =~ /SPELL_BALANCE\s*=\s*\{(.*?)\}/s) {
        my $block = $1;
        for my $el (@ELEMENTS) {
            $table{$el} = $1 + 0 if $block =~ /\b$el\b\s*=\s*([\d.]+)/;
        }
    }
    return \%table;
}

# O bend e' um bonus plano de +1% por ponto, aplicado dentro de
# remakeValue/remakeAirEarth (data/lib/avatar lib.lua). O valor e' lido do
# proprio arquivo para o relatorio nao mentir se alguem mexer no numero.
sub load_bend_per_point {
    return 0.01 unless -f $BALANCE_LIB;
    my $txt = read_file($BALANCE_LIB);
    return $1 + 0 if $txt =~ /SPELL_BALANCE_BEND_PER_POINT\s*=\s*([\d.]+)/;
    return 0.01;
}

# Escalamento extra por level (SPELL_BALANCE_LEVEL_GROWTH): a partir do
# SPELL_BALANCE_LEVEL_BASE o elemento cresce um pouco mais rapido, ate' o teto.
# Lido do proprio lib para o relatorio nao mentir se alguem mexer nos numeros.
sub load_level_growth {
    my %table;
    return \%table unless -f $BALANCE_LIB;
    my $txt = read_file($BALANCE_LIB);
    if ($txt =~ /SPELL_BALANCE_LEVEL_GROWTH\s*=\s*\{(.*?)\}/s) {
        my $block = $1;
        while ($block =~ /(\w+)\s*=\s*([\d.]+)/g) {
            $table{lc($1)} = $2 + 0;
        }
    }
    return \%table;
}

sub load_level_growth_window {
    my $txt = (-f $BALANCE_LIB) ? read_file($BALANCE_LIB) : '';
    my $base = ($txt =~ /SPELL_BALANCE_LEVEL_BASE\s*=\s*([\d.]+)/) ? $1 + 0 : 100;
    my $cap  = ($txt =~ /SPELL_BALANCE_LEVEL_GROWTH_CAP\s*=\s*([\d.]+)/) ? $1 + 0 : 0;
    return ($base, $cap);
}

sub load_spell_entries {
    my $txt = read_file($SPELLS_XML);
    my @entries;
    while ($txt =~ m{<(instant|rune)\b([^>]*?)(?:/>|>(.*?)</\1>)}gs) {
        my $attrs_txt = ($2 // '') . ' ' . ($3 // '');
        my %attrs;
        while ($attrs_txt =~ /([\w]+)\s*=\s*"([^"]*)"/g) {
            $attrs{$1} = $2;
        }
        my @vocs = map { $_ + 0 } ($attrs_txt =~ /<vocation id="(\d+)"/g);
        @vocs = grep { $_ >= 1 && $_ <= 4 } @vocs;
        my $value = $attrs{value} // '';
        next unless @vocs && length $value;
        my @parts = split(m{/}, $value);
        next unless @parts == 2 && grep { $_ eq $parts[0] } @ELEMENTS;
        my $shape = $attrs{needtarget} ? 'target'
                  : $attrs{direction}  ? 'beam'
                  : $attrs{selftarget} ? 'self'
                  : 'area';
        push @entries, {
            name    => ($attrs{name} // ''),
            element => $parts[0],
            script  => $value,
            level   => ($attrs{lvl} // 0) + 0,
            mana    => ($attrs{mana} // 0) + 0,
            cd      => defined $attrs{exhaustion} ? $attrs{exhaustion} / 1000 : 0,
            shape   => $shape,
            vocs    => \@vocs,
        };
    }
    return @entries;
}

sub find_spell_key {
    my ($lua, $xml_name, $info) = @_;
    return lc($1) if $lua =~ /local\s+spellName\s*=\s*"([^"]+)"/;
    my $key = lc($xml_name);
    return $key if exists $info->{$key};
    return undef;
}

# ----------------------------------------------------------------------------
# Interpretador minimo dos callbacks de dano
# ----------------------------------------------------------------------------

sub fmt {
    my ($v) = @_;
    return '0' unless defined $v;
    return sprintf('%.10g', $v);
}

sub mid_random {
    my ($args) = @_;
    my @parts = split(/,/, $args);
    my @nums;
    for my $p (@parts) {
        $p =~ s/^\s+|\s+$//g;
        return undef unless $p =~ /^-?[\d.]+$/;
        push @nums, $p + 0;
    }
    return undef unless @nums;
    return ($nums[0] + $nums[-1]) / 2;
}

sub info_value {
    my ($info, $name, $field, $fallback) = @_;
    my $entry = $info->{lc($name)} // {};
    return $entry->{$field} if defined $entry->{$field};
    return defined $fallback ? $fallback : 100;
}

my %UNKNOWN_COND = ();

sub eval_condition {
    my ($cond) = @_;
    return 0 if $cond =~ /getPlayerInWaterWithUnderwater/;
    return 0 if $cond =~ /exhaustion\.check|canUseWaterSpell|isInPvz|getTileInfo/;
    return 1 if $cond =~ /type\s*\(\s*atk\s*\)|type\s*\(\s*heal\s*\)|type\s*\(\s*cf\./;
    if ($cond =~ /getDobrasLevel\s*\(\s*\w+\s*\)\s*>=\s*(\d+)/) {
        return opt('dobras') >= $1 ? 1 : 0;
    }
    if ($cond =~ /getDobrasLevel\s*\(\s*\w+\s*\)\s*>\s*(\d+)/) {
        return opt('dobras') > $1 ? 1 : 0;
    }
    if ($cond =~ /getDobrasLevel/) {
        return 1;
    }
    return 0 if $cond =~ /^\s*\w+\s*<=?\s*\d+\s*$/;   # i > 4 (loop interno)
    return 0 if $cond =~ /^\s*\w+\s*>=\s*\d+\s*$/;
    $UNKNOWN_COND{$cond}++;
    return 0;
}

sub safe_eval {
    my ($expr, $env) = @_;
    my $e = $expr;
    # math.max(1, X) em volta de tudo: o dano e' o X
    $e =~ s/^\s*math\.(?:max|min)\s*\(\s*[\d.]+\s*,\s*(.*?)\s*\)\s*$/$1/s;
    # wrappers do datapack em volta do dano: o valor e' o que importa
    $e =~ s/\bremakeValue\s*\(\s*\d+\s*,\s*([^,()]+)\s*,\s*\w+\s*\)/$1/g;
    $e =~ s/\bremakeAirEarth\s*\(\s*\w+\s*,\s*([^,()]+)\s*\)/$1/g;
    $e =~ s/\b(?:spellStageScale|spellStageHeal|spellStageDuration)\s*\([^()]*\)/1/g;
    $e =~ s/getPlayerMagLevel\s*\(\s*\w+\s*\)/$env->{magLevel}/g;
    $e =~ s/getPlayerLevel\s*\(\s*\w+\s*\)/$env->{level}/g;
    $e =~ s/getCreatureMaxHealth\s*\(\s*\w+\s*\)/0/g;
    $e =~ s/getPlayerStorageValue\s*\([^)]*\)/0/g;
    $e =~ s/spellsInfo\s*\[\s*"([^"]+)"\s*\]\s*\.\s*(\w+)/info_value($env->{info}, $1, $2)/ge;
    $e =~ s/spellsInfo\s*\[\s*"([^"]+)"\s*\]\s*\[\s*"(\w+)"\s*\]/info_value($env->{info}, $1, $2)/ge;
    $e =~ s/\bcf\.(\w+)/exists $env->{cf}{$1} ? $env->{cf}{$1} : 1/ge;
    for my $n (qw(min max dano m atk heal multiplo multipler multiplier value)) {
        my $default = ($n eq 'm') ? 0 : 1;
        my $v = exists $env->{$n} ? fmt($env->{$n}) : $default;
        $e =~ s/\b$n\b/$v/g;
    }
    $e =~ s/\blevel\b/$env->{level}/g;
    $e =~ s/\bmagLevel\b/$env->{magLevel}/g;
    $e =~ s/\bmath\.random\s*\(([^()]*)\)/fmt(mid_random($1))/ge;
    $e =~ s/\bmath\.(?:floor|ceil)\s*\(([^()]*)\)/($1)/g;
    $e =~ s/\bmath\.max\s*\(([^()]*),[^()]*\)/($1)/g;
    $e =~ s/\bmath\.min\s*\(([^()]*),[^()]*\)/($1)/g;
    $e =~ s/\bmath\.abs\s*\(([^()]*)\)/($1)/g;
    $e =~ s/\bsqrt\b/__SQRT__/g;
    $e =~ s/#\w+/1/g;
    $e =~ s/[A-Za-z_]\w*/1/g;
    $e =~ s/__SQRT__/sqrt/g;
    if ($e !~ /^[\d\s.+\-*\/()a-z]+$/) {
        warn "  [debug] expr nao suportada: $e\n" if opt('debug') > 1;
        return undef;
    }
    my $v = eval $e;    ## no critic
    if ($@ || !defined $v) {
        warn "  [debug] eval falhou: $e ($@)\n" if opt('debug');
        return undef;
    }
    return undef if $v != $v;    # NaN
    return $v + 0;
}

sub run_body {
    my ($body, $env) = @_;
    my @stack = (1);
    my @lines;
    # if COND then STMT end (tudo numa linha) vira STMT ou desaparece
    for my $raw (split(/\n/, $body)) {
        my $line = $raw;
        $line =~ s/--(?!\[\[).*$//;
        $line =~ s/^\s+|\s+$//g;
        if ($line =~ /^(?:if|elseif)\s+(.*?)\s+then\s+(?!$)(.*?)\s*end\s*$/) {
            my ($cond, $inner) = ($1, $2);
            next if $inner =~ /^else\b/;
            push @lines, eval_condition($cond) ? $inner : '';
            next;
        }
        push @lines, $raw;
    }
    for my $raw (@lines) {
        my $line = $raw;
        $line =~ s/--(?!\[\[).*$//;
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;
        next if $line =~ /^function\s/;
        next if $line =~ /^(?:local\s+)?\w+\s*=\s*function/;
        if ($line =~ /^else\s*$/) {
            $stack[-1] = !$stack[-1] if @stack > 1;
            next;
        }
        if ($line =~ /^(?:if|elseif)\b/) {
            my $cond = 0;
            if ($line =~ /^(?:if|elseif)\s+(.*?)\s+then\b/) {
                $cond = eval_condition($1);
            }
            push @stack, ($cond && $stack[-1]) ? 1 : 0;
            next;
        }
        if ($line =~ /^for\b/) {
            $env->{$1} = $2 + 0 if $line =~ /^for\s+(\w+)\s*=\s*([\d.]+)\s*,/;
            push @stack, $stack[-1];
            next;
        }
        if ($line =~ /^(?:end|until)\b/) {
            pop @stack if @stack > 1;
            next;
        }
        next unless $stack[-1];
        if ($line =~ /^return\s+(.*)$/) {
            my $ret = $1;
            $ret =~ s/[{}]//g;              # return {a, b} (tabela de min/max)
            $ret =~ s/^\s+|\s+$//g;
            my ($first) = split(/,/, $ret);
            $first =~ s/^\s+|\s+$//g;
            my $v = safe_eval($first, $env);
            warn "  [debug] return $first = " . (defined $v ? $v : 'undef') . "\n" if opt('debug');
            return undef unless defined $v;
            $v = abs($v);
            return [$v, $v, $v];
        }
        if ($line =~ /^(?:local\s+)?(\w+)\s*=\s*(.+)$/) {
            my ($name, $expr) = ($1, $2);
            $expr =~ s/^\s+|\s+$//g;
            if ($name =~ /^(?:min|max|dano|m|atk|heal)$/) {
                my $v = safe_eval($expr, $env);
                # min/max/dano/m sao o eixo do dano: sem eles o corpo nao vale
                if (!defined $v && $name =~ /^(?:min|max|dano|m)$/) {
                    warn "  [debug] nao avaliei: $name <- $expr\n" if opt('debug');
                    return undef;
                }
                warn "  [debug] $name = $v  <= $expr\n" if opt('debug') && defined $v;
                $env->{$name} = $v if defined $v;
            }
            next;
        }
    }
    return undef;
}

sub callback_bodies {
    my ($lua) = @_;
    my @bodies;
    # Qualquer funcao com calculo de dano: onGetPlayerMinMaxValues, calcDano,
    # getMinAndMax... todas usam o mesmo esqueleto min/max/dano/atk.
    while ($lua =~ /function\s+(\w+)\s*\(([^)]*)\)/g) {
        my $start = pos($lua);
        my $rest = substr($lua, $start);
        my $depth = 1;
        my $endpos;
        while ($rest =~ /\b(function|if|for|while|repeat|end)\b/g) {
            my $word = $1;
            if ($word eq 'end') {
                $depth--;
                if ($depth == 0) {
                    $endpos = $start + pos($rest) - 3;
                    last;
                }
            } else {
                $depth++;
            }
        }
        my $body = defined $endpos ? substr($lua, $start, $endpos - $start) : substr($lua, $start);
        push @bodies, $body if $body =~ /local\s+(?:min|max|dano)\s*=/;
    }
    return @bodies;
}

sub measure_script {
    my ($path, $info, $xml_name) = @_;
    my $lua = read_file($path);
    my $key = find_spell_key($lua, $xml_name, $info);
    my $fields = defined $key ? ($info->{$key} // {}) : {};
    my %cf;
    for my $name (qw(atk heal atk2 segundos bolhas multiplicadorImpacto multiplicadorAoe
                     multiplicadorElectrify chanceFrozzen)) {
        $cf{$name} = $fields->{$name} if defined $fields->{$name};
    }
    my %env = (
        level    => opt('level'),
        magLevel => opt('mag'),
        info     => $info,
        cf       => \%cf,
    );
    my @bodies = callback_bodies($lua);
    return { nodamage => 1 } unless @bodies;
    my @values;
    my $failed = 0;
    for my $body (@bodies) {
        my %copy = %env;
        my $got = run_body($body, \%copy);
        if (defined $got) {
            push @values, $got->[2];
        } else {
            $failed++;
        }
    }
    return undef unless @values;
    my ($max) = sort { $b <=> $a } @values;
    my ($cd_key) = $lua =~ /\b(?:fire|water|air|earth)Exausted\.(\w+)/;
    my $combats = () = $lua =~ /\b(?:doCombat|doTargetCombatHealth|doAreaCombatHealth)\s*\(/g;
    return {
        key     => $key,
        atk     => (defined $fields->{atk} ? $fields->{atk}
                  : defined $fields->{heal} ? $fields->{heal} : undef),
        dmg     => $max,
        hits    => ($HITS_OVERRIDE{$key // ''} // 1),
        failed  => $failed,
        cd_key  => $cd_key,
        combats => $combats,
        remake  => ($lua =~ /remakeValue|remakeAirEarth/) ? 1 : 0,
    };
}

# ----------------------------------------------------------------------------
# Relatorio
# ----------------------------------------------------------------------------

sub parse_args {
    my @argv = @_;
    while (@argv) {
        my $arg = shift @argv;
        if ($arg eq '--level')  { $OPT{level}  = shift(@argv) + 0; }
        elsif ($arg eq '--mag') { $OPT{mag}    = shift(@argv) + 0; }
        elsif ($arg eq '--dobras') { $OPT{dobras} = shift(@argv) + 0; }
        elsif ($arg eq '--only') { $OPT{only} = lc(shift(@argv)); }
        elsif ($arg eq '--json') { $OPT{json} = 1; }
        elsif ($arg eq '--debug') { $OPT{debug} = 2; }
        elsif ($arg eq '--emit') { $OPT{emit} = 1; }
        elsif ($arg eq '--apply') { $OPT{apply} = 1; }
        else { die "opcao desconhecida: $arg\n"; }
    }
}

# ----------------------------------------------------------------------------
# --emit / --apply: reajusta o atk de cada magia para o alvo da sua faixa
# ----------------------------------------------------------------------------

sub emit_atk {
    my ($rows) = @_;
    my $txt = read_file($SPELLS_INFO);
    my @changes;
    my @report;

    for my $r (sort { $a->{level} <=> $b->{level} } @$rows) {
        my $key = $r->{key};
        next unless defined $key && defined $r->{atk};
        my $level  = $r->{level};
        my $shape  = $r->{shape} // 'target';
        my $target = ($TARGET_BASE + $TARGET_PER_LEVEL * $level) * ($SHAPE_FACTOR{$shape} // 0.8);
        # A curva e' dano de UM golpe. Nas magias de varios golpes (DoT, pulsos,
        # ondas) o medidor conta so' uma aplicacao, entao e' ela que vai pra
        # curva: o numero de golpes e' a forca propria da magia.
        my $multi    = $MULTI_APPLICATION{$key};
        my $measured = $multi ? $r->{dmg} : $r->{dmg} * $r->{hits};
        next unless $measured > 0;
        my ($lo, $hi) = (0.40, 2.50);
        my $mult = $target / $measured;
        $mult = $lo if $mult < $lo;
        $mult = $hi if $mult > $hi;
        my $old = $r->{atk};
        my $new = int($old * $mult + 0.5);
        $new = 1 if $new < 1;
        my $tag = $multi ? 'multi/hit' : 'single';
        push @report, sprintf('  %-24s lvl %3d %-7s %-6s atk %5d -> %5d   (alvo %6.0f, medido %6.0f, x%.2f)',
            $key, $level, $r->{element}, $tag, $old, $new, $target, $measured, $mult);
        next if abs($mult - 1) < 0.10;
        push @changes, { key => $key, old => $old, new => $new };
    }

    print "atk proposto por magia (alvo = (", $TARGET_BASE, ' + ', $TARGET_PER_LEVEL,
        " * level) * shape):\n";
    print join("\n", @report), "\n\n";
    printf "%d magias mudariam de atk.\n", scalar(@changes);

    if (!opt('apply')) {
        print "\n(rode com --apply para gravar em data/lib/201-spellsExausted.lua)\n";
        return 0;
    }

    my $applied = 0;
    for my $ch (@changes) {
        my $key = quotemeta($ch->{key});
        my $re = qr/(\["$key"\]\s*=\s*\{[^}]*?\batk\s*=\s*)$ch->{old}\b/;
        if ($txt =~ $re) {
            $txt =~ s/$re/$1$ch->{new}/;
            $applied++;
        } else {
            warn "nao achei a entrada de $ch->{key} (atk $ch->{old}) em 201-spellsExausted.lua\n";
        }
    }
    my $fh;
    open($fh, '>:encoding(UTF-8)', $SPELLS_INFO) or die "nao consegui gravar $SPELLS_INFO: $!";
    print $fh $txt;
    close($fh);
    printf "%d entradas de atk gravadas em data/lib/201-spellsExausted.lua\n", $applied;
    return 0;
}

sub main {
    parse_args(@ARGV);

    my $info     = load_spells_info();
    my $balance  = load_balance();
    my $growth   = load_level_growth();
    my ($growth_base, $growth_cap) = load_level_growth_window();
    $BEND_PER_POINT = load_bend_per_point();
    my $exausted = load_exausted();
    my (@rows, @manual);

    for my $entry (load_spell_entries()) {
        next if defined opt('only') && $entry->{element} ne opt('only');
        my $path = File::Spec->catfile($SCRIPTS_DIR, $entry->{element}, basename($entry->{script}));
        if (!-f $path) {
            push @manual, [$entry, 'script ausente'];
            next;
        }
        my $got = measure_script($path, $info, $entry->{name});
        if (!defined $got) {
            push @manual, [$entry, 'formula nao interpretada'];
            next;
        }
        if ($got->{nodamage}) {
            push @manual, [$entry, 'sem formula de dano (buff/heal/efeito)'];
            next;
        }
        my $factor = $NO_ELEMENT_FACTOR{$got->{key} // ''} ? 1 : $balance->{$entry->{element}};
        my %row = (%$entry, %$got);
        # o cooldown de verdade e' o da tabela *Exausted (e' ele que vai pro client)
        if (defined $got->{cd_key} && defined $exausted->{$entry->{element}}{$got->{cd_key}}) {
            $row{cd} = $exausted->{$entry->{element}}{$got->{cd_key}};
        }
        # Escalamento extra por level (hoje so' a agua tem): vale para qualquer
        # magia do elemento que passe por applySpellBalance.
        my $lvl_bonus = 1;
        if (my $g = $growth->{$entry->{element}}) {
            my $over = opt('level') - $growth_base;
            if ($over > 0) {
                my $b = $over * $g;
                $b = $growth_cap if $b > $growth_cap;
                $lvl_bonus = 1 + $b;
            }
        }
        # So' leva o bonus de bend quem chama remakeValue/remakeAirEarth, que
        # e' o caso de toda magia de dano de player (ver measure_script).
        my $bend = $got->{remake} ? 1 + ($BEND_PER_POINT * opt('mag')) : 1;
        $row{factor}    = $factor;
        $row{lvl_bonus} = $lvl_bonus;
        $row{bend}      = $bend;
        $row{dmg_final} = $got->{dmg} * $factor * $lvl_bonus * $bend;
        $row{dmg_cast}  = $row{dmg_final} * $got->{hits};
        $row{dps}       = $row{cd} ? $row{dmg_cast} / $row{cd} : undef;
        push @rows, \%row;
    }

    if (opt('emit')) {
        return emit_atk(\@rows);
    }

    if (opt('json')) {
        my @json;
        for my $r (@rows) {
            push @json, sprintf(
                '{"spell":"%s","element":"%s","level":%d,"cd":%.1f,"atk":%s,"dmg":%.1f,"hits":%d,"danoCast":%.1f,"dps":%s}',
                $r->{key} // $r->{name}, $r->{element}, $r->{level}, $r->{cd},
                defined $r->{atk} ? sprintf('%.0f', $r->{atk}) : 'null',
                $r->{dmg_final}, $r->{hits}, $r->{dmg_cast},
                defined $r->{dps} ? sprintf('%.3f', $r->{dps}) : 'null'
            );
        }
        print "[\n  " . join(",\n  ", @json) . "\n]\n";
        return 0;
    }

    my $factors = join('  ', map { sprintf('%s=%.3f', $_, $balance->{$_}) } @ELEMENTS);
    print '=' x 104, "\n";
    printf "SPELL BALANCE REPORT | level %d | bend(mag) %d | dobras %d | fatores: %s | bend: +%.0f%%/ponto (x%.2f)\n",
        opt('level'), opt('mag'), opt('dobras'), $factors,
        $BEND_PER_POINT * 100, 1 + ($BEND_PER_POINT * opt('mag'));
    if (%$growth) {
        print 'escalamento por level: ', join('  ', map {
            sprintf('%s +%.3f%%/level acima de %d (teto +%.0f%%) x%.3f',
                $_, $growth->{$_} * 100, $growth_base, $growth_cap * 100,
                1 + (($growth_cap > 0 && (opt('level') - $growth_base) * $growth->{$_} > $growth_cap)
                        ? $growth_cap : (opt('level') > $growth_base ? (opt('level') - $growth_base) * $growth->{$_} : 0)))
        } sort keys %$growth), "\n";
    }
    print '=' x 104, "\n";

    for my $el (@ELEMENTS) {
        my @group = sort { $a->{level} <=> $b->{level} } grep { $_->{element} eq $el } @rows;
        next unless @group;
        my @dmg = sort { $a <=> $b } map { $_->{dmg_final} } @group;
        my @cast = sort { $a <=> $b } map { $_->{dmg_cast} } @group;
        my @dps = sort { $a <=> $b } map { $_->{dps} } grep { defined $_->{dps} } @group;
        my $med = sub { my @l = @_; return @l ? $l[int(@l / 2)] : 0; };
        printf "\n%-6s magias=%2d  mediana dano=%8.0f  mediana dano/cast=%9.0f  mediana dps=%7.2f\n",
            uc($el), scalar(@group), $med->(@dmg), $med->(@cast), $med->(@dps);
        print '-' x 104, "\n";
        printf "  %-24s %4s %5s %6s %9s %5s %10s %8s\n",
            'magia', 'lvl', 'cd', 'atk', 'dano', 'hits', 'dano/cast', 'dps';
        for my $r (@group) {
            printf "  %-24s %4d %5.0f %6s %9.0f %5d %10.0f %8s\n",
                $r->{key} // $r->{name}, $r->{level}, $r->{cd},
                defined $r->{atk} ? sprintf('%.0f', $r->{atk}) : '-',
                $r->{dmg_final}, $r->{hits}, $r->{dmg_cast},
                defined $r->{dps} ? sprintf('%.2f', $r->{dps}) : '-';
        }
    }

    # ---------------------------------------------------------------- faixas
    # "No level X o fire tem que bater mais que todo mundo": em cada faixa,
    # olha o que a vocacao CONSEGUE usar ja' (level <= fim da faixa) e compara
    # a melhor magia (nuke) e a mediana com as do fire.
    print "\n", '=' x 104, "\n";
    print "HIERARQUIA POR FAIXA DE LEVEL (magias ja' liberadas naquele level)\n";
    print '=' x 104, "\n";
    printf "  %-10s", 'ate level';
    for my $el (@ELEMENTS) { printf " %22s", $el; }
    print "\n";
    for my $cap (50, 100, 150, 200, 250) {
        my (%median, %best);
        for my $el (@ELEMENTS) {
            my @vals = sort { $a <=> $b } map { $_->{dmg_cast} }
                       grep { $_->{element} eq $el && $_->{level} <= $cap } @rows;
            $median{$el} = @vals ? $vals[int(@vals / 2)] : undef;
            $best{$el}   = @vals ? $vals[-1] : undef;
        }
        for my $kind (['mediana', \%median], ['melhor', \%best]) {
            my ($label, $set) = @$kind;
            my $fire = $set->{fire};
            printf "  %-10s", sprintf('%s <= %d', $label, $cap);
            for my $el (@ELEMENTS) {
                my $val = $set->{$el};
                printf " %22s", (!defined $val ? '-' : sprintf('%6.0f  %5.2fx fire', $val, ($fire ? $val / $fire : 0)));
            }
            print "\n";
        }
    }

    if (@manual) {
        print "\nMANUAL (nao interpretadas, conferir a mao):\n";
        printf "  %-38s %s\n", $_->[0]{element} . '/' . $_->[0]{script}, $_->[1] for @manual;
    }
    if (%UNKNOWN_COND) {
        print "\nCONDICOES DESCONHECIDAS (tratadas como FALSA):\n";
        printf "  %s  (x%d)\n", $_, $UNKNOWN_COND{$_} for sort keys %UNKNOWN_COND;
    }
    return 0;
}

exit(main());
