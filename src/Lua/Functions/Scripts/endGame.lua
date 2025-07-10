local wrapadd = MM.require("Libs/wrappedadd")

--why is this here
MM.endTypes = {
	{
		msg = "Innocents win!",
		name = "Innocents win Round",
		color = V_GREENMAP,
		results = "innocents",
		patch = "LTACTGREEN"
	},
	{
		msg = "Murderer wins!",
		name = "Murderers win Round",
		color = V_REDMAP,
		results = "murderers",
		patch = "LTACTRED"
	}
}

return function(self, endType, nofreeze)
	if MM_N.gameover then return end

	-- select theme
	local themes = {}
	for k,v in pairs(MM.themes) do
		table.insert(themes, k)
	end

	MM_N.theme = themes[P_RandomRange(1, #themes)]
	if MM.themes[MM_N.theme].init then
		MM.themes[MM_N.theme].init(endType)
	end

	local endType = MM.endTypes[endType] or 1
	MM:discordMessage("***"..endType.msg.."***\n")
	
	MM_N.endType = endType
	MM_N.gameover = true
	if not MM_N.restartingformap
		MM_N.rounds = $ + 1
	end
	
	if not MM_N.sniped_end then
		S_StopMusic(consoleplayer)
	end
	
	if (MM_N.killing_end and not (MM_N.disconnect_end or nofreeze))
		for mo in mobjs.iterate()
			if not (mo and mo.valid) then continue end
			if (mo == MM_N.end_camera) then continue end
			
			if mo.flags & MF_NOTHINK
				mo.notthinking = true
				continue
			end
			
			mo.flags = $|MF_NOTHINK
			if not (mo.flags & MF_MISSILE)
			or (mo.origin and mo.origin.id)
				S_StopSound(mo)
			end
			if (mo.player and mo.player.valid)
				mo.fake_drawangle = mo.player.drawangle
			end
		end
	end
	
	--stop spectating
	if (displayplayer and displayplayer.valid)
	and (consoleplayer and consoleplayer.valid)
		displayplayer = consoleplayer
	end
	
	if (MM_N.disconnect_end) then return end
	if (MM_N.dueling) then return end
	if (MM_N.waiting_for_players) then return end
	if MM_N.restartingformap then return end
	if (MM:pregame()) then return end
	
	--this makes me sad
	local sheriff = 
		((MM_N.end_killed and MM_N.end_killed.valid and MM_N.end_killed.player and MM_N.end_killed.player.mm.role == MMROLE_MURDERER)
			and not (MM_N.end_killer and MM_N.end_killer.valid and MM_N.end_killer.health)
		)
		and MM_N.end_killed
		or MM_N.end_killer
	
	--pay people rings
	for p in players.iterate
		if not (p.mm) then continue end
		if not (p.mm_save) then continue end
		if (p.mm.lastafkmode and p.spectator) then continue end
		
		local payout = 0
		local reason = ""
		
		if (p.mm.role == MMROLE_MURDERER)
			--dont get paid if you suck at the game
			if (MM_N.peoplekilled >= MM_N.minimum_killed)
				local percent = FixedDiv(
					min(MM_N.peoplekilled, MM_N.numbertokill)*FU, MM_N.numbertokill*FU
				)
				local amount = FixedMul(MM_N.numbertokill*4*FU, 3*FU/4)
				amount = ease.outsine(FU/3, $, 75*FU)
				
				reason = "killing "..MM_N.peoplekilled.." out of "..MM_N.numbertokill.." innocents"
				payout = FixedFloor(FixedMul(amount, percent)) >> FRACBITS
			end
			
		elseif sheriff == p.mo
		--leech off of your teammate!
		or (p.mm.role == MMROLE_SHERIFF)
			local percent = FixedDiv(
				(MM_N.numbertokill - min(MM_N.peoplekilled, MM_N.numbertokill))*FU, MM_N.numbertokill*FU
			)
			reason = "saving "..(MM_N.numbertokill - min(MM_N.peoplekilled, MM_N.numbertokill)).." out of "..MM_N.numbertokill.." innocents"
			payout = FixedFloor(FixedMul(90*FU, percent)) >> FRACBITS
			
			--gotta be alive tho
			payout = (not p.spectator) and $ or 0
			
		--INNOCENTS
		else
			--nice going moron
			if p.mm.timesurvived == 0 then continue end
			
			local percent = FixedDiv(
				min(p.mm.timesurvived, MM_N.maxtime)*FU, MM_N.maxtime*FU
			)
			reason = "surviving "..(p.mm.timesurvived/TICRATE).." seconds"
			payout = FixedFloor(FixedMul(75*FU, percent))
			payout = ease.outsine(FU/3, $, 75*FU)>> FRACBITS
		end
		
		if payout ~= 0
			p.mm_save.rings = wrapadd($, payout)
			CONS_Printf(p,"\x82Got "..payout.." ring"..(payout ~= 1 and "s" or "")..
			" that round for "..reason.."!")
		end
		p.mm.ringspaid = payout
	end
end