#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_bosses.py -- Gerador do sistema ALPHA (bosses derivados dos monstros ofensivos)

O que este script faz (100% offline, roda quantas vezes quiser):

  1. Le todos os monstros de  data/monster/Oficial monsters avatar/*.xml
  2. Seleciona apenas os monstros OFENSIVOS  (flag hostile="1")
  3. Gera um boss para cada um deles em   data/monster/bosses/ALPHA <Nome>.xml
     - nome:            "ALPHA <Nome>"
     - vida:            x HP_MULT
     - experiencia:     x EXP_MULT
     - velocidade:      x SPEED_MULT
     - dano (melee):    skill/attack x MELEE_MULT
     - dano (elemental/condicao): min/max x ELEM_MULT
     - defesa/armadura: x DEF_MULT
     - ouro:            countmax x GOLD_MULT
     - loot extra:      luva de craft correspondente (GLOVE_CHANCE) + crystal coin
     - flags de boss:   nao summonable / nao illusionable / nao convinceable /
                        nao pushable / always hostile
  4. Reescreve o bloco  <!-- ALPHA BOSSES -->  dentro de data/monster/monsters.xml
  5. Gera  data/lib/bossConfig.lua  com a tabela usada pelo servidor:
        - nome do monstro -> material de craft, luva, boss, meta de kills
     A meta de kills e' calculada pela forca do monstro (experiencia) e vai de
     MIN_KILLS ate MAX_KILLS (1000 = teto pedido no design).

A luva de cada monstro e' descoberta lendo o loot do proprio monstro:
todo monstro ofensivo droppa exatamente um material de craft (19099..19153) e o
craftingSystem usa esse material como ingrediente "assinatura" da receita.
No mapping do servidor:   luva = material - 1
(ex.: Linho 19099 -> Luva simples 19098; Juba de leao 19121 -> Luvas reais 19120)

Uso:
    python tools/generate_bosses.py
"""

import glob
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

# ---------------------------------------------------------------------------
# CAMINHOS
# ---------------------------------------------------------------------------
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "data", "monster", "Oficial monsters avatar")
MONSTERS_XML = os.path.join(ROOT, "data", "monster", "monsters.xml")
BOSS_DIR = os.path.join(ROOT, "data", "monster", "bosses")
BOSSES_XML = os.path.join(BOSS_DIR, "bosses.xml")
CRAFT_LUA = os.path.join(ROOT, "data", "lib", "craftingSystem.lua")
CONFIG_LUA = os.path.join(ROOT, "data", "lib", "bossConfig.lua")

# ---------------------------------------------------------------------------
# TUNING -- mexa aqui e rode o script de novo para regerar tudo
# ---------------------------------------------------------------------------
PREFIX = "ALPHA "
HP_MULT = 6.0            # vida do boss
EXP_MULT = 8             # experiencia do boss
SPEED_MULT = 1.10        # velocidade base
MELEE_MULT = 1.5         # skill= e attack= das attacks de melee/fisico
ELEM_MULT = 2.0          # min= / max= das attacks elementais
DEF_MULT = 2.0           # armor / defense
GOLD_MULT = 3            # countmax do ouro (2148)

# ---------------------------------------------------------------------------
# CHANCE DE LOOT -- leia isto antes de mexer
# ---------------------------------------------------------------------------
# O "chance=" do xml NAO vira a porcentagem que aparece na tela: em
# sources/monsters.cpp, MonsterType::createLoot() faz
#
#     if (lootChance > 1 && lootChance < 10000 && !lootPercent)
#             lootChance = ceil(lootChance * 0.5);          // METADE
#     random = (uint16_t)ceil(random_range(0,100000) / rateLoot);  // estoura 16 bits
#     if (random < lootChance) -> droppa
#
# rateLoot do config.lua (0.1) joga o sorteio para 0..1.000.000 e o cast para
# uint16_t deixa o valor util em ~0..62500 (16 voltas de 0..62500). Resultado:
#
#     chance efetiva (%) ~= lootChance / 625      (= chance / 1250)
#
# Com o rateLoot atual, chance="4000" droppa ~3,2% e nao 4%.
# Por isso os valores abaixo ja' estao compensados:
#     GLOVE_CHANCE  = 5000 -> lootChance 2500 -> ~4,00%
#     CRYSTAL_CHANCE= 100000 -> SEMPRE dropa (>= 65536 passa direto pelo if,
#                             imune ao rateLoot e ao corte da metade)
#     CRYSTAL_COUNTMAX = 3  -> count = random % 3 + 1 = 1 a 3 moedas por kill
# (o script confere isso no fim e imprime a porcentagem real)
#
# ATENCAO -- o corte do "halving" e' "chance < 10000": por causa dele a
# chance EFETIVA fica quantizada em dois degraus. Com rateLoot=0.1:
#     chance <  10000  ->  efetiva <= 8,00%
#     chance >= 10000  ->  efetiva >= 16,00%
# Nao existe chance=6250 dando 10% (6250 < 10000 cai na metade -> 5%).
GLOVE_CHANCE = 5000      # ~4% efetivo
CRYSTAL_COIN_ID = 2160   # crystal coin = 10k
CRYSTAL_CHANCE = 100000  # 100000 = sempre dropa (imune ao rateLoot/halving)
CRYSTAL_COUNTMAX = 3     # 1 a 3 moedas por kill (count = random % countmax + 1)

GOLD_ID = 2148

RATE_LOOT = 1.0          # preenchido lendo config.lua
GLOVE_EFFECTIVE = 0.0    # preenchido por effective_percent()
CRYSTAL_EFFECTIVE = 0.0

MIN_KILLS = 50           # meta minima de kills na task diaria
MAX_KILLS = 1000         # teto pedido no design
EXP_FOR_MAX_KILLS = 30000  # a partir dessa exp o monstro ja pede MAX_KILLS

# Materiais de craft do Blacksmith (linho + os drops de monstro).
MATERIAL_MIN = 19099
MATERIAL_MAX = 19153

# Monstros que NAO entram no sorteio da task diaria (mas continuam com boss).
# Sao criaturas de evento/andar especial: pedir 1000 kills delas seria impossivel.
DAILY_EXCLUDED = [
    "Mountain Defender",   # exp 0 (quest)
    "Guardian Beetle",     # exp 0 (quest)
    "Swamp Monster",       # boss room do pantano
    "Swamp Man Head",
    "Swamp Man Arm",
    "Swamp Tentacles",
    "Green Hydra Head",    # hydra boss room
    "Blue Hydra Head",
    "Dummy",               # treino
]

# Nunca gerar boss para esses (mesmo se hostile="1")
NEVER_BOSS = ["Dummy"]

MARKER_BEGIN = "\t<!-- ALPHA BOSSES (gerado por tools/generate_bosses.py) -->"
MARKER_END = "\t<!-- /ALPHA BOSSES -->"


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
def read_xml(path):
    """Le um XML preservando comentarios (ElementTree joga comentario fora por padrao)."""
    with open(path, "rb") as fh:
        raw = fh.read()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")
    # remove a declaracao <?xml?>  (ElementTree adiciona de novo)
    text = re.sub(r"^\s*<\?xml[^>]*\?>\s*", "", text, count=1)
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
    return ET.fromstring(text, parser=parser)


def children(node, tag=None):
    """Filhos que sao elementos reais (ignora comentarios)."""
    out = []
    if node is None:
        return out
    for child in list(node):
        if not isinstance(child.tag, str):
            continue
        if tag is None or child.tag == tag:
            out.append(child)
    return out


def int_attr(node, name, default=0):
    value = node.get(name)
    if value is None:
        return default
    try:
        return int(float(value))
    except ValueError:
        return default


def scale(value, mult):
    return int(round(value * mult))


def find_child(node, tag):
    child = node.find(tag)
    return child


def ensure_child(node, tag):
    child = node.find(tag)
    if child is None:
        child = ET.SubElement(node, tag)
    return child


def strip_indent(node):
    """Zera espacos/quebras de linha para o ET.indent reindentar bonitinho."""
    if node.text is not None and not node.text.strip():
        node.text = None
    for child in list(node):
        if child.tail is not None and not child.tail.strip():
            child.tail = None
        strip_indent(child)
    if node.tail is not None and not node.tail.strip():
        node.tail = None


def read_rate_loot():
    """Le rateLoot do config.lua (usado para calcular a chance REAL de loot)."""
    path = os.path.join(ROOT, "config.lua")
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError:
        return 1.0
    m = re.search(r"(?m)^\s*rateLoot\s*=\s*([0-9.]+)", text)
    if not m:
        return 1.0
    try:
        return float(m.group(1)) or 1.0
    except ValueError:
        return 1.0


def effective_percent(chance, rate_loot):
    """Reproduz o sorteio de MonsterType::createLoot() (ver comentario acima)."""
    loot_chance = math.ceil(chance * 0.5) if 1 < chance < 10000 else chance
    if loot_chance >= 65536:
        return 100.0
    hits = 0
    total = 100001
    for r in range(total):
        value = int(math.ceil(r / rate_loot)) & 0xFFFF
        if value < loot_chance:
            hits += 1
    return 100.0 * hits / total


def kills_for(experience):
    """Meta de kills da task diaria em funcao da forca (experiencia) do monstro."""
    if experience <= 0:
        return MIN_KILLS
    ratio = min(1.0, math.sqrt(float(experience) / float(EXP_FOR_MAX_KILLS)))
    return int(min(MAX_KILLS, max(MIN_KILLS, round(MIN_KILLS + (MAX_KILLS - MIN_KILLS) * ratio))))


# ---------------------------------------------------------------------------
# LEITURA DAS RECEITAS DE CRAFT (para validar o mapping material -> luva)
# ---------------------------------------------------------------------------
def load_craft_gloves():
    """Retorna (material -> luva) lido do craftingSystem.lua."""
    with open(CRAFT_LUA, "r", encoding="utf-8", errors="replace") as fh:
        text = fh.read()

    mapping = {}
    # cada receita termina com "resultItemId = N," e tem uma lista de ingredientes
    blocks = re.split(r"\{\s*\n\s*profId", text)
    for block in blocks:
        m = re.search(r"resultItemId\s*=\s*(\d+)", block)
        if not m:
            continue
        result = int(m.group(1))
        ingredients = [int(x) for x in re.findall(r"itemId\s*=\s*(\d+)", block)]
        if not ingredients:
            continue
        # ingrediente "assinatura" = primeiro que nao e' linho
        signature = None
        for ing in ingredients:
            if ing != MATERIAL_MIN:
                signature = ing
                break
        if signature is None:
            signature = MATERIAL_MIN
        mapping[signature] = result
    return mapping


def material_of(loot_ids, craft_map):
    """Descobre o material de craft que o monstro droppa."""
    materials = [i for i in loot_ids if MATERIAL_MIN <= i <= MATERIAL_MAX]
    if not materials:
        return None
    # em caso de duplicidade, prefere o que realmente possui receita
    for m in materials:
        if m in craft_map:
            return m
    return materials[0]


# ---------------------------------------------------------------------------
# TRANSFORMACAO DE UM MONSTRO -> BOSS
# ---------------------------------------------------------------------------
def build_boss(root, glove_id):
    name = root.get("name") or "Unknown"
    boss_name = PREFIX + name

    # ---- tag <monster>
    root.set("name", boss_name)
    root.set("nameDescription", "the alpha " + name)
    root.set("experience", str(int_attr(root, "experience") * EXP_MULT))
    if root.get("speed") is not None:
        root.set("speed", str(scale(int_attr(root, "speed"), SPEED_MULT)))

    # ---- vida
    health = ensure_child(root, "health")
    hp = int_attr(health, "max") or int_attr(health, "now") or 1
    hp = max(1, scale(hp, HP_MULT))
    health.set("now", str(hp))
    health.set("max", str(hp))

    # ---- flags de boss
    flags = ensure_child(root, "flags")
    wanted = {
        "summonable": "0",
        "attackable": "1",
        "hostile": "1",
        "illusionable": "0",
        "convinceable": "0",
        "pushable": "0",
        "canpushitems": "1",
        "canpushcreatures": "0",
        "targetdistance": "1",
        "staticattack": "90",
        "runonhealth": "0",
    }
    existing = {}
    for flag in children(flags):
        key = list(flag.attrib.keys())
        if key:
            existing[key[0]] = flag
    for key, value in wanted.items():
        node = existing.get(key)
        if node is None:
            node = ET.SubElement(flags, "flag")
        node.set(key, value)

    # ---- ataques
    attacks = find_child(root, "attacks")
    if attacks is not None:
        for atk in children(attacks, "attack"):
            for attr in ("skill", "attack"):
                if atk.get(attr) is not None:
                    atk.set(attr, str(scale(int_attr(atk, attr), MELEE_MULT)))
            for attr in ("min", "max"):
                if atk.get(attr) is not None:
                    atk.set(attr, str(scale(int_attr(atk, attr), ELEM_MULT)))

    # ---- defesas
    defenses = find_child(root, "defenses")
    if defenses is not None:
        for attr in ("armor", "defense"):
            if defenses.get(attr) is not None:
                defenses.set(attr, str(scale(int_attr(defenses, attr), DEF_MULT)))

    # ---- loot
    loot = root.find("loot")
    if loot is None:
        loot = ET.SubElement(root, "loot")

    for item in children(loot, "item"):
        if int_attr(item, "id") == GOLD_ID and item.get("countmax") is not None:
            item.set("countmax", str(max(1, scale(int_attr(item, "countmax"), GOLD_MULT))))

    if glove_id:
        node = ET.SubElement(loot, "item")
        node.set("id", str(glove_id))
        node.set("countmax", "1")
        node.set("chance", str(GLOVE_CHANCE))

    node = ET.SubElement(loot, "item")
    node.set("id", str(CRYSTAL_COIN_ID))
    node.set("countmax", str(CRYSTAL_COUNTMAX))
    node.set("chance", str(CRYSTAL_CHANCE))

    return name, boss_name


def serialize(root):
    strip_indent(root)
    ET.indent(root, space="\t")
    body = ET.tostring(root, encoding="unicode")
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + body + "\n"


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    global RATE_LOOT, GLOVE_EFFECTIVE, CRYSTAL_EFFECTIVE
    RATE_LOOT = read_rate_loot()
    GLOVE_EFFECTIVE = effective_percent(GLOVE_CHANCE, RATE_LOOT)
    CRYSTAL_EFFECTIVE = effective_percent(CRYSTAL_CHANCE, RATE_LOOT)

    craft_map = load_craft_gloves()
    if not craft_map:
        print("!! nao foi possivel ler as receitas de", CRAFT_LUA)

    os.makedirs(BOSS_DIR, exist_ok=True)

    monsters = []      # (nome, arquivo, hostile, exp, material, luva, kills, boss)
    skipped = []

    for path in sorted(glob.glob(os.path.join(SRC_DIR, "*.xml"))):
        root = read_xml(path)
        if root.tag != "monster":
            skipped.append((os.path.basename(path), "root tag != monster"))
            continue

        name = root.get("name") or os.path.splitext(os.path.basename(path))[0]
        hostile = 0
        flags = root.find("flags")
        if flags is not None:
            for flag in children(flags):
                if flag.get("hostile") is not None:
                    hostile = int_attr(flag, "hostile")
        experience = int_attr(root, "experience")

        loot_ids = []
        loot = root.find("loot")
        if loot is not None:
            for item in children(loot, "item"):
                if item.get("id") is not None:
                    loot_ids.append(int_attr(item, "id"))

        material = material_of(loot_ids, craft_map)
        glove = (material - 1) if material else None
        if glove is not None and craft_map.get(material) not in (None, glove):
            print("!! divergencia material %d: craftingSystem diz %s, regra diz %s"
                  % (material, craft_map.get(material), glove))

        record = {
            "name": name,
            "file": os.path.basename(path),
            "hostile": hostile,
            "experience": experience,
            "material": material,
            "glove": glove,
            "kills": kills_for(experience),
            "boss": PREFIX + name,
            "root": root,
        }

        if hostile != 1 or name in NEVER_BOSS:
            skipped.append((name, "nao ofensivo"))
        else:
            monsters.append(record)

    # ---------------- arquivos de boss ----------------
    written = []
    for rec in monsters:
        boss_root = read_xml(os.path.join(SRC_DIR, rec["file"]))
        build_boss(boss_root, rec["glove"])
        out = os.path.join(BOSS_DIR, PREFIX + rec["name"] + ".xml")
        with open(out, "w", encoding="utf-8", newline="\r\n") as fh:
            fh.write(serialize(boss_root))
        written.append(os.path.basename(out))

    # remove bosses antigos que nao existem mais
    keep = set(written) | {"bosses.xml"}
    for path in glob.glob(os.path.join(BOSS_DIR, "*.xml")):
        if os.path.basename(path) not in keep:
            os.remove(path)
            print("removido boss obsoleto:", os.path.basename(path))

    # ---------------- bosses.xml (indice proprio) ----------------
    # monsters.xml aponta para "bosses/<arquivo>" diretamente, mas mantemos um
    # indice isolado para o servidor poder recarregar so os bosses se precisar.
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<monsters>"]
    for rec in sorted(monsters, key=lambda r: r["name"].lower()):
        lines.append('\t<monster name="%s" file="%s"/>' % (rec["boss"], PREFIX + rec["name"] + ".xml"))
    lines.append("</monsters>")
    lines.append("")
    with open(BOSSES_XML, "w", encoding="utf-8", newline="\r\n") as fh:
        fh.write("\n".join(lines))

    # ---------------- monsters.xml ----------------
    with open(MONSTERS_XML, "rb") as fh:
        raw = fh.read()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")

    block = [MARKER_BEGIN]
    block.append("\t<!-- Gerado por tools/generate_bosses.py. Nao edite a mao: rode o script. -->")
    for rec in sorted(monsters, key=lambda r: r["name"].lower()):
        block.append('\t<monster name="%s" file="bosses/%s.xml"/>'
                     % (rec["boss"], PREFIX + rec["name"]))
    block.append(MARKER_END)

    text = text.replace("\r\n", "\n").replace("\r", "\n")

    start = text.find(MARKER_BEGIN)
    if start >= 0:
        end = text.find(MARKER_END)
        if end < 0:
            raise SystemExit("marcador final nao encontrado em monsters.xml")
        end += len(MARKER_END)
        if text[end:end + 1] == "\n":
            end += 1
        text = text[:start].rstrip("\n") + "\n" + "\n".join(block) + "\n" + text[end:].lstrip("\n")
    else:
        text = text.rstrip()
        if text.endswith("</monsters>"):
            text = text[: -len("</monsters>")].rstrip("\n") + "\n" + "\n".join(block) + "\n</monsters>\n"

    with open(MONSTERS_XML, "wb") as fh:
        fh.write(text.replace("\n", "\r\n").encode("utf-8"))

    # ---------------- bossConfig.lua ----------------
    excluded = set(DAILY_EXCLUDED)
    pool_note = []
    with open(CONFIG_LUA, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("--[[\n")
        fh.write(" * bossConfig.lua -- GERADO AUTOMATICAMENTE por tools/generate_bosses.py\n")
        fh.write(" *\n")
        fh.write(" * Tabela de ligacao do sistema ALPHA:\n")
        fh.write(" *   [nome do monstro] = {\n")
        fh.write(" *       boss     = nome do monstro ALPHA correspondente\n")
        fh.write(" *       material = item de craft que o monstro droppa (pode ser nil)\n")
        fh.write(" *       glove    = luva completa que o boss pode droppar (4%)\n")
        fh.write(" *       kills    = meta de kills da task diaria (max %d)\n" % MAX_KILLS)
        fh.write(" *   }\n")
        fh.write(" *\n")
        fh.write(" * Nao edite a mao: rode `python tools/generate_bosses.py`.\n")
        fh.write("]]\n\n")
        fh.write("BossConfig = BossConfig or {}\n\n")
        fh.write("BossConfig.prefix = %r\n\n" % PREFIX)
        fh.write("BossConfig.gloveChance = %d\n" % GLOVE_CHANCE)
        fh.write("BossConfig.gloveChancePercent = %.2f  -- %% efetiva com rateLoot=%.2f\n"
                 % (GLOVE_EFFECTIVE, RATE_LOOT))
        fh.write("BossConfig.crystalChance = %d  -- 100000 = sempre dropa\n" % CRYSTAL_CHANCE)
        fh.write("BossConfig.crystalCountmax = %d  -- 1 a %d moedas por kill\n" % (CRYSTAL_COUNTMAX, CRYSTAL_COUNTMAX))
        fh.write("BossConfig.tileItemId = 19333\n")
        fh.write("BossConfig.tileItemId2 = 19334\n")
        fh.write("BossConfig.tileActionId = 50030\n\n")
        fh.write("BossConfig.monsters = {\n")
        for rec in sorted(monsters, key=lambda r: r["name"].lower()):
            fh.write('  ["%s"] = { boss = "%s", material = %s, glove = %s, kills = %d, experience = %d },\n'
                     % (rec["name"], rec["boss"],
                        rec["material"] if rec["material"] else "nil",
                        rec["glove"] if rec["glove"] else "nil",
                        rec["kills"], rec["experience"]))
            if rec["name"] in excluded or rec["experience"] <= 0:
                pool_note.append(rec["name"])
        fh.write("}\n\n")
        fh.write("-- Criaturas que NAO entram no sorteio da task diaria (andar de evento/quest).\n")
        fh.write("BossConfig.dailyExcluded = {\n")
        for name in sorted(set(pool_note), key=lambda s: s.lower()):
            fh.write('  ["%s"] = true,\n' % name)
        fh.write("}\n")

    # ---------------- resumo ----------------
    print("rateLoot do config: %.2f" % RATE_LOOT)
    print("chance da luva    : chance=%d -> %.2f%% efetiva" % (GLOVE_CHANCE, GLOVE_EFFECTIVE))
    print("crystal coin      : chance=%d, countmax=%d -> SEMPRE dropa 1 a %d" % (CRYSTAL_CHANCE, CRYSTAL_COUNTMAX, CRYSTAL_COUNTMAX))
    print("bosses gerados   : %d" % len(monsters))
    print("  com luva       : %d" % len([r for r in monsters if r["glove"]]))
    print("  sem luva       : %s" % ", ".join(sorted(r["name"] for r in monsters if not r["glove"])) or "-")
    print("fora da task     : %s" % ", ".join(sorted(set(pool_note), key=lambda s: s.lower())))
    print("ignorados        : %s" % ", ".join(sorted(n for n, _ in skipped)))
    print("arquivos          : %s" % BOSS_DIR)


if __name__ == "__main__":
    sys.exit(main() or 0)
