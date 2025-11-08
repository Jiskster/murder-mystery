local ImportantStuff = {
	"storm_radius",
	"storm_destradius",
	"storm_ticker",
	"storm_timesmigrated",
	"storm_incre",
	"storm_graceperiod",
	"debuglasers",
	"lasers",
	"garg",
	"startpoint",
	"eased",
	"destpoint",
	"movecooldown",
	"otherpoints",
	"laser_splat",
	"laser_eye",
}
rawset(_G, "RF_ALWAYSONTOP", RF_ALWAYSONTOP or 0x00010000)
rawset(_G, "RF_HIDEINSKYBOX", RF_HIDEINSKYBOX or 0x00020000)

--when the starting radius is bigger than this, the storm will take
--longer to shrink to minimum radius
local BigRadius = 6144*FU
local STORM_STARTINGTIME = 15*TICRATE
local STORM_CLOSERADIUS = 612*FU

--Stores everything important stored in MM_N.storm_point
local function Backup(point)
	if MM_N.storm_backup == nil
		MM_N.storm_backup = {}
	end
	
	for k,v in ipairs(ImportantStuff)
		MM_N.storm_backup[k] = point[k]
	end
end

local function Restore(point)
	for k,v in pairs(MM_N.storm_backup)
		point[k] = v
	end
end

local function onPoint(point1,point2)
	/*
	print(string.format(
		"onPoint(): x1 = %f y1 = %f, x2 = %f y2 = %f",
		FixedFloor(point1.x),FixedFloor(point1.y),
		FixedFloor(point2.x),FixedFloor(point2.y)
		)
	)
	*/
	local x1,y1 = FixedFloor(point1.x),FixedFloor(point1.y)
	local x2,y2 = FixedFloor(point2.x),FixedFloor(point2.y)
	return (x1 >= x2 - FU and x1 <= x2 + FU) and (y1 >= y2 - FU and y1 <= y2 + FU)
end

local function SetDestRadius(point, time, dest)
	point.storm_destradius = dest
	point.storm_incre = point.storm_radius - ease.linear(FU/time,
		point.storm_radius,
		dest
	)
end

local function Init(point)
	if point.init then return end
	
	point.storm_radius = MM_N.storm_startingdist
	point.storm_destradius = MM_N.storm_usedpoints and MM_N.storm_startingdist/8 or 1028*FU
	point.storm_ticker = 0
	point.storm_timesmigrated = 0
	
	local totaltime = 0
	
	if mapheaderinfo[gamemap].mm_stormtimer ~= nil
	and tonumber(mapheaderinfo[gamemap].mm_stormtimer) ~= nil
		totaltime = abs(tonumber(mapheaderinfo[gamemap].mm_stormtimer))*TICRATE
	else
		totaltime = P_RandomRange(40,60)*TICRATE
		if point.storm_radius > BigRadius
			local percent = FixedDiv(point.storm_radius, BigRadius) * 18
			local result = FixedMul(TICRATE*FU, percent)
			--print(string.format("Added %f more seconds", FixedDiv(result,TICRATE*FU)))
			
			totaltime = $ + (result >> FRACBITS)
		end
	end
	
	if mapheaderinfo[gamemap].mm_stormtimer_overtime ~= nil
	and tonumber(mapheaderinfo[gamemap].mm_stormtimer_overtime) ~= nil
		totaltime = abs(tonumber(mapheaderinfo[gamemap].mm_stormtimer_overtime))*TICRATE
	else
		if (MM_N.overtime and not MM_N.showdown)
		or (MM_N.dueling)
			totaltime = $/2
		end
	end
	
	local grace = STORM_STARTINGTIME
	if mapheaderinfo[gamemap].mm_stormtimer_grace ~= nil
	and tonumber(mapheaderinfo[gamemap].mm_stormtimer_grace) ~= nil
		grace = abs(tonumber(mapheaderinfo[gamemap].mm_stormtimer_grace))*TICRATE
	end
	point.storm_graceperiod = grace
	
	SetDestRadius(point, totaltime, point.storm_destradius)
	
	point.init = true
end

