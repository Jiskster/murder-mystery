-- Corrects the player's skin and/or color in case they're cringe and change it
return function(p)
	p.mm.usingsetcolor = false
	if MM:pregame() then return end
	if MM_N.waiting_for_players then return end
	if MM_N.gameover then return end
	if (p.spectator or p.mm.spectator) then return end
	
	local alias = p.mm.alias
	
	if (alias)
		if p.skincolor ~= alias.skincolor
			p.skincolor = alias.skincolor
			p.mo.color = p.skincolor
		end
		if p.mo.skin ~= alias.skin
			R_SetPlayerSkin(p, alias.skin)
		end
		return
	end
	
	if p.mm.savedcolor ~= nil
		if p.skincolor ~= p.mm.savedcolor
			p.skincolor = p.mm.savedcolor
			p.mo.color = p.skincolor
		end
		p.mm.usingsetcolor = true
	--should there be a return here if the colors nil?
	end

	if ((leveltime) % (5*TICRATE)) == 1
		local changed = false
		local mytable
		for k,v in ipairs(MM_N.player_colors)
			if v.player == p then mytable = v; continue end
			if v.color ~= p.skincolor then continue end
			if v.skin ~= skins[p.skin].name then continue end
			--We had this color first, skip.
			if #p < #v.player then continue end
			
			repeat
				p.skincolor = P_RandomRange(SKINCOLOR_WHITE,SKINCOLOR_VOLCANIC)
			until (p.skincolor ~= v.color)
			p.mm.savedcolor = p.skincolor
			p.mo.color = p.skincolor
			changed = true
		end
		if changed
			mytable.color = p.skincolor
			chatprintf(p, "\x82*That color is already being used by someone.")
		end
	end
end