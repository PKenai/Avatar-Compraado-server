import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"

# 1. Update Rsa.cs
rsa_path = os.path.join(bot_dir, "Network", "Rsa.cs")
rsa_code = """using System;
using System.Numerics;

namespace StressBotBenchmark.Network
{
    public static class Rsa
    {
        private static readonly BigInteger Modulus = BigInteger.Parse("145150651151270466484779919781568812250201875212284230137168501189839458887373507732812873500545439343350792465372778666985818022861514964617895776320631654596449465324099038384692053272779586962267710456835672119883134177743573901310535581143694244349508718386785205908159997953997910264735418591383674696179");
        
        public static byte[] Encrypt(byte[] data)
        {
            if (data.Length != 128)
                throw new ArgumentException("RSA Input data must be exactly 128 bytes.");
                
            byte[] mBytes = new byte[129];
            for(int i = 0; i < 128; i++) 
            {
                mBytes[128 - 1 - i] = data[i]; // Reverse to Little Endian
            }
            mBytes[128] = 0x00; // Sign bit, ensures positive integer
            
            BigInteger m = new BigInteger(mBytes);
            BigInteger c = BigInteger.ModPow(m, 65537, Modulus);
            
            byte[] cBytes = c.ToByteArray();
            byte[] result = new byte[128];
            int count = Math.Min(128, cBytes.Length);
            for(int i = 0; i < count; i++) 
            {
                result[128 - 1 - i] = cBytes[i];
            }
            return result;
        }
    }
}
"""
with open(rsa_path, "w", encoding="utf-8") as f:
    f.write(rsa_code)
print("Updated Rsa.cs")

# 2. Update BotConfig.cs
config_path = os.path.join(bot_dir, "BotConfig.cs")
config_code = """namespace StressBotBenchmark
{
    public class BotConfig
    {
        public string Host { get; set; } = "127.0.0.1";
        public int Port { get; set; } = 9192;
        public bool UseApiLogin { get; set; } = false;
        public string ApiLoginUrl { get; set; } = "http://127.0.0.1:5185/auth/login";
        
        public int BotCount { get; set; } = 30;
        public string Prefix { get; set; } = "stressbot";
        public string Password { get; set; } = "test123";
        public int AccountWidth { get; set; } = 3;
        
        public double LoginDelayMs { get; set; } = 300;
        public int BurstSize { get; set; } = 5;
        public double BurstPauseMs { get; set; } = 500;
        
        public double WalkIntervalMs { get; set; } = 500;
        public double ChatIntervalMs { get; set; } = 8000;
        public double SpellIntervalMs { get; set; } = 4000;
        public double AttackScanIntervalMs { get; set; } = 1000;
        
        public string SpellText { get; set; } = "Flame Spit";
        public bool EnableRandomWalk { get; set; } = true;
        public bool EnableChat { get; set; } = false;
        public bool EnableSpell { get; set; } = true;
        public bool EnableAttack { get; set; } = true;
        public bool EnableChaseMode { get; set; } = true;
        
        public byte FightMode { get; set; } = 1; // 1 = Offensive
        public bool SafeFight { get; set; } = false;
        
        public double DashboardIntervalMs { get; set; } = 2000;
        public bool LoginOnly { get; set; } = false;
        public bool Reconnect { get; set; } = true;
        
        public int QueueSize { get; set; } = 32;
        public int MaxSendLagMsToDrop { get; set; } = 1500;
    }
}
"""
with open(config_path, "w", encoding="utf-8") as f:
    f.write(config_code)
print("Updated BotConfig.cs")

