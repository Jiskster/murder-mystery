local perk_name = "Footsteps"
local perk_price = 0

local fuse_max = 20*TICRATE
local fuse_min = 10*TICRATE
MM_PERKS[MMPERK_FOOTSTEPS] = {
	icon = "MM_PI_FOOTSTEP",
	icon_scale = FU/2,
	name = perk_name,

	description = {
		"\x82Primary:\x80 See everyone's footsteps!",
		"Footsteps last 20 seconds before disappearing.",
		
		"",
		
		"\x82Secondary:\x80 See everyone's footsteps!",
		"Footsteps last 10 seconds before disappearing.",
	},
	cost = perk_price,
}

freeslot("MT_MM_FOOTSTEP","S_MM_FOOTSTEP")
states[S_MM_FOOTSTEP] = {
	sprite = SPR_BGLS,
	frame = I|FF_SEMIBRIGHT|FF_FLOORSPRITE,
	tics = 1,
	nextstate = S_MM_FOOTSTEP,
	action = function(step)
		if not step.init
			step.fuse = fuse_max
			step.init = true
		end
		
		if (MM_N.gameover)
			P_RemoveMobj(step)
			return
		end
		
		if not (displayplayer and displayplayer.valid) then return end
		local p = displayplayer
		
		if (p.realmo == step.tracer)
			step.flags2 = $|MF2_DONTDRAW
			return
		end
		
		if (p.mm.role ~= MMROLE_MURDERER) then
			step.flags2 = $|MF2_DONTDRAW
			return
		end
		
		if (p.mm_save.pri_perk ~= MMPERK_FOOTSTEPS)
		and (p.mm_save.sec_perk ~= MMPERK_FOOTSTEPS) then
			step.flags2 = $|MF2_DONTDRAW
			return
		end
		
		step.flags2 = $ &~MF2_DONTDRAW
		if (p.mm_save.sec_perk ~= MMPERK_FOOTSTEPS) then return end
		
		if fuse_max - step.fuse > fuse_min
			step.flags2 = $|MF2_DONTDRAW
		end
	end
}
mobjinfo[MT_MM_FOOTSTEP] = {
	doomednum = -1,
	spawnstate = S_MM_FOOTSTEP,
	flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING,
	spawnhealth = 1,
	height = 0,
	radius = 6*FRACUNIT,
}

local function shouldspawnstep(p,me)
	if not P_IsObjectOnGround(me) then return false; end
	--if not (p.skin) then return end
	if not (me.sprite2) then return end
	
	/*
	print(skins[p.skin],
		skins[p.skin].sprites,
		skins[p.skin].sprites[me.sprite2],
		skins[p.skin].sprites[me.sprite2].numframes
	)
	*/
	local halfframe = (skins[p.skin].sprites[me.sprite2].numframes)
	halfframe = min($,8)
	if halfframe == 1
		return (leveltime % 8) == 0
	end
	
	halfframe = $/2
	local myframe = (me.frame & FF_FRAMEMASK)
	
	if (myframe == me.mm_lastframe and me.sprite2 == me.mm_lastsprite2)
	or (p.panim == PA_IDLE)
		return false
	end
	
	if myframe == A
	or myframe == halfframe
		return true 
	end
	
	return false
end

MM.addHook("PlayerThink",function(player)
	if not MM_N.spawnfootsteps then return end
	if player.spectator then return end
	if not (player.mo and player.mo.valid) then return end
	if not (player.mo.health) then return end
	if not (player.mm) then return end
	if player.mm.role == MMROLE_MURDERER then return end
	
	local spawnit = shouldspawnstep(player, player.mo)
	player.mo.mm_lastframe = (player.mo.frame & FF_FRAMEMASK)
	player.mo.mm_lastsprite2 = player.mo.sprite2
	
	if not spawnit then return end
	
	local step = P_SpawnMobjFromMobj(player.mo, 0,0,FU/5, MT_MM_FOOTSTEP)
	step.color = player.skincolor
	local size = FU*3/4
	step.spritexscale,step.spriteyscale = size,size
	step.renderflags = $|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT|RF_OBJECTSLOPESPLAT|RF_NOSPLATROLLANGLE
	step.angle = R_PointToAngle2(0,0, player.mo.momx, player.mo.momy)
	step.tracer = player.mo
	
	if (player.mo.standingslope)
		P_CreateFloorSpriteSlope(step)
		local slope = step.floorspriteslope
		local sslope = player.mo.standingslope
		slope.o = {
			x = step.x, --sslope.o.x,
			y = step.y, --sslope.o.y,
			z = step.z, --sslope.o.z
		}
		slope.xydirection = sslope.xydirection
		slope.zdelta = sslope.zdelta
		slope.zangle = sslope.zangle
	end
end)

addHook("ThinkFrame",do
	MM_N.spawnfootsteps = false
	
	if (MM_N.dueling) then return end
	
	local gt = MM.returnGametype()
	if (gt.disable_perks) then return end
	
	for p in players.iterate
		if p.spectator then continue end
		if not (p.mo and p.mo.valid) then continue end
		if not (p.mo.health) then continue end
		if not (p.mm) then continue end
		if (p.mm.role ~= MMROLE_MURDERER) then continue end
		
		if not (p.mm_save.pri_perk == MMPERK_FOOTSTEPS
		or (p.mm_save.sec_perk ~= MMPERK_FOOTSTEPS))
			continue
		end
		
		MM_N.spawnfootsteps = true
	end
end)

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_FOOTSTEPS