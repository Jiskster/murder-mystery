return function(self)
	if MM_N.voting then return end
	
	MM_N.voting = true
	MM_N.end_ticker = 0
	
	MM_N.mapVote = {
		maps = {},
		state = "voting",
		ticker = 12*TICRATE
	}
	
	if not (MM_N.killing_end)
		local theme = MM.themes[MM_N.theme or "srb2"]
		
		mapmusname = theme.music or "CHRSEL"
		S_ChangeMusic(mapmusname)
	end
	P_SwitchWeather(PRECIP_NONE)
	
	local addedMaps = 0
	local timesrejected = 0
	while addedMaps < 4 do
		local map = P_RandomRange(1, 1035)
		if not mapheaderinfo[map] then continue end

		local data = mapheaderinfo[map]
		
		local mapWasIn = false
		for _,oldmap in ipairs(MM_N.mapVote.maps) do
			if map == oldmap.map then mapWasIn = true break end
		end
		
		if MM_N.lastmap ~= -1
		and (map == MM_N.lastmap)
		--its no use! let it back in then
		and timesrejected < 3
			mapWasIn = true
			timesrejected = $+1
		end
		
		if mapWasIn then continue end

		if not (data.typeoflevel & TOL_SAXAMM) then
			continue
		end
		if data.bonustype then continue end

		table.insert(MM_N.mapVote.maps, {
			map = map;
			votes = 0;
			gametype = 1;
		})
		addedMaps = $+1
	end
	
	for p in players.iterate do
		if not (p and p.mm) then continue end

		if p.mm.role == MMROLE_MURDERER then
			table.insert(MM_N.murderers, p)
			continue
		end
		table.insert(MM_N.innocents, p)
		
		p.mm.cur_map = P_RandomRange(1, #MM_N.mapVote.maps) -- Be on random selection when vote starts.
	end
end