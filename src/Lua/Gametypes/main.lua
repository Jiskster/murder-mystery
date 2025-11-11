MM.Gametypes = {}

local DEFAULT_MAX_TIME = 3*60*TICRATE

function MM.RegisterGametype(name, _data)
	local gametype_id = #MM.Gametypes + 1
	MM.Gametypes[gametype_id] = _data or {}
	MM.Gametypes[gametype_id].name = name
	MM.Gametypes[gametype_id].id = gametype_id
	
	if MM.Gametypes[gametype_id].max_time == nil then
		MM.Gametypes[gametype_id].max_time = DEFAULT_MAX_TIME
	end
	
	return MM.Gametypes[gametype_id]
end

-- TODO: arg1 is the gametype_id, which returns that gametype's table.
function MM.returnGametype(arg1)
	return MM.Gametypes[MM_N.gametype]
end

-- MM_N.maxtime has a different variable name than Gametype[id].max_time

MM.RegisterGametype("Classic")

dofile("Gametypes/Team Versus/main")