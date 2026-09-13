#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Gera as spells proprias de todos os monstros do servidor.

Uso:  python tools/gen_monster_spells.py            (aplica as mudancas)
      python tools/gen_monster_spells.py --dry-run  (so mostra o que faria)

O que ele escreve:
  1. data/lib/monsterSpellBook.lua          -> a configuracao (nome/elemento/formato de cada spell)
  2. data/spells/spells.xml                 -> um <instant> por spell, todos apontando pro motor
  3. data/monster/Oficial monsters avatar/* -> o <attack> da spell assinatura de cada monstro
  4. MONSTER_SPELLS.md                      -> a lista (monstro -> spell -> o que faz)

As entradas genericas "Monster <Elemento> Wave/Nova/Blast" (que eu tinha posto
em alguns monstros) sao trocadas pela spell propria do bicho, e as suas
registracoes em spells.xml foram removidas (os scripts ficaram obsoletos).

Os bichos de ambiente (dict PASSIVE) ficam SEM spell: o gerador tira o <attack>
deles, apaga a <instant> correspondente em spells.xml e forca o perfil passivo
no XML (hostile=0 + strategy attack=0).

O dano da spell NAO fica em script: o <attack min max> daqui e' o que o
servidor usa (Monster::getCombatValues), entao ajustar balanceamento = mexer
nos numeros desta tabela e rodar de novo.
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MONSTER_DIR = os.path.join(ROOT, "data", "monster", "Oficial monsters avatar")
SPELLS_XML = os.path.join(ROOT, "data", "spells", "spells.xml")
BOOK_LUA = os.path.join(ROOT, "data", "lib", "monsterSpellBook.lua")
LISTING = os.path.join(ROOT, "MONSTER_SPELLS.md")

ENGINE = "monster/monsterSpell.lua"
GENERIC_RE = re.compile(r'^\s*<attack name="Monster (?:Air|Fire|Water|Earth) (?:Wave|Nova|Blast)".*?/>[ \t]*\r?\n', re.M)

# ---------------------------------------------------------------------------
# A Tabela. Uma entrada por monstro (50).
#   shape: blast | burst | nova | wave | beam | breath | rain
#   dmg:   (min, max) -> vai pro <attack> e e' o dano real da spell
# ---------------------------------------------------------------------------
SPELLS = {
    # ---- bichos fracos ----
    # (Chicken, Crab, Frog, Rabbit, Sheep, Swan, Wild Wolf e Bee sao bichos de
    #  ambiente e NAO tem spell nenhuma: ver PASSIVE, logo abaixo da tabela.)
    "Momo": dict(
        spell="Little Fury", element="physical", shape="blast",
        dmg=(-20, -40), interval=3000, chance=25, range=4,
        desc="Momo avança raivoso no alvo (é summonável, então essa ele usa de verdade)"),

    # ---- bichos pequenos ----
    "Cockroach": dict(
        spell="Carapace Scuttle", element="earth", shape="nova", radius=1,
        dmg=(-4, -9), interval=3000, chance=20, range=2,
        desc="bate a carapaça no chão e abre uma rachadura 3x3 em volta dele"),
    "Earth Beetle": dict(
        spell="Beetle Tremor", element="earth", shape="nova", radius=1,
        dmg=(-4, -9), interval=3000, chance=20, range=2,
        desc="tremor curto de terra 3x3 em volta do besouro"),
    "Cemetery Worm": dict(
        spell="Grave Burrow", element="poison", shape="burst", radius=1,
        dmg=(-6, -15), interval=3500, chance=20, range=5, cond="poison",
        desc="some no chão e explode terra de cemitério no alvo (3x3 + veneno)"),
    "Giant Snail": dict(
        spell="Slime Trail", element="poison", shape="beam", length=3,
        dmg=(-8, -16), interval=3000, chance=20, range=4, cond="poison",
        desc="deixa um rastro de limo venenoso em linha (3 sqm)"),
    "Earth Ladybug": dict(
        spell="Ladybug Quake", element="earth", shape="wave", length=3, width=1,
        dmg=(-20, -40), interval=3000, chance=20, range=4,
        desc="onda de terra 3x3 que avança na direção em que ela olha"),
    "Warm Cape Crab": dict(
        spell="Scalding Tide", element="water", shape="nova", radius=2,
        dmg=(-10, -20), interval=3000, chance=20, range=3,
        desc="água quente das fontes do Cabo jorra 5x5 em volta dele"),

    # ---- bichos médios ----
    "Earth Woodpecker": dict(
        spell="Stone Peck", element="physical", shape="beam", length=4,
        dmg=(-70, -140), interval=3000, chance=25, range=5,
        desc="bica o chão e a pedra voa em linha reta (4 sqm)"),
    "Fierce Bear": dict(
        spell="Bear Maul", element="physical", shape="breath", length=2,
        dmg=(-40, -80), interval=3000, chance=25, range=3,
        desc="patada dupla que abre em cone curto na frente dele"),
    "Hippo": dict(
        spell="River Crush", element="physical", shape="nova", radius=2,
        dmg=(-40, -80), interval=3500, chance=20, range=2,
        desc="esmaga o chão com a bocarra: 5x5 de poeira e impacto"),
    "Mud Bee": dict(
        spell="Mud Swarm", element="poison", shape="rain", count=6, radius=2,
        dmg=(-40, -80), interval=3000, chance=20, range=6, cond="poison",
        desc="enxame de lama envenenada caindo em volta do alvo (6 impactos)"),
    "Mud Man": dict(
        spell="Mud Grasp", element="earth", shape="burst", radius=2,
        dmg=(-50, -100), interval=4000, chance=20, range=5,
        desc="mãos de lama agarram o alvo, explosão de terra 5x5"),
    "Stone Tarantula": dict(
        spell="Venom Web", element="poison", shape="nova", radius=2,
        dmg=(-60, -120), interval=4000, chance=20, range=3, cond="poison",
        desc="dispara teia venenosa em todas as direções (5x5 + veneno)"),
    "Giant Cricket": dict(
        spell="Chirp Screech", element="physical", shape="nova", radius=2,
        dmg=(-30, -60), interval=3000, chance=20, range=3,
        desc="estridula tão alto que o som machuca em 5x5"),
    "Gleaming Beetle": dict(
        spell="Gleam Flash", element="energy", shape="nova", radius=2,
        dmg=(-40, -80), interval=3000, chance=20, range=3,
        desc="a carapaça brilhante solta um clarão elétrico 5x5"),
    "Steel Shell Centipede": dict(
        spell="Steel Coil", element="physical", shape="wave", length=3, width=1,
        dmg=(-60, -120), interval=3000, chance=20, range=4,
        desc="se enrola e chicoteia o ar com o corpo de aço (onda 3x3)"),
    "Stone-Spitting Spider": dict(
        spell="Stone Spit", element="earth", shape="blast",
        dmg=(-80, -150), interval=3000, chance=25, range=7,
        desc="cospe uma pedra no alvo; o impacto de terra é o dano real"),
    "Elephant": dict(
        spell="Tusk Stampede", element="physical", shape="wave", length=4, width=1,
        dmg=(-60, -110), interval=3000, chance=25, range=4,
        desc="corre embalado e a tromba/ presas abrem um corredor de 4 sqm"),
    "Earth Mordecai": dict(
        spell="Mordecai's Landslide", element="earth", shape="breath", length=4,
        dmg=(-140, -200), interval=4000, chance=20, range=5,
        desc="deslizamento de terra em cone de 4 sqm na direção em que ele olha"),

    # ---- bichos fortes ----
    "Vulture Bee": dict(
        spell="Carrion Sting", element="poison", shape="rain", count=6, radius=2,
        dmg=(-80, -140), interval=3000, chance=20, range=6, cond="poison",
        desc="nuvem de ferroadas de carniça em volta do alvo (6 impactos + veneno)"),
    "Hermit Crab": dict(
        spell="Shell Smash", element="physical", shape="burst", radius=1,
        dmg=(-90, -180), interval=3500, chance=20, range=4,
        desc="se fecha e despenca a concha gigante em cima do alvo (3x3)"),
    "Jaguar": dict(
        spell="Jaguar Maul", element="physical", shape="burst", radius=1,
        dmg=(-120, -220), interval=3000, chance=25, range=4,
        desc="bote curto com as duas patas no alvo (3x3 de impacto)"),
    "Sea Iguana": dict(
        spell="Tidal Snap", element="water", shape="wave", length=4, width=1,
        dmg=(-50, -90), interval=3000, chance=20, range=4,
        desc="mordida que puxa uma onda junto (corredor de água de 4 sqm)"),
    "Swamp Tentacles": dict(
        spell="Tentacle Drag", element="water", shape="beam", length=3,
        dmg=(-150, -300), interval=3500, chance=20, range=4,
        desc="três tentáculos batem em linha, tentando arrastar o alvo pro pântano"),
    "Ba Sing Se Lion": dict(
        spell="Ba Sing Se Roar", element="fire", shape="nova", radius=3,
        dmg=(-60, -120), interval=4000, chance=20, range=3,
        desc="rugido flamejante de Mura de Ba Sing Se: 7x7 de fogo ao redor dele"),
    "Traitor": dict(
        spell="Backstab Dust", element="earth", shape="blast",
        dmg=(-150, -250), interval=3000, chance=20, range=6,
        desc="ataque traiçoeiro pelas costas, com estilhaço de terra no alvo"),
    "Rock-Eating Cockroach": dict(
        spell="Rock Crunch", element="physical", shape="burst", radius=2,
        dmg=(-250, -380), interval=3500, chance=20, range=5,
        desc="mastiga pedra e cospe o cascalho no alvo, estourando 5x5"),
    "Desert Crocodile": dict(
        spell="Sandwater Ambush", element="water", shape="breath", length=4,
        dmg=(-180, -300), interval=3500, chance=20, range=5,
        desc="emergir da areia molhada num bote em cone de 4 sqm"),
    "Uncontrolled Knowledge": dict(
        spell="Whispered Madness", element="death", shape="nova", radius=3,
        dmg=(-180, -300), interval=4000, chance=20, range=3, cond="curse",
        desc="sussurros que enlouquecem: 7x7 de dano de morte + maldição"),
    "Guardian Beetle": dict(
        spell="Guardian's Tremor", element="earth", shape="nova", radius=3,
        dmg=(-150, -250), interval=4000, chance=20, range=3,
        desc="golpeia o chão como guardião: tremor 7x7 em volta dele"),
    "White Scarab": dict(
        spell="Sacred Sandstorm", element="earth", shape="rain", count=8, radius=3,
        dmg=(-250, -400), interval=4000, chance=20, range=6,
        desc="tempestade de areia sagrada caindo em volta do alvo (8 impactos)"),

    # ---- elites / chefes ----
    "Swamp Man Arm": dict(
        spell="Swamp Slam", element="physical", shape="wave", length=3, width=1,
        dmg=(-350, -600), interval=3500, chance=20, range=3,
        desc="braçada de pântano que abre uma onda de lama de 3 sqm"),
    "Forbidden Folds Book": dict(
        spell="Forbidden Chapter", element="death", shape="rain", count=6, radius=2,
        dmg=(-280, -450), interval=4000, chance=20, range=6, cond="curse",
        desc="folhas que viram lâminas caem do céu em volta do alvo (6 impactos + maldição)"),
    "Swamp Man Head": dict(
        spell="Swamp Miasma", element="poison", shape="nova", radius=3,
        dmg=(-500, -900), interval=4500, chance=20, range=3, cond="poison",
        desc="nuvem de gás do pântano 7x7 em volta da cabeça + envenenamento"),
    "Swamp Monster": dict(
        spell="Swamp Devour", element="poison", shape="breath", length=4,
        dmg=(-500, -900), interval=4500, chance=20, range=4, cond="poison",
        desc="abre a boca e engole a área num cone de 4 sqm venenoso"),
    "Blue Hydra Head": dict(
        spell="Blue Hydra Storm", element="energy", shape="rain", count=7, radius=2,
        dmg=(-700, -1400), interval=4000, chance=20, range=6,
        desc="cabeça azul chama raios do céu em volta do alvo (7 descargas)"),
    "Green Hydra Head": dict(
        spell="Green Hydra Spores", element="poison", shape="nova", radius=3,
        dmg=(-700, -1400), interval=4500, chance=20, range=3, cond="corrode",
        desc="solta esporos corrosivos em 7x7 que continuam corroendo depois"),
    "Hopper": dict(
        spell="Hopper Cyclone", element="air", shape="nova", radius=3,
        dmg=(-180, -300), interval=4000, chance=20, range=3,
        desc="salta e gira criando um ciclone de ar 7x7 em volta dele"),
    "Black Panther": dict(
        spell="Panther Pounce", element="physical", shape="burst", radius=2,
        dmg=(-300, -500), interval=3500, chance=20, range=5,
        desc="salto longo caindo em cima do alvo com explosão 5x5"),
    "Mountain Defender": dict(
        spell="Mountain Slam", element="earth", shape="nova", radius=3,
        dmg=(-300, -600), interval=4000, chance=20, range=3,
        desc="arranca um pedaço da montanha e espatifa no chão: 7x7"),
    "Trenix": dict(
        spell="Trenix Inferno", element="fire", shape="breath", length=4,
        dmg=(-450, -650), interval=4000, chance=20, range=4, cond="burn",
        desc="baforada de fogo em cone de 4 sqm que deixa queimando"),
    "Vacaceronte": dict(
        spell="Charging Horns", element="physical", shape="beam", length=5,
        dmg=(-200, -350), interval=3500, chance=20, range=5,
        desc="carregada com os chifres, atropelando tudo em 5 sqm de linha"),
}

# ---------------------------------------------------------------------------
# Bichos de ambiente: nao tem spell assinatura.
#   Aqui o gerador faz o inverso do resto: tira o <attack> da spell (se ainda
#   estiver no XML) e garante o perfil passivo do bicho -> <flag hostile="0"/>,
#   <strategy attack="0" defense="0"/> e nenhum ataque que fira o player.
# ---------------------------------------------------------------------------
PASSIVE = {
    "Chicken": "Feather Flurry",
    "Crab": "Pinching Tide",
    "Frog": "Bubble Blast",
    "Rabbit": "Panic Dash",
    "Sheep": "Wool Cloud",
    "Swan": "Wing Gust",
    "Wild Wolf": "Pack Howl",
    "Bee": "Sting Barrage",
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def read(path):
    with io.open(path, "r", encoding="latin-1", newline="") as fh:
        return fh.read()


def write(path, text):
    with io.open(path, "w", encoding="latin-1", newline="") as fh:
        fh.write(text)


def newline_of(text):
    return "\r\n" if "\r\n" in text else "\n"


def lua_quote(s):
    return '"%s"' % s.replace("\\", "\\\\").replace('"', '\\"')


def slugify(name):
    s = name.lower()
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    return s


def build_attack(cfg):
    target = ' target="1"' if cfg["shape"] in ("blast", "burst") else ""
    return ('<attack name="%s" interval="%d" chance="%d" range="%d"%s min="%d" max="%d"/>'
            % (cfg["spell"], cfg["interval"], cfg["chance"], cfg["range"], target,
               cfg["dmg"][0], cfg["dmg"][1]))


def build_instant(cfg):
    # enabled="0": Spell::checkSpell (spells.cpp:654) recusa o cast de PLAYER,
    # mas Spells::getInstantSpellByName (usado pelo monstro) ignora essa flag.
    # Ou seja: nenhum player casta a spell de monstro por palavras.
    lines = [
        '\t<instant name="%s" words="monster %s" aggressive="1" needlearn="1" enabled="0" event="script" value="%s">'
        % (cfg["spell"], slugify(cfg["spell"]), ENGINE),
        '\t\t<vocation id="6"/>',
        '\t</instant>',
    ]
    return "\n".join(lines)


def patch_monster(path, cfg):
    """Troca as spells genericas pela assinatura do monstro. Devolve None se nada mudou."""
    text = read(path)
    original = text
    nl = newline_of(text)

    # 1) remove as entradas genericas (Monster Air Wave, Monster Fire Nova, ...)
    text, removidas = GENERIC_RE.subn("", text)

    # 2) se a spell assinatura ja esta la', nao duplica
    if 'name="%s"' % cfg["spell"] in text:
        if text == original:
            return None
        write(path, text)
        return "ok (removeu %d generica(s))" % removidas

    attack_line = build_attack(cfg)
    tabs = "\t\t"
    m = re.search(r"^([ \t]*)<attack ", text, re.M)
    if m:
        tabs = m.group(1)

    if "</attacks>" in text:
        # insere antes do fechamento, mantendo a indentacao dos irmaos
        pattern = re.compile(r"([ \t]*)</attacks>")
        match = pattern.search(text)
        close_tabs = match.group(1)
        text = text[:match.start()] + tabs + attack_line + nl + close_tabs + "</attacks>" + text[match.end():]
    else:
        block_tabs = "\t"
        block = (block_tabs + "<attacks>" + nl +
                 block_tabs + "\t" + attack_line + nl +
                 block_tabs + "</attacks>" + nl)
        # entra logo antes de <defenses ...>, <elements ...> ou do </monster>
        for tag in ("<defenses", "<elements", "</monster>"):
            idx = text.find(tag)
            if idx != -1:
                line_start = text.rfind(nl, 0, idx) + len(nl)
                text = text[:line_start] + block + text[line_start:]
                break

    write(path, text)
    return "ok (%d generica(s) removida(s), attack adicionado)" % removidas


def patch_passive(path, spell):
    """Bicho de ambiente: sem spell, sem ataque e sem escolher alvo."""
    text = read(path)
    original = text

    # 1) tira o <attack> da spell assinatura (se ainda estiver la')
    pattern = re.compile(r'[ \t]*<attack name="%s"[^>]*/>[ \t]*\r?\n' % re.escape(spell))
    text, removidas = pattern.subn("", text)

    # 2) perfil passivo: nunca escolhe alvo e nao tem forca de ataque
    text = re.sub(r'<flag hostile="1"', '<flag hostile="0"', text)
    text = re.sub(r'<strategy attack="\d+"', '<strategy attack="0"', text)

    if text == original:
        return None

    write(path, text)
    return "passivo (attack removido: %d, hostile=0, strategy attack=0)" % removidas


