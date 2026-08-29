-- !setshader [nome|list|off]
-- Sem parametro: aplica um shader aleatorio no outfit do player.
-- !setshader list: lista todos os shaders disponiveis.
-- !setshader off: remove o shader.

local AVAILABLE_SHADERS = {
    {id = 2, name = "outfit_spiritual", desc = "Espiritual (azul etereo)"},
    {id = 3, name = "outfit_arcane_overlay", desc = "Arcane Overlay"},
    {id = 4, name = "outfit_blessed", desc = "Blessed"},
    {id = 5, name = "outfit_bounce", desc = "Bounce"},
    {id = 6, name = "outfit_bounce_high", desc = "Bounce High"},
    {id = 7, name = "outfit_bounce_high_blue", desc = "Bounce High Blue"},
    {id = 8, name = "outfit_bounce_high_green", desc = "Bounce High Green"},
    {id = 9, name = "outfit_bounce_sideways", desc = "Bounce Sideways"},
    {id = 10, name = "outfit_brazil", desc = "Brazil"},
    {id = 11, name = "outfit_bubble", desc = "Bubble"},
    {id = 12, name = "outfit_bubble_blue", desc = "Bubble Blue"},
    {id = 13, name = "outfit_bubble_green", desc = "Bubble Green"},
    {id = 14, name = "outfit_camouflage", desc = "Camouflage"},
    {id = 15, name = "outfit_celestial_radiance", desc = "Celestial Radiance"},
    {id = 16, name = "outfit_circle", desc = "Circle"},
    {id = 17, name = "outfit_circle2", desc = "Circle 2"},
    {id = 18, name = "outfit_circle3", desc = "Circle 3"},
    {id = 19, name = "outfit_circle4", desc = "Circle 4"},
    {id = 20, name = "outfit_colorizingWave", desc = "Colorizing Wave"},
    {id = 21, name = "outfit_cosmic", desc = "Cosmic"},
    {id = 22, name = "outfit_cosmic_flow", desc = "Cosmic Flow"},
    {id = 23, name = "outfit_cosmos", desc = "Cosmos"},
    {id = 24, name = "outfit_cursed", desc = "Cursed"},
    {id = 25, name = "outfit_cyber_glitch", desc = "Cyber Glitch"},
    {id = 26, name = "outfit_cyber_matrix", desc = "Cyber Matrix"},
    {id = 27, name = "outfit_default", desc = "Default"},
    {id = 28, name = "outfit_drunk", desc = "Drunk"},
    {id = 29, name = "outfit_dual_energy", desc = "Dual Energy"},
    {id = 30, name = "outfit_dual_glitter", desc = "Dual Glitter"},
    {id = 31, name = "outfit_dual_texture", desc = "Dual Texture"},
    {id = 32, name = "outfit_electric", desc = "Electric"},
    {id = 33, name = "outfit_electric_eel", desc = "Electric Eel"},
    {id = 34, name = "outfit_electric_goldgreen", desc = "Electric Gold Green"},
    {id = 35, name = "outfit_electric_green", desc = "Electric Green"},
    {id = 36, name = "outfit_electric_purple", desc = "Electric Purple"},
    {id = 37, name = "outfit_electric_red", desc = "Electric Red"},
    {id = 38, name = "outfit_electric_southeast", desc = "Electric Southeast"},
    {id = 39, name = "outfit_falling_stars", desc = "Falling Stars"},
    {id = 40, name = "outfit_fire", desc = "Fire"},
    {id = 41, name = "outfit_fizzy", desc = "Fizzy"},
    {id = 42, name = "outfit_fizzy_blue", desc = "Fizzy Blue"},
    {id = 43, name = "outfit_fizzy_green", desc = "Fizzy Green"},
    {id = 44, name = "outfit_fizzy_guitar", desc = "Fizzy Guitar"},
    {id = 45, name = "outfit_fizzy_pink", desc = "Fizzy Pink"},
    {id = 46, name = "outfit_fizzy_purple", desc = "Fizzy Purple"},
    {id = 47, name = "outfit_flame_knight", desc = "Flame Knight"},
    {id = 48, name = "outfit_fractal_flame", desc = "Fractal Flame"},
    {id = 49, name = "outfit_ghost", desc = "Ghost"},
    {id = 50, name = "outfit_glitch", desc = "Glitch"},
    {id = 51, name = "outfit_glitter_oceangreen", desc = "Glitter Ocean Green"},
    {id = 52, name = "outfit_glitter_purple", desc = "Glitter Purple"},
    {id = 53, name = "outfit_glitter_twitch", desc = "Glitter Twitch"},
    {id = 54, name = "outfit_glittering_ruby", desc = "Glittering Ruby"},
    {id = 55, name = "outfit_gold", desc = "Gold"},
    {id = 56, name = "outfit_goofy_stretchy", desc = "Goofy Stretchy"},
    {id = 57, name = "outfit_grayscale", desc = "Grayscale"},
    {id = 58, name = "outfit_hologram_glitch", desc = "Hologram Glitch"},
    {id = 59, name = "outfit_huegreen", desc = "Hue Green"},
    {id = 60, name = "outfit_ice", desc = "Ice"},
    {id = 61, name = "outfit_inverted", desc = "Inverted"},
    {id = 62, name = "outfit_jello", desc = "Jello"},
    {id = 63, name = "outfit_jumping", desc = "Jumping"},
    {id = 64, name = "outfit_jumping_fixed", desc = "Jumping Fixed"},
    {id = 65, name = "outfit_lava", desc = "Lava"},
    {id = 66, name = "outfit_lightning_storm", desc = "Lightning Storm"},
    {id = 67, name = "outfit_line", desc = "Line"},
    {id = 68, name = "outfit_matrixFall", desc = "Matrix Fall"},
    {id = 69, name = "outfit_metallic", desc = "Metallic"},
    {id = 70, name = "outfit_metallic_bronze", desc = "Metallic Bronze"},
    {id = 71, name = "outfit_metallic_gold", desc = "Metallic Gold"},
    {id = 72, name = "outfit_metallic_purple", desc = "Metallic Purple"},
    {id = 73, name = "outfit_metallic_silver", desc = "Metallic Silver"},
    {id = 74, name = "outfit_mexican_fiesta", desc = "Mexican Fiesta"},
    {id = 75, name = "outfit_midget", desc = "Midget"},
    {id = 76, name = "outfit_molten_crystal", desc = "Molten Crystal"},
    {id = 77, name = "outfit_monsterrarity_cosmos", desc = "Monster Cosmos"},
    {id = 78, name = "outfit_monsterrarity_death", desc = "Monster Death"},
    {id = 79, name = "outfit_monsterrarity_earth", desc = "Monster Earth"},
    {id = 80, name = "outfit_monsterrarity_energy", desc = "Monster Energy"},
    {id = 81, name = "outfit_monsterrarity_fire", desc = "Monster Fire"},
    {id = 82, name = "outfit_monsterrarity_holy", desc = "Monster Holy"},
    {id = 83, name = "outfit_monsterrarity_ice", desc = "Monster Ice"},
    {id = 84, name = "outfit_mystical_aura", desc = "Mystical Aura"},
    {id = 85, name = "outfit_neon_cyber", desc = "Neon Cyber"},
    {id = 86, name = "outfit_neon_green", desc = "Neon Green"},
    {id = 87, name = "outfit_neon_purple", desc = "Neon Purple"},
    {id = 88, name = "outfit_neon_red", desc = "Neon Red"},
    {id = 89, name = "outfit_onsale", desc = "On Sale"},
    {id = 90, name = "outfit_outline", desc = "Outline"},
    {id = 91, name = "outfit_outlineblack", desc = "Outline Black"},
    {id = 92, name = "outfit_outlinegreen", desc = "Outline Green"},
    {id = 93, name = "outfit_outlinegrey", desc = "Outline Grey"},
    {id = 94, name = "outfit_outlinered", desc = "Outline Red"},
    {id = 95, name = "outfit_outlinewhite", desc = "Outline White"},
    {id = 96, name = "outfit_outlineyellow", desc = "Outline Yellow"},
    {id = 97, name = "outfit_overtexture_shimmering", desc = "Shimmering"},
    {id = 98, name = "outfit_pantone_gradient", desc = "Pantone Gradient"},
    {id = 99, name = "outfit_pantone_spectrum", desc = "Pantone Spectrum"},
    {id = 100, name = "outfit_pixel_lava", desc = "Pixel Lava"},
    {id = 101, name = "outfit_pixelated", desc = "Pixelated"},
    {id = 102, name = "outfit_plasmic", desc = "Plasmic"},
    {id = 103, name = "outfit_plasmic_fast", desc = "Plasmic Fast"},
    {id = 104, name = "outfit_plasmic_ocean", desc = "Plasmic Ocean"},
    {id = 105, name = "outfit_plasmic_purple", desc = "Plasmic Purple"},
    {id = 106, name = "outfit_plasmic_toxic", desc = "Plasmic Toxic"},
    {id = 107, name = "outfit_poisoned", desc = "Poisoned"},
    {id = 108, name = "outfit_prismatic", desc = "Prismatic"},
    {id = 109, name = "outfit_prismatic_downward", desc = "Prismatic Downward"},
    {id = 110, name = "outfit_pulsing_rings", desc = "Pulsing Rings"},
    {id = 111, name = "outfit_purpleneon", desc = "Purple Neon"},
    {id = 112, name = "outfit_purplesky", desc = "Purple Sky"},
    {id = 113, name = "outfit_rainbow", desc = "Rainbow"},
    {id = 114, name = "outfit_rainbowRGB", desc = "Rainbow RGB"},
    {id = 115, name = "outfit_rainbowWave", desc = "Rainbow Wave"},
    {id = 116, name = "outfit_rainbow_basic", desc = "Rainbow Basic"},
    {id = 117, name = "outfit_rainbow_cascade", desc = "Rainbow Cascade"},
    {id = 118, name = "outfit_rainbow_epilepsy", desc = "Rainbow Epilepsy"},
    {id = 119, name = "outfit_rainbow_fast", desc = "Rainbow Fast"},
    {id = 120, name = "outfit_rainbow_mutation", desc = "Rainbow Mutation"},
    {id = 121, name = "outfit_rainbow_ripple", desc = "Rainbow Ripple"},
    {id = 122, name = "outfit_rainbow_turbo", desc = "Rainbow Turbo"},
    {id = 123, name = "outfit_redGlow", desc = "Red Glow"},
    {id = 124, name = "outfit_retro_pixelated", desc = "Retro Pixelated"},
    {id = 125, name = "outfit_ruby", desc = "Ruby"},
    {id = 126, name = "outfit_shadow_cloak", desc = "Shadow Cloak"},
    {id = 127, name = "outfit_shimmering", desc = "Shimmering"},
    {id = 128, name = "outfit_shine", desc = "Shine"},
    {id = 129, name = "outfit_shockwave", desc = "Shockwave"},
    {id = 130, name = "outfit_silly_googly", desc = "Silly Googly"},
    {id = 131, name = "outfit_snow", desc = "Snow"},
    {id = 132, name = "outfit_split", desc = "Split"},
    {id = 133, name = "outfit_stargaze", desc = "Stargaze"},
    {id = 134, name = "outfit_starsLinkDarken", desc = "Stars Link Darken"},
    {id = 135, name = "outfit_starsRainbowNebula", desc = "Stars Rainbow Nebula"},
    {id = 136, name = "outfit_starsover", desc = "Stars Over"},
    {id = 137, name = "outfit_starsover2", desc = "Stars Over 2"},
    {id = 138, name = "outfit_starsover3", desc = "Stars Over 3"},
    {id = 139, name = "outfit_starsover4", desc = "Stars Over 4"},
    {id = 140, name = "outfit_starsover_improved", desc = "Stars Over Improved"},
    {id = 141, name = "outfit_static_noise", desc = "Static Noise"},
    {id = 142, name = "outfit_swamp", desc = "Swamp"},
    {id = 143, name = "outfit_swamp_bugs", desc = "Swamp Bugs"},
    {id = 144, name = "outfit_tall", desc = "Tall"},
    {id = 145, name = "outfit_testMovingImg", desc = "Test Moving Img"},
    {id = 146, name = "outfit_textured_rings", desc = "Textured Rings"},
    {id = 147, name = "outfit_trippy", desc = "Trippy"},
    {id = 148, name = "outfit_tunnel_vortex", desc = "Tunnel Vortex"},
    {id = 149, name = "outfit_tunnel_vortex_blue", desc = "Tunnel Vortex Blue"},
    {id = 150, name = "outfit_tunnel_vortex_gold", desc = "Tunnel Vortex Gold"},
    {id = 151, name = "outfit_tunnel_vortex_green", desc = "Tunnel Vortex Green"},
    {id = 152, name = "outfit_tunnel_vortex_neon", desc = "Tunnel Vortex Neon"},
    {id = 153, name = "outfit_tunnel_vortex_purple", desc = "Tunnel Vortex Purple"},
    {id = 154, name = "outfit_tunnel_vortex_red", desc = "Tunnel Vortex Red"},
    {id = 155, name = "outfit_velvet", desc = "Velvet"},
    {id = 156, name = "outfit_vortex", desc = "Vortex"},
    {id = 157, name = "outfit_vortex_glitter", desc = "Vortex Glitter"},
    {id = 158, name = "outfit_wave", desc = "Wave"},
    {id = 159, name = "outfit_whiplash", desc = "Whiplash"},
}

