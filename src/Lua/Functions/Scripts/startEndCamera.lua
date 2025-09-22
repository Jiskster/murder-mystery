local STAGE_SWIRL = 0
local STAGE_INTERMEDIATE = 1
local STAGE_TOSHERIFF = 2

local function intervalhelper(t, d)
	return (min(t,d)*FU) / (max(d,1))
end

local function interval(t, s, d)
	return intervalhelper(max(t,s) - s, d)
end

local function follow(mobj, mul)
	/*
	P_MoveOrigin(mobj,
		mobj.origin[1] + P_ReturnThrustX(nil,mobj.angle,-mobj.lerpradius),
		mobj.origin[2] + P_ReturnThrustY(nil,mobj.angle,-mobj.lerpradius),
		mobj.z
	)
	*/

	mobj.flags = $ &~MF_NOCLIPHEIGHT
	P_MoveOrigin(mobj,
		mobj.origin[1], --+ P_ReturnThrustX(nil,mobj.angle,-mobj.lerpradius),
		mobj.origin[2], --+ P_ReturnThrustY(nil,mobj.angle,-mobj.lerpradius),
		mobj.startz
	)
	local maxmove = 32
	for i = 0,maxmove
		--shitty hack
		if MM_N.end_camera.free_noclip
		and (i <= maxmove/3)
			mobj.flags = $|MF_NOCLIP
		else
			mobj.flags = $ &~MF_NOCLIP
		end

		local move = (i == maxmove) and -mobj.lerpradius or FixedDiv(-mobj.lerpradius,maxmove*FU)*i
		move = FixedMul($, mobj.scale)

		P_TryMove(mobj,
			mobj.origin[1] + P_ReturnThrustX(nil,mobj.angle,move),
			mobj.origin[2] + P_ReturnThrustY(nil,mobj.angle,move),
			true
		)
	end

	mobj.flags = $|MF_NOCLIPHEIGHT
	P_MoveOrigin(mobj,
		mobj.x,
		mobj.y,
		--SRB2 is a GREAT game
		mobj.startz - 20*FU
	)
end

