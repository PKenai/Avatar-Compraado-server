#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
spell_power_tool.py -- ajusta a forca de uma magia em % e manda o servidor
recarregar sozinho.

O que ele mexe: o `atk` (dano) ou o `heal` (cura) da magia em
    data/lib/201-spellsExausted.lua
O atk e' a porcentagem do dano que a formula da propria magia calcula:
100 = dano original da formula, 50 = metade, 0 = 1 de dano.

Como o servidor aplica sem restart: o globalevent
data/globalevents/scripts/spellPowerHotReload.lua observa esse arquivo e chama
doReloadInfo(RELOAD_SPELLS) quando ele muda. O /reload spells do motor passa por
Spells::clear() -> reInitState(), que re-le a lib inteira e re-executa os scripts
de magia -- por isso o valor novo vale na hora.

Uso:
    python tools/spell_power_tool.py                       # interface
    python tools/spell_power_tool.py --list                # so' listar
    python tools/spell_power_tool.py --spell "fire wave" --set 25     # +25%
    python tools/spell_power_tool.py --spell "fire wave" --set -15    # -15%
    python tools/spell_power_tool.py --spell "fire wave" --exact 30   # atk = 30
    python tools/spell_power_tool.py --undo                # volta a ultima mudanca
    python tools/spell_power_tool.py --medir "fire wave"   # dano estimado (roda o report)

Com --vps o alvo passa a ser o servidor DA VPS: o tool puxa o
201-spellsExausted.lua da pasta do servidor de la' (VPS_ROOT, abaixo), ajusta em
cima do que esta' no ar, devolve pela WinRM e quem recarrega e' o watcher da
propria VPS (globalevent SpellPowerHotReload) -- sem restart. A copia local fica
sincronizada no fim.
Vale para qualquer opcao: --list, --spell, --undo, --medir e a interface.
Precisa da credencial da VPS (a mesma que o subir_vps.bat usa).

Com --local o tool forca o modo antigo: mexe so' no arquivo desta maquina e nao
recarrega nada. E' o que o forca_das_magias.bat usa quando voce pede --local,
porque o padrao dele hoje e' a VPS.

Aviso: o reload tambem passa por g_monsters.reload() (e' o caminho do
/reload spells no motor) e zera o que os scripts de magia guardam em memoria
(tornados do stormcall, canais como o water heal). Nao ajuste com gente
canalizando ou em PvP.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPELLS_INFO = os.path.join(ROOT, "data", "lib", "201-spellsExausted.lua")
SPELLS_XML = os.path.join(ROOT, "data", "spells", "spells.xml")
RELOAD_LOG = os.path.join(ROOT, "data", "logs", "spellPowerReload.log")
BACKUP = SPELLS_INFO + ".bak"

# --- modo VPS (--vps) -------------------------------------------------------
# Sem --vps o tool edita o arquivo LOCAL e espera o servidor local recarregar.
# Com --vps o alvo e' o servidor da VPS: o arquivo de la' e' puxado para
# VPS_PULLED, ajustado em cima do que esta' no ar e devolvido; quem recarrega
# e' o watcher da propria VPS.
VPS_HELPER = os.path.join(ROOT, "tools", "vps_file.ps1")
# Pasta do servidor que ESTA' NO AR na VPS (a copia que fica na Area de
# Trabalho do Administrador). O C:\Avatar era uma segunda copia, nunca usada
# pelo servidor de verdade, e foi apagada. Se a pasta da VPS mudar de lugar, e'
# SO' esta linha que precisa acompanhar.
VPS_ROOT = r"C:\Users\Administrador\Desktop\Avatar-Compraado-server"
VPS_LIB = VPS_ROOT + r"\data\lib\201-spellsExausted.lua"
VPS_RELOAD_LOG = VPS_ROOT + r"\data\logs\spellPowerReload.log"
# O espelho da VPS fica FORA de data/: o engine carrega TODO *.lua de data/lib e
# um 201-spellsExausted.vps.lua la' sobrescreveria a tabela spellsInfo inteira.
VPS_PULLED = os.path.join(ROOT, "tools", "vps_cache", "201-spellsExausted.lua")

