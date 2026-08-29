import hashlib

accounts_sql = []
players_sql = []

for i in range(1, 301):
    name = f"stressbot{i:03d}"
    pwd_sha = hashlib.sha1("test123".encode()).hexdigest()
    accounts_sql.append(f"('{name}', '{pwd_sha}', 1)")
    players_sql.append(f"('{name}', 1, (SELECT id FROM accounts WHERE name = '{name}'), 150, 1, 1500, 1500, 4200, 136, 50, 1500, 1500, 100, 1, 505, 342, 7, 400, '')")

with open(r"c:\Users\imfis\Desktop\Avatar-Compraado-server\insert_300_stressbots_avatar.sql", "w") as f:
    f.write("USE avatar;\nSTART TRANSACTION;\n")
    f.write("INSERT IGNORE INTO accounts (name, password, type) VALUES\n" + ",\n".join(accounts_sql) + ";\n")
    f.write("INSERT IGNORE INTO players (name, group_id, account_id, level, vocation, health, healthmax, experience, looktype, maglevel, mana, manamax, soul, town_id, posx, posy, posz, cap, conditions) VALUES\n" + ",\n".join(players_sql) + ";\n")
    f.write("COMMIT;\n")

print("SQL Generated Successfully!")
