import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"

tibia_bot_path = os.path.join(bot_dir, "TibiaBot.cs")
with open(tibia_bot_path, "r", encoding="utf-8") as f:
    bot_code = f.read()

target_block = """        private async Task SendLoginMessageAsync(CancellationToken token)
        {
            // TFS 8.60 RSA decrypted structure (128 bytes):
            // [XTEA 16 bytes][1 byte GM][string accountName][string characterName][string password][6 bytes zeroes]
            var rsaBytes = new OutputMessage();
            for (int i = 0; i < 4; i++) rsaBytes.AddU32(_xteaKey[i]); // 16 bytes XTEA
            rsaBytes.AddU8(0); // gamemaster flag
            rsaBytes.AddString(_name); // account name
            rsaBytes.AddString(_name); // character name
            rsaBytes.AddString(_password); // password
            rsaBytes.AddBytes(new byte[6]); // 6 bytes padding"""

replacement_block = """        private async Task SendLoginMessageAsync(CancellationToken token)
        {
            // TFS 8.60 RSA decrypted structure (128 bytes):
            // [0x00 first byte][XTEA 16 bytes][1 byte GM][string accountName][string characterName][string password][6 bytes zeroes]
            var rsaBytes = new OutputMessage();
            rsaBytes.AddU8(0); // FIRST BYTE MUST BE 0 FOR RSA_decrypt check
            for (int i = 0; i < 4; i++) rsaBytes.AddU32(_xteaKey[i]); // 16 bytes XTEA
            rsaBytes.AddU8(0); // gamemaster flag
            rsaBytes.AddString(_name); // account name
            rsaBytes.AddString(_name); // character name
            rsaBytes.AddString(_password); // password
            rsaBytes.AddBytes(new byte[6]); // 6 bytes padding"""

if target_block in bot_code:
    bot_code = bot_code.replace(target_block, replacement_block)
    with open(tibia_bot_path, "w", encoding="utf-8") as f:
        f.write(bot_code)
    print("Fixed TibiaBot.cs RSA first byte 0")
else:
    print("WARNING: target_block not found in TibiaBot.cs")
