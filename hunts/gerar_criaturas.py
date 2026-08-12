# -*- coding: utf-8 -*-
"""
Gerador de criaturas Avatar.
Le as respostas de respostas_avatar.txt (nome;looktype;arquivo_atual),
cria o monstro em data/monster/Oficial monsters avatar/ usando a VIDA e o
DANO do Tibia GLOBAL e registra no monsters.xml.

- HP: coluna 'vida no global' da lista_criaturas.txt
- Dano: tabela DANO_GLOBAL (melee max, aproximado)
- XP por kill = exp_hora / KILLS_PER_HOUR   (ajuste KILLS_PER_HOUR se quiser)
- Loot de gold = gold_hora / KILLS_PER_HOUR por kill (em media)
"""
import os, re, sys

KILLS_PER_HOUR = 40

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)
MONSTER_DIR = os.path.join(ROOT, 'data', 'monster')
OUT_DIR = os.path.join(MONSTER_DIR, 'Oficial monsters avatar')
MONSTERS_XML = os.path.join(MONSTER_DIR, 'monsters.xml')
RESP_FILE = os.path.join(SCRIPT_DIR, 'respostas_avatar.txt')
LISTA_FILE = os.path.join(SCRIPT_DIR, 'lista_criaturas.txt')

# dano melee (max, aproximado) do Tibia GLOBAL por arquivo atual
DANO_GLOBAL = {
    'clawed rotworm.xml': 12, 'larva.xml': 10, 'swamp troll.xml': 19,
    'crocodile.xml': 30, 'tarantula.xml': 30, 'elf.xml': 25,
    'minotaur.xml': 15, 'stone golem.xml': 35, 'mutated human.xml': 80,
    'goblin scavenger.xml': 20, 'zombie.xml': 40, 'ancient scarab.xml': 45,
    'pirate buccaneer.xml': 30, 'blood crab.xml': 35, 'draptor.xml': 90,
    'crystal spider.xml': 120, 'haunted treeling.xml': 50, 'bonebeast.xml': 75,
    'dragon.xml': 150, 'mutated rat.xml': 60, 'bog raider.xml': 90,
    'wyrm.xml': 120, 'swarmer.xml': 25, 'giant spider.xml': 110,
    'acolyte of the cult.xml': 40, 'nightmare scion.xml': 65, 'hero.xml': 180,
    'dragon lord.xml': 260, 'vampire.xml': 80, 'sea serpent.xml': 190,
    'hydra.xml': 320, 'orc warlord.xml': 90, 'lizard chosen.xml': 160,
    'elder wyrm.xml': 420, 'werewolf.xml': 130, 'deepling scout.xml': 110,
    'grim reaper.xml': 300, 'seacrest serpent.xml': 260, 'draken elite.xml': 280,
    'medusa.xml': 250, 'diremaw.xml': 300, 'fury.xml': 220,
    'askarak demon.xml': 260, 'spectre.xml': 320, 'thornback tortoise.xml': 30,
    'nightmare.xml': 180,
}


def ler_dados_lista(arquivo):
    """retorna {hp, xp_hora, gold_hora} da linha do arquivo na lista do guia"""
    alvo = arquivo.lower()
    with open(LISTA_FILE, encoding='utf-8', errors='replace') as fh:
        for linha in fh:
            p = linha.strip().split(';')
            if len(p) >= 6 and p[2].strip().lower() == alvo:    return {
        'hp': int(p[3] or 0),
        'xp_hora': int(p[4] or 0),
        'gold_range': p[5].strip() or '0-0',
    }
    return {'hp': 100, 'xp_hora': 0, 'gold_range': '0-0'}


def ler_respostas():
    """retorna lista de (nome, looktype, arquivo_atual)"""
    if not os.path.exists(RESP_FILE):
        return []
    out = []
    with open(RESP_FILE, encoding='utf-8-sig', errors='replace') as fh:
        for linha in fh:
            linha = linha.strip()
            if not linha:
                continue
            partes = linha.split(';')
            if len(partes) < 3:
                continue
            nome, lk, arquivo = partes[0].strip(), partes[1].strip(), partes[2].strip()
            if nome:
                out.append((nome, lk, arquivo))
    return out


def ler_info_atual(arquivo):
    """speed, corpse, look, race, xp do arquivo atual (se existir)"""
    p = os.path.join(MONSTER_DIR, arquivo)
    if not os.path.exists(p):
        return None
    raw = open(p, encoding='utf-8', errors='replace').read()

    def g(pat):
        m = re.search(pat, raw)
        return m.group(1) if m else None

    return {
        'speed': g(r'speed="(\d+)"'),
        'corpse': g(r'corpse="(\d+)"'),
        'look': g(r'<look\s+type="(\d+)"'),
        'race': g(r'race="(\w+)"'),
        'xp': int(g(r'experience="(\d+)"') or 0),
    }


