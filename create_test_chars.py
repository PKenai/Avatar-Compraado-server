# -*- coding: utf-8 -*-
"""
Cria os 4 personagens de teste (level 150, estatisticas IDENTICAS entre si)
no banco MySQL do servidor Avatar, mais a conta "teste"/"teste".

Build usado (igual nos 4):
  - Level 150, exp = expForLevel(150) = 54.042.300 (0% de progresso)
  - Vida:   110 + 150*30 + 30 atributos*50 = 6110   (healthvalue = 30)
  - Mana:   95  + 150*5  + 8  atributos*20 = 1005   (speedvalue  = 8)
  - Mag level: 20 (bend de status, bendvalue = 20; sem bend de treino)
  - Dodge:  10% (getPointsInDodge = 10)
  - Skills: todas 10, soul 100, stamina 2520 (42h), cap 4125
  - Pontos: gastos 130 (52 vida + 40 mana + 21 bend + 17 dodge) + saldo 19
    por elemento = 149 pontos (level-1), consistente com o check do login.
  - Itens: mochila (1987) + 100 gold dentro.

STORAGES por personagem: iguais para todos, exceto o saldo elementar
("getPoints<elemento>" = 19), que usa a chave do elemento de cada um.
"""
import hashlib
import time
import mysql.connector

DB = dict(host="127.0.0.1", port=3306, user="root", password="", database="avatar")

ACCOUNT = "teste"
PASSWORD = "teste"

LEVEL = 150
EXP = 54042300  # (50*149^3 - 150*149^2 + 400*149) / 3

# Build de atributos
HEALTH_ATTR = 30
MANA_ATTR = 8
BEND_ATTR = 20
DODGE_ATTR = 10
BALANCE = 19  # saldo por elemento

HEALTH_MAX = 110 + LEVEL * 30 + HEALTH_ATTR * 50   # 6110
MANA_MAX = 95 + LEVEL * 5 + MANA_ATTR * 20         # 1005
MAG_LEVEL = BEND_ATTR                              # 20

CHARS = [
    ("Teste fogo", 1, "fire"),
    ("Teste agua", 2, "water"),
    ("Teste ar", 3, "air"),
    ("Teste terra", 4, "earth"),
]

PLAYER_COLS = (
    "name, world_id, group_id, account_id, level, vocation, health, healthmax, "
    "experience, lookbody, lookfeet, lookhead, looklegs, looktype, lookaddons, "
    "lookmount, maglevel, mana, manamax, manaspent, soul, town_id, posx, posy, "
    "posz, conditions, cap, sex, lastlogin, lastip, save, skull, skulltime, "
    "rank_id, guildnick, lastlogout, blessings, pvp_blessing, balance, stamina, "
    "skill_fist, skill_fist_tries, skill_club, skill_club_tries, skill_sword, "
    "skill_sword_tries, skill_axe, skill_axe_tries, skill_dist, skill_dist_tries, "
    "skill_shielding, skill_shielding_tries, skill_fishing, skill_fishing_tries, "
    "direction, loss_experience, loss_mana, loss_skills, loss_containers, "
    "loss_items, premend, online, onlinetime, marriage, promotion, deleted, "
    "description, auction_balance, broadcasting, cast, castDescription, "
    "castViewers, comment, created, fragTime, hide_char, ip, nick_verify, "
    "offlinetraining_skill, offlinetraining_time, old_name, questpromotion, "
    "rep, resets, show_bars, show_eq, show_outfit, show_quests, show_skills, "
    "stars, timeOnline, viewers, worldtransfer, deletion"
)


def player_values(name, account_id, voc):
    return (
        # name, world_id, group_id, account_id, level, vocation
        name, 0, 1, account_id, LEVEL, voc,
        # health, healthmax, experience
        HEALTH_MAX, HEALTH_MAX, EXP,
        # lookbody, lookfeet, lookhead, looklegs, looktype, lookaddons, lookmount
        114, 0, 115, 68, 1020, 0, 0,
        # maglevel, mana, manamax, manaspent
        MAG_LEVEL, MANA_MAX, MANA_MAX, 0,
        # soul, town_id, posx, posy, posz, conditions
        100, 1, 514, 358, 7, "",
        # cap, sex, lastlogin, lastip, save
        4125, 1, 0, 0, 1,
        # skull, skulltime, rank_id, guildnick, lastlogout
        0, 0, 0, "", 0,
        # blessings, pvp_blessing, balance, stamina
        0, 0, 0, 2520,
        # 7 skills + tries
        10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0,
        # direction, loss_*
        2, 60, 100, 100, 100, 0,
        # premend, online, onlinetime, marriage, promotion, deleted
        0, 0, 0, 0, 0, 0,
        # description, auction_balance, broadcasting, cast, castDescription,
        # castViewers, comment
        "", 0, 0, 0, "", 0, "",
        # created, fragTime, hide_char, ip, nick_verify
        0, 0, 0, "0", 0,
        # offlinetraining_skill, offlinetraining_time, old_name
        -1, 43200, "",
        # questpromotion, rep, resets
        0, 0, 0,
        # show_*
        1, 1, 1, 1, 1,
        # stars, timeOnline, viewers, worldtransfer, deletion
        1, 0, 0, 0, 0,
    )