# 3. Update Program.cs
prog_path = os.path.join(bot_dir, "Program.cs")
with open(prog_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(r"C:\Users\imfis\Desktop\SakkenOT\Server\data\items\items.otb", r"c:\Users\imfis\Desktop\Avatar-Compraado-server\data\items\items.otb")
with open(prog_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated Program.cs")

# 4. Update TibiaBot.cs
tibia_bot_path = os.path.join(bot_dir, "TibiaBot.cs")
with open(tibia_bot_path, "r", encoding="utf-8") as f:
    bot_code = f.read()

# Replace ConnectAndRunAsync and SendLoginMessageAsync
old_connect_method = """        private async Task ConnectAndRunAsync(CancellationToken token)
        {
            _client = new TcpClient();
            await _client.ConnectAsync(_config.Host, _config.Port, token);
            _stream = _client.GetStream();
            _inWorld = false; // Reset

            // Server sends: [2-byte size | 4-byte checksum | 0x1F | 4-byte timestamp | 1-byte rand]
            // ReadMessageAsync returns the body (which includes the 4-byte checksum + actual content)
            byte[] challengeMsg = await ReadMessageAsync(token);
            Console.WriteLine($"[Bot {_name}] Challenge Hex: {BitConverter.ToString(challengeMsg)}");
            
            // The body starts with 4 bytes of Adler32 checksum, then opcode 0x1F at byte [4]
            // Skip the 4-byte checksum; opcode 0x1F should be at index 4
            if (challengeMsg.Length < 10)
                throw new Exception($"Challenge too short ({challengeMsg.Length} bytes)");
            
            // Find 0x1F opcode — search from byte 4 (after checksum)
            int opIdx = -1;
            for(int i = 4; i < challengeMsg.Length; i++) {
                if (challengeMsg[i] == 0x1F) { opIdx = i; break; }
            }
            if (opIdx == -1) throw new Exception("Invalid challenge: 0x1F not found after checksum");
            
            uint ts = BitConverter.ToUInt32(challengeMsg, opIdx + 1);
            byte rand = challengeMsg[opIdx + 5];
            Console.WriteLine($"[Bot {_name}] Extracted TS: 0x{ts:X8} ({ts}), Rand: 0x{rand:X2} ({rand})");

            await SendLoginMessageAsync(ts, rand, token);

            var readTask = ReadLoopAsync(token);
            var chatTask = ChatLoopAsync(token);
            var spellTask = SpellLoopAsync(token);
            var aiTask = AILoopAsync(token);

            await Task.WhenAll(readTask, chatTask, spellTask, aiTask);
            _cts?.Cancel();
        }

        private async Task SendLoginMessageAsync(uint ts, byte rand, CancellationToken token)
        {
            // --- Build the 128-byte RSA block ---
            // After RSA_decrypt(), server reads: [0x00][xtea x4][0x00 GM][sessionKey string][charName string][ts u32][rand u8]
            var rsaBytes = new OutputMessage();
            rsaBytes.AddU8(0); // Must be 0 after RSA decryption (Protocol::RSA_decrypt checks this)
            for (int i = 0; i < 4; i++) rsaBytes.AddU32(_xteaKey[i]); // 16 bytes XTEA key
            rsaBytes.AddU8(0); // gamemaster flag (protocolgame.cpp line 379)
            
            // sessionKey = "accountName\\npassword\\ntoken\\ntokenTime" (line 381-401)
            // Token is empty, tokenTime = 0 (accounts without 2FA)
            rsaBytes.AddString($"{_name}\\n{_password}\\n\\n0");
            rsaBytes.AddString(_name); // characterName (line 408)
            rsaBytes.AddU32(ts);       // challengeTimestamp (line 410)
            rsaBytes.AddU8(rand);      // challengeRandom (line 411)
            
            byte[] rawRsa = rsaBytes.GetBuffer();
            if (rawRsa.Length > 128)
                throw new Exception($"RSA payload too large: {rawRsa.Length} bytes (max 128)");
            byte[] paddedRsa = new byte[128];
            Array.Copy(rawRsa, 0, paddedRsa, 0, rawRsa.Length); // data at start, rest is zero-padding
            byte[] encryptedRsa = Rsa.Encrypt(paddedRsa);

            // --- Build the unencrypted game login packet ---
            // Server parsePacket reads the Protocol ID byte (0x0A) first via make_protocol(),
            // THEN calls onRecvFirstMessage(msg) where msg already past the protocol ID.
            // So we must include 0x0A as the FIRST byte of our payload.
            var msg = new OutputMessage();
            msg.AddU8(0x0A);               // Protocol ID — Game protocol (connection.cpp line 203 + 210)
            msg.AddU16(4);                 // OperatingSystem_t = 4 (StressBot)
            msg.AddU16(1098);               // client version
            msg.AddBytes(new byte[7]);      // 7 skip bytes: U32 clientVersion, U8 clientType, U16 datRevision
            msg.AddBytes(encryptedRsa);     // 128-byte RSA block

            byte[] payload = msg.GetBuffer();
            uint checksum = Adler32(payload);

            // Wire format: [2-byte totalSize][4-byte checksum][payload]
            // totalSize = len(checksum) + len(payload) = 4 + payload.Length
            byte[] final = new byte[2 + 4 + payload.Length];
            int totalSize = 4 + payload.Length;
            final[0] = (byte)(totalSize & 0xFF);
            final[1] = (byte)((totalSize >> 8) & 0xFF);
            final[2] = (byte)(checksum & 0xFF);
            final[3] = (byte)((checksum >> 8) & 0xFF);
            final[4] = (byte)((checksum >> 16) & 0xFF);
            final[5] = (byte)((checksum >> 24) & 0xFF);
            Array.Copy(payload, 0, final, 6, payload.Length);

            Console.WriteLine($"[Bot {_name}] Sending login packet ({final.Length} bytes). RSA block size: {rawRsa.Length}");
            await _stream!.WriteAsync(final, token);
        }"""

new_connect_method = """        private async Task ConnectAndRunAsync(CancellationToken token)
        {
            _client = new TcpClient();
            await _client.ConnectAsync(_config.Host, _config.Port, token);
            _stream = _client.GetStream();
            _inWorld = false;

            await SendLoginMessageAsync(token);

            var readTask = ReadLoopAsync(token);
            var chatTask = ChatLoopAsync(token);
            var spellTask = SpellLoopAsync(token);
            var aiTask = AILoopAsync(token);

            await Task.WhenAll(readTask, chatTask, spellTask, aiTask);
            _cts?.Cancel();
        }

        private async Task SendLoginMessageAsync(CancellationToken token)
        {
            // TFS 8.60 RSA decrypted structure (128 bytes):
            // [XTEA 16 bytes][1 byte GM][string accountName][string characterName][string password][6 bytes zeroes]
            var rsaBytes = new OutputMessage();
            for (int i = 0; i < 4; i++) rsaBytes.AddU32(_xteaKey[i]); // 16 bytes XTEA
            rsaBytes.AddU8(0); // gamemaster flag
            rsaBytes.AddString(_name); // account name
            rsaBytes.AddString(_name); // character name
            rsaBytes.AddString(_password); // password
            rsaBytes.AddBytes(new byte[6]); // 6 bytes padding
            
            byte[] rawRsa = rsaBytes.GetBuffer();
            if (rawRsa.Length > 128)
                throw new Exception($"RSA payload too large: {rawRsa.Length} bytes (max 128)");
            byte[] paddedRsa = new byte[128];
            Array.Copy(rawRsa, 0, paddedRsa, 0, rawRsa.Length);
            byte[] encryptedRsa = Rsa.Encrypt(paddedRsa);

            // TFS 8.60 Login Packet structure:
            // [0x0A protocol id][2 bytes OS = 2][2 bytes version = 860][128 bytes encrypted RSA]
            var msg = new OutputMessage();
            msg.AddU8(0x0A);               // Protocol ID
            msg.AddU16(2);                  // OS: 2 = Windows
            msg.AddU16(860);                // Client Version = 860
            msg.AddBytes(encryptedRsa);     // 128-byte RSA block

            byte[] payload = msg.GetBuffer();
            uint checksum = Adler32(payload);

            byte[] final = new byte[2 + 4 + payload.Length];
            int totalSize = 4 + payload.Length;
            final[0] = (byte)(totalSize & 0xFF);
            final[1] = (byte)((totalSize >> 8) & 0xFF);
            final[2] = (byte)(checksum & 0xFF);
            final[3] = (byte)((checksum >> 8) & 0xFF);
            final[4] = (byte)((checksum >> 16) & 0xFF);
            final[5] = (byte)((checksum >> 24) & 0xFF);
            Array.Copy(payload, 0, final, 6, payload.Length);

            Console.WriteLine($"[Bot {_name}] Sending 8.60 game login packet ({final.Length} bytes)...");
            await _stream!.WriteAsync(final, token);
        }"""

if old_connect_method in bot_code:
    bot_code = bot_code.replace(old_connect_method, new_connect_method)
    with open(tibia_bot_path, "w", encoding="utf-8") as f:
        f.write(bot_code)
    print("Updated TibiaBot.cs")
else:
    print("WARNING: Could not find exact old_connect_method block in TibiaBot.cs")
