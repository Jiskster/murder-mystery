local wrapadd = MM.require("Libs/wrappedadd")

COM_AddCommand("MM_GiveItem", function(p, name)
	if not MM:isMM() then return end

    if not MM.Items[name]
        CONS_Printf(p,"\x85".."Item name "..tostring(name).." not valid. \x82List of items:")
        for k,v in pairs(MM.Items)
            CONS_Printf(p, "* "..tostring(k))
        end
        return
    end

	MM:GiveItem(p, name)
end, COM_ADMIN)

COM_AddCommand("MM_EndGame", function(p)
	if not MM:isMM() then return end

	MM:endGame(1)
	MM_N.killing_end = false
	MM_N.disconnect_end = true
	MM_N.end_ticker = 3*TICRATE - 1
	S_StartSound(nil,sfx_s253)
end, COM_ADMIN)

COM_AddCommand("MM_StartShowdown", function(p)
	if not MM:isMM() then return end
	if MM_N.showdown then return end
	
	MM:startShowdown()
end, COM_ADMIN)

COM_AddCommand("MM_TimeTo0", function(p)
	if not MM:isMM() then return end
	
	MM_N.time = 0
end, COM_ADMIN)

COM_AddCommand("MM_MapClueCount", function(p)
	local count = 0
	
	for thing in mapthings.iterate do
		if thing.type == mobjinfo[MT_MM_CLUESPAWN].doomednum then
			count = $ + 1
		end
	end
	
	CONS_Printf(p, string.format("Total clues in map data: %s", count))
end, COM_LOCAL)

COM_AddCommand("MM_toptextsay", function(p,time,header,...)
	if not MM:isMM() then return end
	
	if not tostring(time)
		CONS_Printf(p,"mm_toptextsay <time> <header> <...>")
		return
	end
	
	local args = {...}
	MMHUD:PushToTop(abs(tonumber(time) or 5)*TICRATE,
		header,
		unpack(args)
	)
end, COM_ADMIN)

COM_AddCommand("MM_stormradius", function(p,dest,time)
	if not MM:isMM() then return end
	
	if dest == nil then return end
	if (time == nil) then return end
	local point = MM_N.storm_point
	
	if not (point and point.valid) then return end
    if point.storm_radius == nil then return end
	
	dest = abs(tofixed($))
	time = abs(tonumber($))
	
	point.storm_destradius = dest
	point.storm_incre = point.storm_radius - ease.linear(FU/(time or 1),
		point.storm_radius,
		dest
	)
end, COM_ADMIN)

COM_AddCommand("MM_MakeMeA", function(p, newrole)
	if not MM:isMM() then return end
	if not (p.mm) then return end
	if newrole == nil then return end
	
	do
		local todo = string.upper(newrole)
		if todo == "SPECTATOR"
			p.mm.spectator = true
			p.spectator = true
			return
		end
		
		local realnum = _G["MMROLE_"..todo]
		if realnum ~= nil
			p.mm.got_weapon = false
			p.mm.role = realnum
			
			for play in players.iterate()
				if not (play.mm) then continue end
				play.mm.teammates = nil
			end
			
			if (p.mm.spectator)
				p.mm.spectator = false
				p.mm.joinedmidgame = false
				p.playerstate = PST_REBORN
				p.mm.role = realnum
			end
		else
			CONS_Printf(p,todo.." is not a role.")
		end
	end
	
end, COM_ADMIN)

COM_AddCommand("MM_SpectatorMode", function(p)
	if not MM:isMM() then return end
	if not (p.mm) then return end
	
	/*
	if not (p.spectator)
		CONS_Printf(p,"You can't use this right now.")
		return
	end
	*/
	
	p.mm_save.afkmode = not $
	
	local msg = ""
	if p.mm_save.afkmode
		msg = "You'll start as a spectator every round now."
	else
		msg = "You'll spawn regularly next round."
		
		if (MM_N.waiting_for_players)
			p.mm.spectator = false
			p.playerstate = PST_REBORN
		end
	end
	CONS_Printf(p,msg)
end)

COM_AddCommand("MM_SetPerk", function(p, slot, newperk)
	if not MM:isMM() then return end
	if not (p.mm) then return end
	if slot == nil then return end
	if newperk == nil then return end
	slot = string.lower($)
	
	do
		local todo = string.upper(newperk)
		local realnum = _G["MMPERK_"..todo]
		if todo == "NONE"
			realnum = 0
		end
		
		if realnum ~= nil
			local chosen = 0
			if slot == "1"
			or string.sub(slot,1,3) == "pri"
				p.mm_save.pri_perk = realnum
				
				if p.mm_save.sec_perk == p.mm_save.pri_perk
					p.mm_save.sec_perk = 0
				end
				chosen = 1
			elseif slot == "2"
			or string.sub(slot,1,3) == "sec"
				p.mm_save.sec_perk = realnum
				
				if p.mm_save.pri_perk == p.mm_save.sec_perk
					p.mm_save.pri_perk = 0
				end
				chosen = 2
			end
			
			if chosen
				CONS_Printf(p,"Set "..todo.." as "..(chosen == 1 and "primary" or "secondary").." perk.")
			else
				CONS_Printf(p,"Didn't set perk. Argument 1 must be 1, 2, pri..., sec...")
			end
			
		else
			CONS_Printf(p,todo.." is not a perk.")
		end
	end
	
end, COM_ADMIN)