local function SpawnLaser(point,i, debug, x,y, ang, scale, clr, rawangle, dist, lasersize)
	local mastertable = debug and point.debuglasers or point.lasers
	
	if (mastertable[i] == nil)
		local laser = P_SpawnMobjFromMobj(point,
			x - point.x,
			y - point.y,
			0,
			MT_THOK
		)
		if debug
			point.debuglasers[i] = laser
		else
			point.lasers[i] = laser
		end
		laser.myindex = i
		laser.tics = -1
		laser.fuse = -1
		laser.renderflags = $|RF_PAPERSPRITE|RF_NOCOLORMAPS|RF_HIDEINSKYBOX
		laser.blendmode = AST_ADD
		laser.sprite = SPR_BGLS
		laser.frame = A|FF_FULLBRIGHT
		laser.scale = scale
		laser.angle = ang + ANGLE_90
		laser.flags = $|MF_NOTHINK
		laser.radius = 40 * scale
	end
	local laser = mastertable[i]
	laser.angle = ang + ANGLE_90
	laser.color = clr
	laser.scale = scale
	
	local sec = R_PointInSubsector(x,y).sector --laser.subsector.sector
	
	--P_GetZAt(sec.c_slope, laser.x,laser.y,sec.ceilingheight or laser.ceilingz)
	local fz = sec and sec.floorheight --or laser.z
	local cz = sec and sec.ceilingheight --or laser.ceilingz
	
	if (sec.f_slope and sec.f_slope.valid)
		fz = P_GetZAt(sec.f_slope, laser.x,laser.y)
	end
	if (sec.c_slope and sec.c_slope.valid)
		cz = P_GetZAt(sec.c_slope, laser.x,laser.y)
	end
	
	P_MoveOrigin(laser, x,y, fz)
	
	local fade = FU
	do
		local starting = MM_N.storm_ticker < point.storm_graceperiod and FixedDiv(MM_N.storm_ticker*FU, point.storm_graceperiod*FU) or FU
		local dist = R_PointToDist(x,y)
		local nofade = false
		if (displayplayer and displayplayer.valid and displayplayer.realmo and displayplayer.realmo.valid)
			local m = displayplayer.realmo
			dist = min($, R_PointToDist2(m.x,m.y, x,y))
		end
		if dist <= max(lasersize*4*scale, 128*FU)
		and not nofade
			local fudge = FU/10
			fade = fudge + FixedMul(FixedDiv(dist, lasersize*4*scale), FU - fudge)
		end
		laser.alpha = FixedMul(starting,fade)
		
		laser.spriteyscale = FixedMul(
			FixedDiv(cz - fz, 10*laser.scale),
			starting
		)
		laser.height = FixedMul(cz - fz, starting)
		
		--handle colormap here too
		--CANT cause every sector needs a unique colormap for this to work....
		/*
		local galclr = skincolors[SKINCOLOR_GALAXY].ramp[4]
		local r,g,b = color.paletteToRgb(galclr)
		local cmap = P_GetSectorColormapAt(laser.subsector.sector,
			laser.x, laser.y, laser.z
		)
		if cmap
			cmap.red,cmap.green,cmap.blue = r,g,b
			cmap.alpha = 255
		end
		*/
	end
	
	if MM_N.gameover
		laser.spritexscale = max($ - FU/50, 0)
	end
	
	if (leveltime % 6 == 0)
	and not debug
	and not MM_N.gameover
		local fake_scale = scale
		if (scale > FU)
			fake_scale = max(0, $-FU)
		end
		local scale = FU + fake_scale
		
		for j = 0,1
			local dist = P_RandomRange(-40,40)*FU
			local dust = P_SpawnMobjFromMobj(laser,
				P_ReturnThrustX(nil, laser.angle, dist),
				P_ReturnThrustY(nil, laser.angle, dist),
				0,
				MT_ARIDDUST
			)
			
			if j == 1
				dust.eflags = $|MFE_VERTICALFLIP
			end
			
			dust.state = dust.info.spawnstate + P_RandomRange(0, 2)
			P_SetScale(dust, 3 * scale, true)
			P_SetOrigin(dust, dust.x, dust.y,
				j == 1 and (laser.z + laser.height - dust.height) or dust.z
			)
			
			dust.angle = rawangle + FixedAngle( ((MM_N.storm_ticker + 6)*FU) / 2 )
			P_Thrust(dust,dust.angle, 5 * scale)
			
			dust.color = laser.color
			dust.colorized = true
			dust.destscale = 1
			dust.scalespeed = FixedDiv(dust.scale, dust.tics * FU)
			dust.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
			if point.storm_radius <= STORM_CLOSERADIUS
				dust.alpha = max(FU/10,
					FixedDiv(point.storm_radius, STORM_CLOSERADIUS)
				)
			end
			dust.alpha = FixedMul($, fade)
			
			dust.momz = (P_RandomRange(1,4)*scale) * (j == 1 and -1 or 1)
		end
	end
	
	/*
	local move_layer = laser.tracer
	while (move_layer and move_layer.valid)
		P_MoveOrigin(move_layer,
			point.x + P_ReturnThrustX(nil, move_layer.angle, dist),
			point.y + P_ReturnThrustY(nil, move_layer.angle, dist),
			move_layer.z
		)
		P_SetScale(move_layer, scale, true)
		
		move_layer.angle = $ + ANG10 / 2
		
		move_layer.momx = laser.momx
		move_layer.momy = laser.momy
		
		move_layer = move_layer.tracer
	end
	
	if (leveltime % 24 == 0)
		for i = 0, 3
			local fa = i * ANGLE_90
			local px = point.x + P_ReturnThrustX(nil, fa, dist)
			local py = point.y + P_ReturnThrustY(nil, fa, dist)
			local pz = laser.z
			
			local layer = P_SpawnMobj(
				px,py,pz,
				MT_DUSTLAYER
			)
			if not (layer and layer.valid) then continue end
			
			P_SetScale(layer, scale, true)
			layer.momz = 7*scale
			layer.angle = ANGLE_90 + fa
			layer.extravalue1 =  3*TICRATE
			layer.fuse = layer.extravalue1
			layer.tics = layer.extravalue1
			
			layer.color = laser.color
			layer.colorized = true
			
			layer.tracer = laser.tracer
			laser.tracer = layer
		end
	end
	*/
	
	--okay ig... there could be a better way to do this
	if not S_SoundPlaying(laser,sfx_laser)
	and not MM_N.gameover
		S_StartSound(laser,sfx_laser)
	end
