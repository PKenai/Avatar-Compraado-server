-- Farm System: Cria a tabela no banco de dados ao inicializar o servidor.
function onStartup()
    db.query([[
        CREATE TABLE IF NOT EXISTS `player_creature_manager` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player_id` INT NOT NULL,
            `creature_name` VARCHAR(255) NOT NULL,
            `custom_name` VARCHAR(255) NOT NULL,
            `stage` INT NOT NULL DEFAULT 1,
            `last_train` BIGINT NOT NULL DEFAULT 0,
            FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
        );
    ]])
    print("[FarmSystem] Tabela player_creature_manager verificada/criada com sucesso.")
    return true
end
