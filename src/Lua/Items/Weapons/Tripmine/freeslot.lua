local TR = TICRATE
local function SafeFreeslot(...)
	for _, item in ipairs({...})
		if rawget(_G, item) == nil
			return freeslot(item)
		end
	end
end
local HITLAG_DURATION = TR/2
local HITLAG_JITTER = FU / 2

SafeFreeslot("SPR_TRIPMINEEXPLOSION")
SafeFreeslot("S_MM_TRIPMINE_EXPLODE")
states[S_MM_TRIPMINE_EXPLODE] = {
	sprite = SPR_TRIPMINEEXPLOSION,
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	action = function(mo)
		if (mo.ticker == nil) then mo.ticker = 0 end
		
		if not mo.set
			mo.radius,mo.height = 6*mo.scale,6*mo.scale
			mo.flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_RUNSPAWNFUNC|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT
			mo.anim_duration = 2
			mo.fuse = 22
			mo.set = true
			mo.flags2 = $ &~MF2_DONTDRAW
			mo.shadowscale = 0
			mo.mirrored = P_RandomChance(FU/2)
		else
			local oldframe = mo.frame &~FF_FRAMEMASK
			mo.frame = (mo.ticker/2)|oldframe
		end
		
		if mo.oldfx
			mo.flags = $ &~(MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPHEIGHT)
			mo.momz = $ + P_GetMobjGravity(mo)*3/2
			mo.frame = A|($ &~(FF_ANIMATE|FF_FRAMEMASK))
		end
		mo.ticker = $+1
		
		if leveltime % 3 == 0
		and mo.thought
		and mo.oldfx
			local new = P_SpawnMobjFromMobj(mo,0,0,0,MT_THOK)
			new.flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_RUNSPAWNFUNC
			new.state = S_MM_TRIPMINE_EXPLODE
			new.momz = 0
			new.flags2 = $ &~MF2_DONTDRAW
			new.color = mo.color
			new.colorized = mo.colorized
		else
		
		end
		mo.thought = true
	end,
	var1 = 13,
	var2 = 2,
	tics = 1,
	nextstate = S_MM_TRIPMINE_EXPLODE,
}

local function SpawnExplosions(mine, doquake, docount, colorized)
	if doquake
		P_StartQuake(30*FU, TICRATE*2,
			{mine.x, mine.y, mine.z},
			550*mine.scale
		)
	end
	
	local radius = 32*FU
	local minz = 10
	local maxz = 30
	
	local count = docount
    if count == nil then count = 25 end

	local anglecount = FixedDiv(360*FU,count*FU)
	for i = 0,count
		local fa = FixedAngle(anglecount*i)
        -- adjusted fixed angle
        local afa = fa + P_RandomRange(-360, 360)*ANG1

		local mobj = P_SpawnMobjFromMobj(mine,
			FixedMul(cos(afa),radius + P_RandomRange(0,10)*FU),
			FixedMul(sin(afa),radius + P_RandomRange(0,10)*FU),
			0, --FU - FixedMul(mobjinfo[type].height,tracer.scale)/2,
			MT_THOK
		)
		mobj.flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_RUNSPAWNFUNC
		mobj.state = S_MM_TRIPMINE_EXPLODE
		mobj.momz = 0
		--mobj.spritexscale,mobj.spriteyscale = FU*2,FU*2
		mobj.flags2 = $ &~MF2_DONTDRAW
		
		mobj.angle = R_PointToAngle2(mobj.x,mobj.y, mine.x,mine.y)
		mobj.scale = $+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))
		
		P_Thrust(mobj, mobj.angle,
			-6*mobj.scale
		)
		P_SetObjectMomZ(mobj,P_RandomRange(minz,maxz)*FU)
		mobj.oldfx = true
		if colorized ~= nil
			mobj.color = colorized
			mobj.colorized = true
		end
		
		local static = P_SpawnMobjFromMobj(mine,
			FixedMul(cos(fa),radius + P_RandomRange(0,10)*FU),
			FixedMul(sin(fa),radius + P_RandomRange(0,10)*FU),
			0,
			MT_THOK
		)
		static.flags = MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_RUNSPAWNFUNC
		static.state = S_MM_TRIPMINE_EXPLODE
		static.momz = 0
		static.flags2 = $ &~MF2_DONTDRAW
		
		static.angle = R_PointToAngle2(mobj.x,mobj.y, mine.x,mine.y)
		static.scale = $+(P_RandomFixed()*((P_RandomChance(FU/2)) and 1 or -1))
		
		P_Thrust(static, static.angle,
			-6*static.scale
		)
		if colorized ~= nil
			static.color = colorized
			static.colorized = true
		end
	end
