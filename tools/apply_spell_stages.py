#!/usr/bin/env python3
"""Liga os estagios (mini <50 / padrao 50-99 / elite 100+) nas magias de player.

O motor (Combat::getStageArea, em sources/combat.cpp) deriva a area de cada
estagio a partir da area original, preservando o formato da magia. Entao cada
script so' precisa dizer "esta magia tem estagios":

    setCombatArea(combat, createCombatArea(AREA_CROSS1X1))
    setCombatStageScaling(combat)          <-- adicionado por esta ferramenta

Magias de alvo unico (sem area) ganham o eco do estagio elite:

    registerSpellStageEcho(combat)

Nada mais e' reescrito: checks, dobras, efeitos e, principalmente, o DANO
continuam identicos. O `onCastSpell` de nenhuma magia e' alterado.

Uso:
    python tools/apply_spell_stages.py            # dry-run
    python tools/apply_spell_stages.py --apply    # escreve
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPELLS_XML = ROOT / "data" / "spells" / "spells.xml"
SCRIPTS = ROOT / "data" / "spells" / "scripts"

ELEMENTS = ("fire", "water", "air", "earth")
HEAL_WORDS = ("recover", "heal", "regen", "bloodcontrol")
CONVERTED = ("setCombatStageScaling", "registerSpellStage", "pickSpellStage",
             "spellStageElite", "spellStageEcho", "getSpellStage", "AREA_STAGE_",
             "isSpellElite", "spellStageScale", "spellStageHeal", "spellStageSeconds",
             "spellStageDuration", "spellStageCount", "spellStageSpeed")

AREA_LINE = re.compile(r"^(?P<indent>[ \t]*)setCombatArea\((?P<combat>.+?),[ \t]*createCombatArea", re.M)
DAMAGE_BIND = re.compile(r"^(?P<indent>[ \t]*)setCombatCallback\((?P<combat>\w+),[ \t]*CALLBACK_PARAM_LEVELMAGICVALUE", re.M)


def statement_end(source, start):
    """Fim da instrucao cujo '(' esta' em `start`, balanceando parenteses.

    Inserir no fim da LINHA e' errado quando a chamada continua nas linhas
    seguintes - foi exatamente esse bug que quebrou 14 magias:

        setCombatArea(combat, createCombatArea(
        setCombatStageScaling(combat)        <-- ficou DENTRO da expressao
              {0, 0, 1, 0, 0}))

    Aqui a varredura so' termina quando o parentese da chamada fecha, ignorando
    strings e comentarios para nao contar parenteses que nao sao de codigo.
    """
    depth = 0
    i = start
    length = len(source)
    while i < length:
        char = source[i]

        if source.startswith("--", i) and not source.startswith("--[[", i):
            while i < length and source[i] != "\n":
                i += 1
            continue

        if char in "'\"":
            quote = char
            i += 1
            while i < length and source[i] != quote:
                i += 2 if source[i] == "\\" else 1
            i += 1
            continue

        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                newline = source.find("\n", i)
                return length if newline == -1 else newline
        i += 1
    return length


def player_spells():
    xml = SPELLS_XML.read_text(encoding="utf-8", errors="replace")
    out = []
    for block in re.findall(r"<instant\b[^>]*?/>|<instant\b.*?</instant>", xml, re.S):
        value = re.search(r'value="([^"]+)"', block)
        name = re.search(r'name="([^"]+)"', block)
        lvl = re.search(r'lvl="(\d+)"', block)
        if not value or not name:
            continue
        path = value.group(1)
        if path.split("/")[0] not in ELEMENTS:
            continue
        if not set(re.findall(r'<vocation id="(\d+)"', block)) & {"1", "2", "3", "4"}:
            continue                                    # magia de monstro
        flat = name.group(1).lower().replace(" ", "")
        if any(word in flat for word in HEAL_WORDS):
            continue                                    # cura fica sem estagios
        if " man" in path or "old" in path:
            continue
        out.append((path, int(lvl.group(1)) if lvl else 0, name.group(1)))
    return out


def convert(path, apply):
    source = path.read_text(encoding="utf-8", errors="replace")
    if any(marker in source for marker in CONVERTED):
        return "ja convertida", []

    areas = list(AREA_LINE.finditer(source))

    if areas:
        # cada area declara um combat; todos recebem os estagios
        insertions = [(statement_end(source, source.index("(", m.start())),
                       f"\n{m.group('indent')}setCombatStageScaling({m.group('combat').strip()})")
                      for m in areas]
        notes = [f"{len(areas)} combat(s)"]
    else:
        # alvo unico: so' o eco do estagio elite
        binds = list(DAMAGE_BIND.finditer(source))
        if not binds:
            return "sem area e sem callback de dano -> manual", []
        insertions = [(statement_end(source, source.index("(", m.start())),
                       f"\n{m.group('indent')}registerSpellStageEcho({m.group('combat')})")
                      for m in binds]
        notes = [f"{len(binds)} combat(s) de alvo unico (eco elite)"]

    if apply:
        # preserva o estilo de quebra de linha do arquivo original, senao o
        # diff inteiro fica marcado como alterado
        newline = "\r\n" if "\r\n" in source else "\n"
        source = source.replace("\r\n", "\n")
        for position, text in sorted(insertions, reverse=True):
            source = source[:position] + text + source[position:]
        path.write_text(source, encoding="utf-8", newline=newline)

    return "ok", notes


def main(argv):
    apply = "--apply" in argv
    stats = {"ok": 0, "ja convertida": 0}
    manual = []
    combats = 0

    for script, lvl, name in player_spells():
        path = SCRIPTS / script
        if not path.exists():
            manual.append((script, "arquivo nao existe"))
            continue
        status, notes = convert(path, apply)
        if status == "ok":
            stats["ok"] += 1
            print(f"[+] {script:32s} lvl {lvl:>3}  {name:22s} {', '.join(notes)}")
            combats += int(notes[0].split()[0])
        elif status in stats:
            stats[status] += 1
        else:
            manual.append((script, status))

    print("\n---- resumo ----")
    for key, value in stats.items():
        print(f"  {key:14s}: {value}")
    print(f"  combats       : {combats}")
    if manual:
        print(f"  precisam de mao: {len(manual)}")
        for script, reason in manual:
            print(f"      {script}: {reason}")
    if not apply:
        print("\n(dry-run: rode com --apply para escrever)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
