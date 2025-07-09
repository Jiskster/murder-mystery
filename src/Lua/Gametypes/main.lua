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

-- MM_N.maxtime has a different variable name than Gametype[id].max_time

MM.RegisterGametype("Classic")

MM.RegisterGametype("Freeze Tag", {
	max_time = 4*60*TICRATE;
	disable_overtime = true;
	no_sheriff = true;
})