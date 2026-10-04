#!/usr/bin/env python3
"""Diagnostico do cliente Avatar Eclipse: por que nao aparece texto?

Uso:
    python diagnostico_cliente.py "C:\\caminho\\da\\pasta\\do\\cliente"

Confere:
  1. Qual EXE esta na pasta e quais formatos de criptografia ele entende
     (AV03/ENC3 = formato antigo do --encrypt; AVX1 = vault AES-256-GCM novo).
  2. Em que formato estao init.lua, data/fonts, data/locales, modules, mods.
  3. Testa de verdade: decripta um .otfont e diz se o texto do fonte sai legivel.
  4. Procura no log da pasta por "Unable to load font" / "font ... not found".

Se o EXE nao entender o formato dos arquivos, o cliente abre normal mas
nao registra nenhuma fonte -> cai no fonte vazio ("emptyfont") -> NENHUM
texto na tela, sem mensagem de erro.
"""
import hashlib
import os
import struct
import sys
import zlib

MAGICS = {b"AV03": "AV03 (--encrypt antigo)", b"AVX1": "AVX1 (vault AES)", b"ENC3": "ENC3 (legado)"}
EXT_SKIP = (".dll", ".exe", ".zip", ".otmm", ".otml", ".txt", ".log", ".dmp")


# ----------------------------------------------------------------- AV03
def _bdecrypt(buf, k):
    M = 0xFFFFFFFF
    DELTA = 0x9E3779B9
    key = [(k >> 32) & M, k & M, 0xDEADDEAD, 0xB00BEEEF]
    n = len(buf) // 4
    if n < 2:
        return buf
    v = list(struct.unpack("<%dI" % n, buf[: n * 4]))
    rounds = 6 + 52 // n
    s = (rounds * DELTA) & M
    y = v[0]
    for _ in range(rounds):
        e = (s >> 2) & 3
        for p in range(n - 1, 0, -1):
            z = v[p - 1]
            mx = ((((z >> 5) ^ ((y << 2) & M)) + ((y >> 3) ^ ((z << 4) & M)))
                  ^ ((s ^ y) + (key[(p & 3) ^ e] ^ z))) & M
            v[p] = (v[p] - mx) & M
            y = v[p]
        z = v[n - 1]
        mx = ((((z >> 5) ^ ((y << 2) & M)) + ((y >> 3) ^ ((z << 4) & M)))
              ^ ((s ^ y) + (key[e] ^ z))) & M
        v[0] = (v[0] - mx) & M
        y = v[0]
        s = (s - DELTA) & M
    return struct.pack("<%dI" % n, *v) + buf[n * 4:]


def dec_av03(data):
    """Devolve (plaintext, seed) ou levanta excecao."""
    key = struct.unpack_from("<Q", data, 4)[0]
    csz = struct.unpack_from("<I", data, 12)[0]
    size = struct.unpack_from("<I", data, 16)[0]
    adler = struct.unpack_from("<I", data, 20)[0]
    body = data[24:24 + csz]
    if len(body) != csz:
        raise ValueError("AV03 truncado (%d de %d bytes)" % (len(body), csz))
    plain = zlib.decompress(_bdecrypt(body, key))
    if len(plain) != size:
        raise ValueError("tamanho errado")
    seed = adler ^ (zlib.adler32(plain) & 0xFFFFFFFF)
    return plain, seed


# ----------------------------------------------------------------- AVX1
AVX1_LOW = (0xA6923C8889734D11, 0xE019AE493F771F86)
AVX1_HIGH = (0xF844F0D2252CCAAC, 0xF4C42C28FC7F17FA)
AVX1_SALT = 0xC85E6750E737D0CE
_AVX1_KEY = hashlib.sha256(
    struct.pack("<QQ", *AVX1_LOW) + struct.pack("<Q", AVX1_SALT) + struct.pack("<QQ", *AVX1_HIGH)
).digest()


def dec_avx1(data):
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    if len(data) < 44:
        raise ValueError("AVX1 truncado")
    flags = data[4]
    nonce = data[8:20]
    plain_size = struct.unpack_from("<I", data, 20)[0]
    body_size = struct.unpack_from("<I", data, 24)[0]
    tag = data[28:44]
    key = hashlib.sha256(_AVX1_KEY + b"ae.file.key.v1" + nonce).digest()
    dec = Cipher(algorithms.AES(key), modes.GCM(nonce, tag)).decryptor()
    dec.authenticate_additional_data(data[:28])
    plain = dec.update(data[44:]) + dec.finalize()
    if flags & 1:
        plain = zlib.decompress(plain)
    if len(plain) != plain_size or len(data) - 44 != body_size:
        raise ValueError("cabecalho AVX1 inconsistente")
    return plain


def desencrypta(path):
    """Devolve (plaintext, formato). Levanta excecao se nao der."""
    data = open(path, "rb").read()
    magic = data[:4]
    if magic == b"AV03":
        return dec_av03(data)[0], "AV03"
    if magic == b"AVX1":
        return dec_avx1(data), "AVX1"
    raise ValueError("nao e um container conhecido (%r)" % magic)


# ----------------------------------------------------------------- EXE
def analisa_exe(path):
    data = open(path, "rb").read()
    suporta = [name for magic, name in MAGICS.items() if data.find(magic) >= 0]
    vault = data.find(b"ae.file.key.v1") >= 0
    return hashlib.md5(data).hexdigest(), suporta, vault


def conta_formatos(pasta):
    r = {"AV03": 0, "AVX1": 0, "ENC3": 0, "puro": 0, "erro": 0}
    for root, _dirs, files in os.walk(pasta):
        for fn in files:
            try:
                with open(os.path.join(root, fn), "rb") as fh:
                    head = fh.read(4)
            except OSError:
                continue
            if head in (b"AV03", b"AVX1", b"ENC3"):
                r[head.decode()] += 1
            else:
                r["puro"] += 1
    return r


