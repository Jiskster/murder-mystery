/*
local function can_be_role(p, count)
	if count < 2 then
		return true
	end
	
	return true
end
*/

local function select_player_from_table(p, tbl)
	local returnthis
	while not returnthis do
		local i = P_RandomRange(1, #tbl)

		if p ~= tbl[i] then
			returnthis = tbl[i]
			break
		end
	end

	return returnthis
end

local getCount = dofile("Libs/getCount")

--if alreadychosen is true, then we've already set roles, and are just filling up missing slots (people who left)
--murdorsherf: true = only murds, false = only count sheriffs, nil = do nothing
return function(self, count, alreadychosen, murdorsherf)
	local murderer_chance_table = {} 
	local sheriff_chance_table = {}
	local total_table = {}

	-- Insert each player's chances in their tables.
	for p in players.iterate do
		if not (p and p.valid and p.mm) 
		/*and not can_be_role(p, pcount)*/ then continue end
		
		if p.mm_save.afkmode then continue end
		if alreadychosen and (p.mm.role ~= MMROLE_INNOCENT) then continue end
		
		for i=1,p.mm_save.murderer_chance_multi do
			table.insert(murderer_chance_table, p)
		end
		for i=1,p.mm_save.sheriff_chance_multi do
			table.insert(sheriff_chance_table, p)
		end
		table.insert(total_table,p)
	end

	-- Select players.
	local murderers = {}
	local sheriffs = {}
	local i = 0

	if MM_N.dueling or CV_MM.force_duel.value then		
		local murderer = select_player_from_table(p, murderer_chance_table)
		local sheriff = select_player_from_table(p, sheriff_chance_table)
		local tries = 0
		local max_tries = 50
		
		-- If sheriff is the same as murderer, then reroll sheriff
		while (sheriff == murderer) and tries < max_tries do
			sheriff = total_table[P_RandomRange(1,#total_table)]
			tries = $ + 1
			
			if tries == max_tries then
				error("Caught infinite loop.")
			end
		end
		
		murderers[murderer] = true
		murderer.mm.role = MMROLE_MURDERER
		
		sheriffs[sheriff] = true
		sheriff.mm.role = MMROLE_SHERIFF
		
		return murderers, sheriffs
	end

	local tries = 0
	while i < count do
		local mp = select_player_from_table(p, murderer_chance_table)
		local sp = select_player_from_table(p, sheriff_chance_table)
		
		if mp ~= sp
		and not (murderers[mp])
		and not (sheriffs[sp]) then
			if murdorsherf == nil or (murdorsherf == true) then
				mp.mm.role = MMROLE_MURDERER
				mp.mm_save.murderer_chance_multi = 1
				
				if murdorsherf ~= nil
					if CV_MM.debug.value
						chatprint("\x83*" .. mp.name .. "\x83 has been magically made a \x85Murderer!\x82")
					else
						chatprintf(mp, "\x83*You have been magically made a \x85Murderer!\x82")
					end
				end
				murderers[mp] = true
			end
			
			if murdorsherf == nil or (murdorsherf == false) then
				sp.mm.role = MMROLE_SHERIFF
				sp.mm_save.sheriff_chance_multi = 1
				
				if murdorsherf ~= nil
					if CV_MM.debug.value
						chatprint("\x83*" .. sp.name .. "\x83 has been magically made a \x84Sheriff!\x82")
					else
						chatprintf(sp, "\x83*You have been magically made a \x84Sheriff!\x82")
					end
				end
				sheriffs[sp] = true
			end
			i = $+1
		end

		tries = $ + 1
		if (tries > 64) then
			MM_N.waiting_for_players = true
			if CV_MM.debug.value
				print("\x83MM:\x80\Caught infinite loop in assignRoles!")
			end
		end
	end

	return murderers, sheriffs
end