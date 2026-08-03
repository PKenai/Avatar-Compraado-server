function onExtendedOpcode(cid, opcode, buffer)
  if not CodeRedeem then return true end
  return CodeRedeem.onExtendedOpcode(cid, opcode, buffer)
end