def patch_spells_xml(block):
    text = read(SPELLS_XML)

    # spells.xml e' append-only pelo resto do script, mas as dos bichos de
    # ambiente precisam SAIR: nenhum monstro as usa mais.
    removidas = 0
    for spell in sorted(PASSIVE.values()):
        pattern = re.compile(r'[ \t]*<instant name="%s".*?</instant>[ \t]*\r?\n' % re.escape(spell), re.S)
        text, n = pattern.subn("", text)
        removidas += n

    missing = [cfg for cfg in SPELLS.values() if 'name="%s"' % cfg["spell"] not in text]
    if not missing and not removidas:
        return "ja' registrado"

    if not missing:
        write(SPELLS_XML, text)
        return "%d spell(s) de bicho de ambiente removida(s)" % removidas

    nl = newline_of(text)
    additions = nl.join(build_instant(cfg) for cfg in missing)
    header = ("\n\t<!-- ============================================================\n"
              "\t     Spells proprias dos monstros (motor: monster/monsterSpell.lua)\n"
              "\t     Geradas por tools/gen_monster_spells.py\n"
              "\t     O dano de cada uma vem do <attack min max> no XML do monstro.\n"
              "\t     enabled=\"0\" = nenhum player casta por palavras, so' o monstro.\n"
              "\t     ============================================================ -->\n")
    idx = text.rfind("</spells>")
    line_start = text.rfind(nl, 0, idx) + len(nl)
    body = header + additions + nl
    text = text[:line_start] + body + text[line_start:]
    write(SPELLS_XML, text)
    return "%d spell(s) registradas, %d removida(s)" % (len(missing), removidas)


