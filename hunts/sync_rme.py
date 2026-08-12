# -*- coding: utf-8 -*-
"""
Sync RME (Remere's Map Editor) com as criaturas Avatar.

O RME monta a aba de monstros "Others" a partir de DOIS arquivos por versao:
  1. <Rmezin>/data/<versao>/creatures.xml          (padrao, so monstros classicos)
  2. %APPDATA%/Remere's Map Editor/data/<versao>/creatures.xml  (do usuario)

Este script:
  - Esvazia o creatures.xml padrao de TODAS as versoes (remove os classicos)
  - No do usuario (todas as versoes que existirem): REMOVE todos os monstros
    e MANTEM os NPCs (aang, appa, etc.)
  - Adiciona um <creature> por monstro existente na pasta
    data/monster/Oficial monsters avatar/  (nome + looktype lidos do XML)

Rode sempre que criar novos monstros com criar_criaturas_avatar.bat
(o proprio gerar_criaturas.py ja chama isso no final).
"""
import os
import re
import glob
import xml.etree.ElementTree as ET

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)
AVATAR_DIR = os.path.join(ROOT, 'data', 'monster', 'Oficial monsters avatar')

RME_DATA = r"C:\Users\imfis\Desktop\Rmezin\data"
APPDATA = os.environ.get('APPDATA', r'C:\Users\imfis\AppData\Roaming')
RME_USER_DATA = os.path.join(APPDATA, "Remere's Map Editor", 'data')


def extrair_monstros_avatar():
    """Retorna [(nome, looktype)] dos XMLs em Oficial monsters avatar/."""
    out = []
    if not os.path.isdir(AVATAR_DIR):
        return out
    for fname in sorted(os.listdir(AVATAR_DIR)):
        if not fname.lower().endswith('.xml'):
            continue
        path = os.path.join(AVATAR_DIR, fname)
        raw = open(path, encoding='utf-8', errors='replace').read()
        m = re.search(r'<monster\s+name="([^"]+)"', raw)
        if not m:
            continue
        nome = m.group(1)
        lk = re.search(r'<look\s+type="(\d+)"', raw)
        out.append((nome, lk.group(1) if lk else '0'))
    return out


def limpar_standard():
    """Esvazia o creatures.xml padrao de todas as versoes do RME."""
    total = 0
    for path in glob.glob(os.path.join(RME_DATA, '*', 'creatures.xml')):
        with open(path, encoding='utf-8', errors='replace') as fh:
            raw = fh.read()
        novo = raw[:raw.find('<creatures')] + '<creatures>\n</creatures>\n'
        with open(path, 'w', encoding='utf-8', newline='') as fh:
            fh.write(novo)
        total += raw.count('<creature')
    print('  standard: %d criaturas removidas de %d pastas de versao'
          % (total, len(glob.glob(os.path.join(RME_DATA, '*', 'creatures.xml')))))


def atualizar_usuarios(avatar):
    """Nos creatures.xml do usuario: remove monstros, mantem NPCs, adiciona os do avatar."""
    for path in glob.glob(os.path.join(RME_USER_DATA, '*', 'creatures.xml')):
        versao = os.path.basename(os.path.dirname(path))
        tree = ET.parse(path)
        root = tree.getroot()

        npcs = []
        removed = 0
        for c in list(root):
            if c.tag != 'creature':
                continue
            if c.get('type') == 'npc':
                npcs.append(c)
            else:
                removed += 1
            root.remove(c)

        linhas = ['<?xml version="1.0"?>', '<creatures>']
        for c in npcs:
            attrs = ' '.join('%s="%s"' % (k, v) for k, v in c.attrib.items())
            linhas.append('\t<creature %s />' % attrs)
        for nome, lk in avatar:
            linhas.append('\t<creature name="%s" type="monster" looktype="%s"/>' % (nome, lk))
        linhas.append('</creatures>')
        with open(path, 'w', encoding='utf-8', newline='') as fh:
            fh.write('\n'.join(linhas) + '\n')
        print('  user %s: %d NPCs mantidos, %d monstros removidos, %d do avatar adicionados'
              % (versao, len(npcs), removed, len(avatar)))


def main():
    avatar = extrair_monstros_avatar()
    print('Sincronizando RME com a pasta Oficial monsters avatar (%d criaturas):' % len(avatar))
    limpar_standard()
    atualizar_usuarios(avatar)
    print('OK. Feche e reabra o RME para ver a aba Others atualizada.')


if __name__ == '__main__':
    main()