def gold_loot(gold_range):
    """loot de moedas POR KILL no estilo classico (faixa por nivel, customs).
    Ex.: '0-15' -> 1..15 gold | '25-50' -> 1..50 gold | '75-100' -> 1..100 gold |
    '1000-2500' -> 1..25 platinum | '10000-50000' -> 1..5 crystal (=1kk/h no lvl 250).
    O motor dropa 1..countmax (nao existe minimo no xml; chance=100000 = sempre).
    Moeda pela faixa maxima: <=1000 gp gold, <=10000 gp platinum, acima crystal.
    Valores: gold (2148)=1 | platinum (2152)=100 | crystal (2160)=10.000 gp."""
    try:
        mx = int(str(gold_range).split('-')[-1].strip())
    except (ValueError, IndexError):
        return []
    if mx <= 0:
        return []
    if mx <= 1000:                     # gold coin
        return [(2148, mx)]
    if mx <= 10000:                    # platinum
        return [(2152, max(1, mx // 100))]
    return [(2160, max(1, mx // 10000))]  # crystal


def sanitizar(nome):
    nome = re.sub(r'[\\/:*?"<>|]', '_', nome).strip()
    return nome or 'criatura'


def artigo(nome):
    return 'an' if nome[:1].lower() in 'aeiou' else 'a'


def gerar_xml(nome, looktype, info, hp, dmg, xp, gold_range):
    look = looktype or info['look'] or '0'
    race = info['race'] or 'blood'
    speed = info['speed'] or '120'
    corpo = info['corpse'] or '0'
    desc = artigo(nome) + ' ' + nome.lower()

    loot = ''
    for iid, c in gold_loot(gold_range):
        loot += '\t\t<item id="%d" countmax="%d" chance="100000"/><!-- moedas -->\n' % (iid, c)
    if not loot:
        loot = '\t\t<!-- sem loot (faixa 0-0 no guia) -->\n'

    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<monster name="%s" nameDescription="%s" race="%s" experience="%d" speed="%s" manacost="0">\n'
            '\t<health now="%d" max="%d"/>\n'
            '\t<look type="%s" corpse="%s"/>\n'
            '\t<targetchange interval="5000" chance="10"/>\n'
            '\t<strategy attack="100" defense="0"/>\n'
            '\t<flags>\n'
            '\t\t<flag summonable="0"/>\n'
            '\t\t<flag attackable="1"/>\n'
            '\t\t<flag hostile="1"/>\n'
            '\t\t<flag illusionable="0"/>\n'
            '\t\t<flag convinceable="0"/>\n'
            '\t\t<flag pushable="1"/>\n'
            '\t\t<flag canpushitems="1"/>\n'
            '\t\t<flag canpushcreatures="0"/>\n'
            '\t\t<flag targetdistance="1"/>\n'
            '\t\t<flag staticattack="90"/>\n'
            '\t\t<flag runonhealth="0"/>\n'
            '\t</flags>\n'
            '\t<attacks>\n'
            '\t\t<attack name="melee" interval="2000" skill="30" attack="%d"/>\n'
            '\t</attacks>\n'
            '\t<defenses armor="0" defense="0"/>\n'
            '\t<loot>\n%s'
            '\t</loot>\n'
            '</monster>\n') % (nome, desc, race, xp, speed, hp, hp, look, corpo, dmg, loot)


def registrar_no_monsters_xml(nome, arquivo):
    text = open(MONSTERS_XML, encoding='utf-8', errors='replace').read()
    if re.search(r'<monster\s+name="%s"\s' % re.escape(nome), text, re.IGNORECASE):
        return False
    linha = '\t<monster name="%s" file="Oficial monsters avatar/%s"/>\r\n' % (nome, arquivo)
    novo = text.replace('</monsters>', linha + '</monsters>')
    open(MONSTERS_XML, 'w', encoding='utf-8', newline='').write(novo)
    return True


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    respostas = ler_respostas()
    if not respostas:
        print('Nenhuma resposta em respostas_avatar.txt ainda.')
        print('Rode criar_criaturas_avatar.bat e responda as perguntas.')
        return

    print('%-32s %-6s %-5s %-8s %-8s %s' % ('NOVA CRIATURA', 'HP', 'DMG', 'XP/kill', 'GOLD/kill', 'ARQUIVO'))
    print('-' * 95)
    criadas = registradas = 0
    for nome, lk, arquivo in respostas:
        info = ler_info_atual(arquivo)
        if info is None:
            print('!! arquivo atual nao encontrado: %s (pulando %s)' % (arquivo, nome))
            continue
        dados = ler_dados_lista(arquivo)
        hp = dados['hp'] or 100
        dmg = DANO_GLOBAL.get(arquivo.lower(), 40)
        xp = max(1, dados['xp_hora'] // KILLS_PER_HOUR) if dados['xp_hora'] > 0 else info['xp']

        fname = sanitizar(nome) + '.xml'
        destino = os.path.join(OUT_DIR, fname)
        if os.path.exists(destino):
            print('%-32s ja existe (pulando)' % nome)
            continue

        xml = gerar_xml(nome, lk, info, hp, dmg, xp, dados['gold_range'])
        with open(destino, 'w', encoding='utf-8', newline='') as fh:
            fh.write(xml)
        criadas += 1

        if registrar_no_monsters_xml(nome, fname):
            registradas += 1

        print('%-32s %-6s %-5s %-8s %-8s %s' % (nome, hp, dmg, xp, dados['gold_range'] or '-', fname))
        if dados['xp_hora'] > 0 and info['xp']:
            print('   (XP do arquivo atual: %s -> novo: %s)' % (info['xp'], xp))

    print('-' * 95)
    print('Criadas: %d | Registradas no monsters.xml: %d' % (criadas, registradas))
    print('Pasta: data/monster/Oficial monsters avatar/')
    print('HP e dano seguem o Tibia global; XP segue o guia (%d kills/hora).' % KILLS_PER_HOUR)
    print('Gold segue a faixa por kill da lista (ex.: 0-15, 25-50, 75-100).')
    print('Ajuste depois criatura a criatura.')
    print()

    # Sincroniza o RME (aba Others) com as novas criaturas
    try:
        sys.path.insert(0, SCRIPT_DIR)
        import sync_rme
        print()
        sync_rme.main()
    except Exception as e:
        print('\n!! Falha ao sincronizar o RME: %s' % e)
        print('   Rode manualmente: python hunts/sync_rme.py')


if __name__ == '__main__':
    main()