def build_book():
    nl = "\n"
    out = []
    out.append("--[[")
    out.append("  monsterSpellBook.lua - as spells assinatura dos monstros.")
    out.append("")
    out.append("  Chave = nome do monstro (como esta' no XML dele). Toda spell daqui")
    out.append("  usa o mesmo motor (data/spells/scripts/monster/monsterSpell.lua), que")
    out.append("  descobre a spell pelo nome de quem esta' conjurando.")
    out.append("")
    out.append("  shape: blast | burst | nova | wave | beam | breath | rain")
    out.append("  O dano nao esta aqui: ele vem do <attack min max> no XML do monstro.")
    out.append("  Gerado por tools/gen_monster_spells.py - mudar aqui a mao se perde.")
    out.append("]]")
    out.append("")
    out.append("monsterSpellBook = {")
    for monster in sorted(SPELLS):
        cfg = SPELLS[monster]
        fields = [
            "spell = %s" % lua_quote(cfg["spell"]),
            "element = %s" % lua_quote(cfg["element"]),
            "shape = %s" % lua_quote(cfg["shape"]),
        ]
        if "radius" in cfg:
            fields.append("radius = %d" % cfg["radius"])
        if "length" in cfg:
            fields.append("length = %d" % cfg["length"])
            fields.append("width = %d" % cfg.get("width", 0))
        if "count" in cfg:
            fields.append("count = %d" % cfg["count"])
        if cfg.get("cond"):
            fields.append("cond = %s" % lua_quote(cfg["cond"]))
        out.append("  [%s] = {" % lua_quote(monster))
        out.append("    " + ", ".join(fields))
        out.append("  },")
    out.append("}")
    write(BOOK_LUA, nl.join(out) + nl)
    return BOOK_LUA


