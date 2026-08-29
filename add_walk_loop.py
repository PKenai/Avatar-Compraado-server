import os

bot_dir = r"C:\Users\imfis\Desktop\BOTS DE TESTE SERVER"
tibia_bot_path = os.path.join(bot_dir, "TibiaBot.cs")

with open(tibia_bot_path, "r", encoding="utf-8") as f:
    bot_code = f.read()

# Replace Task.WhenAll in ConnectAndRunAsync
old_tasks = """            var readTask = ReadLoopAsync(token);
            var chatTask = ChatLoopAsync(token);
            var spellTask = SpellLoopAsync(token);
            var aiTask = AILoopAsync(token);

            await Task.WhenAll(readTask, chatTask, spellTask, aiTask);"""

new_tasks = """            var readTask = ReadLoopAsync(token);
            var chatTask = ChatLoopAsync(token);
            var spellTask = SpellLoopAsync(token);
            var walkTask = WalkLoopAsync(token);
            var aiTask = AILoopAsync(token);

            await Task.WhenAll(readTask, chatTask, spellTask, walkTask, aiTask);"""

walk_loop_code = """        private async Task WalkLoopAsync(CancellationToken token)
        {
            if (!_config.EnableRandomWalk) { await Task.Delay(-1, token); return; }
            await Task.Delay(Random.Shared.Next(1000, 3000), token);

            byte[] directions = { 0x65, 0x66, 0x67, 0x68, 0x6A, 0x6B, 0x6C, 0x6D }; // N, E, S, W, NE, SE, SW, NW
            byte lastDir = directions[Random.Shared.Next(directions.Length)];
            int stepsInSameDir = 0;

            while (!token.IsCancellationRequested)
            {
                int delay = (int)_config.WalkIntervalMs + Random.Shared.Next(-50, 100);
                if (delay < 250) delay = 250;
                await Task.Delay(delay, token);

                if (!_inWorld) continue;

                if (stepsInSameDir > Random.Shared.Next(3, 8) || Random.Shared.Next(100) < 25)
                {
                    lastDir = directions[Random.Shared.Next(directions.Length)];
                    stepsInSameDir = 0;
                }

                stepsInSameDir++;

                var msg = new OutputMessage();
                msg.AddU8(lastDir);
                await SendRawGameMessageInternalAsync(msg, token);
                _metrics.IncWalks();
                LastWalkTime = DateTime.UtcNow;
            }
        }
"""

if old_tasks in bot_code:
    bot_code = bot_code.replace(old_tasks, new_tasks)
    # Add WalkLoopAsync before AILoopAsync
    bot_code = bot_code.replace("private async Task AILoopAsync", walk_loop_code + "\n        private async Task AILoopAsync")
    with open(tibia_bot_path, "w", encoding="utf-8") as f:
        f.write(bot_code)
    print("Added WalkLoopAsync to TibiaBot.cs")
else:
    print("WARNING: old_tasks not found")
