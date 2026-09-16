#!/usr/bin/env python3
"""Checagem leve de balanceamento de blocos Lua (function/if/do/end, repeat/until).

Nao substitui um parser de verdade, mas pega o erro mais comum depois de editar
um script de spell na mao: `end` faltando ou sobrando. O servidor so' acusa esse
tipo de erro na hora de subir, entao vale conferir antes.

Uso:
    python tools/check_lua_blocks.py                 # varre data/spells
    python tools/check_lua_blocks.py arquivo.lua ...
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Comentarios, strings e blocos longos sao removidos antes de contar tokens
TOKEN_RE = re.compile(
    r"--\[\[.*?\]\]"          # comentario longo
    r"|--[^\n]*"              # comentario de linha
    r"|\[\[.*?\]\]"           # string longa
    r'|"(?:\\.|[^"\\])*"'     # string com aspas duplas
    r"|'(?:\\.|[^'\\])*'"     # string com aspas simples
    r"|[A-Za-z_]\w*",         # palavras
    re.S,
)

OPEN_WORDS = {"function", "if", "do", "repeat"}
CLOSE_WORDS = {"end", "until"}


def check(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    problems: list[str] = []

    depth = 0
    pending_for_while = 0
    line = 1
    last_line = 1
    for match in TOKEN_RE.finditer(text):
        line += text.count("\n", last_line, match.start())
        last_line = match.start()
        word = match.group(0)
        if word in OPEN_WORDS:
            if word == "do" and depth == 0:
                # `for ... do` / `while ... do`: o do fecha a estrutura aberta
                # pelo for/while, que nao conta como bloco proprio
                pass
            depth += 1
        elif word in CLOSE_WORDS:
            depth -= 1
            if depth < 0:
                problems.append(f"linha {line}: '{word}' sem bloco aberto")
                depth = 0
        elif word in ("for", "while"):
            pending_for_while += 1

    if depth != 0:
        problems.append(f"{depth:+d} bloco(s) sem fechar (end/until faltando ou sobrando)")

    for opener, closer in (("(", ")"), ("{", "}"), ("[", "]")):
        code = TOKEN_RE.sub(" ", text)
        if code.count(opener) != code.count(closer):
            problems.append(
                f"'{opener}{closer}' desbalanceado ({code.count(opener)} x {code.count(closer)})"
            )

    return problems


def main(argv: list[str]) -> int:
    if argv:
        targets = [Path(a) for a in argv]
    else:
        targets = sorted((PROJECT_ROOT / "data" / "spells").rglob("*.lua"))

    failures = 0
    for path in targets:
        if not path.exists():
            print(f"[?] nao encontrado: {path}")
            failures += 1
            continue
        problems = check(path)
        if problems:
            failures += 1
            print(f"[X] {path}")
            for problem in problems:
                print(f"      {problem}")

    print(f"\n{len(targets)} arquivo(s) conferido(s), {failures} com problema.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