end
MM.Tripmine_SpawnExplosions = SpawnExplosions

SafeFreeslot("SPR_SBSM")
sfxinfo[SafeFreeslot("sfx_subsma")].caption = "Mine activate"
sfxinfo[SafeFreeslot("sfx_subsme")] = {
	caption = "Explosion",
	flags = SF_X8AWAYSOUND
}
sfxinfo[SafeFreeslot("sfx_subsmt")].caption = "/"

states[SafeFreeslot("S_MM_TRIPMINE_HELD")] = {
	sprite = SPR_NULL,
	frame = A,
	tics = -1
}

states[SafeFreeslot("S_MM_TRIPMINE")] = {
	sprite = SPR_SBSM,
	frame = A,
	action = function(mine)
		mine.activatein = 2
		mine.activatewait = 0
		mine.primed = false
		mine.fade = 0
	end,
	tics = -1
}
mobjinfo[SafeFreeslot("MT_MM_TRIPMINE")] = {
	doomednum = -1,
	spawnstate = S_MM_TRIPMINE,
	deathsound = sfx_subsme,
	activesound = sfx_subsma,
	seesound = sfx_subsmt,
	spawnhealth = 1,
	height = 32*FRACUNIT,
	radius = 16*FRACUNIT,
	flags = MF_SOLID|MF_RUNSPAWNFUNC|MF_SHOOTABLE
}

local function ExplosionCompliment(mine)
	local sfx = P_SpawnGhostMobj(mine)
	sfx.fuse = 3 * TICRATE
	sfx.tics = sfx.fuse
	sfx.flags2 = $|MF2_DONTDRAW
	S_StartSound(sfx, sfx_mmdie0)
	S_StartSound(sfx, sfx_mmdie0)
	
	local a = mine.angle + ANGLE_45
	local spr_scale = FU * 2
	local tntstate = S_TNTBARREL_EXPL3
	local rflags = RF_PAPERSPRITE|RF_FULLBRIGHT|RF_NOCOLORMAPS
	local wavestate = S_FACESTABBERSPEAR
	local wavetime = TICRATE
	for i = 0,1
		local bam = P_SpawnMobjFromMobj(mine,0,0,0,MT_THOK)
		P_SetMobjStateNF(bam, tntstate)
		bam.spritexscale = FixedMul($, spr_scale)
		bam.spriteyscale = bam.spritexscale
		bam.renderflags = $|rflags
		bam.angle = a + ANGLE_90 * i
		
		bam.color = SKINCOLOR_GALAXY
		bam.colorized = true
		bam.blendmode = AST_SUBTRACT
		
		local wave = P_SpawnMobjFromMobj(mine,0,0,0,MT_THOK)
		P_SetMobjStateNF(wave, wavestate)
		wave.spritexscale = FixedMul($, spr_scale)
		wave.spriteyscale = wave.spritexscale
		wave.renderflags = $|rflags
		wave.angle = a + ANGLE_90 * i
		wave.tics = wavetime
		wave.fuse = wavetime
		wave.destscale = wave.scale * 6
		wave.scalespeed = FixedDiv(wave.destscale - wave.scale, wavetime*FU)
		
		wave.color = SKINCOLOR_GALAXY
		wave.colorized = true
		wave.blendmode = AST_ADD
	end
end

local function GetActorZ(actor,targ,type)
	if type == nil then type = 1 end
	if not (actor and actor.valid) then return 0 end
	if not (targ and targ.valid) then return 0 end
	
	local flip = P_MobjFlip(actor)
	
	--get z
	if type == 1
		if flip == 1
			return actor.z
		else
			return actor.z+actor.height-targ.height
		end
	--get top z
	elseif type == 2
		if flip == 1
			return actor.z+actor.height
		else
			return actor.z-targ.height
		end
		
	--RELATIVE
	--get z
	--since theres a good chance we're using these with P_SpawnMobjFromMobj,
	--make the distances absolute (FU, not mo.scale) since ^ already
	--does that
	elseif type == 3
		if flip == 1
			--ez
			return 0
		else
			return FixedDiv(actor.height-targ.height,actor.scale)
		end
	--get top z
	elseif type == 4
		if flip == 1
			return FixedDiv(actor.height,actor.scale)
		else
			return -FixedDiv(targ.height,actor.scale)
		end
	end
	
	return 0
