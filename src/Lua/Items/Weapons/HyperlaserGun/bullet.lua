states[freeslot("S_MM_LASER_B")] = {
	sprite = SPR_HYPERLASERGUN,
	frame = B|FF_FULLBRIGHT,
	tics = -1,
	nextstate = S_MM_LASER_B
}

mobjinfo[freeslot("MT_MM_LASER")] = {
	radius = 5*FU,
	height = 10*FU,
	spawnstate = S_MM_LASER_B,
	flags = MF_NOGRAVITY,
	deathstate = S_SMOKE1,
	deathsound = sfx_hlgn_h,
	speed = 60*FU
}

mobjinfo[MT_MM_LASER].sparkvfx_func = function(spark, mo)
	spark.flags = $ | MF_NOGRAVITY
	spark.colorized = true
	spark.color = SKINCOLOR_SKY
	spark.blendmode = AST_ADD
	spark.alpha = FU * 3/4
	spark.destscale = 0
	spark.scalespeed = FixedDiv(spark.scale, spark.fuse*FU)
end

local off = 4
addHook("MobjThinker", function(mo)
	if not (mo and mo.valid) then return end

	if mo.z <= mo.floorz
	or mo.z+mo.height >= mo.ceilingz
	or (mo.eflags & MFE_JUSTSTEPPEDDOWN) then
		MM.BulletDies(mo)
		P_RemoveMobj(mo)
		return
	end

	if (leveltime % 2)
		local effect = P_SpawnMobjFromMobj(mo,
			P_RandomRange(-off, off)*FU,
			P_RandomRange(-off, off)*FU,
			P_RandomRange(-off, off)*FU,
			MT_PARTICLE
		)
		effect.state = S_SMOKE1
		effect.colorized = true
		effect.color = SKINCOLOR_CORNFLOWER
		effect.renderflags = $|RF_SEMIBRIGHT
		effect.blendmode = AST_ADD
		P_SetObjectMomZ(effect, P_RandomRange(2,4) * P_RandomFixed())

		local angoff = FixedAngle(P_RandomRange(-45,45) * P_RandomFixed())
		P_Thrust(effect, mo.angle + angoff, -4 * P_RandomFixed())
	end
	local g = P_SpawnGhostMobj(mo)
	g.blendmode = AST_ADD
	g.tics = 8
	P_SetOrigin(g,
		mo.x + (P_RandomRange(-off, off)*mo.scale),
		mo.y + (P_RandomRange(-off, off)*mo.scale),
		mo.z + (P_RandomRange(-off, off)*mo.scale)
	)

	local speed = FixedMul(mo.info.speed, mo.scale)
	mo.momx = P_ReturnThrustX(nil, mo.angle, FixedMul(speed, cos(mo.aiming)))
	mo.momy = P_ReturnThrustY(nil, mo.angle, FixedMul(speed, cos(mo.aiming)))
	mo.momz = FixedMul(speed, sin(mo.aiming))
end,MT_MM_LASER)

addHook("MobjMoveCollide", MM.BulletHit, MT_MM_LASER)
addHook("MobjMoveBlocked", function(ring, m,l)
	if not (ring and ring.valid) then return end
	
	MM.BulletDies(ring, m,l)
	P_RemoveMobj(ring)
end, MT_MM_LASER)

return MT_MM_LASER