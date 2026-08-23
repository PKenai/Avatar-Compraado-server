-- Buff registration for game_buffs system
-- This file registers all buff types that can be used by the server
-- Buff IDs must match the enum in src/buff.h

-- registerBuffType(id, name, description, icon, border, stacked, maxStacks, ticks, isDebuff)

-- Example buff (id = 1)
registerBuffType(1, "Example Buff", "This is an example buff", "buff_cosmic_insight", "frame-2-gold", false, 1, -1, false)

-- Haste (id = 2) - 33 seconds
registerBuffType(2, "Haste", "You can run more faster", "utani_hur", "frame-6-sky", false, 1, 33000, false)

-- Strong Haste (id = 3) - 22 seconds
registerBuffType(3, "Strong Haste", "You can run more faster", "utani_gran_hur", "frame-2-gold", false, 1, 22000, false)

-- Magic Shield (id = 4) - 200 seconds
registerBuffType(4, "Magic Shield", "You are protected by a magic shield", "utamo_vita", "frame-2-gold", false, 1, 200000, false)

-- Swift Foot (id = 5) - 10 seconds
registerBuffType(5, "Swift Foot", "You are hasted", "utamo_tempo_san", "frame-2-gold", false, 1, 10000, false)

-- Recovery (id = 6) - 3 seconds
registerBuffType(6, "Recovery", "You are healing", "utura", "frame-2-gold", false, 1, 3000, false)

-- Protector (id = 7) - 13 seconds
registerBuffType(7, "Protector", "You are shielded", "utamo_tempo", "frame-2-gold", false, 1, 13000, false)

-- Invisible (id = 8) - 200 seconds
registerBuffType(8, "Invisible", "No one can see you", "utana_vid", "frame-2-gold", false, 1, 200000, false)

-- Intense Recovery (id = 9) - 3 seconds
registerBuffType(9, "Intense Recovery", "You are healing", "utura_gran", "frame-2-gold", false, 1, 3000, false)

-- Charge (id = 10) - 5 seconds
registerBuffType(10, "Charge", "You are hasted", "utani_tempo_hur", "frame-2-gold", false, 1, 5000, false)

-- Experience Scroll (id = 11) - persistent, managed via storage 'hasExpScroll'
registerBuffType(11, "Exp Scroll", "+50% experience", "exp_scroll", "frame-2-magenta", false, 1, -1, false, true)

-- Example Debuff (id = 12)
registerBuffType(12, "Slow", "You are slowed down", "debuff_slow", "frame-9-red", false, 1, 10000, true)
