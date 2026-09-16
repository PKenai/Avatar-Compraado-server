#!/usr/bin/env python3
"""Relatorio dos estagios das magias (mini <50 / padrao 50-99 / elite 100+).

Le data/spells/spells.xml + os scripts + as areas do lib e SIMULA o que o motor
faz em sources/combat.cpp (scaleMatrixArea) para cada createCombatArea encontrado
no script da magia, mostrando quantos tiles cada estagio atinge.

Uso:  python tools/report_spell_stages.py [--json]
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "data/spells/scripts"
LIB = ROOT / "data/spells/lib"


# --------------------------------------------------------------------------
# Tabelas Lua -> matriz
# --------------------------------------------------------------------------
def iter_tables(text):
    """Rende (nome, corpo) de cada `NOME = { ... }` no nivel de topo do texto."""
    for m in re.finditer(r"\b([A-Za-z_][\w.]*)(?:\[[^\]]*\])?\s*=\s*\{", text):
        name = m.group(1)
        start = m.end() - 1
        depth, i, n = 0, start, len(text)
        while i < n:
            ch = text[i]
            if ch == "-" and text[i:i + 2] == "--":
                j = text.find("\n", i)
                i = n if j < 0 else j
                continue
            if ch == '"':
                i = text.find('"', i + 1) + 1 or n
                continue
            if ch in "{[(":
                depth += 1
            elif ch in "}])":
                depth -= 1
                if depth == 0:
                    yield name, text[start:i + 1]
                    break
            i += 1


def parse_matrix(body):
    """`{{0,1,0},{1,3,1}}` -> lista de linhas se parecer uma area; senao None."""
    inner = body.strip()
    if not inner.startswith("{") or not inner.endswith("}"):
        return None
    inner = inner[1:-1].strip()
    rows = []
    for row in re.findall(r"\{([^{}]*)\}", inner):
        vals = [v.strip() for v in row.split(",") if v.strip()]
        if not vals or not all(re.fullmatch(r"\d+", v) for v in vals):
            return None
        rows.append([int(v) for v in vals])
    if not rows:
        return None
    width = len(rows[0])
    if any(len(r) != width for r in rows):
        return None
    return rows


def parse_matrix_list(body):
    """`{ {matriz}, {matriz}, ... }` -> lista de matrizes (para arr[x])."""
    inner = body.strip()
    if not (inner.startswith("{") and inner.endswith("}")):
        return []
    inner = inner[1:-1]
    out, i = [], 0
    while i < len(inner):
        if inner[i] == "{":
            depth, j = 0, i
            while j < len(inner):
                if inner[j] == "{":
                    depth += 1
                elif inner[j] == "}":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            m = parse_matrix(inner[i:j + 1])
            if m:
                out.append(m)
            else:
                out.extend(parse_matrix_list(inner[i:j + 1]))
            i = j + 1
        else:
            i += 1
    return out


def load_areas():
    areas = {}
    for f in sorted(LIB.glob("*.lua")):
        text = f.read_text(encoding="utf-8", errors="replace")
        for name, body in iter_tables(text):
            m = parse_matrix(body)
            if m:
                areas.setdefault(name, m)
    return areas


# --------------------------------------------------------------------------
# scaleMatrixArea (sources/combat.cpp) replicado
# --------------------------------------------------------------------------
# Convencao do motor (CombatArea::createArea em sources/combat.cpp):
#   valor 1 = tile atingido
#   valor 2 = CENTRO apenas (nao e' tile de dano)
#   valor 3 = centro + tile atingido
# Sem 2/3 o centro fica em (0,0) (MatrixArea::MatrixArea).
HIT = (1, 3)
CENTER = (2, 3)


def center_of(rows):
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v in CENTER:
                return y, x
    return 0, 0


def scale(rows, mode):
    cy, cx = center_of(rows)
    cells = [(y - cy, x - cx) for y, row in enumerate(rows)
             for x, v in enumerate(row) if v in HIT]
    if not cells:
        return []
    max_r = max(max(abs(dy), abs(dx)) for dy, dx in cells)

    rel = []
    for dy, dx in cells:
        if mode < 0 and max_r > 0 and max(abs(dy), abs(dx)) >= max_r:
            continue
        rel.append((dy, dx))

    if not rel:  # anel unico: mini vira a cruz em volta do conjurador
        rel = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]

    if mode > 0:
        for dy, dx in list(rel):
            if max(abs(dy), abs(dx)) != max_r:
                continue
            ny = dy + (1 if dy > 0 else (-1 if dy < 0 else 0))
            nx = dx + (1 if dx > 0 else (-1 if dx < 0 else 0))
            if (ny, nx) not in rel:
                rel.append((ny, nx))
    return rel


def render(rel):
    if not rel:
        return "(vazio)"
    miny = min(y for y, _ in rel)
    minx = min(x for _, x in rel)
    maxy = max(y for y, _ in rel)
    maxx = max(x for _, x in rel)
    grid = [["." for _ in range(maxx - minx + 1)] for _ in range(maxy - miny + 1)]
    for y, x in rel:
        grid[y - miny][x - minx] = "#"
    grid[-miny][-minx] = "@"  # @ = tile do conjurador (centro da magia)
    return " / ".join("".join(r) for r in grid)


# --------------------------------------------------------------------------
# Varredura das magias
# --------------------------------------------------------------------------
def declared_spells():
    xml = (ROOT / "data/spells/spells.xml").read_text(encoding="utf-8", errors="replace")
    out = []
    for m in re.finditer(r"<(instant|rune)\s+([^>]*?)>", xml, re.S):
        attrs = m.group(2)
        g = lambda k, d="": (re.search(rf'{k}="([^"]*)"', attrs).group(1)
                             if re.search(rf'{k}="([^"]*)"', attrs) else d)
        script = g("value")
        if not script:
            continue
        out.append({
            "kind": m.group(1),
            "name": g("name"),
            "file": script.replace("\\", "/"),
            "level": int(g("lvl", "0") or 0),
        })
    return out


def area_shapes(script_text, areas):
    """Resolve cada createCombatArea(...) do script para uma matriz."""
    shapes = []
    for m in re.finditer(r"createCombatArea\(\s*", script_text):
        i = m.end()
        if script_text[i] == "{":  # literal multi-linha
            depth, j = 0, i
            while j < len(script_text):
                if script_text[j] == "{":
                    depth += 1
                elif script_text[j] == "}":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            expr = script_text[i:j + 1]
        else:
            j = i
            while j < len(script_text) and script_text[j] not in "),\n":
                j += 1
            expr = script_text[i:j].strip()
        m2 = parse_matrix(expr)
        if m2:
            shapes.append((expr.replace("\n", " ").replace(" ", ""), m2))
            continue
        # arr[x] / MyLocal.areas[x] -> tenta a tabela literal local com esse nome
        base = re.sub(r"\[[^\]]*\]$", "", expr)
        found = []
        for name, body in iter_tables(script_text):
            if name.split(".")[-1] != base.split(".")[-1]:
                continue
            mm = parse_matrix(body)
            if mm:
                found.append(mm)
            else:
                found.extend(parse_matrix_list(body))
        if not found and base in areas:
            found = [areas[base]]
        for mm in (found or []):
            shapes.append((expr, mm))
    return shapes


def main():
    as_json = "--json" in sys.argv
    areas = load_areas()
    report = []
    for sp in declared_spells():
        p = SCRIPTS / sp["file"]
        if not p.exists():
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        marks = {
            "scaling": len(re.findall(r"setCombatStageScaling", text)),
            "echo": len(re.findall(r"registerSpellStageEcho", text)),
            "manual": sorted(set(re.findall(
                r"\b(spellStage\w+|pickSpellStage|getSpellStage|isSpellElite|isSpellMini)\b", text))),
        }
        if not (marks["scaling"] or marks["echo"] or marks["manual"]):
            continue
        shapes = area_shapes(text, areas)
        entry = dict(sp)
        entry["marks"] = marks
        entry["areas"] = []
        seen = set()
        for expr, mat in shapes:
            if mat is None:
                continue
            key = json.dumps(mat)
            if key in seen:
                continue
            seen.add(key)
            base = scale(mat, 0)
            entry["areas"].append({
                "expr": expr,
                "base": len(base),
                "mini": len(scale(mat, -1)),
                "elite": len(scale(mat, 1)),
                "base_map": render(base),
                "mini_map": render(scale(mat, -1)),
                "elite_map": render(scale(mat, 1)),
            })
        report.append(entry)

    if as_json:
        print(json.dumps(report, ensure_ascii=False, indent=1))
        return

    for e in report:
        tag = []
        if e["marks"]["scaling"]:
            tag.append(f"area×{e['marks']['scaling']}")
        if e["marks"]["echo"]:
            tag.append(f"echo×{e['marks']['echo']}")
        if e["marks"]["manual"]:
            tag.append("manual:" + ",".join(e["marks"]["manual"]))
        print(f"\n=== {e['name']} (lvl {e['level']}, {e['file']}) [{' '.join(tag)}]")
        if not e["areas"]:
            print("    (sem createCombatArea resolvido)")
        for a in e["areas"]:
            print(f"    {a['expr']:<24} mini {a['mini']:>3} tiles | base {a['base']:>3} | elite {a['elite']:>3}")
            print(f"        mini : {a['mini_map']}")
            print(f"        base : {a['base_map']}")
            print(f"        elite: {a['elite_map']}")

    total = len(report)
    scanned = len({s["file"] for s in declared_spells()})
    print(f"\n--- {total} magias com estagio de {scanned} scripts declarados ---")


if __name__ == "__main__":
    main()
