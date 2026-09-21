--[[
================================================================================
  STATUE DONATION - extended opcode 121 (lado creaturescript)
--------------------------------------------------------------------------------
  Registrado como creatureevent "extendedopcode" (StatueDonationOpcode) e
  ativado por player no login (login.lua).

  O evento "extendedopcode" recebe TODOS os opcodes, entao cada script filtra o
  seu. Toda a logica esta em data/lib/statueDonation.lua.

  Protocolo (JSON):
    client -> server   {action="donate", data={target="fire", amount=50000}}
                       {action="donate", data={target="exp"}}
                       {action="open"}
    server -> client   {action="state", data={...}}  /  {action="msg", data={...}}
================================================================================
]]

local STATUE_OPCODE = 121

function onExtendedOpcode(cid, opcode, buffer)
    if opcode ~= STATUE_OPCODE then
        return false
    end
    if type(StatueDonation) ~= "table" then
        return false
    end
    return StatueDonation.onOpcode(cid, buffer)
end
