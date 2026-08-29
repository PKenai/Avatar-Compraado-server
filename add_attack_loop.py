import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"
tibia_bot_path = os.path.join(bot_dir, "TibiaBot.cs")

with open(tibia_bot_path, "r", encoding="utf-8") as f:
    bot_code = f.read()

# 1. Update monster ID range in heuristic scanner
bot_code = bot_code.replace("val >= 0x40000000 && val <= 0x401FFFFF", "val >= 0x40000001 && val <= 0x7FFFFFFF")

# 2. Update Task.WhenAll in ConnectAndRunAsync
old_tasks = """            var readTask = ReadLoopAsync(token);
            var chatTask = ChatLoopAsync(token);
            var spellTask = SpellLoopAsync(token);
            var walkTask = WalkLoopAsync(token);
            var aiTask = AILoopAsync(token);

            await Task.WhenAll(readTask, chatTask, spellTask, walkTask, aiTask);"""

new_tasks = """            var readTask = ReadLoopAsync(token);
            var chatTask = ChatLoopAsync(token);
            var spellTask = SpellLoopAsync(token);
            var walkTask = WalkLoopAsync(token);
            var attackTask = AttackLoopAsync(token);
            var aiTask = AILoopAsync(token);

            await Task.WhenAll(readTask, chatTask, spellTask, walkTask, attackTask, aiTask);"""

attack_loop_code = """        private uint _currentTargetId = 0;
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
        }
"""

if old_tasks in bot_code:
    bot_code = bot_code.replace(old_tasks, new_tasks)
    bot_code = bot_code.replace("private async Task WalkLoopAsync", attack_loop_code + "\n        private async Task WalkLoopAsync")
    with open(tibia_bot_path, "w", encoding="utf-8") as f:
        f.write(bot_code)
    print("Added AttackLoopAsync and updated monster detection in TibiaBot.cs")
else:
    print("WARNING: old_tasks not found in TibiaBot.cs")