end

local function delete3d(door)
	if not door.made3d
		return
	end
	
	if door.sides
		for k,v in pairs(door.sides)
			if v and v.valid
				P_RemoveMobj(v)
			end
		end
	end
	
	door.made3d = false
end

local numtotrans = {
	[10] = FF_TRANS90,
	[9] = FF_TRANS90,
	[8] = FF_TRANS80,
	[7] = FF_TRANS70,
	[6] = FF_TRANS60,
	[5] = FF_TRANS50,
	[4] = FF_TRANS40,
	[3] = FF_TRANS30,
	[2] = FF_TRANS20,
	[1] = FF_TRANS10,
	[0] = 0,
}
local TAKIS_3D_FLAGS = MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP|MF_SCENERY

local function ThreeDThinker(door)
	local trans = numtotrans[door.fade]
	if door.fade == 10
		delete3d(door)
		return
	end
	
	local x = 0
	local y = 0
	local z = 0
	local movefunc = P_MoveOrigin
	if door.markedfordeath ~= nil
		local offset = door.markedfordeath * HITLAG_JITTER
		if (leveltime & 1) then offset = -$ end
		
		x = $ + offset
		y = $ + offset
		z = $ + offset
		movefunc = P_SetOrigin
	end
	
	if not door.made3d
		local list
		local flip = P_MobjFlip(door)
		door.flags2 = $|MF2_DONTDRAW
		
		door.sides = {}
		list = door.sides
		
		for i = 1,4
			local angle = door.angle+(FixedAngle(90*FU*(i-1)))
			list[0+i] = P_SpawnMobjFromMobj(door,
				P_ReturnThrustX(nil,angle,16*FU),
				P_ReturnThrustY(nil,angle,16*FU),
				0,MT_RAY
			)
			list[0+i].frame = A|FF_FULLBRIGHT
			list[0+i].sprite = SPR_SBSM
			list[0+i].tics,list[0+i].fuse = -1,-1
			list[0+i].flags = TAKIS_3D_FLAGS
			list[0+i].renderflags = $|RF_PAPERSPRITE|RF_NOSPLATBILLBOARD
			list[0+i].angle = angle+ANGLE_90
			list[0+i].height = 32*FU
			list[0+i].radius = 0
			list[0+i].destscale = door.scale
			list[0+i].scalespeed = list[0+i].destscale + 1
			list[0+i].translation = door.translation
			P_SetOrigin(list[0+i],
				list[0+i].x + x,
				list[0+i].y + y,
				GetActorZ(door,list[0+i],1) + z
			)
		end
		list[7] = P_SpawnMobjFromMobj(door,0,0,0,MT_RAY)
		list[7].frame = C|FF_FULLBRIGHT
		list[7].sprite = SPR_SBSM
		list[7].tics,list[7].fuse = -1,-1
		list[7].flags = TAKIS_3D_FLAGS
		list[7].angle = door.angle
		list[7].height = door.height
		list[7].scale = door.scale
		list[7].destscale = door.destscale
		list[7].scalespeed = door.scalespeed
		list[7].translation = door.translation
		P_SetOrigin(list[7],
			list[7].x + x,
			list[7].y + y,
			GetActorZ(door,list[7],1) + z
		)
		
		door.made3d = true
	
	--update positions
	else
		local list = door.sides
		
		for i = 1,4
			local angle = door.angle+(FixedAngle(90*FU*(i-1)))
			list[0+i].angle = angle+ANGLE_90
			list[0+i].height = 32*FU
			list[0+i].radius = 0
			list[0+i].destscale = door.scale
			list[0+i].scalespeed = list[0+i].destscale + 1
			list[0+i].frame = ($ &~FF_TRANSMASK)|trans
			list[0+i].translation = door.translation
			movefunc(list[0+i],
				door.x+P_ReturnThrustX(nil,angle,16*door.scale) + door.momx + x,
				door.y+P_ReturnThrustY(nil,angle,16*door.scale) + door.momy + y,
				GetActorZ(door,list[0+i],1) + door.momz + z
			)
			
			if door.fade == 10
				list[0+i].flags2 = $|MF2_DONTDRAW
			end
		end
		
		list[7].angle = door.angle
		list[7].scale = door.scale
		list[7].frame = ($ &~FF_TRANSMASK)|trans
		list[7].translation = door.translation
		movefunc(list[7],
			door.x + door.momx + x,
			door.y + door.momy + y,
			GetActorZ(door,list[7],1) + door.momz + z
		)
		if door.fade == 10
			list[7].flags2 = $|MF2_DONTDRAW
		end
		
	end
	
