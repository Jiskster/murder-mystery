local TR = TICRATE
local CAM_PANWAIT = 3*TR
local CAM_PANTIME = 2*TR

local CAM_3DFRAME = {
	attach = A,
	wire = H|FF_PAPERSPRITE,
	
	back = B|FF_PAPERSPRITE,
	side = D|FF_PAPERSPRITE,
	face = F|FF_PAPERSPRITE,
	top = E,
	bottom = C,
	view = I|FF_PAPERSPRITE|FF_FULLBRIGHT
}

--l,w,h
local CAM_DIMEN = {
	l = 14*FU,
	w = 24*FU,
	h = 12*FU,
	a = ANG20,
}

local debug = false
local freeslotted = false
local function dprint(...)
	if not debug then return end
	print(...)
end

local CamInteraction = MM.addInteraction(function(p,cam)
	if (p.mmcam.cam and p.mmcam.cam.valid) then return end
	
	local camlist = MMCAM.CAMS[cam.args.sequence]
	
	dprint("camera sequence "..cam.args.sequence)
	dprint("number of camrs "..(#camlist)+1)
	
	p.mmcam.fade = 32
	MMCAM.StartViewing(p,camlist[0])
end,"CameraInteraction")


addHook("MapChange",do
	MMCAM.CAMS = {}
	MMCAM.TOTALCAMS = {}
end)
addHook("NetVars",function(n)
	MMCAM.CAMS = n($)
	MMCAM.TOTALCAMS = n($)
end)

addHook("MapThingSpawn",function(cam,mt)
	local angle = FixedAngle(mt.angle*FU)
	local aiming = FixedAngle(mt.pitch*FU)
	local panwait = mt.args[5] ~= 0 and mt.args[5] or CAM_PANTIME
	
	cam.args = {
		viewpoint		=	(mt.args[0] == 1),
		sequence		=	(mt.args[1]),
		order			=	(mt.args[2]),
		
		pan				=	(mt.args[3] == 1),
		panamount		=	FixedAngle(mt.args[4]*FU),
		panduration		=	panwait,
		panwait			=	P_RandomRange(0,panwait),
		panstage		=	P_RandomChance(FU/2) and 1 or -1,
		panning			=	0,
		panstart		=	0,
		panadjust		=	0,
		firstpan		=	false,
		
		name			=	mt.stringargs[0] ~= '' and mt.stringargs[0] or nil,
		startangle		=	angle,
		aiming			=	aiming,
		active			=	false,
		players			=	{},
		scanlines		=	{},
		drawwires		=	(mt.args[7] ~= 1),
		dontdraw		=	(mt.args[6] == 1),
	}
	cam.dontdrawinteract = true
	cam.flags2 = $|MF2_DONTDRAW
	
	for i = 0,#players-1
		cam.args.players[i] = {}
	end
	
	if not cam.args.viewpoint
		if MMCAM.CAMS[cam.args.sequence] == nil
			MMCAM.CAMS[cam.args.sequence] = {}
		end
		MMCAM.CAMS[cam.args.sequence][cam.args.order] = cam
	end
	
	table.insert(MMCAM.TOTALCAMS,cam)
end,MT_MM_CAMERA)

addHook("MapLoad",do
	if (gamestate ~= GS_LEVEL) then return end
	
 	local totals = {
		seq = {}
	}
	
	for k,cam in ipairs(MMCAM.TOTALCAMS)
		local args = cam.args
		
		if totals.seq[args.sequence] == nil
			totals.seq[args.sequence] = {
				order = 0,
				cams = {}
			}
		end
		totals.seq[args.sequence].cams[args.order] = cam
		totals.seq[args.sequence].order = max($,args.order)
		
	end
	
	for k,seq in pairs(totals.seq)
		for i = 0, seq.order
			local cam = seq.cams[i]
			if not (cam and cam.valid)
				print("\x82WARNING\x80: Camera sequence "..k.." is missing camera "..i)
			end
			
		end
	end
end)

addHook("ThinkFrame",do
	if not CV_MM then return end
	debug = CV_MM.debug.value == 1
end)

local function Update3D(cam,args)
	
	if args.drawwires
		if not (args.wiretop and args.wiretop.valid)
			local thok = P_SpawnMobjFromMobj(cam,0,0,
				FixedDiv(cam.height,cam.scale),
				MT_THOK
			)
			thok.tics = -1
			thok.fuse = -1
			thok.sprite = SPR_MMCM
			thok.frame = CAM_3DFRAME.attach
			thok.renderflags = RF_FLOORSPRITE|RF_NOSPLATBILLBOARD
			thok.dontdrawforviewmobj = cam
			args.wiretop = thok
			
			P_SetOrigin(thok,thok.x,thok.y, cam.ceilingz)
			dprint("spawned wiretop")
		end
		
		if not (args.wireL and args.wireL.valid)
			local thok = P_SpawnMobjFromMobj(cam,0,0,
				FixedDiv(cam.height,cam.scale),
				MT_THOK
			)
			thok.tics = -1
			thok.fuse = -1
			thok.sprite = SPR_MMCM
			thok.frame = CAM_3DFRAME.wire
			thok.dontdrawforviewmobj = cam
			args.wireL = thok
			dprint("spawned wireL")
		end
		if not (args.wireR and args.wireR.valid)
			local thok = P_SpawnMobjFromMobj(cam,0,0,
				FixedDiv(cam.height,cam.scale),
				MT_THOK
			)
			thok.tics = -1
			thok.fuse = -1
			thok.sprite = SPR_MMCM
			thok.frame = CAM_3DFRAME.wire
			thok.angle = $ + ANGLE_90
			thok.dontdrawforviewmobj = cam
			args.wireR = thok
			dprint("spawned wireR")
		end
		
		local cz = P_MobjFlip(cam) == 1 and cam.ceilingz or cam.floorz
		local fz = P_MobjFlip(cam) == 1 and cam.z+cam.height or cam.z
		
		args.wireL.spriteyscale = FixedDiv(cz - fz, 12*cam.scale)
		args.wireR.spriteyscale = args.wireL.spriteyscale
	end
	
	--camera body
	do
		local origin = {
			x = P_ReturnThrustX(nil,cam.angle,5*FU),
			y = P_ReturnThrustY(nil,cam.angle,5*FU)
		}
		
		if not args.body
			args.body = {}
			if not (args.body.top)
				local thok = P_SpawnMobjFromMobj(cam,
					origin.x,origin.y,
					FixedDiv(cam.height,cam.scale),
					MT_THOK
				)
				thok.tics = -1
				thok.fuse = -1
				thok.sprite = SPR_MMCM
				thok.frame = CAM_3DFRAME.top
				thok.renderflags = RF_FLOORSPRITE|RF_NOSPLATBILLBOARD
				thok.angle = cam.angle - ANGLE_90
				thok.dontdrawforviewmobj = cam
				args.body.top = thok
			end
			if not (args.body.bottom)
				local thok = P_SpawnMobjFromMobj(cam,
					origin.x,origin.y,
					0,
					MT_THOK
				)
				thok.tics = -1
				thok.fuse = -1
				thok.sprite = SPR_MMCM
				thok.frame = CAM_3DFRAME.bottom
				thok.renderflags = RF_FLOORSPRITE|RF_NOSPLATBILLBOARD
				thok.angle = cam.angle - ANGLE_90
				thok.dontdrawforviewmobj = cam
				args.body.bottom = thok
			end
			if not (args.body.face)
				local thok = P_SpawnMobjFromMobj(cam,
					origin.x + P_ReturnThrustX(nil,cam.angle,CAM_DIMEN.w/2),
					origin.y + P_ReturnThrustY(nil,cam.angle,CAM_DIMEN.w/2),
					0,
					MT_THOK
				)
				thok.tics = -1
				thok.fuse = -1
				thok.sprite = SPR_MMCM
				thok.frame = CAM_3DFRAME.face
				thok.angle = cam.angle + ANGLE_90
				thok.dontdrawforviewmobj = cam
				args.body.face = thok
			end
			if not (args.body.back)
				local thok = P_SpawnMobjFromMobj(cam,
					origin.x - P_ReturnThrustX(nil,cam.angle,CAM_DIMEN.w/2),
					origin.y - P_ReturnThrustY(nil,cam.angle,CAM_DIMEN.w/2),
					0,
					MT_THOK
				)
				thok.tics = -1
				thok.fuse = -1
				thok.sprite = SPR_MMCM
				thok.frame = CAM_3DFRAME.back
				thok.angle = cam.angle + ANGLE_90
				thok.dontdrawforviewmobj = cam
				args.body.back = thok
			end
			for i = -1,1,2
				local thok = P_SpawnMobjFromMobj(cam,
					origin.x + P_ReturnThrustX(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/2),
					origin.y + P_ReturnThrustY(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/2),
					0,
					MT_THOK
				)
				thok.tics = -1
				thok.fuse = -1
				thok.sprite = SPR_MMCM
				thok.frame = CAM_3DFRAME.side
				thok.angle = cam.angle
				thok.dontdrawforviewmobj = cam
				if (i == -1)
					args.body.sideR = thok
				else
					args.body.sideL = thok
				end
			end
			
			for i = -1,1,2
				local ox = P_ReturnThrustX(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/4)
				local oy = P_ReturnThrustY(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/4)
				local thok = P_SpawnMobjFromMobj(cam,
					origin.x + P_ReturnThrustX(nil,cam.angle,CAM_DIMEN.w/2) + ox,
					origin.y + P_ReturnThrustY(nil,cam.angle,CAM_DIMEN.w/2) + oy,
					0,
					MT_THOK
				)
				thok.tics = -1
				thok.fuse = -1
				thok.sprite = SPR_MMCM
				thok.frame = CAM_3DFRAME.view
				thok.blendmode = AST_ADD
				thok.angle = cam.angle + (CAM_DIMEN.a*i)
				thok.color = SKINCOLOR_RED
				thok.rollangle = args.aiming
				thok.flags2 = $|MF2_DONTDRAW
				thok.dontdrawforviewmobj = cam
				if (i == -1)
					args.body.viewR = thok
				else
					args.body.viewL = thok
				end
			end
			
		--Update positions
		else
			origin.x,origin.y = $1 + cam.x, $2 + cam.y
			
			if (args.wiretop and args.wiretop.valid)
				P_SetOrigin(args.wiretop,cam.x,cam.y, cam.ceilingz)
			end
			
			P_MoveOrigin(args.body.top,
				origin.x,origin.y,
				cam.z + cam.height
			)
			args.body.top.angle = cam.angle - ANGLE_90
			
			P_MoveOrigin(args.body.bottom,
				origin.x,origin.y,
				cam.z
			)
			args.body.bottom.angle = cam.angle - ANGLE_90
			
			P_MoveOrigin(args.body.face,
				origin.x + P_ReturnThrustX(nil,cam.angle,CAM_DIMEN.w/2),
				origin.y + P_ReturnThrustY(nil,cam.angle,CAM_DIMEN.w/2),
				cam.z
			)
			args.body.face.angle = cam.angle + ANGLE_90
			if args.active
				args.body.face.frame = (CAM_3DFRAME.face &~FF_FRAMEMASK)|((((2*leveltime)/TICRATE) & 1) and G or F)
			else
				args.body.face.frame = CAM_3DFRAME.face
			end
			P_MoveOrigin(args.body.back,
				origin.x - P_ReturnThrustX(nil,cam.angle,CAM_DIMEN.w/2),
				origin.y - P_ReturnThrustY(nil,cam.angle,CAM_DIMEN.w/2),
				cam.z
			)
			args.body.back.angle = cam.angle + ANGLE_90
			
			for i = -1,1,2
				local part = (i == -1) and args.body.sideR or args.body.sideL
				
				P_MoveOrigin(part,
					origin.x + P_ReturnThrustX(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/2),
					origin.y + P_ReturnThrustY(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/2),
					cam.z
				)
				part.angle = cam.angle
			end
			
			for i = -1,1,2
				local part = (i == -1) and args.body.viewR or args.body.viewL
				local ox = P_ReturnThrustX(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/4)
				local oy = P_ReturnThrustY(nil,cam.angle + (ANGLE_90*i),CAM_DIMEN.l/4)
				
				P_MoveOrigin(part,
					origin.x + P_ReturnThrustX(nil,cam.angle,CAM_DIMEN.w/2) + ox,
					origin.y + P_ReturnThrustY(nil,cam.angle,CAM_DIMEN.w/2) + oy,
					cam.z
				)
				part.angle = cam.angle + (CAM_DIMEN.a*i)
				
				if args.active
					part.flags2 = $ &~MF2_DONTDRAW
				else
					part.flags2 = $|MF2_DONTDRAW
				end
			end
		end
		
	end
end

addHook("MobjThinker",function(cam)
	if not (cam and cam.valid) then return end
	local args = cam.args
	
	if not (args) then return end
	
	if debug
		cam.skin = "takisthefox"
		cam.sprite = SPR_PLAY
		cam.sprite2 = SPR2_STND
	else
		cam.flags2 = $|MF2_DONTDRAW
	end
	
	cam.pitch,cam.roll = 0,0
	
	if (args.viewpoint)
		for p in players.iterate
			MM.interactPoint(p, cam,
				"Cameras",
				"View",
				BT_CUSTOM3,
				TR/2,
				CamInteraction
			)
		end
		
		if debug
			do
				local bub = P_SpawnMobjFromMobj(cam,
					0,0,70*FU,
					MT_THOK
				)
				bub.fuse = -1
				bub.tics = 2
				bub.sprite = SPR_MMCD
				bub.frame = args.sequence|FF_FULLBRIGHT
				bub.color = SKINCOLOR_JET
			end
		end
		
		cam.color = SKINCOLOR_SALMON
		return
	end
	
	if debug
		if not (cam.arrow and cam.arrow.valid)
			local arrow = P_SpawnMobjFromMobj(cam,
				P_ReturnThrustX(nil,cam.angle,25*FU),
				P_ReturnThrustY(nil,cam.angle,25*FU),
				16*FU,
				MT_THOK
			)
			arrow.tics = -1
			arrow.fuse = -1
			arrow.sprite = SPR_THND
			arrow.angle = cam.angle
			arrow.frame = FF_PAPERSPRITE
			cam.arrow = arrow
		else
			cam.arrow.rollangle = args.aiming
		end
		
		do
			local bub = P_SpawnMobjFromMobj(cam,
				0,0,70*FU,
				MT_THOK
			)
			bub.fuse = -1
			bub.tics = 2
			bub.sprite = SPR_MMCD
			bub.frame = args.sequence|FF_FULLBRIGHT
			bub.color = SKINCOLOR_JET
			
			local bub = P_SpawnMobjFromMobj(cam,
				0,0,90*FU,
				MT_THOK
			)
			bub.fuse = -1
			bub.tics = 2
			bub.sprite = SPR_MMCD
			bub.frame = args.order|FF_FULLBRIGHT
			bub.color = SKINCOLOR_GALAXY
		end
	end
	
	if (args.pan)
		if not args.firstpan
			args.startangle = cam.angle
			args.firstpan = true
		end
		
		local dest2 = 0
		if not (args.panwait)
			if args.panning ~= CAM_PANTIME + 1
				local panstage = args.panstage ~= 2 and args.panstage or 0
				local dest = args.panamount * abs(panstage)
				dest2 = dest
				
				if panstage ~= 0
					args.panadjust = FixedAngle(ease.linear(
						(FU/CAM_PANTIME)*args.panning,
						AngleFixed(args.panstart),
						AngleFixed(dest)
					)) * (panstage == -1 and -1 or 1)
				else
					if args.panstage == 2
						args.panadjust = FixedAngle(ease.linear(
							(FU/CAM_PANTIME)*args.panning,
							AngleFixed(args.panstart),
							AngleFixed(dest)
						))
					else
						args.panadjust = FixedAngle(ease.linear(
							(FU/CAM_PANTIME)*args.panning,
							0,
							AngleFixed(args.panamount)
						)) - args.panamount
					end
				end
				
				args.panning = $+1
				
			else
				
				/*
					-1
					0
					1
					2 (0)
					repeat
				*/
				args.panstage = ($ + 1)
				if (args.panstage) == 3 then args.panstage = -1 end
				if (args.panstage) == 1 then args.panadjust = 0 end
				
				args.panwait = CAM_PANWAIT
				args.panning = 0
				args.panstart = args.panadjust
			end
		else
			args.panwait = max($-1,0)
		end
		cam.angle = args.startangle	+ args.panadjust
		
	end
	
	for i = 0,#players - 1
		local p = args.players[i]
		if not (p and p.valid) then continue end
		
		local mmc = p.mmcam
		
		if not mmc
		or mmc.cam ~= cam
		or not p.mo.health
			args.players[i] = nil
			continue
		end
	end
	
	/*
	if args.active
		cam.color = (((2*leveltime)/TICRATE) & 1) and SKINCOLOR_RED or SKINCOLOR_NONE
	else
		cam.color = SKINCOLOR_NONE
	end
	*/
	
	if P_RandomChance(FU/5)
	and (leveltime/4) % 4 == 0
		table.insert(args.scanlines,{
			height = P_RandomRange(3,8)*FU,
			tics = 8*TR,
			y = P_RandomRange(-10,0)*FU,
			momy = P_RandomFixed() + P_RandomFixed(),
		})
	end
	
	for k,scan in ipairs(args.scanlines)
		scan.tics = $ - 1
		if scan.tics == 0
			table.remove(args.scanlines,k)
			continue
		end
		scan.y = $ + scan.momy
	end
	
	if not args.dontdraw
		Update3D(cam,args)
	end
end,MT_MM_CAMERA)

addHook("PreThinkFrame",function(p)
for p in players.iterate
	
	if not (p.mmcam)
		MMCAM.Init(p)
		return
	end
	
	local mmc = p.mmcam
	
	mmc.fade = max($-2,0)
	if (mmc.cam and mmc.cam.valid)
		local cam = mmc.cam
		local args = cam.args
		local cmd = p.cmd
		
		
		p.awayviewmobj = cam
		p.awayviewtics = TR
		p.awayviewaiming = args.aiming
		
		p.pflags = $|PF_FULLSTASIS|PF_FORCESTRAFE
		p.powers[pw_nocontrol] = 1
		
		if (p.cmd.buttons & BT_USE)
		or not p.mo.health
		or (MM_N.gameover)
			MMCAM.StopViewing(p,mmc.cam)
			S_StartSound(nil,sfx_mmcam1,p)
			return
		end
		
		if #MMCAM.CAMS[mmc.sequence] >= 1
			if cmd.sidemove >= 20
				mmc.right = $ + 1
				mmc.left = 0
			else
				mmc.right = 0
			end
			if cmd.sidemove <= -20
				mmc.left = $ + 1
				mmc.right = 0
			else
				mmc.left = 0
			end
			
			if mmc.right == 1
				local mycams = MMCAM.CAMS[mmc.sequence]
				local nextindex = args.order + 1
				if not (mycams[nextindex] and mycams[nextindex].valid) then nextindex = 0 end
				local nextcam = mycams[nextindex]
				
				args.active = false
				args.players[#p] = nil
				MMCAM.StartViewing(p,nextcam)
				return
			end
			if mmc.left == 1
				local mycams = MMCAM.CAMS[mmc.sequence]
				local nextindex = args.order - 1
				if not (mycams[nextindex] and mycams[nextindex].valid) then nextindex = #mycams end
				local nextcam = mycams[nextindex]
				
				args.active = false
				args.players[#p] = nil
				MMCAM.StartViewing(p,nextcam)
				return
			end
		end
		args.active = true
		args.players[#p] = p
		
		p.cmd.buttons = 0
		p.mm.afkhelpers.keepalive = true
	else
		if (mmc.sequence)
			p.pflags = $ &~PF_FORCESTRAFE
		end
		
		mmc.cam = nil
		mmc.sequence = -1
	end

end
end)