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
            `watered_stage` INT NOT NULL DEFAULT 0,
            FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
        );
    ]])
    -- o CREATE TABLE acima ja inclui `watered_stage`; o ALTER so e necessario
    -- para bancos criados antes dessa coluna existir. Checamos antes de rodar
    -- para o ALTER nunca falhar (e nao imprimir o erro "Duplicate column name"
    -- no console a cada startup).
    local result = db.getResult("SELECT COUNT(*) AS `count` FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'player_creature_manager' AND COLUMN_NAME = 'watered_stage'")
    local hasColumn = false
    if result then
        hasColumn = result:getDataInt("count") > 0
        result:free()
    end
    if not hasColumn then
        db.query("ALTER TABLE `player_creature_manager` ADD COLUMN `watered_stage` INT NOT NULL DEFAULT 0")
    end
    return true
end
