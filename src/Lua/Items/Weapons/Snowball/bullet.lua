local zcollide = MM.require "Libs/zcollide"
local ticsuntilnograv = 6

states[freeslot("S_MM_SNOWBALL_B")] = {
	sprite = SPR_SNB9,
	frame = A|FF_ANIMATE|FF_SEMIBRIGHT,
	
	nextstate = S_MM_REVOLV_B
}

states[freeslot("S_MM_SNOWBALL_DIE")] = {
	sprite = SPR_NULL,
	frame = A,
	tics = 0,
	action = function(mo)
		local angle = mo.angle + ANGLE_90
		
		local spokes = 8
		local fa = FixedDiv(360*FU, spokes*FU)
		local speed = 6*mo.scale
		
		local rev_x = P_ReturnThrustX(nil, mo.angle, -mo.scale * 3)
		local rev_y = P_ReturnThrustY(nil, mo.angle, -mo.scale * 3)
		
		local floormode = false
		if mo.z <= mo.floorz
		or mo.z+mo.height >= mo.ceilingz
			floormode = true
		end
		
		for i = 1, spokes
			local my_ang = FixedAngle(fa * i)
			
			local spark = P_SpawnMobjFromMobj(mo, rev_y, rev_x,
				FixedDiv((41*mo.height)/48, mo.scale),
				MT_THOK
			)
			if not floormode
				P_InstaThrust(spark, angle, FixedMul(cos(my_ang), speed))
				spark.momz = FixedMul(sin(my_ang), speed)
				
				P_Thrust(spark, angle + ANGLE_90,
					speed / 3
				)
			else
				local sign = (mo.z+mo.height >= mo.ceilingz) and -1 or 1
				P_SetObjectMomZ(spark, speed * sign)
				P_InstaThrust(spark, my_ang, speed / 3)
			end
			
			spark.flags = $ &~MF_NOGRAVITY
			spark.fuse = TICRATE * 3
			spark.tics = spark.fuse
			spark.sprite = SPR_SNB9
			
			P_SetScale(spark, spark.scale * 2, true)
			spark.spritexscale = $ / 4
			spark.spriteyscale = $ / 4
			
			P_SetOrigin(spark, spark.x, spark.y, spark.z)
		end
	end	
}

mobjinfo[freeslot("MT_MM_SNOWBALL_BULLET")] = {
	radius = 24*FU,
	height = 24*FU,
	spawnstate = S_MM_SNOWBALL_B,
	flags = MF_NOGRAVITY,
	speed = 80*FRACUNIT,
	deathstate = S_MM_SNOWBALL_DIE
}

addHook("MobjThinker", function(mobj)
	if mobj and mobj.valid then
		local dead = false
		
		if mobj.state ~= S_MM_SNOWBALL_B then
			mobj.colorized = true
			mobj.color = SKINCOLOR_WHITE
			mobj.scalespeed = 1
			mobj.destscale = 2*FU
			
			mobj.momx = 0
			mobj.momy = 0
			mobj.momz = 0
			
			dead = true
		end
		
		mobj.snowball_tics = $ or 0
		mobj.snowball_tics = $ + 1
		
		if not dead then
			local thok = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_THOK)
			thok.state = S_MM_SNOWBALL_B
			thok.scalespeed = FRACUNIT/10
			thok.fuse = 15
			thok.destscale = 1
		end
		
		if mobj.snowball_tics >= ticsuntilnograv
		and (mobj.flags & MF_NOGRAVITY) then
			mobj.flags = $ & ~MF_NOGRAVITY
		end
		
		if (mobj.eflags & MFE_JUSTHITFLOOR) then
			P_ExplodeMissile(mobj)
		end
	end
end, MT_MM_SNOWBALL_BULLET)


addHook("MobjMoveCollide", function(tmthing, thing)
	if not (tmthing and tmthing.valid) then return end
	if not (thing and thing.valid) then return end
	if not zcollide(tmthing, thing) then return end
	if (tmthing.target and tmthing.target == thing) then return end
	if (thing.type ~= MT_PLAYER) then return end
	if (tmthing.state ~= S_MM_SNOWBALL_B) then return end
	
	local power = 30*FRACUNIT
	local punchangle = tmthing.angle
	
	P_Thrust(thing, punchangle, power)
	if (thing.player)
		P_MovePlayer(thing.player)
	end
	
	P_ExplodeMissile(tmthing)
end, MT_MM_SNOWBALL_BULLET)

addHook("MobjMoveBlocked", function(mobj)
	if mobj and mobj.valid then
		P_ExplodeMissile(mobj)
	end
end, MT_MM_SNOWBALL_BULLET)