end

local function SpawnDebugLasers(point,dist)
	if not CV_MM.debug.value
		if (point.debuglasers ~= nil)
			for k,laser in ipairs(point.debuglasers)
				P_RemoveMobj(laser)
			end
			point.debuglasers = nil
		end
		return
	end
	
	point.debuglasers = $ or {}
	
	local numlasers = 32
	local angoff = 360*FU / numlasers
	local laserspace = 110
	local ticker_offset = FixedAngle((MM_N.storm_ticker*FU)/2)
	
	local circ = FixedMul((22*FU/7), dist*2)
	local scale = circ / laserspace / numlasers
	scale = max(abs($),FU/50)
	
	for i = 1,numlasers
		local ang = FixedAngle((i-1)*angoff) - FixedAngle((leveltime*FU)/2)
		local x = point.x + P_ReturnThrustX(nil,ang, dist)
		local y = point.y + P_ReturnThrustY(nil,ang, dist)
		
		SpawnLaser(point,i, true, x,y, ang, scale, SKINCOLOR_GREEN, FixedAngle((i-1)*angoff), dist, laserspace)
	end
end

local laser_colors = {
	SKINCOLOR_GALAXY,
	SKINCOLOR_VAPOR,
	SKINCOLOR_DUSK,
	SKINCOLOR_MAJESTY,
	SKINCOLOR_PASTEL,
	SKINCOLOR_PURPLE,
	SKINCOLOR_NOBLE,
	SKINCOLOR_MIDNIGHT,
	SKINCOLOR_LAVENDER,
	SKINCOLOR_SUPERPURPLE5,
}

