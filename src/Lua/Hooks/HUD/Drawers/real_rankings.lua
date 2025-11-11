local TILEWIDTH = 64
local TILEHEIGHT = 16
local TILEMARGIN = 4
local ROWLENGTH = 300 / TILEWIDTH

--[done?]TODO: spectators and innocents during showdown always know the role
--		of other people
--[done?]TODO: murderers should always know who is dead, using this tablist
--		as a checklist
local function isDead(p, alwaysknow)
	-- print("death", (not (p and p.mo and p.mo.valid)), p.spectator, p.mo.health <= 0)
	if p.mm and p.mm.joinedmidgame then
		return true
	end
	
	--those who should ALWAYS know
	if (consoleplayer.mm.role == MMROLE_MURDERER
	or consoleplayer.mm.spectator)
	or (MM_N.showdown or MM_N.dueling)
	or alwaysknow
		if (not (p and p.mo and p.mo.valid))
		or p.spectator
		or p.mo.health <= 0
		or (p.mm and p.mm.spectator)
			return true
		end
	end
	
	if MM_N.knownDeadPlayers[#p]
		return true
	end
	
	return false
end

local SECRECY_NOTSECRET = 0
local SECRECY_MURDERERALLOWED = 1
local SECRECY_SHERIFFALLOWED = -1
local SECRECY_SECRET = 2

local roles = MM.require "Variables/Data/Roles"

local ROLESTYLES = {
	Unknown = {
		secrecy = SECRECY_NOTSECRET
	},
	Dead = {
		overlay = "MM_PLAYERLIST_OVERLAY_DEAD",
		overlayFlags = 0,
		overlayScale = FU/2,
		subtitle = "\x86" .. "Dead",
		secrecy = SECRECY_NOTSECRET
	},
	MidgameJoin = {
		overlay = "MM_PLAYERLIST_OVERLAY_DEAD",
		overlayFlags = 0,
		overlayScale = FU/2,
		subtitle = "\x82(joined midgame)",
		secrecy = SECRECY_NOTSECRET
	},
	Innocent = {
		subtitle = "Innocent",
		secrecy = SECRECY_SECRET,
		standardRole = true
	},
	Murderer = {
		bg = "MM_PLAYERLIST_BG_MURDERER",
		subtitle = "\x85Murderer",
		secrecy = SECRECY_MURDERERALLOWED,
		standardRole = true
	},
	Sheriff = {
		bg = "MM_PLAYERLIST_BG_SHERRIF",
		subtitle = "\x84Sheriff",
		secrecy = SECRECY_SHERIFFALLOWED,
		standardRole = true
	},
	AFKMode = {
		overlay = "MM_PLAYERLIST_OVERLAY_DEAD",
		overlayFlags = 0,
		overlayScale = FU/2,
		subtitle = "\x86".."AFK",
		secrecy = SECRECY_NOTSECRET
	}
}

local function getViewedPlayerRole(player, viewer)
	local gt = MM.returnGametype()

	local role = "Unknown"

	if not player.mm then return "Unknown" end
	if (player.mm.afkmodelast) and player.spectator
		return "AFKMode"
	end
	if player.mm.joinedmidgame then
		role = "MidgameJoin"
	elseif isDead(player) then
		role = "Dead"
	else
		role = roles[player.mm.role].name
	end

	if player == viewer then
		-- i should know what i am
		return role
	end
	
	local imDead = (not (viewer and viewer.mo and viewer.mo.valid))
	or viewer.spectator
	or viewer.mo.health <= 0
	or (viewer.mm and viewer.mm.spectator)
	
	if (player.mm.role == viewer.mm.role)
	and (viewer.mm.role ~= MMROLE_INNOCENT)
		-- i should know who my teammates are
		if isDead(player, true)
			role = "Dead"
		end
		return role
	end
	
	if imDead
	--if it works it works
	or isDead(player)
		-- dead people should know who everyone is
		return role
	end
	
	--wwwait, we should always know dead murderers, the chat does
	--announce them after all
	if isDead(player)
	and player.mm.role == MMROLE_MURDERER
		return role
	end
	
	--[[
	local secrecyLevel = (ROLESTYLES[role] and ROLESTYLES[role].secrecy) or 0
	local privilegeLevel = SECRECY_NOTSECRET
	if isDead(viewer) or MM_N.gameover or MM_N.showdown /*DEBUG!* / or (viewer.cmd.buttons & BT_CUSTOM3)/**/  then
		privilegeLevel = SECRECY_SECRET
	elseif (viewer.mm and viewer.mm.role == MMROLE_MURDERER) then
		privilegeLevel = SECRECY_MURDERERALLOWED
	elseif (viewer.mm and viewer.mm.role == MMROLE_SHERIFF) then
		privilegeLevel = SECRECY_SHERIFFALLOWED
	end
	]]--
	
	if MM_N.gameover or MM_N.showdown or gt.reveal_roles then
		return role
	end
	
	if (viewer ~= player)
		return "Unknown"
	end
	
	-- print(player.name .. ": " .. role .. " with secrecy " .. secrecyLevel .. " and priv " .. privilegeLevel)
	/*
	if role == "Sheriff" then
		if privilegeLevel ~= SECRECY_SHERIFFALLOWED then
			role = "Unknown"
		end
	elseif (privilegeLevel < secrecyLevel) then
		role = "Unknown"
	end
	*/
	return role
end

--[[@param v videolib]]
local function HUD_TabScoresDrawer(v)
	local playerlist = {}
	local deadplayerlist = {}
	local afkplayerlist = {}
	-- while #playerlist < 32 do
	for p in players.iterate do
		if p and p.valid then
			local isafk = false
			if (p.mm_save and p.mm.afkmodelast and p.spectator)
				isafk = true
			end
			
			if isafk
				table.insert(afkplayerlist, p)
				continue
			end
			
			if isDead(p) then
				table.insert(deadplayerlist, p)
			else
				table.insert(playerlist, p)
			end
		end
	end
	for _, p in ipairs(deadplayerlist) do
		table.insert(playerlist, p)
	end
	for _, p in ipairs(afkplayerlist) do
		table.insert(playerlist, p)
	end
	-- end
	-- while #playerlist > 32 do
	-- 	table.remove(playerlist, #playerlist)
	-- end
	
	local xroot = 160 - TILEWIDTH/2 - (min(ROWLENGTH, #playerlist)-1)*(TILEWIDTH+TILEMARGIN)/2
	local yroot = 100 - TILEHEIGHT/2 - ((#playerlist-1)/ROWLENGTH)*(TILEHEIGHT+TILEMARGIN)/2
	
	local bgPatch = v.cachePatch("MM_PLAYERLIST_BG")
	for ind, p in ipairs(playerlist) do
		local x = xroot + (TILEWIDTH+TILEMARGIN)*((ind-1)%ROWLENGTH)
		local y = yroot + (TILEHEIGHT+TILEMARGIN)*((ind-1)/ROWLENGTH)
		
		local role = getViewedPlayerRole(p, consoleplayer)
		local roleStyle = ROLESTYLES[role] or ROLESTYLES.Unknown
		
		local thisBgPatch = bgPatch
		if roleStyle.bg then
			thisBgPatch = v.cachePatch(roleStyle.bg)
		end
		--TODO: use V_REVERSESUBTRACT
		v.draw(x, y, thisBgPatch, V_50TRANS) --|V_REVERSESUBTRACT, v.getColormap(nil,nil,"Invert"))
		
		local p_skin = p.skin
		--fuck
		local p_skincolor = (p.mm.usingsetcolor) and p.mm.savedcolor or p.skincolor
		local name = p.name

		if p.mm
		and p.mm.alias then
			p_skin = p.mm.alias.skin
			p_skincolor = p.mm.alias.skincolor
			name = p.mm.alias.name
		end

		--#region life icon
		local iconpatch = v.getSprite2Patch(p_skin, SPR2_XTRA, false, A)
		local stndpatch = v.getSprite2Patch(p_skin, SPR2_STND, false, A)
		if iconpatch == stndpatch then
			iconpatch = v.cachePatch("WHODISICON")
		end
		local p_cmap = v.getColormap(p_skin, p_skincolor)
		if userdataType(p_cmap) ~= "colormap" --!!!
			p_cmap = v.getColormap(p.skin, p.mm.savedcolor)
		end
		if roleStyle.overlay then p_cmap = v.getColormap(p_skin,p_skincolor,"Grayscale") end
		v.drawScaled(x*FU, y*FU, FU/2, iconpatch, 0, p_cmap)
		--#endregion

		--#region name rendering
		local style = "small"
		local clr = role == "Dead" and V_REDMAP or 0
		-- name = string.sub(name, 1, sin(ANG2*leveltime)/(FU/12)+14)
		if v.stringWidth(name, 0, "small") >= (TILEWIDTH-18) then
			style = "small-thin"
			if v.stringWidth(name, 0, "thin")/2 >= (TILEWIDTH-16) then
				while v.stringWidth(name .. "...", 0, "thin")/2 >= (TILEWIDTH-16) do
					name = string.sub(name, 1, #name-1)
				end
				name = name .. "..."
			end
		end
		v.drawString(
			x + 17, y,
			name, V_ALLOWLOWERCASE|clr,
			style
		)
		--#endregion

		if roleStyle.subtitle then
			local subtitle = roleStyle.subtitle
			if role == "Dead" then
				local preDeathRole = roles[p.mm.role].name
				subtitle = subtitle .. " " .. ROLESTYLES[preDeathRole].subtitle
			end
			style = "small"
			if v.stringWidth(subtitle, 0, "small") >= (TILEWIDTH-18) then
				style = "small-thin"
			end
			v.drawString(
				x + 17, y+5,
				subtitle, V_ALLOWLOWERCASE,
				style
			)
		end
		
		--draw ping
		do
			local player = p
			if p.mm
			and p.mm.alias
			and (p.mm.alias.posingas and p.mm.alias.posingas.valid) then
				player = p.mm.alias.posingas
			end
			
			local pingclr = V_REDMAP
			local pingstr = player.ping.."ms"
			if player.bot
				pingstr = "BOT"
				pingclr = V_GRAYMAP
			elseif (player.ping < 128)
				pingclr = V_GREENMAP
			elseif (player.ping < 256)
				pingclr = V_YELLOWMAP
			end
			if (player == server)
				pingstr = "SERV"
				pingclr = V_AQUAMAP
			end
			
			v.drawString(
				x+17, y+10,
				pingstr,
				pingclr|V_ALLOWLOWERCASE,
				"small"
			)
		end
		
		if roleStyle.overlay then
			v.drawScaled(x*FU, y*FU, roleStyle.overlayScale or FU, v.cachePatch(roleStyle.overlay), roleStyle.overlayFlags)
		end

		if p == consoleplayer then
			v.draw(x, y, v.cachePatch("MM_PLAYERLIST_OUTLINE_YOU"))
		elseif p == displayplayer then
			v.draw(x, y, v.cachePatch("MM_PLAYERLIST_OUTLINE_SPEC"))
		end
	end
	v.drawString(
		160,
		yroot + (TILEHEIGHT+TILEMARGIN)*((#playerlist - 1)/ROWLENGTH) + 20,
		"\x85"..MM_N.special_count.." Murderer"..(MM_N.special_count ~= 1 and "s" or '').."\x80 this round.",
		V_ALLOWLOWERCASE,
		"thin-center"
	)
end

return HUD_TabScoresDrawer,"scores",100
