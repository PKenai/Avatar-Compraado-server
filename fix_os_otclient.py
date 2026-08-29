import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"
tibia_bot_path = os.path.join(bot_dir, "TibiaBot.cs")

with open(tibia_bot_path, "r", encoding="utf-8") as f:
    bot_code = f.read()

target = "msg.AddU16(2);                  // OS: 2 = Windows"
replacement = "msg.AddU16(11);                 // OS: 11 = CLIENTOS_OTCLIENT_WINDOWS"

if target in bot_code:
    bot_code = bot_code.replace(target, replacement)
    with open(tibia_bot_path, "w", encoding="utf-8") as f:
        f.write(bot_code)
    print("Updated OperatingSystem to OTClient Windows (11)")
else:
    print("WARNING: target not found")