VPS_MODE = False

# Arquivo que ESTA execucao edita (local ou o puxado da VPS) e o .bak que
# guarda o estado anterior dele.
ACTIVE = {"lib": SPELLS_INFO, "backup": BACKUP}

ELEMENTS = ("fire", "water", "air", "earth")

ENTRY_RE = re.compile(rb'^\s*\["([^"]+)"\]\s*=\s*\{([^}]*)\}\s*,?\s*(?:--.*)?\r?$')
FIELD_RE = r'\b{field}\s*=\s*(\d+(?:\.\d+)?)'
XML_SPELL_RE = re.compile(
    r'<(?:instant|rune)\b[^>]*?name="([^"]+)"[^>]*?value="([^"]+)"[^>]*?>'
)


# ----------------------------------------------------------------------------
# leitura
# ----------------------------------------------------------------------------
def read_bytes(path):
    with open(path, "rb") as fh:
        return fh.read()


def parse_spells_info():
    """Devolve [{key, field, value, line, element}] do 201-spellsExausted.lua."""
    raw = read_bytes(ACTIVE["lib"])
    out = []
    for i, line in enumerate(raw.split(b"\n")):
        m = ENTRY_RE.match(line)
        if not m:
            continue
        key = m.group(1).decode("utf-8", "replace")
        body = m.group(2)
        field = None
        for candidate in ("atk", "heal"):
            fm = re.search(FIELD_RE.format(field=candidate).encode(), body)
            if fm:
                field, value = candidate, float(fm.group(1))
                break
        if not field:
            continue
        out.append({
            "key": key,
            "field": field,
            "value": value,
            "line": i,
            "element": key.split(" ", 1)[0] if key.split(" ", 1)[0] in ELEMENTS else "?",
        })
    return out


def parse_scripts():
    """script relativo ('fire/wave.lua') -> spellName declarado dentro dele.

    E' por esse `spellName` que o script procura o atk em spellsInfo, e ele nem
    sempre e' igual ao nome que aparece no jogo (o spells.xml chama a lvl 1 da
    agua de 'Water Wave', mas o script pede spellsInfo['water whip']).
    """
    base = os.path.join(ROOT, "data", "spells", "scripts")
    out = {}
    for dirpath, _, files in os.walk(base):
        for fn in files:
            if not fn.endswith(".lua"):
                continue
            path = os.path.join(dirpath, fn)
            try:
                head = read_bytes(path)[:4000].decode("utf-8", "replace")
            except OSError:
                continue
            m = re.search(r'spellName\s*=\s*"([^"]+)"', head)
            if m:
                rel = os.path.relpath(path, base).replace("\\", "/")
                out[rel] = m.group(1)
    return out


def parse_spells_xml(scripts):
    """chave do spellsInfo -> {name, level, element} a partir do spells.xml.

    A ponte e' o arquivo de script: o XML diz o nome do jogo e o script, o
    script diz qual chave do spellsInfo ele usa.
    """
    out = {}
    try:
        text = read_bytes(SPELLS_XML).decode("utf-8", "replace")
    except OSError:
        return out
    for m in XML_SPELL_RE.finditer(text):
        name, script = m.group(1), m.group(2)
        key = scripts.get(script.replace("\\", "/"))
        if not key:
            continue
        element = "?"
        for el in ELEMENTS:
            if script.startswith(el + "/"):
                element = el
                break
        lvl_match = re.search(r'\blvl="(\d+)"', m.group(0))
        level = int(lvl_match.group(1)) if lvl_match else 0
        atual = out.get(key)
        if not atual or level < atual["level"]:
            out[key] = {"name": name, "level": level, "element": element}
    return out


