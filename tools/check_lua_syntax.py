#!/usr/bin/env python3
"""Checador de delimitadores para os scripts Lua do server.

Nao existe um interpretador Lua nesta maquina, mas o erro mais provavel de uma
edicao automatica e' justamente desbalancear parenteses/colchetes/chaves - foi
o que aconteceu quando uma ferramenta inseriu uma linha no MEIO da chamada
createCombatArea(...). Este checador percorre cada script ignorando strings e
comentarios e verifica:

  * cada (, [, { tem o par correspondente, na ordem correta;
  * tudo fecha no fim do arquivo;
  * o arquivo termina em profundidade 0.

Falhas de `end`/`then`/`do` ficam por conta de tools/check_lua_blocks.py.

Uso: python tools/check_lua_syntax.py [caminho ...]
"""

import pathlib
import sys

PAIRS = {")": "(", "]": "[", "}": "{"}
OPEN = set("([{")

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT = ROOT / "data" / "spells" / "scripts"


def strip_ignorables(source):
    """Troca strings e comentarios por espacos, mantendo os '\\n' e as posicoes."""
    out = []
    i = 0
    n = len(source)
    while i < n:
        ch = source[i]

        # comentario de linha
        if source.startswith("--", i) and not source.startswith("--[[", i):
            while i < n and source[i] != "\n":
                out.append(" ")
                i += 1
            continue

        # comentario longo --[[ ... ]] (aceita niveis --[==[)
        if source.startswith("--[", i):
            eq = 0
            j = i + 3
            while j < n and source[j] == "=":
                eq += 1
                j += 1
            if j < n and source[j] == "[":
                close = "]" + "=" * eq + "]"
                end = source.find(close, j)
                end = n if end == -1 else end + len(close)
                out.append("".join("\n" if c == "\n" else " " for c in source[i:end]))
                i = end
                continue

        # string longa [[ ... ]] / [==[ ... ]==]
        if ch == "[":
            eq = 0
            j = i + 1
            while j < n and source[j] == "=":
                eq += 1
                j += 1
            if j < n and source[j] == "[":
                close = "]" + "=" * eq + "]"
                end = source.find(close, j)
                end = n if end == -1 else end + len(close)
                out.append("".join("\n" if c == "\n" else " " for c in source[i:end]))
                i = end
                continue

        # string simples
        if ch in "'\"":
            quote = ch
            out.append(" ")
            i += 1
            while i < n:
                if source[i] == "\\":
                    out.append(" ")
                    if i + 1 < n:
                        out.append("\n" if source[i + 1] == "\n" else " ")
                    i += 2
                    continue
                if source[i] == quote:
                    out.append(" ")
                    i += 1
                    break
                out.append("\n" if source[i] == "\n" else " ")
                i += 1
            continue

        out.append(ch)
        i += 1

    return "".join(out)


def check(path):
    raw = path.read_text(encoding="utf-8", errors="surrogateescape")
    clean = strip_ignorables(raw)

    stack = []
    line = 1
    errors = []
    for ch in clean:
        if ch == "\n":
            line += 1
        elif ch in OPEN:
            stack.append((ch, line))
        elif ch in PAIRS:
            if not stack:
                errors.append(f"linha {line}: '{ch}' sem abertura")
            elif stack[-1][0] != PAIRS[ch]:
                open_ch, open_line = stack.pop()
                errors.append(f"linha {line}: '{ch}' fecha '{open_ch}' aberto na linha {open_line}")
            else:
                stack.pop()

    for ch, open_line in stack:
        errors.append(f"'{ch}' aberto na linha {open_line} nunca foi fechado")

    return errors


def main(argv):
    targets = [pathlib.Path(a) for a in argv] or [DEFAULT]
    files = []
    for target in targets:
        if target.is_dir():
            files.extend(sorted(target.rglob("*.lua")))
        else:
            files.append(target)

    bad = 0
    for path in files:
        errors = check(path)
        if errors:
            bad += 1
            print(f"[!] {path}")
            for err in errors[:6]:
                print(f"      {err}")
            if len(errors) > 6:
                print(f"      ... mais {len(errors) - 6}")

    print(f"\n{len(files)} arquivo(s) verificado(s), {bad} com problema")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