end

addHook("MobjThinker",function(mine)
	if not (mine and mine.valid) then return end
	
	ThreeDThinker(mine)
	P_ButteredSlope(mine)
	
	if mine.markedfordeath
		mine.markedfordeath = $ - 1
		mine.fade = 0
		mine.translation = "Invert"
		mine.flags = $ &~MF_SHOOTABLE
		
		if mine.markedfordeath == 0
			P_KillMobj(mine, mine.deathvar[1], mine.deathvar[2])
			return
		end
		return true
	end
	
	if R_PointToDist2(0,0,mine.momx,mine.momy) <= 3*mine.scale
		if mine.activatein
			if not mine.activatewait
				S_StartSound(mine,mine.info.activesound)
				mine.activatewait = TR*3/2
				mine.activatein = $-1
				
				if mine.activatein == 0
					S_StartSound(mine,mine.info.seesound)
				end
			else
				mine.activatewait = $-1
			end
			
		end
		
	end
	
	if not mine.activatein
		if not mine.primed
			mine.flags = $|MF_SPECIAL
			mine.aura_ticker = 0
		end
		mine.primed = true
		
		if mine.fade < 10
		and (leveltime & 1)
			mine.fade = $+1
		end
	end
	
	if mine.fade == 10
		mine.aura_ticker = $+1
		
		local size = FU*3/2
		local maxtime = 45*TR
		if mine.aura_ticker > maxtime
			if (mine.aura and mine.aura.valid)
				P_RemoveFloorSpriteSlope(mine.aura)
				P_RemoveMobj(mine.aura)
				mine.aura = nil
			end
			return
		else
			size = ease.linear((FU/maxtime)*mine.aura_ticker, $, 1)
		end
		
		if not (mine.aura and mine.aura.valid)
			local aura = P_SpawnMobjFromMobj(mine,0,0,0,MT_THOK)
			aura.tics = -1
			aura.fuse = -1
			aura.renderflags = $|RF_FLOORSPRITE|RF_NOCOLORMAPS|RF_SLOPESPLAT|RF_OBJECTSLOPESPLAT
			aura.sprite = SPR_BGLS
			aura.frame = B|FF_FULLBRIGHT|FF_ADD|FF_TRANS60
			aura.scale = $
			aura.color = SKINCOLOR_GALAXY
			
			mine.aura = aura
		else
			local aura = mine.aura
			local mysin = sin(FixedAngle(mine.aura_ticker*5*FU))
			
			aura.spritexscale = size + mysin/5
			aura.spriteyscale = aura.spritexscale
			aura.color = SKINCOLOR_GALAXY
			aura.dispoffset = -5
			P_MoveOrigin(aura,
				mine.x,
				mine.y,
				mine.z + (FU/20)
			)
			
			if (mine.standingslope)
				if not aura.floorspriteslope
					P_CreateFloorSpriteSlope(aura)
				end
				local slope = aura.floorspriteslope
				local stand = mine.standingslope
				
				slope.o = {stand.o.x, stand.o.y, stand.o.z}
				slope.zangle = stand.zangle
				slope.xydirection = stand.xydirection
				
			elseif aura.floorspriteslope
				P_RemoveFloorSpriteSlope(aura)
			end
			
		end
	end
	
end,MT_MM_TRIPMINE)

local sparkle_fuse = TICRATE * 3
local roll_limit = 20