def build_catalog():
    """Catalogo ordenado: primeiro o que esta' no jogo, depois as chaves mortas.

    Chave morta = valor no spellsInfo que nenhum script do spells.xml pede
    (sobrou de magia renomeada/removida). Mexer nela nao muda dano nenhum, e a
    interface avisa isso em vez de deixar o usuario editar no vazio.
    """
    scripts = parse_scripts()
    xml = parse_spells_xml(scripts)
    info = parse_spells_info()
    for row in info:
        meta = xml.get(row["key"])
        row["live"] = meta is not None
        row["name"] = meta["name"] if meta else row["key"]
        row["level"] = meta["level"] if meta else 0
        if row["element"] == "?" and meta:
            row["element"] = meta["element"]
    info.sort(key=lambda r: (
        not r["live"],
        ELEMENTS.index(r["element"]) if r["element"] in ELEMENTS else 9,
        r["level"], r["key"]))
    for i, row in enumerate(info, 1):
        row["n"] = i
    return info


# ----------------------------------------------------------------------------
# escrita
# ----------------------------------------------------------------------------
def write_value(row, new_value):
    """Troca SO' o numero do campo daquela linha, preservando o resto do arquivo."""
    raw = read_bytes(ACTIVE["lib"])
    if not os.path.exists(ACTIVE["backup"]):
        shutil.copyfile(ACTIVE["lib"], ACTIVE["backup"])
    lines = raw.split(b"\n")
    line = lines[row["line"]]
    pattern = re.compile(
        (r'(\b{field}\s*=\s*)(\d+(?:\.\d+)?)').format(field=row["field"]).encode()
    )
    text = ("%d" % new_value) if float(new_value).is_integer() else ("%g" % new_value)
    new_line, count = pattern.subn(lambda m: m.group(1) + text.encode(), line, count=1)
    if count != 1:
        raise RuntimeError("nao consegui trocar o valor na linha %d" % (row["line"] + 1))
    lines[row["line"]] = new_line
    tmp = ACTIVE["lib"] + ".tmp"
    with open(tmp, "wb") as fh:
        fh.write(b"\n".join(lines))
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, ACTIVE["lib"])   # troca atomica: o vigilante nunca ve' meio arquivo


def reload_marker():
    if not os.path.exists(RELOAD_LOG):
        return 0
    return os.path.getsize(RELOAD_LOG)


def wait_server_reload(marker, timeout=20):
    """Espera o vigilante do servidor confirmar o reload no log dele."""
    if not os.path.exists(RELOAD_LOG):
        return None
    deadline = time.time() + timeout
    while time.time() < deadline:
        if os.path.getsize(RELOAD_LOG) > marker:
            return True
        time.sleep(0.4)
    return False


# ----------------------------------------------------------------------------
# transporte com a VPS (--vps)
# ----------------------------------------------------------------------------
def _ps(args, timeout=180):
    """Roda tools/vps_file.ps1 e devolve a saida limpa."""
    exe = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", VPS_HELPER] + args
    try:
        proc = subprocess.run(exe, capture_output=True, text=True, timeout=timeout)
    except OSError as err:
        raise RuntimeError("nao consegui chamar o PowerShell: %s" % err)
    except subprocess.TimeoutExpired:
        raise RuntimeError("a VPS nao respondeu em %d s" % timeout)
    if proc.returncode != 0:
        msg = (proc.stderr or proc.stdout or "o transporte falhou").strip()
        raise RuntimeError(msg.replace("\n", " ")[:300])
    return (proc.stdout or "").strip()


def vps_pull():
    """Traz o arquivo que o servidor da VPS esta' usando."""
    os.makedirs(os.path.dirname(VPS_PULLED), exist_ok=True)
    _ps(["-Get", "-Remote", VPS_LIB, "-Local", VPS_PULLED])
    return VPS_PULLED


