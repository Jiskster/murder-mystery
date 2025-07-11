local roles = MM.require "Variables/Data/Roles"
local TR = TICRATE

local vowels = {
	["a"] = true,
	["e"] = true,
	["i"] = true,
	["o"] = true,
	["u"] = true,
}

local teammates
local waitingfade = 0

local function HUD_TFW_DrawTeammates(v,p)
	if (p.mm.role == MMROLE_INNOCENT) then return end
	
	if not teammates
		teammates = {}
		
		table.insert(teammates,p)
		for play in players.iterate
			if (play == p) then continue end
			if not (play.mm) then continue end
			if (play.mm.role ~= p.mm.role) then continue end
			
			table.insert(teammates,play)
		end
	end
	
	if #teammates
		local work = 0
		for k,play in ipairs(teammates)
			if not (play and play.valid)
				table.remove(teammates,k)
				continue
			end
			
			local hires = FU
			if (skins[play.skin].highresscale)
				hires = skins[play.skin].highresscale
			end
			
			v.drawScaled(5*FU - MMHUD.weaponslidein,
				65*FU + work,
				hires/2,
				v.getSprite2Patch(play.skin,SPR2_LIFE,false,0,0,0),
				V_SNAPTOLEFT,
				v.getColormap(play.skin,play.skincolor)
			)
			
			v.drawString(10*FU - MMHUD.weaponslidein,
				60*FU + work,
				play.name,
				V_SNAPTOLEFT|V_ALLOWLOWERCASE|(play == p and V_YELLOWMAP or roles[p.mm.role].color),
				"thin-fixed"
			)
			
			work = $ + 10*FU
		end
		
		v.drawString(5*FU - MMHUD.weaponslidein,
			50*FU,
			"Team:",
			V_SNAPTOLEFT|V_ALLOWLOWERCASE,
			"fixed"
		)
	end
	
end

local lastp
local function HUD_TimeForWeapon(v,p)
	if not MM:isMM() then return end
	--if not (p.mo and p.mo.health and p.mm) then return end
	
	if MM_N.waiting_for_players then
		if MMHUD.ticker < waitingfade
			waitingfade = MMHUD.ticker
		end
		
		local fade = 0
		if (waitingfade >= 5*TICRATE)
			local adjust = waitingfade - 5*TICRATE
			adjust = min($, 8)
			
			fade = adjust << V_ALPHASHIFT
		end
		
		v.drawString(160*FU,
			40*FU - MMHUD.weaponslidein,
			"Waiting for players...",
			V_SNAPTOTOP|V_ALLOWLOWERCASE|fade,
			"thin-fixed-center"
		)
		
		waitingfade = $ + 1
		return
	end
	waitingfade = 0
	
	--we'll also draw the ending countdown here too
	if leveltime >= MM_N.pregame_time + 5
		/*
		if (MM_N.showdown) then return end
		if (MM_N.time > 30*TICRATE) then return end
		
		--end countdown
		local time = MM_N.time
		if (time <= 3*TICRATE)
		and (time > 0)
			local letterpatch = v.cachePatch("RACE".. ((time/TR) + 1) )
			local letteroffset = letterpatch.width*FU
			local yoff = 0
			if (time % TR) > TR*3/4
				yoff = 9*FU - (TR - (time % TR))*FU
				yoff = ease.linear(FU*3/4,$,0)
			end
			
			v.drawScaled(160*FU - letteroffset/2,
				10*FU - yoff,
				FU,
				letterpatch,
				V_SNAPTOTOP
			)
		end
		*/
		
		return
	end
	
	local time = (MM_N.pregame_time)-leveltime
	if (leveltime < TR)
	or (displayplayer ~= lastp)
		teammates = nil
	end
	lastp = displayplayer
	
	local flags = V_SNAPTOTOP
	local ypos = 32*FU - MMHUD.weaponslidein
	if (splitscreen)
		flags = V_HUDTRANS
		ypos = 80*FU
	end
	
	if not (p.spectator)
	and not splitscreen
		local color = roles[p.mm.role].colorcode
		local name = roles[p.mm.role].name
		local grammar = ''
		if vowels[string.sub(string.lower(name),1,1)] == true
			grammar = "n"
		end
		local text = (MM_N.dueling and "You're dueling!" or "You're a"..grammar..' '..color..name.."\x80!")
		
		v.drawString(160*FU,
			ypos,
			text,
			flags|V_ALLOWLOWERCASE,
			"thin-fixed-center"
		)
	end
	
	v.drawString(160*FU,
		ypos + 8*FU,
		(not splitscreen) and (roles[p.mm.role].weapon and "You'll get your weapon in" or
		"Round starts in") or "Duel starts in",
		flags|V_ALLOWLOWERCASE,
		roles[p.mm.role].weapon and "thin-fixed-center" or "fixed-center"
	)
	do
		local letterpatch = v.cachePatch("STTNUM"..(time/TR))
		local letteroffset = v.cachePatch("STTNUM0").width*FU * tostring(time/TR):len()
		local yoff = 0
		if time/TR <= 3
			letterpatch = v.cachePatch("RACE"..(time/TR == 0 and "GO" or (time/TR)))
			letteroffset = letterpatch.width*FU
			if (time % TR) > TR*3/4
				yoff = 9*FU - (TR - (time % TR))*FU
				yoff = ease.linear(FU*3/4,$,0)
			end

			if (MM_N.dueling and time/TR == 0)
				v.drawString(160*FU,
					ypos + 18*FU - yoff,
					"DUEL!!",
					flags|V_YELLOWMAP,
					"fixed-center"
				)
			else
				v.drawScaled(160*FU - letteroffset/2,
					ypos + 18*FU - yoff,
					FU,
					letterpatch,
					flags
				)
			end
			
		else
			local work = 0
			local tstr = tostring(time/TR)
			for i = 1,string.len(tstr)
				v.drawScaled(160*FU - letteroffset/2 + work,
					ypos + 18*FU - yoff,
					FU,
					v.cachePatch("STTNUM"..string.sub(tstr,i,i)),
					flags
				)
				work = $ + v.cachePatch("STTNUM0").width*FU
			end
			
		end
		
	end
	
	if splitscreen then return end
	
	v.drawString(160*FU,
		150*FU + MMHUD.weaponslidein,
		"\x85"..MM_N.special_count.." Murderer"..(MM_N.special_count ~= 1 and "s" or '').."\x80 this round.",
		V_SNAPTOBOTTOM|V_ALLOWLOWERCASE,
		"thin-fixed-center"
	)
	if p == consoleplayer
	and not (p.spectator)
		local mchance = p.mm_save.cons_murderer_chance
		--local schance = p.mm_save.cons_sheriff_chance
		local y = 158*FU + MMHUD.weaponslidein
		
		v.drawString(160*FU,
			y,
			string.format("%.2f",mchance).."% chance to be a Murderer",
			V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_REDMAP,
			"thin-fixed-center"
		)
		/*
		v.drawString(160*FU,
			y + (8*FU),
			string.format("%.2f",schance).."% chance to be a Sheriff",
			V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_BLUEMAP,
			"thin-fixed-center"
		)
		*/
	end
	
	if (leveltime >= TR)
		HUD_TFW_DrawTeammates(v,p)
		v.WslideDrawString(320,0,
			MM.Gametypes[MM_N.gametype].name,
			V_ALLOWLOWERCASE|V_SNAPTORIGHT|V_SNAPTOTOP|V_YELLOWMAP,
			"thin-right",false
		)
	end
end

return HUD_TimeForWeapon