def build_listing():
    nl = "\n"
    # do mais fraquinho pro mais forte (magnitude do dano)
    order = sorted(SPELLS, key=lambda m: abs(SPELLS[m]["dmg"][0]))
    out = ["# Spells proprias dos monstros", "",
           "Cada monstro do servidor tem uma spell assinatura com nome, elemento, formato e visual proprios,",
           "listadas abaixo do mais fraco ao mais forte pelo dano do `<attack>`.",
           "O motor e' unico (`data/spells/scripts/monster/monsterSpell.lua`) e le' a configuracao em",
           "`data/lib/monsterSpellBook.lua`; o dano de cada uma vem do `<attack min max>` no XML do monstro.", "",
           "| # | Monstro | Spell | Elemento | Formato | Dano | O que faz |",
           "|---|---------|-------|----------|---------|------|-----------|"]
    for i, monster in enumerate(order, 1):
        cfg = SPELLS[monster]
        shape = cfg["shape"]
        extra = ""
        if "radius" in cfg:
            extra = " raio %d" % cfg["radius"]
        elif "length" in cfg:
            extra = " %d sqm%s" % (cfg["length"], (" larg %d" % cfg["width"]) if cfg.get("width") else "")
        elif "count" in cfg:
            extra = " %d impactos" % cfg["count"]
        cond = (" *(aplica %s)*" % cfg["cond"]) if cfg.get("cond") else ""
        out.append("| %d | %s | **%s** | %s | %s%s | %d a %d | %s%s |"
                   % (i, monster, cfg["spell"], cfg["element"], shape, extra,
                      cfg["dmg"][0], cfg["dmg"][1], cfg["desc"], cond))
    out.append("")
    out.append("## Bichos de ambiente (sem spell)")
    out.append("")
    out.append("Estes nao tem spell nenhuma e sao passivos no XML (`<flag hostile=\"0\"/>`,")
    out.append("`<strategy attack=\"0\"/>`): nao escolhem alvo e nao atacam o player. A entrada aqui")
    out.append("e' so' o registro de que a spell deles foi removida.")
    out.append("")
    out.append("| Monstro | Spell que foi removida |")
    out.append("|---------|------------------------|")
    for monster in sorted(PASSIVE):
        out.append("| %s | %s |" % (monster, PASSIVE[monster]))
    write(LISTING, nl.join(out) + nl)
    return LISTING