def vps_push(path):
    _ps(["-Put", "-Local", path, "-Remote", VPS_LIB])


def vps_log_size():
    """Tamanho do log de reload LA' na VPS (-1 se ainda nao existe)."""
    out = _ps(["-Size", "-Remote", VPS_RELOAD_LOG])
    try:
        return int(out.split()[-1])
    except (ValueError, IndexError):
        return -1


def wait_vps_reload(marker, timeout=60):
    """Espera o servidor DA VPS confirmar o reload no log dele."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        if vps_log_size() > marker:
            return True
        time.sleep(1.5)
    return False


def reload_marker_live():
    """Marca do log de reload do servidor que este tool esta' ajustando."""
    return vps_log_size() if VPS_MODE else reload_marker()


def publish():
    """Entrega o arquivo ajustado ao servidor de verdade."""
    if VPS_MODE:
        vps_push(ACTIVE["lib"])
        shutil.copyfile(ACTIVE["lib"], SPELLS_INFO)   # o repo acompanha o que esta' no ar
        print("  enviado para a VPS: " + VPS_LIB)
        print("  copia local sincronizada (nao fica divergente do que esta' no ar)")
    else:
        print("  gravado em data/lib/201-spellsExausted.lua (backup: %s)" % os.path.basename(ACTIVE["backup"]))


# ----------------------------------------------------------------------------
# apresentacao
# ----------------------------------------------------------------------------
def titulo(row):
    """Nome que o jogador ve' e, se for outro, a chave do atk entre parenteses."""
    if row["name"].lower() == row["key"].lower():
        return row["name"]
    return "%s (%s)" % (row["name"], row["key"])


def print_catalog(catalog):
    print()
    print("  #   magia                              elem    lvl   campo   valor")
    print("  " + "-" * 70)
    current = None
    for row in catalog:
        if not row["live"]:
            continue
        if row["element"] != current:
            current = row["element"]
            print("  [%s]" % current)
        print("  %-3d %-34s %-6s %5d  %-6s %6g" % (
            row["n"], titulo(row)[:34], row["element"], row["level"], row["field"], row["value"]))
    dead = [r for r in catalog if not r["live"]]
    if dead:
        print("  [fora de uso -- nenhum script do spells.xml pede esses valores;")
        print("   chegue nelas pelo numero ou por 'buscar <texto>']")
        for row in dead:
            print("  %-3d %-34s %-6s %5s  %-6s %6g" % (
                row["n"], titulo(row)[:34], row["element"], "-", row["field"], row["value"]))
    print()


def find_rows(catalog, needle, incluir_mortas=False):
    """Aceita numero da lista, chave do atk ou nome do jogo.

    Se o texto casar com uma magia viva e uma chave morta ao mesmo tempo (o caso
    de 'water wave', que e' o nome da Water Wave e tambem o nome de uma chave
    velha), a magia viva ganha: sem isso o ajuste sairia nas duas. As mortas
    ficam alcancaveis pelo numero da lista ou por 'buscar'.
    """
    needle = needle.strip().lower()
    if not needle:
        return []
    if needle.isdigit():
        n = int(needle)
        return [r for r in catalog if r["n"] == n]
    exact = [r for r in catalog
             if r["key"].lower() == needle or r["name"].lower() == needle]
    rows = exact or [r for r in catalog
                     if needle in r["key"].lower() or needle in r["name"].lower()]
    if not incluir_mortas:
        vivas = [r for r in rows if r["live"]]
        if vivas:
            rows = vivas
    return sorted(rows, key=lambda r: not r["live"])


def preview(row, percent, exact=None):
    old = row["value"]
    new = float(exact) if exact is not None else old * (1 + percent / 100.0)
    new = max(0.0, new)
    new = round(new)
    return old, new


