function onSay(cid, words, param, channel)
  param = tonumber(param)
  -- Com o protocolo U16 (magicEffectU16 = true no config.lua) o client aceita
  -- effects de 0 a 65535. O CONST_ME_LAST antigo (179) so vale para o protocolo
  -- de 1 byte e nao se aplica mais aqui.
  if(not param or param < 0 or param > 65535) then
    doPlayerSendCancel(cid, "Numeric param may not be lower than 0 and higher than 65535.")
    return true
  end

  doSendMagicEffect(getCreaturePosition(cid), param)
  return true
end
