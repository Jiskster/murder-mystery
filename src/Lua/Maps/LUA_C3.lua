--TD Script and behavior used with permission of DylanSahr from TD Forest

freeslot("SPR_TDOL", "SFX_TDSEE", "SFX_SCRETD", "S_TD_FLOAT1", "S_TD_CHASE1", "S_TD_CHASE2", "MT_TAILSDOLL")

-- A_DetonChase
local function TDChase(mo)
	local exact
	local xydist, dist
	
	if not (mo.tracer and mo.tracer.valid and mo.tracer.health > 0)
		mo.threshold = 0
	else
		mo.threshold = 1
	end
	
	if not (mo.tracer and mo.tracer.valid and mo.tracer.flags & MF_SHOOTABLE)
		if P_LookForPlayers(mo, 0, true,true)
			return
		end
		
		mo.momx, mo.momy, mo.momz = 0,0,0
		mo.state = mo.info.spawnstate
		return
	end
	
	if (multiplayer and (not mo.threshold) and P_LookForPlayers(mo, 0, true,true))
		return
	end
	
	exact = R_PointToAngle2(mo.x,mo.y, mo.tracer.x, mo.tracer.y)
	mo.angle = exact
	
	xydist = P_AproxDistance(mo.tracer.x - mo.x, mo.tracer.y - mo.y)
	exact = R_PointToAngle2(0,0, xydist, mo.tracer.z - mo.z)
	mo.movedir = exact
	
	if (mo.tracer and mo.tracer.valid)
		if P_AproxDistance(mo.tracer.x - mo.x, mo.tracer.y - mo.y) < mo.radius + mo.tracer.radius
			if not ((mo.tracer.z > mo.z + mo.height) or (mo.z > mo.tracer.z + mo.tracer.height))
				P_ExplodeMissile(mo)
				return
			end
		end
	end
	
	dist = P_AproxDistance(xydist, mo.tracer.z - mo.z)
	if (dist > mo.info.painchance * mo.scale)
		mo.tracer = nil
		return
	end
	
	if (mo.reactiontime == 0)
		mo.reactiontime = mo.info.reactiontime
		return
	end
	
	if (mo.reactiontime > 1)
		mo.reactiontime = $ - 1
		return
	end
	
	if (mo.reactiontime > 0)
		mo.reactiontime = -42
		if mo.info.seesound
			S_StartSound(mo, mo.info.seesound)
		end
	end
	
	if (mo.reactiontime == -42)
		local xyspeed, speed
		speed = mo.info.speed
		mo.reactiontime = -42
		
		exact = mo.movedir
		xyspeed = FixedMul(FixedMul(speed, FU*3/4), cos(exact))
		mo.momz = FixedMul(FixedMul(speed, FU*3/4), sin(exact))
		
		exact = mo.angle
		mo.momx = FixedMul(xyspeed, cos(exact))
		mo.momy = FixedMul(xyspeed, sin(exact))
		
		xyspeed = P_AproxDistance(mo.tracer.x - mo.x, P_AproxDistance(mo.tracer.y - mo.y, mo.tracer.z - mo.z)) >> (FRACBITS+6)
		if xyspeed < 1 then xyspeed = 1; end
		
		if (leveltime % xyspeed == 0)
			S_StartSound(mo, sfx_deton)
		end
	end
end

states[S_TD_FLOAT1] = {SPR_TDOL, A, 1, A_Look, 65535, 0, S_TD_FLOAT1}
states[S_TD_CHASE1] = {SPR_TDOL, FF_FULLBRIGHT|B, 1, TDChase, 0, 0, S_TD_CHASE2}
states[S_TD_CHASE2] = {SPR_TDOL, FF_FULLBRIGHT|C, 1, TDChase, 0, 0, S_TD_CHASE1}

mobjinfo[MT_TAILSDOLL] = {
	//$Name Tails Doll
	//$Sprite TDOLA1
	//$Category Enemies
	doomednum = -1,
	spawnstate = S_TD_FLOAT1,
	spawnhealth = 1,
	seestate = S_TD_CHASE1,
	seesound = sfx_TDSEE,
	painchance = 2000,
	reactiontime = 1,
	speed = 30*FRACUNIT,
	radius = 10*FRACUNIT,
	height = 40*FRACUNIT,
	damage = 1,
	flags = MF_RUNSPAWNFUNC|MF_ENEMY|MF_SHOOTABLE|MF_FLOAT|MF_NOGRAVITY|MF_SPECIAL
}

--Script by: SpectrumUK
addHook("MobjThinker", function(mo)
	if not mo.tracer then return end
	if not S_SoundPlaying(mo, sfx_tdsee)
		S_StartSound(mo, sfx_tdsee)
	end
end, MT_TAILSDOLL)

local td_kill = function(mo, mo2)
	local icankillthisguy = false
	if (mo.markfordeath and mo.markfordeath.valid)
		icankillthisguy = mo2 == mo.markfordeath
	else
		icankillthisguy = true
	end
	
	if (icankillthisguy)
		P_KillMobj(mo2, mo, mo)
	else
		P_DamageMobj(mo2, mo,mo)
	end
	P_KillMobj(mo)
	return true
end
addHook("TouchSpecial", td_kill, MT_TAILSDOLL)
addHook("LinedefExecute", function(line, me)
	local p = me.player
	if not (p and p.valid) then return end
	
	-- Hardcoded, but who cares.
	local doll = P_SpawnMobj(363*FU, 2608*FU, 32*FU, MT_TAILSDOLL)
	doll.markfordeath = me
	doll.tracer = me
	doll.state = S_TD_CHASE1
end, "MM_TAILD")

--Other Interactions

freeslot("sfx_loff")

--Lord X painting
freeslot("sfx_haha")

local hauntedmansion_screen = function(v,p)
	if not p.statictimer then return end
	if p.statictimer then
		local frame = (leveltime % 4)
		local patch = v.cachePatch("STATIC"..frame)
		local wid = (v.width() / v.dupx()) + 1
		local hei = (v.height() / v.dupy()) + 1
		local p_w = patch.width
		local p_h = patch.height
		v.drawStretched(0,0,
			FixedDiv(wid * FU, p_w * FU),
			FixedDiv(hei * FU, p_h * FU),
			patch,
			V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS
		)
	end
end

local trigger_lordxstatic = function(line, mo)
	if mo.player
		if not mo.player.statictimer then mo.player.statictimer = 2*TICRATE end
	end
end
local staticperplayer = function(p)
	if not p.statictimer then return end
	p.statictimer = $-1
end
addHook("PlayerThink", staticperplayer)
addHook("LinedefExecute", trigger_lordxstatic, "LORDX")

customhud.SetupItem("hauntedmansion_events", "HauntedMansion", hauntedmansion_screen, "game", -1)