def apply_change(row, old, new, announce=True):
    if new == old:
        print("  nada a fazer: o valor ja e' %g." % old)
        return False
    if not row["live"]:
        print("  ATENCAO: '%s' e' chave fora de uso -- nenhum script do spells.xml" % row["key"])
        print("  pede esse valor, entao mexer nela NAO muda o dano em jogo.")
    marker = reload_marker_live()
    write_value(row, new)
    print()
    print("  %s: %s %g -> %g  (%+d%%)" % (
        row["key"], row["field"], old, new,
        round((new - old) / old * 100) if old else 0))
    try:
        publish()
    except RuntimeError as err:
        print("  [ERRO] nao consegui entregar o arquivo: %s" % err)
        return False

    if VPS_MODE:
        print("  aguardando o servidor da VPS disparar o reload...")
        if wait_vps_reload(marker):
            print("  OK: o reload foi disparado NA VPS (sem restart).")
            print("  Confira em %s:" % VPS_RELOAD_LOG)
            print("  <data>  reload #N disparado")
        else:
            print("  AVISO: a VPS nao registrou o reload em 60s.")
            print("  Veja %s e se o" % VPS_RELOAD_LOG)
            print("  globalevent SpellPowerHotReload esta' no globalevents.xml de la.")
        return True

    if os.path.exists(RELOAD_LOG):
        print("  aguardando o servidor disparar o reload...")
        ok = wait_server_reload(marker)
        if ok:
            print("  OK: o servidor registrou o reload (data/logs/spellPowerReload.log).")
            print("  Ele roda no proximo tique do motor -- confira no console:")
            print("  [spellPower] ... recarregando as magias (reload #N)")
        else:
            print("  AVISO: o servidor nao registrou o reload em 20s.")
            print("  Confira se o globalevent SpellPowerHotReload esta' no ar")
            print("  (precisa de /reload globalevents ou restart depois de instalar).")
    else:
        print("  AVISO: data/logs/spellPowerReload.log nao existe ainda.")
        print("  O vigilante (data/globalevents/scripts/spellPowerHotReload.lua) so'")
        print("  passa a rodar depois de /reload globalevents ou de um restart.")
        print("  O valor gravado ja vale no proximo restart de qualquer jeito.")
        print("  ATENCAO: isto e' o modo LOCAL -- o SERVIDOR DA VPS nao mudou.")
        print("  O servidor roda na VPS, nao nesta maquina. Para ajustar la' (com")
        print("  reload em segundos, sem restart) rode:")
        print("    forca_das_magias.bat            (o padrao dele ja e' a VPS)")
        print("    forca_das_magias.bat --spell \"<magia>\" --set <porcento>")
    return True


# ----------------------------------------------------------------------------
# interface
# ----------------------------------------------------------------------------
def ask(prompt):
    try:
        return input(prompt).strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return ""


