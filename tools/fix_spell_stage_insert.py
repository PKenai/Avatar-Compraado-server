#!/usr/bin/env python3
"""Conserta as linhas de setCombatStageScaling que ficaram DENTRO da chamada
createCombatArea(...):

    setCombatArea(combat, createCombatArea(
    setCombatStageScaling(combat)      <-- Lua le isso como argumento e quebra
          {0, 0, 1, 0, 0},
          }))

O certo e' mover a linha para depois do fechamento do setCombatArea:

    setCombatArea(combat, createCombatArea(
          {0, 0, 1, 0, 0},
          }))
    setCombatStageScaling(combat)

Como setCombatStageScaling() apenas liga a flag do combat (a area de cada
estagio e' resolvida no cast, em Combat::getStageArea()), a posicao da chamada
nao importa - so' precisa estar fora da expressao e no mesmo escopo do
setCombatArea (importante nos combats dentro de loops).

Uso: python tools/fix_spell_stage_insert.py [--apply]
"""

import argparse
import pathlib
import re
import sys

SCRIPTS = pathlib.Path(__file__).resolve().parent.parent / "data" / "spells" / "scripts"

BAD_LINE = re.compile(r'^([ \t]*)setCombatStageScaling\(([\w\[\]\'"\.]+)\)\s*$')
CALL_OPEN = re.compile(r'createCombatArea\(\s*$')


def find_close(lines, start):
    """Indice da linha que fecha o createCombatArea aberto em start-1."""
    for j in range(start, len(lines)):
        if "}))" in lines[j]:
            return j
    return None


def enclosing_indent(lines, close_idx):
    """Indentacao da linha do setCombatArea que abriu o bloco."""
    for k in range(close_idx, -1, -1):
        if "setCombatArea(" in lines[k]:
            return re.match(r'^([ \t]*)', lines[k]).group(1)
    return ""


def fix_file(path, apply):
    lines = path.read_text(encoding="utf-8", errors="surrogateescape").splitlines(keepends=True)
    moves = []
    i = 0
    while i < len(lines):
        m = BAD_LINE.match(lines[i])
        if m and i > 0 and CALL_OPEN.search(lines[i - 1]):
            close = find_close(lines, i + 1)
            if close is None:
                moves.append((i, None, None, lines[i].rstrip("\n")))
            else:
                indent = enclosing_indent(lines, close)
                moves.append((i, close, f"{indent}setCombatStageScaling({m.group(2)})\n",
                              lines[i].rstrip("\n")))
            i += 1
            continue
        i += 1

    if not moves:
        return 0

    # remove de tras pra frente e insere depois do fechamento
    for idx, close, new_line, _ in sorted(moves, key=lambda t: -t[0]):
        if close is None:
            continue
        del lines[idx]
        if idx < close:
            close -= 1
        lines.insert(close + 1, new_line)

    if apply:
        path.write_text("".join(lines), encoding="utf-8", errors="surrogateescape")
    return len(moves)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="grava as mudancas")
    args = ap.parse_args()

    total = 0
    problems = 0
    touched = []
    for path in sorted(SCRIPTS.rglob("*.lua")):
        n = fix_file(path, args.apply)
        if n:
            total += n
            touched.append(path.relative_to(SCRIPTS.parent.parent.parent))
    for p in touched:
        print(("aplicado " if args.apply else "dry-run ") + str(p))

    print(f"\n{total} site(s) em {len(touched)} arquivo(s)"
          + (" - gravado" if args.apply else " - use --apply para gravar"))
    return 0 if total else 1


if __name__ == "__main__":
    sys.exit(main())