local function SpawnSparks(mo)
	for i = 12,P_RandomRange(20,25)
		local spark = P_SpawnMobjFromMobj(mo,
			P_RandomRange(-32,32)*FU,
			P_RandomRange(-32,32)*FU,
			FixedDiv(mo.height/2,mo.scale) + P_RandomRange(-16,16)*FU,
			MT_WKPL_SPARKLE
		)
		spark.tics = -1
		spark.alpha = 0
		spark.colorized = true
		spark.color = SKINCOLOR_MAJESTY
		spark.scale = $ + P_RandomFixed()/2
		
		spark.fuse = sparkle_fuse + P_RandomRange(-5, 5)
		spark.start = spark.fuse
		spark.threshold = P_RandomRange(-roll_limit, roll_limit) * ANG1
		
		P_Thrust(spark,
			R_PointToAngle2(spark.x,spark.y, mo.x,mo.y),
			spark.scale
		)
		P_SetObjectMomZ(spark,P_RandomRange(-1,1)*FU)
	end
end

local function SetPurplePlanes(mo)
	local fakerange = 256*mo.scale
	searchBlockmap("lines", function(ref, line)
		if line.frontside
			line.frontside.toptexture = R_TextureNumForName("VIOWALL")
			line.frontside.bottomtexture = line.frontside.toptexture
		end
		if line.backside
			line.backside.toptexture = R_TextureNumForName("VIOWALL")
			line.backside.bottomtexture = line.backside.toptexture
		--there is void behind this line
		else
			line.frontside.midtexture = R_TextureNumForName("VIOWALL")
		end
		
		if line.frontsector
			P_SpawnLightningFlash(line.frontsector)
			
			if line.frontsector.floorpic ~= "F_SKY1"
				line.frontsector.floorpic = "VIOWALL"
			end
			if line.frontsector.ceilingpic ~= "F_SKY1"
				line.frontsector.ceilingpic = "VIOWALL"
			end
			
			for fof in line.frontsector.ffloors()
				if fof.sector.floorpic ~= "F_SKY1"
					fof.sector.floorpic = "VIOWALL"
				end
				if fof.sector.ceilingpic ~= "F_SKY1"
					fof.sector.ceilingpic = "VIOWALL"
				end
				
				if fof.master.frontside
					fof.master.frontside.toptexture = R_TextureNumForName("VIOWALL")
					fof.master.frontside.bottomtexture = fof.master.frontside.toptexture
				end
				if fof.master.backside
					fof.master.backside.toptexture = R_TextureNumForName("VIOWALL")
					fof.master.backside.bottomtexture = fof.master.backside.toptexture
				--there is void behind this line
				else
					fof.master.frontside.midtexture = R_TextureNumForName("VIOWALL")
				end
			end
			
		end
		if line.backsector
			P_SpawnLightningFlash(line.backsector)
			
			if line.backsector.floorpic ~= "F_SKY1"
				line.backsector.floorpic = "VIOWALL"
			end
			if line.backsector.ceilingpic ~= "F_SKY1"
				line.backsector.ceilingpic = "VIOWALL"
			end
			
			for fof in line.backsector.ffloors()
				if fof.sector.floorpic ~= "F_SKY1"
					fof.sector.floorpic = "VIOWALL"
				end
				if fof.sector.ceilingpic ~= "F_SKY1"
					fof.sector.ceilingpic = "VIOWALL"
				end
				
				if fof.master.frontside
					fof.master.frontside.toptexture = R_TextureNumForName("VIOWALL")
					fof.master.frontside.bottomtexture = fof.master.frontside.toptexture
				end
				if fof.master.backside
					fof.master.backside.toptexture = R_TextureNumForName("VIOWALL")
					fof.master.backside.bottomtexture = fof.master.backside.toptexture
				--there is void behind this line
				else
					fof.master.frontside.midtexture = R_TextureNumForName("VIOWALL")
				end
			end
		end
	end, 
	mo,
	mo.x-fakerange, mo.x+fakerange,
	mo.y-fakerange, mo.y+fakerange)
	
end

