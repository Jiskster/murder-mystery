local stateLUT = {
	[MMROLE_MURDERER] = S_MM_TEAMMATE1,
	[MMROLE_SHERIFF] = S_MM_TEAMMATE2,
}
--leveltime at which V_HUDTRANS starts fading in
local HUD_STARTFADEIN = (50 / 2) + 10

return function(p)
	if leveltime < HUD_STARTFADEIN then return end
	if (p.mm.role == MMROLE_INNOCENT) then return end
	
	--this is TECHNICALLY for teammates, so tic it here
	for k, att in ipairs(p.mm.attract)
		if (att.tics <= 0)
			table.remove(p.mm.attract, k)
			continue
		end
		att.tics = $ - 1
	end
	
	--endgame cutscene
	if (p.mo.flags & MF_NOTHINK) then return end
	
	if not p.mm.teammates
	or (#p.mm.teammates == 0)
	or (p.mm.refreshteammates)
		p.mm.teammates = {}
		
		for p2 in players.iterate
			if p2 == p then continue end
			if not (p2.mm) then continue end
			if (p2.mm.spectator or p.spectator) then continue end
			if p2.mm.role ~= p.mm.role then continue end
			
			table.insert(p.mm.teammates,p2)
		end
		p.mm.refreshteammates = false
	end
	
	for k,play in ipairs(p.mm.teammates)
		if not (play and play.valid)
		or not (play.mo and play.mo.valid and play.mo.health)
		or (play.mm.spectator or play.spectator)
		--!?!?
		or (play.mm.role ~= p.mm.role)
			table.remove(p.mm.teammates,k)
			p.mm.refreshteammates = true
			continue
		end
		
		P_SpawnLockOn(p, play.mo, stateLUT[p.mm.role] or S_MM_TEAMMATE1)
	end
end