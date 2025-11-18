mobjinfo[freeslot "MT_MM_BULLET"] = {
	radius = 8*FU,
	height = 16*FU,
	spawnstate = S_MM_REVOLV_B,
	flags = MF_NOGRAVITY,
	deathstate = S_SMOKE1,
	speed = 32*FU
}

addHook("MobjThinker", function(mo)
	if not mo.valid then return end
	
	if MM_N.dueling
		MM.GenericHitscan(mo)
		return
	end
	
	if mo.z <= mo.floorz
	or mo.z+mo.height >= mo.ceilingz
	or (mo.eflags & MFE_JUSTSTEPPEDDOWN) then
		MM.BulletDies(mo)
		P_RemoveMobj(mo)
		return
	end
	
	if mo.timealive == nil
		mo.timealive = 0
	else
		mo.timealive = $+1
	end
	if (mo.drag == nil)
		mo.drag = FU
	end
	
	local flip = P_MobjFlip(mo)
	local speed = 140
	mo.momx = FixedMul(speed*cos(mo.angle), cos(mo.aiming))
	mo.momy = FixedMul(speed*sin(mo.angle), cos(mo.aiming))
	mo.momz = speed*sin(mo.aiming)
	
	mo.momx = FixedMul($, mo.drag)
	mo.momy = FixedMul($, mo.drag)
	
	if mo.timealive >= TICRATE/4
		mo.aiming = $ - ANG1*flip
	end
	if mo.timealive >= TICRATE/6
		mo.aiming = $ - (ANG1/3)*flip
		mo.drag = max($ - FU/20, FU/10)
	end
	
	if (mo.timealive % 4) == 0
		P_SpawnGhostMobj(mo).frame = $|FF_SEMIBRIGHT
	end
end, MT_MM_BULLET)

addHook("MobjMoveCollide", MM.BulletHit, MT_MM_BULLET)

addHook("MobjMoveBlocked", function(ring, m,l)
	if not (ring and ring.valid) then return end
	
	MM.BulletDies(ring, m,l)
	P_RemoveMobj(ring)
end, MT_MM_BULLET)

return MT_MM_BULLET