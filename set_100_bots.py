import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"
config_path = os.path.join(bot_dir, "BotConfig.cs")

with open(config_path, "r", encoding="utf-8") as f:
    code = f.read()

code = code.replace("public int BotCount { get; set; } = 30;", "public int BotCount { get; set; } = 100;")
with open(config_path, "w", encoding="utf-8") as f:
    f.write(code)

print("Updated default BotCount to 100")
