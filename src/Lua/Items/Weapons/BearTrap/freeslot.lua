local TR = TICRATE
local function SafeFreeslot(...)
	for _, item in ipairs({...})
		if rawget(_G, item) == nil
			return freeslot(item)
		end
	end
end

SafeFreeslot("sfx_brtrap")

sfxinfo[sfx_brtrap] = {
	priority = 64,
	flags = SF_X4AWAYSOUND,
	caption = "Beartrap set off"
}

states[SafeFreeslot("S_MM_BEARTRAP_FRIENDLY")] = {
	sprite = SafeFreeslot("SPR_BEARTRAP"),
	frame = A,
	tics = -1
}

states[SafeFreeslot("S_MM_BEARTRAP_WAIT")] = {
	sprite = SPR_BEARTRAP,
	frame = A,
	tics = -1
}

SafeFreeslot("S_MM_BEARTRAP_SNAPPED")
states[SafeFreeslot("S_MM_BEARTRAP_CATCH")] = {
	sprite = SPR_BEARTRAP,
	frame = B|FF_ANIMATE,
	var1 = F - B,
	var2 = 2,
	tics = F*2,
	nextstate = S_MM_BEARTRAP_SNAPPED
}
states[S_MM_BEARTRAP_SNAPPED] = {
	sprite = SPR_BEARTRAP,
	frame = F,
	tics = 4*TR,
}

mobjinfo[SafeFreeslot("MT_MM_BEARTRAP")] = {
	doomednum = -1,
	spawnstate = S_MM_BEARTRAP_WAIT,
	deathstate = S_MM_BEARTRAP_CATCH,
	deathsound = sfx_thok,
	activesound = sfx_brtrap,
	seesound = sfx_subsmt,
	spawnhealth = 1,
	height = 12*FRACUNIT,
	radius = 16*FRACUNIT,
	flags = MF_RUNSPAWNFUNC
}

MM:RegisterEffect("perk.beartrap.slow", {
	modifiers = {
		normalspeed_multi = FU/3
	},
})

addHook("MobjThinker",function(trap)
	if not (trap and trap.valid) then return end
	if P_IsObjectOnGround(trap)
		trap.flags = $|MF_SPECIAL
	end
	
	if trap.tracer and trap.tracer.valid
	and trap.tracer.player and trap.tracer.player.valid then
		if not trap.target then
			if (displayplayer and displayplayer.valid)
				local hide = false
				if (displayplayer.mm)
					if (displayplayer.spectator or displayplayer.mm.spectator)
						hide = false
					elseif (displayplayer.mm.role ~= p.mm.role)
						hide = true
					end
				else
					hide = true
				end

				trap.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
			end
		else
			trap.flags2 = $ &~MF2_DONTDRAW
		end
	end
	
	local me = trap.target
	if not (me and me.valid) then return end
	
	P_MoveOrigin(trap, me.x,me.y,me.z)
	trap.flags = $|MF_NOGRAVITY
	trap.momx,trap.momy,trap.momz = 0,0,0
	trap.dispoffset = me.dispoffset + 2
	
	--fall off
	if trap.tics == 1
	and (trap.state == S_MM_BEARTRAP_SNAPPED)
		trap.state = S_MM_BEARTRAP_FRIENDLY
		trap.fuse = 3*TR
		trap.flags = $ &~MF_NOGRAVITY
		trap.momx,trap.momy = $1 + me.momx, $2 + me.momy
		trap.momz = $ + me.momz
		P_SetObjectMomZ(trap,4*FU,true)
		S_StartSound(trap, sfx_kc50)
		trap.target = nil
	end
	if (trap.state == S_MM_BEARTRAP_CATCH)
		local g = P_SpawnGhostMobj(trap)
		g.tics = 3
		g.fuse = 3
		g.blendmode = AST_ADD
		g.destscale = 1
		--5 tics, intentional
		g.scalespeed = FixedDiv(g.scale, 5*FU)
	end
end,MT_MM_BEARTRAP)

addHook("TouchSpecial",function(mine,me)
	if not (mine and mine.valid) then return end
	if not (me and me.valid) then return end
	if not (me.health) then return end
	
	local p = me.player
	
	--dont kill our teammates lol
	local isTeamMate = (p.mm.role == MMROLE_MURDERER
	and mine.tracer.player.mm.role == MMROLE_MURDERER)
	and (me ~= mine.tracer)
	
	/*
	if isTeamMate or (me == mine.tracer) then
		mine.health = mine.info.spawnhealth
		mine.flags = $|MF_SPECIAL
		return true
	end
	*/
	
	local sfx = P_SpawnGhostMobj(mine)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 3*TR
	
	S_StartSound(sfx,mine.info.deathsound)
	
	--caught
	mine.target = me
	mine.drawonlyforplayer = nil
	MM:ApplyPlayerEffect(p, "perk.beartrap.slow", 4*TR)
	S_StartSound(me,mine.info.activesound)
	
	--catch fx
	do
		local spr_scale = FU * 3/4
		local tntstate = S_TNTBARREL_EXPL3
		local rflags = RF_FULLBRIGHT|RF_NOCOLORMAPS
		
		local bam = P_SpawnMobjFromMobj(me,0,0,0,MT_THOK)
		P_SetMobjStateNF(bam, tntstate)
		bam.spritexscale = FixedMul($, spr_scale)
		bam.spriteyscale = bam.spritexscale
		bam.renderflags = $|rflags
		bam.color = SKINCOLOR_GREY
		bam.colorized = true
		bam.dispoffset = me.dispoffset - 2
		bam.alpha = FU * 3/4
	end
	
	local angdiff = FixedAngle(FixedDiv(360*FU, 6*FU))
	for i = 0, 6
		local fx = P_SpawnMobjFromMobj(me, 0,0,0, MT_PARTICLE)
		fx.flags = MF_NOCLIPHEIGHT|MF_NOCLIP|MF_NOCLIPTHING
		fx.tics = -1
		fx.fuse = TR
		fx.state = mobjinfo[MT_SPIKEBALL].spawnstate
		fx.frame = $|FF_SEMIBRIGHT
		fx.blendmode = AST_MODULATE
		fx.alpha = FU / 2
		
		fx.momx = P_ReturnThrustX(nil, angdiff*i, 5*me.scale)
		fx.momy = P_ReturnThrustY(nil, angdiff*i, 5*me.scale)
		P_SetObjectMomZ(fx, 10*FU)
		
		P_SetScale(fx, me.scale * 2, true)
		fx.spritexscale = $ / 2
		fx.spriteyscale = $ / 2
	end
	
end,MT_MM_BEARTRAP)

MM.addHook("KilledPlayer", function(attacker, target)
	local found, found_slot = MM:GetInventoryItemFromId(attacker, "beartrap") -- this only finds the first item, not multiple items btw lol
	
	if found then
		if found.ammoleft == nil
			print("\x83MM:\x82 WARNING\x80: KilledPlayer::BearTrap - ammoleft is nil")
		end
		
		if found and found_slot and found.ammoleft ~= nil then
			found.ammoleft = $ + 2
		end
	end
end)

return S_MM_BEARTRAP_FRIENDLY