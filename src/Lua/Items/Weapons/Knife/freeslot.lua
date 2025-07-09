states[freeslot("S_MM_KNIFE")] = {
	sprite = freeslot("SPR_KNFE"),
	frame = A,
	tics = -1
}
states[freeslot("S_MM_KNIFE_SPIN")] = {
	sprite = SPR_KNFE,
	frame = C|FF_FULLBRIGHT|FF_ANIMATE,
	var1 = 3,
	var2 = 1,
	tics = 4,
	nextstate = S_MM_KNIFE_SPIN
}

sfxinfo[freeslot("sfx_kequip")].caption = "Knife equip"
sfxinfo[freeslot("sfx_kffire")] = { 
	caption = "Stab",
	flags = SF_X4AWAYSOUND
}
sfxinfo[freeslot("sfx_kwhiff")].caption = "Whiff"
sfxinfo[freeslot("sfx_kcharg")].caption = "Charging"

--Sprite credit: instashield by pastel
states[freeslot("S_MM_KNIFE_WHIFF")] = {
	sprite = freeslot("SPR_MMWH"),
	frame = A|FF_FLOORSPRITE|FF_ANIMATE|FF_SEMIBRIGHT,
	var1 = G,
	var2 = 1,
	tics = G + 1
}

mobjinfo[freeslot("MT_MM_KNIFE_PROJECT")] = {
	radius = 8*FU,
	height = 24*FU,
	spawnstate = S_MM_KNIFE_SPIN,
	flags = MF_NOGRAVITY,
	--move in quarter steps
	speed = 80*FU / 4,
	deathstate = S_SPRK1
}
--local tics_til_grav = 12
addHook("MobjThinker",function(mo)
	if not (mo and mo.valid) then return end
	if not mo.health
		mo.momx,mo.momy,mo.momz = 0,0,0
		mo.renderflags = $|RF_FULLBRIGHT
		return
	end
	if mo.timealive == nil
		mo.timealive = 0
		mo.nobulletfx = true
		
		--speed
		P_InstaThrust(mo, mo.angle,
			FixedMul(mo.info.speed, cos(mo.aiming))
		)
		mo.momz = FixedMul(mo.info.speed, sin(mo.aiming))
		S_StartSound(mo, sfx_cdfm35)
	end
	
	mo.timealive = $ + 1
	/*
	if mo.timealive == tics_til_grav
		mo.flags = $ &~MF_NOGRAVITY
	end
	*/
	if mo.timealive == TICRATE
		P_KillMobj(mo)
		return
	end
	
	for i = 1,3
		P_XYMovement(mo)
		if not (mo and mo.valid) then return end
		P_ZMovement(mo)
		if not (mo and mo.valid) then return end
	end
	
	do --if leveltime % 3 == 0
		local g = P_SpawnGhostMobj(mo)
		g.blendmode = AST_ADD
		g.renderflags = $|RF_FULLBRIGHT
		g.translation = "Grayscale"
	end
	
	if (mo.z <= mo.floorz)
	or (mo.z + mo.height >= mo.ceilingz)
		P_KillMobj(mo)
	end
end,MT_MM_KNIFE_PROJECT)

addHook("MobjMoveBlocked",function(mo)
	if (mo and mo.valid and mo.health and not mo.safeknife)
		P_KillMobj(mo)
	end
end,MT_MM_KNIFE_PROJECT)
addHook("MobjMoveCollide",MM.BulletHit,MT_MM_KNIFE_PROJECT)

return S_MM_KNIFE