def storage_map(element):
    now = int(time.time())
    base = {
        "10001501": 65539, "42001": 1, "188100": LEVEL,
        "9740": now, "9741": 8, "9999": now, "1150001": now, "timeLogin": now,
        "startedWithMana": 1, "playerHasGetInitialItens": 1,
        "isAvatar": 0, "lastGlobalSaveLogin": 6, "getPlayerLang": "isEnglish",
        "autolootdesativo": 1, "morreuD": -1, "playerOnAir": -1,
        "playerWithBless": -1, "entroumontado": -1, "antiloop": -1,
        "getAwnserAntiBot": -1, "bombermanInQueue": -1, "expBeforeDie": -1,
        "firstPendentes": 1, "pendentes": 0, "hasResetedBug2": 1,
        "getTurnMsgPoints": 1, "playerCanMoveDirection": 0,
        "getPointsInDodge": DODGE_ATTR, "healthvalue": HEALTH_ATTR,
        "speedvalue": MANA_ATTR, "bendvalue": BEND_ATTR,
        "getPointsInHealth": HEALTH_ATTR * 20,
        "getPointsInMana": MANA_ATTR * 5,
        "getPointsInBendLevel": BEND_ATTR,
        "knockoutOldLevel": LEVEL, "pvpLevelMessage": 1,
        "onMoveFlyPosX": 514, "onMoveFlyPosY": 358, "onMoveFlyPosZ": 7,
        "getPoints" + element: BALANCE,
    }
    for i in range(9701, 9732):
        base[str(i)] = 0
    return base


def main():
    cnx = mysql.connector.connect(**DB)
    cur = cnx.cursor()
    try:
        # --- Conta ---
        cur.execute("SELECT id FROM accounts WHERE name = %s", (ACCOUNT,))
        row = cur.fetchone()
        if row:
            account_id = row[0]
            print("Conta '%s' ja existia (id %d)" % (ACCOUNT, account_id))
        else:
            pw = hashlib.sha1(PASSWORD.encode()).hexdigest()
            cur.execute(
                "INSERT INTO accounts (name, password, type, premdays) VALUES (%s, %s, 1, 65535)",
                (ACCOUNT, pw),
            )
            account_id = cur.lastrowid
            print("Conta '%s' criada (id %d, senha '%s')" % (ACCOUNT, account_id, PASSWORD))

        # --- Personagens ---
        for name, voc, element in CHARS:
            cur.execute(
                "SELECT id FROM players WHERE name = %s AND deleted = 0", (name,)
            )
            existing = cur.fetchone()
            if existing:
                print("JA EXISTE (pulado): %s (id %d)" % (name, existing[0]))
                continue

            values = player_values(name, account_id, voc)
            placeholders = ", ".join(["%s"] * len(values))
            cur.execute(
                "INSERT INTO players (%s) VALUES (%s)" % (PLAYER_COLS, placeholders),
                values,
            )
            pid = cur.lastrowid

            # storages
            st = storage_map(element)
            for key, value in st.items():
                cur.execute(
                    "INSERT INTO player_storage (player_id, `key`, `value`) VALUES (%s, %s, %s)",
                    (pid, key, str(value)),
                )

            # itens: mochila (slot 3) + 100 gold dentro
            cur.execute(
                "INSERT INTO player_items (player_id, pid, sid, itemtype, count, attributes) VALUES (%s, 3, 101, 1987, 1, '')",
                (pid,),
            )
            cur.execute(
                "INSERT INTO player_items (player_id, pid, sid, itemtype, count, attributes) VALUES (%s, 101, 102, 2148, 100, %s)",
                (pid, bytes([0x0F, 100])),
            )

            print("CRIADO: %s (id %d, voc %d, level %d, hp %d, mana %d, ml %d)"
                  % (name, pid, voc, LEVEL, HEALTH_MAX, MANA_MAX, MAG_LEVEL))

        cnx.commit()
        print("\nOK - commit realizado")
    finally:
        cur.close()
        cnx.close()


if __name__ == "__main__":
    main()