def procura_no_log(pasta):
    achados = []
    for base in [pasta, os.path.join(os.environ.get("APPDATA", ""), "AvatarEclipse")]:
        if not base or not os.path.isdir(base):
            continue
        for root, _d, files in os.walk(base):
            for fn in files:
                if not fn.lower().endswith(".log"):
                    continue
                try:
                    txt = open(os.path.join(root, fn), "r", errors="ignore").read()
                except OSError:
                    continue
                for linha in txt.splitlines():
                    if ("Unable to load font" in linha or "not found" in linha and "font" in linha
                            or "Corrupted asset" in linha or "Unable to run script init.lua" in linha):
                        achados.append("%s: %s" % (os.path.join(root, fn), linha.strip()))
    return achados


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    pasta = os.path.abspath(sys.argv[1])
    print("Pasta do cliente: %s\n" % pasta)

    exes = [f for f in os.listdir(pasta) if f.lower().endswith(".exe")]
    if not exes:
        print("!! Nenhum .exe na pasta.")
    for exe in exes:
        md5, suporta, vault = analisa_exe(os.path.join(pasta, exe))
        print("EXE  %-24s md5=%s" % (exe, md5))
        print("     formatos que entende: %s%s" % (", ".join(suporta) or "NENHUM LEGIVEL",
                                                   "  [traz a chave do vault AVX1]" if vault else ""))

    print("\nFormato dos arquivos:")
    for rel in ["init.lua", "data", "modules", "mods", "layouts"]:
        alvo = os.path.join(pasta, rel)
        if os.path.isfile(alvo):
            head = open(alvo, "rb").read(4)
            print("  %-10s -> %s" % (rel, MAGICS.get(head, "texto puro")))
        elif os.path.isdir(alvo):
            r = conta_formatos(alvo)
            print("  %-10s -> AV03=%d AVX1=%d ENC3=%d puro=%d" %
                  (rel, r["AV03"], r["AVX1"], r["ENC3"], r["puro"]))
        else:
            print("  %-10s -> AUSENTE" % rel)

    faltam_fontes = 0
    fontes = os.path.join(pasta, "data", "fonts")
    if os.path.isdir(fontes):
        otf = sorted(f for f in os.listdir(fontes) if f.endswith(".otfont"))
        pngs = [f for f in os.listdir(fontes) if f.endswith(".png")]
        print("\nFontes: %d .otfont e %d .png" % (len(otf), len(pngs)))
        # testa TODAS as fontes: le (decriptando se for container), valida o OTML
        # e confere se a textura referida existe. Texto puro e' o estado correto.
        import re
        falhas = 0
        for fn in otf:
            plano = os.path.join(fontes, fn)
            bruto = open(plano, "rb").read()
            if bruto[:4] in (b"AV03", b"AVX1", b"ENC3"):
                try:
                    plain, fmt = desencrypta(plano)
                except Exception as exc:  # noqa: BLE001
                    print("  !! %-34s NAO decripta (%s) -> fonte nao carrega" % (fn, exc))
                    falhas += 1
                    continue
            else:
                plain, fmt = bruto, "texto puro"
            if not plain.startswith(b"Font"):
                print("  !! %-34s %s mas nao e' OTML de fonte" % (fn, fmt))
                falhas += 1
                continue
            m = re.search(rb"texture:\s*(.+)$", plain, re.M)
            if m:
                tex = m.group(1).decode("latin-1").strip().rstrip("\r")
                tex_png = tex if tex.lower().endswith(".png") else tex + ".png"
                if not os.path.exists(os.path.join(fontes, tex_png)):
                    print("  !! %-34s aponta para textura AUSENTE: %s" % (fn, tex_png))
                    falhas += 1
        print("  fontes com problema: %d de %d" % (falhas, len(otf)))
        faltam_fontes = falhas
    else:
        print("\n!! data/fonts AUSENTE -> nao existe fonte para desenhar texto.")

    print("\nLog do cliente:")
    achados = procura_no_log(pasta)
    if achados:
        for linha in achados[:20]:
            print("  " + linha)
    else:
        print("  (nada de erros de fonte nos logs)")

    print("\nVEREDITO:")
    if exes:
        md5, suporta, _v = analisa_exe(os.path.join(pasta, exes[0]))
        if not suporta:
            print("  Exe sem suporte a nenhum formato -> ele nunca le os arquivos.")
        else:
            tem = {"AV03": False, "AVX1": False}
            for rel in ["data", "modules", "mods"]:
                alvo = os.path.join(pasta, rel)
                if os.path.isdir(alvo):
                    r = conta_formatos(alvo)
                    for k in ("AV03", "AVX1"):
                        tem[k] = tem[k] or r[k] > 0
            faltando = [f for f in ("AV03", "AVX1") if tem[f] and not any(f in s for s in suporta)]
            if faltando:
                print("  MISMATCH: os arquivos estao em %s e o exe NAO le %s." %
                      ("/".join(faltando), "/".join(faltando)))
                print("  Efeito: decriptacao falha em silencio (seed 0) e as fontes nao")
                print("  carregam -> cliente abre normal, mas SEM NENHUM TEXTO.")
                print("  Solucao: redistribuir exe + arquivos da MESMA versao.")
            elif faltam_fontes:
                print("  O exe le o formato, mas %d fonte(s) falharam acima." % faltam_fontes)
            else:
                print("  Exe e arquivos compativeis. O problema NAO e' de criptografia.")


if __name__ == "__main__":
    main()