local function SpawnAllLasers(point,dist)
	if dist <= 0
		if (point.lasers ~= nil)
			for k,laser in ipairs(point.lasers)
				P_RemoveMobj(laser)
			end
			point.lasers = nil
		end
		return
	end
	
	point.lasers = $ or {}
	
	local numlasers = 32
	local angoff = 360*FU / numlasers
	local laserspace = 110
	local ticker_offset = FixedAngle((MM_N.storm_ticker*FU)/2)
	
	local circ = FixedMul((22*FU/7), dist*2)
	local scale = circ / laserspace / numlasers
	scale = max(abs($),FU/50)
	
	local color = SKINCOLOR_SUPERPURPLE1 + abs(((MM_N.storm_ticker>>1)%9)-4) --laser_colors[P_RandomRange(1, #laser_colors)]
	for i = 1,numlasers
		local ang = FixedAngle((i-1)*angoff) + ticker_offset
		local x = point.x + P_ReturnThrustX(nil,ang, dist)
		local y = point.y + P_ReturnThrustY(nil,ang, dist)
		
		SpawnLaser(point,i, false, x,y, ang, scale, color, FixedAngle((i-1)*angoff), dist, laserspace)
	end
end

local function FXHandle(point,dist)
	
	SpawnAllLasers(point,dist)
	SpawnDebugLasers(point,MM_N.storm_startingdist)
	
	if not (point.laser_eye and point.laser_eye.valid)
		point.laser_eye = P_SpawnMobjFromMobj(point,0,0,0,MT_THOK)
		local laser = point.laser_eye
		laser.tics = -1
		laser.fuse = -1
		laser.renderflags = $|RF_NOCOLORMAPS
		laser.sprite = SPR_BGLS
		laser.frame = A|FF_FULLBRIGHT
		laser.scale = $
		laser.blendmode = AST_ADD
	end
	
	if not (point.laser_splat and point.laser_splat.valid)
		point.laser_splat = P_SpawnMobjFromMobj(point,0,0,0,MT_THOK)
		local laser = point.laser_splat
		laser.tics = -1
		laser.fuse = -1
		laser.renderflags = $|RF_FLOORSPRITE|RF_NOCOLORMAPS
		laser.sprite = SPR_BGLS
		laser.frame = B|FF_FULLBRIGHT
		laser.scale = $
		laser.dispoffset = -25
		laser.blendmode = AST_ADD
	end
	
	--people like to hide behind these so dont let em do that
	local mysin = sin(FixedAngle(MM_N.storm_ticker*5*FU))
	local fade = max(FixedDiv(mysin + FU, 2*FU), FU/4)
	
	do
		local laser = point.laser_eye
		do
			local cz = laser.subsector.sector and laser.subsector.sector.ceilingheight or P_CeilingzAtPos(laser.x,laser.y,laser.ceilingz, 20*FU)
			local fz = laser.z --P_FloorzAtPos(laser.x,laser.y,20*FU)
			laser.spriteyscale = FixedDiv(cz - fz, 10*laser.scale)
		end
		laser.spritexscale = FU + mysin/5
		laser.color = SKINCOLOR_GALAXY
		laser.dispoffset = -4
		laser.alpha = fade
		P_MoveOrigin(laser,
			point.x,
			point.y,
			point.z
		)
	end
	do
		local laser = point.laser_splat
		laser.spritexscale = FU + mysin/5
		laser.spriteyscale = laser.spritexscale
		laser.color = SKINCOLOR_GALAXY
		laser.dispoffset = -5
		laser.alpha = fade
		P_MoveOrigin(laser,
			point.x,
			point.y,
			point.z + (FU/20)
		)
	end
	if (point.garg and point.garg.valid)
		point.garg.spriteyoffset = ease.inoutquad(FU/4,$, 32*FU + (mysin/3)*20)
		P_MoveOrigin(point.garg,
			point.x,
			point.y,
			point.z
		)
		point.garg.angle = point.angle
		point.garg.pitch = 0
		point.garg.roll = 0
		point.garg.shadowscale = 0
	else
		local garg = P_SpawnMobjFromMobj(
			point,
			0,0,0,
			MT_GARGOYLE
		)
		garg.flags = MF_NOCLIPTHING
		garg.colorized = true
		garg.color = SKINCOLOR_GALAXY
		garg.angle = point.angle
		garg.frame = ($ &~FF_FRAMEMASK)|B|FF_SEMIBRIGHT
		point.garg = garg
	end

end

return function(self)
	local point = MM_N.storm_point
	
	if not (point and point.valid) then return end
	
	if (MM:pregame()) then MM_N.storm_backup = nil; return end
	
	--Uh oh
	if not (point and point.valid)
		--lets just HOPE the gargoyle is valid and spawn from there
		local newpoint = P_SpawnMobj(
			MM_N.storm_garg.x,
			MM_N.storm_garg.y,
			MM_N.storm_garg.z,
			MT_THOK
		)
		newpoint.state = S_THOK
		newpoint.tics = -1
		newpoint.fuse = -1
		newpoint.flags2 = $|MF2_DONTDRAW
		newpoint.flags = MF_NOCLIPTHING
		newpoint.garg = MM_N.storm_garg
		MM_N.storm_point = newpoint
		point = MM_N.storm_point
		
		Restore(point)
	end
	
	Init(point)
	Backup(point)
	
	if MM_N.storm_ticker == 0
		for sec in sectors.iterate
			if sec.ceilingpic == "F_SKY1" then continue end
			sec.flags = $|(1<<6) --MSF_INVERTPRECIP
		end
	end
	
	MM_N.storm_ticker = $+1
	
	if (point.storm_radius ~= point.storm_destradius)
	and (MM_N.overtime or MM_N.showdown)
		local storm_incre = point.storm_incre
		if not (MM_N.time)
		and not MM_N.showdown
			storm_incre = $*2
		end
		
		if point.storm_destradius > point.storm_radius
			point.storm_radius = $ - storm_incre
			point.storm_radius = min($,point.storm_destradius)
		elseif point.storm_radius > point.storm_destradius
			point.storm_radius = $ - storm_incre
			point.storm_radius = max($,point.storm_destradius)
		end
	end
	
	local dist = point.storm_radius
	FXHandle(point,dist)
	
	if MM_N.gameover then return end
	
	for p in players.iterate
		if not p.mm then continue end
		if p.spectator
		or (p.playerstate ~= PST_LIVE)
		or not (p.mo and p.mo.valid)
		--Move this here because otherwise we would never be considered
		--in bounds during the endcam, eventually killing us
		or MM_N.gameover
			p.mm.outofbounds = false
			p.mm.oob_dist = 0
			continue
		end
		
		p.mm.lastoob = p.mm.outofbounds
		p.mm.ouofbounds = false
		p.mm.oob_lenient = MM_N.storm_ticker <= point.storm_graceperiod
		
		local me = p.mo
		
		local pDist = R_PointToDist2(me.x,me.y, point.x,point.y)
		p.mm.oob_dist = pDist
		
		if pDist > dist - p.mo.radius
			p.mm.outofbounds = true
			
			if not p.mm.lastoob
				S_StartSound(me,P_RandomRange(sfx_mmste0,sfx_mmste1),p)
				P_SwitchWeather(PRECIP_STORM,p) --lul
			end
		else
			if p.mm.lastoob
				S_StartSound(me,P_RandomRange(sfx_mmstl0,sfx_mmstl2),p)
				P_SwitchWeather(MM_N.map_weather,p)
				S_StopSoundByID(p.mo,sfx_rainin)
			end
			
			p.mm.outofbounds = false
		end
	end

	if point.storm_radius ~= point.storm_destradius then return end
	if point.otherpoints == nil or #point.otherpoints < 2 then return end
	
	if point.movecooldown ~= nil
		if point.movecooldown
			point.movecooldown = $-1
			if point.movecooldown == 0
				MMHUD:PushToTop(8*TICRATE,
					"\x89Storm eye Migrating"
				)
				S_StartSound(nil,sfx_mmsmig)
			else
				return
			end
		end
	else
		point.movecooldown = 10*TICRATE
		MMHUD:PushToTop(8*TICRATE,
			"\x89Storm eye Migrates in",
			"\x82".."10\x80 seconds"
		)
		S_StartSound(nil,sfx_alarm)
		return
	end
	
	if not (point.destpoint)
		point.eased = 0
		point.destpoint = point.otherpoints[P_RandomRange(1,#point.otherpoints)]
		point.startpoint = {
			x = point.x,
			y = point.y,
			z = point.z,
			a = point.angle
		}
	end
	if onPoint(point,point.destpoint)
	and not point.movecooldown
		repeat
			point.destpoint = point.otherpoints[P_RandomRange(1,#point.otherpoints)]
		until not onPoint(point,point.destpoint)
		point.eased = 0
		point.startpoint = {
			x = point.x,
			y = point.y,
			z = point.z,
			a = point.angle
		}
		
		--wait before moving again...
		point.movecooldown = 10*TICRATE
		MMHUD:PushToTop(8*TICRATE,
			"\x89Storm eye Migrates in",
			"\x82".."10\x80 seconds"
		)
		S_StartSound(nil,sfx_alarm)
		
		SetDestRadius(point, 5*TICRATE, point.storm_destradius/2)
		return
	end
	
	local nextpoint = point.destpoint
	local easetics = 35*TICRATE
	local frac = min((FU/easetics)*point.eased,FU)
	local x = ease.inoutquad(frac, point.startpoint.x, nextpoint.x)
	local y = ease.inoutquad(frac, point.startpoint.y, nextpoint.y)
	local z = ease.inoutquad(frac, point.startpoint.z, nextpoint.z)
	P_MoveOrigin(point,
		x,y,z
	)
	point.angle = FixedAngle(
		ease.inoutquad(frac,
			AngleFixed(point.startpoint.a),
			AngleFixed(nextpoint.a)
		)
	)
	point.eased = $+1
	
end