function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str(v) )
    done[ k ] = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end


Market = {
  
  opcodes  = 230,
  limitPag =  15, -- Não alterar, se foi colocado 15 é pq tem uma razão. No modulo em updatecontrols tbm esta como 15
  
  getCountOffers = function()
    local row   = db.getResult("SELECT count(*) as count FROM auction_system WHERE expired = 0 AND world_id = "..getConfigValue('worldId')..";")
	local count = 0
    if ( row:getID() ~= -1 ) then
      count = math.max(1, row:getDataInt("count"))
	  row:free()
    end	
	return count
  end,
  
  getOfferDescription = function(offerId)
    local row  = db.getResult("SELECT `desc` FROM `auction_system` WHERE `id` = ".. offerId .." AND `world_id` = ".. getConfigValue('worldId'))
	local desc = ""
	if ( row:getID() ~= -1 ) then
	  desc = row:getDataString("desc")
	  row:free()
	end
	return desc
  end,
  
  getOffers = function(cid, pag)
  
    local offers = {}
	local numPag = math.ceil(Market.getCountOffers()/Market.limitPag)	
	
    pag = ( pag <= 0 or pag > numPag ) and 1 or pag
    
    local offset = math.ceil(Market.limitPag * (pag-1))
    local rows   = db.getResult("SELECT id, item_id, item_name, player, (SELECT name FROM players WHERE `id` = player) AS player_name, cost, count FROM auction_system WHERE expired = 0 AND world_id = "..getConfigValue('worldId').." ORDER BY id DESC LIMIT "..Market.limitPag.." OFFSET "..offset)
    
	if( rows:getID() ~= -1 ) then
	  repeat
	    table.insert(offers, {
		  id = rows:getDataInt("id"),
		  itemId   = getItemInfo(rows:getDataInt("item_id")).clientId,
		  itemName = rows:getDataString("item_name"),
		  type   = rows:getDataInt("player") == getPlayerGUID(cid) and 1 or 0,
		  player = rows:getDataString("player_name"),
		  price  = rows:getDataInt("cost"),
		  count  = rows:getDataInt("count")					
	    })
	  until not rows:next()
	  rows:free()
    end
    return offers
  end,
  
  sendOfferOtclient = function(cid, pag)
    doSendPlayerExtendedOpcode(cid, Market.opcodes, "create>"..Market.getCountOffers()..">"..table.tostring(Market.getOffers(cid, pag)))
  end
}