function onSay(cid, words, param, channel)
    if not param or param == "" then
        -- Aplica um shader aleatorio e informa qual foi
        local chosen = AVAILABLE_SHADERS[math.random(#AVAILABLE_SHADERS)]
        local outfit = getCreatureOutfit(cid)
        outfit.lookShader = chosen.id
        doCreatureChangeOutfit(cid, outfit)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
            "[SHADER] Shader aleatorio aplicado: " .. chosen.name .. " (" .. chosen.desc .. ")")
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            "Use !setshader off para remover | !setshader <nome/id> para escolher | !setshader list para ver todos")
        doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
        return true
    end

    local shaderParam = string.lower(param)

    if shaderParam == "off" or shaderParam == "none" or shaderParam == "remove" or shaderParam == "0" then
        local outfit = getCreatureOutfit(cid)
        outfit.lookShader = 0
        doCreatureChangeOutfit(cid, outfit)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
            "[SHADER] Shader removido do seu outfit.")
        return true
    end

    if shaderParam == "list" or shaderParam == "lista" or shaderParam == "help" then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "=== SHADERS DISPONIVEIS ===")
        for i, s in ipairs(AVAILABLE_SHADERS) do
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, i .. ") ID: " .. s.id .. " - " .. s.name .. " (" .. s.desc .. ")")
        end
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "==========================")
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Uso: !setshader <nome ou id>")
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Exemplo: !setshader outfit_fire ou !setshader 40")
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Para remover: !setshader off")
        return true
    end

    -- Busca o shader pelo nome ou id
    local numId = tonumber(shaderParam)
    local shaderId = nil
    local shaderName = ""
    local shaderDesc = ""

    for _, s in ipairs(AVAILABLE_SHADERS) do
        if (numId and s.id == numId) or s.name == shaderParam or string.lower(s.name) == "outfit_" .. shaderParam then
            shaderId = s.id
            shaderName = s.name
            shaderDesc = s.desc
            break
        end
    end

    if not shaderId then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_ORANGE,
            "[SHADER] Shader '" .. param .. "' nao encontrado. Use !setshader list para ver os disponiveis.")
        return true
    end

    -- Aplica o shader no outfit
    local outfit = getCreatureOutfit(cid)
    outfit.lookShader = shaderId
    doCreatureChangeOutfit(cid, outfit)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_WARNING,
        "[SHADER] Shader '" .. shaderName .. "' (" .. shaderDesc .. ") aplicado no seu outfit!")
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)

    return true
end