def interactive(catalog):
    print("=" * 78)
    print(" FORCA DAS MAGIAS -- ajuste em %% com gravacao automatica e reload no servidor")
    if VPS_MODE:
        print(" alvo   : servidor da VPS -> " + VPS_LIB)
        print("          (edita la' e o proprio servidor de la' recarrega)")
    else:
        print(" arquivo: data/lib/201-spellsExausted.lua  (SO' esta maquina)")
        print(" para o servidor da VPS: use forca_das_magias_vps.bat (ou --vps)")
    print(" obs: so' aparecem magias com atk (dano) ou heal (cura) na tabela -- buffs,")
    print("      summons e utamos nao tem valor de dano pra ajustar aqui.")
    print("=" * 78)

    while True:
        print_catalog(catalog)
        print(" digite: numero(s) da magia (ex: 12 ou 12,44), nome (ex: fire wave),")
        print("         'buscar texto', 'medir numero', ou ENTER para sair.")
        alvo = ask("\n magia > ")
        if alvo == "":
            print(" tchau.")
            return
        if alvo.lower().startswith("buscar"):
            rows = find_rows(catalog, alvo[6:].strip(), incluir_mortas=True)
            if not rows:
                print("  nenhuma magia com esse texto.")
            for r in rows:
                print("  %-3d %-32s %-6s lvl %-4d %s %g" % (
                    r["n"], titulo(r)[:32], r["element"], r["level"], r["field"], r["value"]))
            continue
        if alvo.lower().startswith("medir"):
            partes = alvo.split()
            rows = find_rows(catalog, " ".join(partes[1:]))
            for r in rows:
                measure(r)
            continue

        rows = []
        for token in alvo.split(","):
            found = find_rows(catalog, token)
            if not found:
                print("  nao achei '%s'." % token.strip())
                rows = []
                break
            rows.extend(found)
        if not rows:
            continue

        for r in rows:
            print("\n  escolhida: %s  (%s, lvl %d)  %s = %g" % (
                titulo(r), r["element"], r["level"], r["field"], r["value"]))
            if not r["live"]:
                print("  ATENCAO: chave fora de uso (nenhum script do spells.xml pede")
                print("  esse valor) -- editar aqui nao muda nada em jogo.")

        direcao = ask("  aumentar ou diminuir? [a/d] > ").lower()
        if direcao in ("a", "aumentar", "+"):
            sinal = 1
        elif direcao in ("d", "diminuir", "-"):
            sinal = -1
        else:
            print("  opcao invalida, cancelado.")
            continue

        pct_txt = ask("  quantos por cento? (ex: 25) > ").replace("%", "").replace(",", ".")
        try:
            percent = abs(float(pct_txt)) * sinal
        except ValueError:
            print("  numero invalido, cancelado.")
            continue
        if abs(percent) > 100:
            print("  atencao: %.0f%% de uma vez muda bastante o balanceamento." % percent)

        print()
        for r in rows:
            old, new = preview(r, percent)
            print("  %-32s %s %g -> %g" % (titulo(r)[:32], r["field"], old, new))
        if ask("  confirma? [S/n] > ").lower() in ("n", "nao", "no"):
            print("  cancelado.")
            continue

        for r in rows:
            old, new = preview(r, percent)
            apply_change(r, old, new)
            r["value"] = new
            if old and abs(new - old) / old > 0.2:
                print("  (essa foi grande: se a magia ficar fora da faixa das outras")
                print("   do mesmo elemento, vale rodar o spell_balance_report depois.)")
        print()


def measure(row):
    """Roda o spell_balance_report.pl (--json) e mostra o dano medido da magia.

    O relatorio le' a formula do script, o atk da tabela e o XML, entao o numero
    que sai aqui e' o dano por cast do modelo -- e' assim que da' para conferir se
    o ajuste deixou a magia na faixa das outras do mesmo elemento.
    """
    report = os.path.join(ROOT, "tools", "spell_balance_report.pl")
    if not os.path.exists(report):
        print("  tools/spell_balance_report.pl nao encontrado.")
        return
    print("  medindo %s em level 100 / bend 48 (isso leva alguns segundos)..." % row["key"])
    # O relatorio monta o caminho do datapack a partir do diretorio atual, entao
    # tem que rodar da raiz do servidor e receber o caminho RELATIVO -- com o
    # caminho absoluto ele concatena os dois e nao acha o 201-spellsExausted.lua.
    try:
        proc = subprocess.run(
            ["perl", os.path.join("tools", "spell_balance_report.pl"),
             "--level", "100", "--mag", "48", "--json"],
            capture_output=True, text=True, timeout=300, cwd=ROOT)
    except (OSError, subprocess.TimeoutExpired) as err:
        print("  nao consegui medir: %s" % err)
        return
    if "[" not in proc.stdout:
        print("  o relatorio nao devolveu JSON (perl: %s)" % (proc.stderr or "sem stderr").strip()[:200])
        return
    try:
        dados = json.loads(proc.stdout[proc.stdout.index("["):])
    except ValueError as err:
        print("  JSON do relatorio invalido: %s" % err)
        return

    achados = [d for d in dados if str(d.get("spell", "")).lower() == row["key"].lower()]
    if not achados:
        if row["live"]:
            print("  o relatorio mede DANO -- essa magia nao aparece nele (cura, buff,")
            print("  summon ou uma formula que ele nao interpreta).")
        else:
            print("  o relatorio nao cobre essa magia (ele mede as magias do spells.xml;")
            print("  chave fora de uso nao aparece nele).")
        return
    for d in achados:
        print("  %-22s lvl %-4s cd %.1fs  atk %-4s dano/cast %-8.0f dps %.1f" % (
            d["spell"], d["level"], float(d["cd"]), d["atk"], d["danoCast"], d["dps"]))


