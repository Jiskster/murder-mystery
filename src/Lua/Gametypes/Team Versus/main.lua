local teamversus_mode = MM.RegisterGametype("Team Versus", {
	max_time = 2*60*TICRATE;
	required_players = 8;
	inventory_count = 2;
	fill_teams = true;
	disable_item_mapthing = true; -- includes interactions that drop items.
	disable_perks = true;
	disable_proximity_chat = true;
	disable_clues = true;
	disable_killgoal = true;
	disable_showdown = true;
	disable_gun_countdown = true;
	force_overtime = true;
	reveal_roles = true;
	all_droppable_items = true;
	instant_body_discover = true;
	items = {"revolver", "shotgun", "sword", "knife"};
})

local TR = TICRATE
local ANIM = 2*TR
local FADEIN = 6
local msgstatus = {
	str = "",
	tics = 0,
}

MM.addHook("KilledPlayer", function(attacking_p, player)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	
	local count = MM.countPlayers()
	if (consoleplayer and consoleplayer.valid and consoleplayer.mm)
		if consoleplayer.mm.role == MMROLE_MURDERER
			msgstatus.str = "\x85"..count.murderers.."\x80 vs \x84"..count.sheriffs
		else
			msgstatus.str = "\x84"..count.sheriffs.."\x80 vs \x85"..count.murderers
		end
		msgstatus.tics = ANIM
	end
end)

local byteLUT = {}
for i = 26, 126
	byteLUT[i] = ("%.3d"):format(i)
end

MMHUD.addHud("TVS_VsCount", false,false, function(v,p,c)
	local gt = MM.returnGametype()
	if gt.name ~= "Team Versus" then return end
	if not (msgstatus.tics) then return end
	if (MM_N.gameover)
		msgstatus.tics = 0
		return
	end
	
	local x = 160*FU
	local y = 30*FU
	local str = msgstatus.str
	
	local flags = V_SNAPTOTOP
	local scale = FU
	if (ANIM - msgstatus.tics < FADEIN)
		local tics = ANIM - msgstatus.tics
		local progress = FixedDiv(tics*FU, FADEIN*FU)
		
		scale = ease.incubic(progress, 3*FU, FU)
		y = $ - (4 * (scale - FU))
		
		local fade = ease.incubic(progress, 10*FU, 0)/FU
		flags = $|(min(fade, 9)<<V_ALPHASHIFT)
	end
	
	if (msgstatus.tics < 10)
		flags = $|(10 - msgstatus.tics)<<V_ALPHASHIFT
	end
	
	x = $ - (v.stringWidth(str,0,"normal")*scale)/2
	
	local cmap
	for i = 1, str:len()
		local char = str:sub(i,i)
		local byte = char:byte()
		if (byte < 26 or byte > 126)
			if byte == 132 -- "\x84"
				cmap = v.getStringColormap(V_BLUEMAP)
			elseif byte == 133 -- "\x85"
				cmap = v.getStringColormap(V_REDMAP)
			else
				cmap = nil
			end
			continue
		end
		if (char == " ")
			x = $ + 4*scale
			continue
		end
		local letter = v.cachePatch("STCFN" .. byteLUT[byte])
		v.drawScaled(x,y, scale, letter, flags, cmap)
		x = $ + (letter.width*scale)
	end
	
	msgstatus.tics = max($ - 1, 0)
end, "game")