addHook("TouchSpecial",function(mine,me)
	if not (mine and mine.valid) then return end
	if not (me and me.valid) then return end
	if not (me.health) then return end
	
	local p = me.player
	
	--dont kill our teammates lol
	if (p.mm.role == MMROLE_MURDERER
	and mine.tracer and mine.tracer.player.mm.role == MMROLE_MURDERER)
	and (me ~= mine.tracer)
		mine.health = mine.info.spawnhealth
		mine.flags = $|MF_SPECIAL|MF_SOLID
		
		mine.activatein = 1
		mine.fade = 0
		return true
	end
	
	local sfx = P_SpawnGhostMobj(mine)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 12*TR
	
	S_StartSound(sfx,mine.info.deathsound)
	S_StartSound(sfx,mine.info.deathsound)
	S_StartSound(sfx,mine.info.deathsound)
	
	if mine.aura and mine.aura.valid
		P_RemoveMobj(mine.aura)
	end
	
	if MM.Gametypes[MM_N.gametype].tamer_tripmine then
		P_DamageMobj(me, mine, (mine.tracer and mine.tracer.valid) and mine.tracer or mine, 999, DMG_INSTAKILL)
	else
		P_KillMobj(me,mine,mine.tracer,DMG_INSTAKILL)
	end
	
	me.color = SKINCOLOR_GALAXY
	me.stormkilledme = true
	me.colorized = true
	S_StartSound(me,mine.info.deathsound)
	
	SpawnSparks(mine)
	SpawnSparks(me)
	SetPurplePlanes(mine)
	SpawnExplosions(mine,true,nil,SKINCOLOR_GALAXY)
	ExplosionCompliment(mine)
	
	mine.steppedon = true
	delete3d(mine)
end,MT_MM_TRIPMINE)

addHook("MobjDeath",function(mine,_,src,dmgt)
	if (mine.steppedon) then return end
	if dmgt == DMG_CRUSHED
		mine.flags = $ &~MF_SHOOTABLE
		mine.markedfordeath = HITLAG_DURATION
		S_StartSound(mine, sfx_buzz3)
		mine.deathvar = {_,src}
		return true
	end

	local sfx = P_SpawnGhostMobj(mine)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.fuse = 12*TR
	
	S_StartSound(sfx,mine.info.deathsound)
	S_StartSound(sfx,mine.info.deathsound)
	S_StartSound(sfx,mine.info.deathsound)
	
	if mine.aura and mine.aura.valid
		P_RemoveMobj(mine.aura)
	end
	SpawnSparks(mine)
	SetPurplePlanes(mine)
	SpawnExplosions(mine,true,nil,SKINCOLOR_GALAXY)
	ExplosionCompliment(mine)
	delete3d(mine)
	
	local killing_player = (src and src.valid and src.player and src.player.valid) and src
	local radius = 550*mine.scale
	for p in players.iterate
		if (p.spectator) then continue end
		if not (p.mo and p.mo.valid) then continue end
		local me = p.mo
		if not (me.health) then continue end
		
		if abs(mine.x - me.x) > radius
		or abs(mine.y - me.y) > radius
		or abs(mine.z - me.z) > radius
			continue
		end

		--credit the sheriff if they killed the murderer
		local killer = mine.tracer
		if (p.mm.role == MMROLE_MURDERER)
		and (killing_player and killing_player.valid)
			--Bro
			if killing_player.player.mm.role == MMROLE_MURDERER
				continue
			end
			
			killer = killing_player
		end
		
		SpawnSparks(me)
		
		if MM.Gametypes[MM_N.gametype].tamer_tripmine then
			P_DamageMobj(me, mine, killer, 999, DMG_INSTAKILL)
		else
			P_KillMobj(me,mine, killer, DMG_INSTAKILL)
		end
		
		me.color = SKINCOLOR_GALAXY
		me.stormkilledme = true
		me.colorized = true
		S_StartSound(me,mine.info.deathsound)
	end
	
	searchBlockmap("objects", function(ref, me)
		if mine == me then return end
		if me.type ~= mine.type then return end
		if me.markedfordeath then return end
		
		if abs(mine.x - me.x) > radius
		or abs(mine.y - me.y) > radius
		or abs(mine.z - me.z) > radius
			return
		end
		
		me.markedfordeath = HITLAG_DURATION
		me.deathvar = {
			_, src
		}
		S_StartSound(me, sfx_buzz3)
	end, 
	mine,
	mine.x - radius, mine.x + radius,
	mine.y - radius, mine.y + radius)

end,MT_MM_TRIPMINE)

addHook("MobjRemoved",delete3d,MT_MM_TRIPMINE)

return S_MM_TRIPMINE_HELD