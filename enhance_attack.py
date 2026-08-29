import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"
tibia_bot_path = os.path.join(bot_dir, "TibiaBot.cs")

with open(tibia_bot_path, "r", encoding="utf-8") as f:
    bot_code = f.read()

# Replace AttackLoopAsync to send both Attack (0xA1) and Follow (0xA2) + Chase Mode (0xA0)
old_attack_loop = """        private uint _currentTargetId = 0;
        private DateTime _lastTargetChange = DateTime.MinValue;

        private async Task AttackLoopAsync(CancellationToken token)
        {
            if (!_config.EnableAttack) { await Task.Delay(-1, token); return; }
            await Task.Delay(Random.Shared.Next(1500, 3500), token);

            while (!token.IsCancellationRequested)
            {
                await Task.Delay((int)_config.AttackScanIntervalMs + Random.Shared.Next(-100, 100), token);
                if (!_inWorld) continue;

                uint targetId = 0;
                lock (_monsterLock)
                {
                    if (_recentMonsters.Count > 0)
                    {
                        if (_currentTargetId == 0 || (DateTime.UtcNow - _lastTargetChange).TotalSeconds > 6)
                        {
                            targetId = _recentMonsters[Random.Shared.Next(_recentMonsters.Count)];
                            _currentTargetId = targetId;
                            _lastTargetChange = DateTime.UtcNow;
                        }
                        else
                        {
                            targetId = _currentTargetId;
                        }
                    }
                }

                if (targetId != 0)
                {
                    // Set fight modes: 1 = Offensive, 1 = Chase/Follow, 0 = Safe fight off
                    var modeMsg = new OutputMessage();
                    modeMsg.AddU8(0xA0); // Set Fight Modes
                    modeMsg.AddU8(1);    // Offensive
                    modeMsg.AddU8(1);    // Chase Mode
                    modeMsg.AddU8(0);    // Safe Fight Off
                    await SendRawGameMessageInternalAsync(modeMsg, token);

                    // Attack creature
                    var atkMsg = new OutputMessage();
                    atkMsg.AddU8(0xA1); // Attack
                    atkMsg.AddU32(targetId);
                    await SendRawGameMessageInternalAsync(atkMsg, token);

                    _metrics.IncAttacks();
                    LastAttackTime = DateTime.UtcNow;
                }
            }
        }"""

new_attack_loop = """        private uint _currentTargetId = 0;
        private DateTime _lastTargetChange = DateTime.MinValue;

        private async Task AttackLoopAsync(CancellationToken token)
        {
            if (!_config.EnableAttack) { await Task.Delay(-1, token); return; }
            await Task.Delay(Random.Shared.Next(1000, 2500), token);

            while (!token.IsCancellationRequested)
            {
                await Task.Delay(Math.Max(300, (int)_config.AttackScanIntervalMs), token);
                if (!_inWorld) continue;

                uint targetId = 0;
                lock (_monsterLock)
                {
                    if (_recentMonsters.Count > 0)
                    {
                        if (_currentTargetId == 0 || (DateTime.UtcNow - _lastTargetChange).TotalSeconds > 8)
                        {
                            targetId = _recentMonsters[_recentMonsters.Count - 1]; // Pick latest seen monster
                            _currentTargetId = targetId;
                            _lastTargetChange = DateTime.UtcNow;
                        }
                        else
                        {
                            targetId = _currentTargetId;
                        }
                    }
                }

                if (targetId != 0)
                {
                    // 1. Set Fight Modes (0xA0): 1 = Offensive, 1 = Chase/Follow, 0 = Safe Fight Off
                    var modeMsg = new OutputMessage();
                    modeMsg.AddU8(0xA0);
                    modeMsg.AddU8(1); // Offensive
                    modeMsg.AddU8(1); // Chase Mode
                    modeMsg.AddU8(0); // Safe Fight Off
                    await SendRawGameMessageInternalAsync(modeMsg, token);

                    // 2. Attack Creature (0xA1)
                    var atkMsg = new OutputMessage();
                    atkMsg.AddU8(0xA1);
                    atkMsg.AddU32(targetId);
                    await SendRawGameMessageInternalAsync(atkMsg, token);

                    // 3. Follow Creature (0xA2) - Server-side pathfinding to chase monster
                    var folMsg = new OutputMessage();
                    folMsg.AddU8(0xA2);
                    folMsg.AddU32(targetId);
                    await SendRawGameMessageInternalAsync(folMsg, token);

                    _metrics.IncAttacks();
                    LastAttackTime = DateTime.UtcNow;
                }
            }
        }"""

if old_attack_loop in bot_code:
    bot_code = bot_code.replace(old_attack_loop, new_attack_loop)
    with open(tibia_bot_path, "w", encoding="utf-8") as f:
        f.write(bot_code)
    print("Enhanced AttackLoopAsync with Follow (0xA2) and latest monster target selection")
else:
    print("WARNING: old_attack_loop not matched")