local perk_list = {
	"Footsteps",
	"Ninja",
	"Haste",
	"Ghost",
	"Swap",
	"Trap",
	"XRay",
	"FakeGun",
	"None"
}
COM_AddCommand("MM_EquipPerk", function(p, slot, newperk)
	if not MM:isMM() then return end
	if not (p.mm) then return end
	if slot == nil
	or newperk == nil
		CONS_Printf(p, "MM_EquipPerk <1/2, primary/secondary>, <perk name>")
		CONS_Printf(p, "Availiable perks:")
		for k,name in ipairs(perk_list)
			CONS_Printf(p, "	"..name)
		end
		return
	end
	
	if ((p.mm.role == MMROLE_MURDERER and not MM:pregame() and not MM_N.gameover) and not p.spectator)
	and not CV_MM.debug.value then
		CONS_Printf(p, "Unable to change perks at this time.")
		return 
	end
	
	
	slot = string.lower($)
	
	do
		local todo = string.upper(newperk)
		local realnum = _G["MMPERK_"..todo]
		if todo == "NONE"
			realnum = 0
		end
		
		--try numerical ID's
		if (realnum == nil)
		and tonumber(newperk) ~= nil
			realnum = tonumber(newperk)
			
			if MM_PERKS[realnum] == nil
				return
			end
		end
		
		if realnum ~= nil
			--check if we own it first
			if not MM.Shop.ownsItem(p, MM_PERKS.perkid_to_itemid[realnum])
			and (realnum ~= 0)
				CONS_Printf(p,"You don't own this item.")
				return
			end
			
			local chosen = 0
			if slot == "1"
			or string.sub(slot,1,3) == "pri"
				p.mm_save.pri_perk = realnum
				
				if p.mm_save.sec_perk == p.mm_save.pri_perk
					p.mm_save.sec_perk = 0
				end
				chosen = 1
			elseif slot == "2"
			or string.sub(slot,1,3) == "sec"
				p.mm_save.sec_perk = realnum
				
				if p.mm_save.pri_perk == p.mm_save.sec_perk
					p.mm_save.pri_perk = 0
				end
				chosen = 2
			end
			
			if chosen
				CONS_Printf(p,"Set "..todo.." as "..(chosen == 1 and "primary" or "secondary").." perk.")
			else
				CONS_Printf(p,"Didn't set perk. Argument 1 must be 1, 2, pri..., sec...")
			end
			
		else
			CONS_Printf(p,todo.." is not a perk.")
		end
	end
	
end)

COM_AddCommand("MM_AddRings", function(p, rings)
	if not MM:isMM() then return end
	if (tonumber(rings) == nil) then return end
	
	p.mm_save.rings = wrapadd($, tonumber(rings))
end, COM_ADMIN)

COM_AddCommand("MM_RadioSong", function(p, str)
	if not (str
	and MMRadio.songs[str:lower()]) then
		CONS_Printf(p, "Usage: mm_radiosong <songname>")
		CONS_Printf(p, "Select a song to be played on your radio when dropped.")
		CONS_Printf(p, "\x82".."Availiable songs:")
		for k,v in pairs(MMRadio.songs) do
			CONS_Printf(p, "* "..k)
		end
		return
	end

	p.mmradio_song = MMRadio.songs[str:lower()]
	CONS_Printf(p, "Your radio song has been set to "..str:lower())
end)

COM_AddCommand("MM_AdminBadge", function(p)
	if not MM:isMM() then return end
	if not (p.mm) then return end
	
	p.mm_save.adminbadge = not $
	
	local msg = ""
	if p.mm_save.adminbadge
		msg = "Your admin badge will now be \x82shown\x80 in chat."
	else
		msg = "Your admin badge will now be \x82hidden\x80 in chat."
	end
	if not (IsPlayerAdmin(p) or (p == server))
		msg = $ .. " \x86(Changes will only be visible when you're an admin)"
	end
	S_StartSound(nil, sfx_strpst,p)
	
	CONS_Printf(p,msg)
end)

COM_AddCommand("MM_OpenMenu", function()
	if MenuLib.client.currentMenu.id ~= -1 then return end
	MenuLib.initMenu(MenuLib.findMenu("MainMenu"))
end, COM_LOCAL)

COM_AddCommand("MM_SetTime", function(p,time)
	if not MM:isMM() then return end
	
	if (time == nil) then return end
	
	time = abs(tonumber($) or 0)
	MM_N.time = $ + time
end, COM_ADMIN)