return function(self, origin, focusang, finalradius, panduration, panspeed)
	if not (MM_N.end_camera and MM_N.end_camera.valid)
		local angle = AngleFixed(focusang)
		
		MM_N.end_camera = P_SpawnMobjFromMobj(origin,
			/*
			P_ReturnThrustX(nil,focusang,-1200*FU),
			P_ReturnThrustY(nil,focusang,-1200*FU),
			*/
			0,0,
			origin.height,
			MT_THOK
		)
		MM_N.end_camera.tics = -1
		MM_N.end_camera.fuse = -1
		MM_N.end_camera.flags2 = $|MF2_DONTDRAW
		MM_N.end_camera.flags = MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOGRAVITY
		MM_N.end_camera.radius = 8*FU
		MM_N.end_camera.height = FU/2
		P_TryMove(MM_N.end_camera,
			origin.x + P_ReturnThrustX(nil,focusang,-1200*FU),
			origin.y + P_ReturnThrustY(nil,focusang,-1200*FU),
			true
		)
		
		MM_N.end_camera.origin = {origin.x,origin.y,origin.z + origin.height}
		MM_N.end_camera.startradius = {1200*FU,800*FU} --{horiz component, verti component}
		MM_N.end_camera.endradius = {finalradius, finalradius/2}
		MM_N.end_camera.lerpradius = MM_N.end_camera.startradius[1]
		MM_N.end_camera.startz = origin.z + (origin.height)
		MM_N.end_camera.scale = origin.scale
		
		MM_N.end_camera.swirldur = 3*TICRATE
		if MM_N.sniped_end then
			-- for music timing
			MM_N.end_camera.swirldur = 3*TICRATE + MM.sniper_theme_offset
		end
		MM_N.end_camera.swirl_stage = STAGE_SWIRL
		MM_N.end_camera.startangle = angle + 90*FU
		MM_N.end_camera.endangle = angle + 810*FU
		
		MM_N.end_camera.target = origin
		
		MM_N.end_camera.panduration = panduration
		MM_N.end_camera.panspeed = panspeed
		
		MM_N.end_camera.ticker = 0
		MM_N.end_camera.angle = R_PointToAngle2(MM_N.end_camera.x,MM_N.end_camera.y, origin.x,origin.y)
		
		MM_N.end_camera.endcamera = true
	--Move
	else
		local time = MM_N.end_camera.ticker
		local pan = ease.outquint(
			interval(time, MM_N.end_camera.swirldur, MM_N.end_camera.panduration),
			FU, 0
		)

		--this makes me sad
		local sheriff = 
			((MM_N.end_killed and MM_N.end_killed.valid and MM_N.end_killed.player and MM_N.end_killed.player.mm.role == MMROLE_MURDERER)
				and not (MM_N.end_killer and MM_N.end_killer.valid and MM_N.end_killer.health)
			)
			and MM_N.end_killed
			or MM_N.end_killer
		
		--death by suicide
		if not (sheriff and sheriff.valid and sheriff.health)
			sheriff = nil
		end
		
		if time <= MM_N.end_camera.swirldur
			if (MM_N.end_camera.swirl_stage == STAGE_SWIRL)
				local swirl = intervalhelper(time, MM_N.end_camera.swirldur)
				
				local ang = FixedAngle(swirl < FU/2 and
					ease.inoutquint(swirl, MM_N.end_camera.startangle, MM_N.end_camera.endangle) or
					ease.inoutquad(swirl, MM_N.end_camera.startangle, MM_N.end_camera.endangle)
				)
				local hdist = ease.outquad(swirl, MM_N.end_camera.startradius[1], MM_N.end_camera.endradius[1])
				
				/*
				local p = {
					x = MM_N.end_camera.origin[1] - FixedMul(cos(ang), hdist),
					y = MM_N.end_camera.origin[2] - FixedMul(sin(ang), hdist),
					z = MM_N.end_camera.origin[3] + ease.outquad(swirl, MM_N.end_camera.startradius[2], MM_N.end_camera.endradius[2])
				}
				*/
				
				MM_N.end_camera.lerpradius = hdist
				
				MM_N.end_camera.angle = ang - ANGLE_90
				MM_N.end_camera.ticker = $+1
				
				if MM_N.end_camera.ticker == MM_N.end_camera.swirldur
				--hold on the murderer
				and not MM_N.sniped_end
					MM_N.end_camera.ticker = 1
					MM_N.end_camera.swirl_stage = STAGE_INTERMEDIATE
					MM_N.end_camera.swirldur = TICRATE*3/2
					
				end
			--just wait
			elseif (MM_N.end_camera.swirl_stage == STAGE_INTERMEDIATE)
				
				MM_N.end_camera.ticker = $+1
				
				if MM_N.end_camera.ticker == MM_N.end_camera.swirldur
				and (sheriff and sheriff.valid)
					MM_N.end_camera.ticker = 1
					MM_N.end_camera.swirl_stage = STAGE_TOSHERIFF
					MM_N.end_camera.swirldur = TICRATE
					
					MM_N.end_camera.origin = {sheriff.x, sheriff.y, sheriff.z + sheriff.height}
					MM_N.end_camera.startradius[1] = R_PointToDist2(
						MM_N.end_camera.x,
						MM_N.end_camera.y,
						sheriff.x,
						sheriff.y
					)
					MM_N.end_camera.lerpradius = MM_N.end_camera.startradius[1]
					MM_N.end_camera.free_noclip = true
					
				end
			elseif (MM_N.end_camera.swirl_stage == STAGE_TOSHERIFF)
				local swirl = intervalhelper(time, MM_N.end_camera.swirldur)
				
				local hdist = ease.outquad(swirl, MM_N.end_camera.startradius[1], MM_N.end_camera.endradius[1])
				local vdist = ease.outquad(swirl, MM_N.end_camera.startz,
					(sheriff and sheriff.valid) and sheriff.z + sheriff.height or MM_N.end_camera.startz
				)
				if (sheriff and sheriff.valid)
					MM_N.end_camera.origin = {sheriff.x, sheriff.y, sheriff.z + sheriff.height}
				end
				
				MM_N.end_camera.lerpradius = hdist
				MM_N.end_camera.startz = vdist
				MM_N.end_camera.free_noclip = MM_N.end_camera.ticker <= MM_N.end_camera.swirldur/4
				MM_N.end_camera.scale = ease.outquad(swirl, $, (sheriff and sheriff.valid) and sheriff.scale or $)
				
				MM_N.end_camera.ticker = $+1
			end
		
		--keep updating our position to move to the sheriff's
		elseif (MM_N.end_camera.swirl_stage == STAGE_TOSHERIFF)
			local swirl = intervalhelper(time, MM_N.end_camera.swirldur)
			local vdist = ease.outquad(swirl, MM_N.end_camera.startz,
				(sheriff and sheriff.valid) and sheriff.z + sheriff.height or MM_N.end_camera.startz
			)
			if (sheriff and sheriff.valid)
				MM_N.end_camera.origin = {sheriff.x, sheriff.y, sheriff.z + sheriff.height}
			end
			
			MM_N.end_camera.startz = vdist
			MM_N.end_camera.free_noclip = MM_N.end_camera.ticker <= MM_N.end_camera.swirldur/4
			MM_N.end_camera.scale = ease.outquad(swirl, $, (sheriff and sheriff.valid) and sheriff.scale or $)
		end
		follow(MM_N.end_camera, FixedMul(pan, MM_N.end_camera.panspeed))
		
		--print(string.format("stage: %d %d %d startz: %f z: %f", MM_N.end_camera.swirl_stage, MM_N.end_ticker, MM_N.end_camera.ticker, MM_N.end_camera.startz, MM_N.end_camera.z))
		
	end
	
	for p in players.iterate
		p.awayviewmobj = MM_N.end_camera
		p.awayviewtics = 40*TICRATE
	end

	camera.chase = true
	if splitscreen then
		camera2.chase = true
	end
end
