local vocations = {}
local playerExaust = {}

for x = 1, 4 do
  vocations[x] = getVocationInfo(x).attackSpeed
end

local config = {
  chanceToCritical = 2.5,
  percentHealCaster = 0.05,
  effectHeal = 12,

  says = {
    "Feel My Power!",
    "For Honor!",
    "", ""
  },

  nerf = 0.75
}

function config.removeExaust(cid)
  playerExaust[cid] = false
end

function config.calculateDamage(cid, weapon)
  local attack = getItemInfo(weapon.itemid).attack + getItemInfo(weapon.itemid).extraAttack
  local skillWeapon = getPlayerSkillLevel(cid, getWeaponSkill(weapon.uid))

  local dmg = (math.ceil(attack+skillWeapon+(getPlayerLevel(cid)/2))+math.random(1, 5))*config.nerf
  if type(WeaponProficiency) == "table" and type(WeaponProficiency.getActiveBonuses) == "function" then
    local profBonuses = WeaponProficiency.getActiveBonuses(cid)
    if profBonuses then
      if profBonuses.critDamage and profBonuses.critDamage > 0 then
        dmg = dmg * (1 + (profBonuses.critDamage / 100))
      end
      if profBonuses.physicalDamage and profBonuses.physicalDamage > 0 then
        dmg = dmg * (1 + (profBonuses.physicalDamage / 100))
      end
      if profBonuses.skillBoost and profBonuses.skillBoost > 0 then
        dmg = dmg + profBonuses.skillBoost
      end
    end
  end
  return dmg
end

function config.calculateChance(cid, weapon)
  local baseChance = config.chanceToCritical + (getItemInfo(weapon.itemid).attack * 0.2)
  local tier = tonumber(getItemAttribute(weapon.uid, "tier")) or 0
  if tier > 0 then
    baseChance = baseChance * (1 + tier * 0.1)
  end
  if type(WeaponProficiency) == "table" and type(WeaponProficiency.getActiveBonuses) == "function" then
    local profBonuses = WeaponProficiency.getActiveBonuses(cid)
    if profBonuses and profBonuses.critChance and profBonuses.critChance > 0 then
      baseChance = baseChance + profBonuses.critChance
    end
  end
  return math.ceil(baseChance)
end

function onAttack(cid, target)
  if playerExaust[cid] then
    return true
  end

  playerExaust[cid] = true
  addEvent(config.removeExaust, vocations[getPlayerVocation(cid)], cid)

  local weapon = getPlayerWeapon(cid)

  if weapon.uid > 0 then
    local weaponType = getItemWeaponType(weapon.uid)

    if weaponType >= WEAPON_DIST or weaponType == WEAPON_NONE then
      return true
    end

    local targetPos, cidPos = getThingPos(target), getThingPos(cid)

    if getDistanceBetween(cidPos, targetPos) <= 1 then
      if math.random(1, 100) <= config.calculateChance(cid, weapon) then
        local damage = config.calculateDamage(cid, weapon)

        doTargetCombatHealth(cid, target, COMBAT_PHYSICALDAMAGE, -damage, -damage, 31)
        doSendAnimatedText(targetPos, "Critical!", COLOR_GREY)
        doCreatureAddHealth(cid, getCreatureMaxHealth(cid)*config.percentHealCaster)
        doSendMagicEffect(cidPos, config.effectHeal)
        doPlayerSay(cid, config.says[math.random(1, #config.says)], TALKTYPE_ORANGE_1)
      end
    end
  end

  return true
end