# ----------------------------------------------------------------------------
def main(argv):
    global VPS_MODE

    if "--local" in argv and "--vps" in argv:
        print("escolha um alvo: --vps (servidor da VPS) ou --local (so' esta maquina).")
        return 1
    if "--local" in argv:
        argv = [a for a in argv if a != "--local"]

    if "--vps" in argv:
        argv = [a for a in argv if a != "--vps"]
        VPS_MODE = True
        print("[VPS] puxando " + VPS_LIB)
        try:
            vps_pull()
        except RuntimeError as err:
            print("  [ERRO] nao consegui puxar o arquivo da VPS: %s" % err)
            return 1
        ACTIVE["lib"] = VPS_PULLED
        ACTIVE["backup"] = VPS_PULLED + ".bak"
        puxado = read_bytes(VPS_PULLED)
        print("  %d bytes" % len(puxado))
        if not os.path.exists(SPELLS_INFO):
            print("  [aviso] nao existe copia local; vou criar uma igual a' da VPS no fim.")
        elif read_bytes(SPELLS_INFO) != puxado:
            print("  [aviso] a copia local estava diferente da VPS; o ajuste parte do que")
            print("          esta' no ar e a copia local acompanha no fim.")

    catalog = build_catalog()

    if "--list" in argv:
        print_catalog(catalog)
        return 0

    if "--undo" in argv:
        if not os.path.exists(ACTIVE["backup"]):
            print("nao existe backup para desfazer (%s)" % ACTIVE["backup"])
            return 1
        marker = reload_marker_live()
        shutil.copyfile(ACTIVE["backup"], ACTIVE["lib"])
        print("restaurado o backup %s" % os.path.basename(ACTIVE["backup"]))
        try:
            publish()
        except RuntimeError as err:
            print("[ERRO] nao consegui entregar o arquivo: %s" % err)
            return 1
        if VPS_MODE:
            ok = wait_vps_reload(marker)
            print("servidor da VPS recarregou." if ok else "a VPS nao confirmou o reload.")
        elif os.path.exists(RELOAD_LOG):
            ok = wait_server_reload(marker)
            print("servidor recarregou." if ok else "o servidor nao confirmou o reload.")
        return 0

    if "--spell" in argv:
        alvo = argv[argv.index("--spell") + 1]
        rows = find_rows(catalog, alvo)
        if not rows:
            print("nao achei a magia '%s'" % alvo)
            return 1
        if "--exact" in argv:
            exact = float(argv[argv.index("--exact") + 1].replace(",", "."))
            percent = None
        elif "--set" in argv:
            percent = float(argv[argv.index("--set") + 1].replace(",", ".").replace("%", ""))
            exact = None
        else:
            print("informe --set <porcento> ou --exact <valor>")
            return 1
        for row in rows:
            old, new = preview(row, percent, exact)
            apply_change(row, old, new)
        return 0

    if "--medir" in argv:
        rows = find_rows(catalog, argv[argv.index("--medir") + 1])
        for row in rows:
            measure(row)
        return 0

    interactive(catalog)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