def main():
    dry = "--dry-run" in sys.argv
    files = sorted(f for f in os.listdir(MONSTER_DIR) if f.endswith(".xml"))
    names = set()
    for f in files:
        text = read(os.path.join(MONSTER_DIR, f))
        m = re.search(r'<monster name="([^"]+)"', text)
        if m:
            names.add(m.group(1))

    faltando = names - set(SPELLS) - set(PASSIVE)
    sobrando = set(SPELLS) - names
    if faltando:
        print("!! monstros sem spell na tabela:", sorted(faltando))
    if sobrando:
        print("!! entradas da tabela sem monstro:", sorted(sobrando))

    def monster_name(f):
        return re.search(r'<monster name="([^"]+)"', read(os.path.join(MONSTER_DIR, f))).group(1)

    if dry:
        for f in files:
            name = monster_name(f)
            if name in PASSIVE:
                print("%-42s -> %-28s %s" % (f, "(bicho de ambiente)", PASSIVE[name]))
            else:
                cfg = SPELLS[name]
                print("%-42s -> %-28s %s" % (f, cfg["spell"], cfg["shape"]))
        print("\nspells.xml: %d entradas | bichos de ambiente: %d" % (len(SPELLS), len(PASSIVE)))
        return 1 if (faltando or sobrando) else 0

    for f in files:
        name = monster_name(f)
        path = os.path.join(MONSTER_DIR, f)
        if name in PASSIVE:
            res = patch_passive(path, PASSIVE[name])
        else:
            res = patch_monster(path, SPELLS[name])
        print("%-42s %s" % (name, res or "sem mudanca"))

    print("\nspells.xml: %s" % patch_spells_xml(None))
    print("book: %s" % build_book())
    print("lista: %s" % build_listing())
    return 1 if (faltando or sobrando) else 0


if __name__ == "__main__":
    sys.exit(main())
