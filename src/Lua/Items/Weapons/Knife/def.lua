local roles = MM.require "Variables/Data/Roles"

local weapon = {}

local MAX_COOLDOWN = TICRATE
local MAX_ANIM = MAX_COOLDOWN
local MAX_HIT = MAX_COOLDOWN/5

weapon.id = "knife"
weapon.category = "Weapon"
weapon.display_name = "Knife"
weapon.display_icon = "MM_KNIFE"
weapon.state = dofile "Items/Weapons/Knife/freeslot"
weapon.timeleft = -1
weapon.hit_time = 2
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE
weapon.range = FU*5
--you should be able to jump over and juke the murderer
weapon.zrange = FU
weapon.position = {
	x = FU,
	y = 0,
	z = 0
}
weapon.animation_position = {
	x = 0,
	y = FU,
	z = 0
}
weapon.stick = true
weapon.animation = true
weapon.damage = true
weapon.weaponize = true
weapon.latencyadjust = true
weapon.droppable = false
weapon.shootable = false
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_kequip
weapon.hitsfx = sfx_kffire
weapon.misssfx = sfx_kwhiff
weapon.allowdropmobj = false
weapon.showinfirstperson = false

local function resetposition(item)
	item.default_pos.x = weapon.position.x
	item.default_pos.y = weapon.position.y
	item.default_pos.z = weapon.position.z
	
	item.damage = weapon.damage
	item.mobj.frame = ($ &~FF_FRAMEMASK)
	item.showinfirstperson = false
	item.aimtrail = false
end

local function distchecks(item, p, target)
	local dist = R_PointToDist2(p.mo.x, p.mo.y, target.x, target.y)
	local maxdist = FixedMul(p.mo.radius + target.radius, item.range)

	if dist > maxdist
	or abs((p.mo.z + p.mo.height/2) - (target.z + target.height/2)) > FixedMul(max(p.mo.height, target.height), item.zrange or item.range)
	or not P_CheckSight(p.mo, target) then
		return false
	end

	--no need to check for angles if we're touchin the guy
	if dist > p.mo.radius + target.radius
		local adiff = FixedAngle(
			AngleFixed(R_PointToAngle2(p.mo.x, p.mo.y, target.x, target.y)) - AngleFixed(p.cmd.angleturn << 16)
		)
		if AngleFixed(adiff) > 180*FU
			adiff = InvAngle($)
		end
		if (AngleFixed(adiff) > 115*FU)
			return false
		end
	end
	
	return true
end

MM.addHook("ItemUse", function(p)
	local inv = p.mm.inventory
	local item = inv.items[inv.cur_sel]
	
	if item.id ~= "knife" then return end
	
	if item.altfiretime
		return true
	end
end)

--item_t btw, get mobj from item->mobj
local throw_tic = (TICRATE * 5/4)
local throw_sfx = sfx_cdfm35
local charge_vol = 255 * 3/5
weapon.thinker = function(item, p)
	if not (p and p.valid) then return end
	if p.mm.inventory.items[p.mm.inventory.cur_sel].cooldown
		resetposition(item)
		if item.throwcooldown
			item.throwcooldown = $ - 1
			item.mobj.alpha = (item.throwcooldown == 0) and FU or 0 
		end
		
		return
	end
	
	for p2 in players.iterate do
		if not (p2 ~= p
		and p2
		and p2.mo
		and p2.mo.health
		and p2.mm
		and not p2.mm.spectator) then continue end
		
		local dist = R_PointToDist2(p.mo.x, p.mo.y, p2.mo.x, p2.mo.y)
		local maxdist = FixedMul(p.mo.radius+p2.mo.radius, item.range)
		
		if (p2.mm.role == p.mm.role) then
			continue
		end
		
		if not distchecks(item,p,p2.mo) then continue end
		
		P_SpawnLockOn(p, p2.mo, S_LOCKON1)
	end
	
	if MMCAM
	and MMCAM.TOTALCAMS
		for k,cam in pairs(MMCAM.TOTALCAMS)
			if not (cam and cam.valid) then continue end
			if not (cam.health) then continue end
			if not (cam.args) then continue end
			if (cam.args.viewpoint) then continue end
			if not (cam.args.melee and cam.args.melee.valid) then continue end
			
			if not distchecks(item,p, cam.args.melee) then continue end
			
			P_SpawnLockOn(p, cam, S_LOCKON1)
		end
	end
	
	if item.altfiretime == nil then item.altfiretime = 0 end
	if item.throwcooldown == nil then item.throwcooldown = 0 end

	local charging = false
	if (p.cmd.buttons & BT_FIRENORMAL)
		if not item.release
			charging = true
		end
	else
		item.release = nil
	end
	
	if charging
	and not item.release
	and not item.throwcooldown
		if item.altfiretime == 0
			S_StartSound(nil, sfx_kcharg, p)
		end
		
		item.altfiretime = min($ + 1, throw_tic)
		item.damage = false
		item.hit = 0
		
		do --if not item.altfiretime == throw_tic
			if not (item.ghost and item.ghost.valid)
				local g = P_SpawnGhostMobj(item.mobj)
				g.tics = 12
				g.fuse = g.tics
				g.blendmode = AST_ADD
				g.renderflags = $|RF_FULLBRIGHT
				g.destscale = g.scale * 2
				g.scalespeed = FixedDiv(g.destscale - g.scale, g.fuse*FU)
				g.frame = $ &~FF_TRANSMASK
				item.ghost = g
				P_SetOrigin(item.ghost,
					item.mobj.x + p.mo.momx, item.mobj.y + p.mo.momy, item.mobj.z + p.mo.momz
				)
			else
				P_MoveOrigin(item.ghost,
					item.mobj.x + p.mo.momx, item.mobj.y + p.mo.momy, item.mobj.z + p.mo.momz
				)
				item.ghost.frame = $ &~FF_TRANSMASK
				item.ghost.angle = item.mobj.angle
			end
			--item.mobj.spriteyoffset = (item.altfiretime * FU*3/4)
			if item.mobj.sprite == states[weapon.state].sprite
				item.mobj.frame = ($ &~FF_FRAMEMASK)|B
			else
				item.mobj.frame = ($ &~FF_FRAMEMASK)
			end
			item.mobj.dontdrawforviewmobj = nil
			
			item.showinfirstperson = true
			item.default_pos.x = weapon.position.x - (item.altfiretime * FU/100)
			item.default_pos.y = -(item.altfiretime * FU/25)
			item.default_pos.z = (item.altfiretime * FU/50)
			item.aimtrail = true
		end
	else
		if item.altfiretime >= throw_tic
			item.release = true
			item.mobj.spriteyoffset = 0
			S_StartSound(p.mo, weapon.misssfx)
			S_StartSound(p.mo, weapon.misssfx)
			--play this from the missile instead
			--S_StartSoundAtVolume(p.mo, throw_sfx, 255 * 2/10)
			
			--throw
			p.mm.inventory.items[p.mm.inventory.cur_sel].cooldown = weapon.cooldown_time
			item.throwcooldown = weapon.cooldown_time - 1
			
			item.shootable = true
			item.shootmobj = MT_MM_KNIFE_PROJECT
			MM.FireBullet(p, MM.Items[item.id], item, p.mo.angle, p.aiming, false)
			item.shootable = false
			item.shootmobj = MT_NULL
			
			for k,bull in ipairs(item.bullets)
				if not (bull and bull.valid)
					table.remove(item.bullets,k)
					continue
				end
				bull.pitch = item.mobj.pitch
				bull.roll = item.mobj.roll
			end
			
			--fuckkkkk
            item.hit = 0
		end
		
		if item.altfiretime
		and item.altfiretime < throw_tic
			p.mm.inventory.items[p.mm.inventory.cur_sel].cooldown = TICRATE * 3/4
			S_StartSound(p.mo, sfx_kc50)
		end
		
		item.altfiretime = 0
		
		if item.ghost and item.ghost.valid
			P_RemoveMobj(item.ghost)
		end
		item.mobj.spriteyoffset = 0
		resetposition(item)
	end
end

weapon.unequip = function(item,p)
	if item.altfiretime
		item.cooldown = TICRATE * 3/4
		S_StartSound(p.mo, sfx_kc50)
	end
	item.altfiretime = 0
	item.release = true
	
	if item.ghost and item.ghost.valid
		P_RemoveMobj(item.ghost)
	end
	item.mobj.spriteyoffset = 0
	resetposition(item)
end
weapon.drop = weapon.unequip

--Whiff so people know youre bad at the game
weapon.onmiss = function(item,p)
	if not item.misssfx then return end
	S_StartSound(p.mo,item.misssfx)
end

weapon.drawer = function(v, p,item, x,y,scale,flags, selected, active)
	if item.throwcooldown == nil
	or item.altfiretime == nil
		return
	end
	
	local width = 32 * scale
	local height = 32 * scale
	local bottomy = y + height
	
	local timer = 0
	local maxtime = 0
	if item.throwcooldown
		timer = item.throwcooldown
		maxtime = weapon.cooldown_time - 1
	elseif item.altfiretime
		timer = item.altfiretime
		maxtime = throw_tic
	end
	
	if maxtime ~= 0
		local patch = v.cachePatch("1PIXELW")
		local stretch = FixedDiv(timer*FU, maxtime*FU)
		
		v.slideDrawStretched(x, bottomy - FixedMul(height, stretch),
			width, FixedMul(height, stretch), patch,
			(flags &~V_ALPHAMASK)|V_30TRANS
		)
	end
	
	--v.drawString(x,y, timer.."/"..maxtime, flags, "thin-fixed")
end

MM.MeleeWhiffFX = function(p)
	local me = p.mo
	
	if not (me and me.valid) then return end
	
	local angle = p.cmd.angleturn << 16
	local dist = 16*FU
	local whiff = P_SpawnMobjFromMobj(me,
		P_ReturnThrustX(nil,angle, dist) + me.momx,
		P_ReturnThrustY(nil,angle, dist) + me.momy,
		FixedDiv(me.height,me.scale)/2,
		MT_THOK
	)
	whiff.state = S_MM_KNIFE_WHIFF
	whiff.fuse = -1 --whiff.tics
	whiff.angle = angle
	whiff.renderflags = $|RF_NOSPLATBILLBOARD|RF_SLOPESPLAT
	whiff.scale = FixedMul($, tofixed("1.8"))
	whiff.height = 0
	
	local aiming = AngleFixed(p.aiming + ANGLE_90)
	--clamp so it doesnt distort so much
	aiming = max(50*FU,min(130*FU,$))
	aiming = FixedAngle($) - ANGLE_90
	
	P_CreateFloorSpriteSlope(whiff)
	local slope = whiff.floorspriteslope
	slope.o = {
		x = whiff.x, y = whiff.y, z = whiff.z
	}
	slope.zangle = aiming
	slope.xydirection = angle
	
	--wumbo steve
	whiff.spritexscale = whiff.scale
	whiff.spriteyscale = FixedMul(cos(slope.zangle), whiff.scale + (slope.zangle == ANGLE_90 - 1 and 1024 or 0))
	
	me.whiff_fx = whiff
end

weapon.attack = function(item,p)
	MM.MeleeWhiffFX(p)
	if MMCAM
	and MMCAM.TOTALCAMS
		for k,cam in pairs(MMCAM.TOTALCAMS)
			if not (cam and cam.valid) then continue end
			if not (cam.health) then continue end
			if not (cam.args) then continue end
			if (cam.args.viewpoint) then continue end
			if not (cam.args.melee and cam.args.melee.valid) then continue end
			
			if not distchecks(item,p, cam.args.melee) then continue end
			
			P_KillMobj(cam,item.mobj,me)
		end
	end
	
end

MM:addPlayerScript(function(p)
	local me = p.mo
	
	if not (me and me.valid) then return end
	if (me.flags & MF_NOTHINK) then return end
	
	if (me.whiff_fx and me.whiff_fx.valid)
		local angle = p.cmd.angleturn << 16
		local dist = 16*FU
		
		P_MoveOrigin(me.whiff_fx,
			me.x + P_ReturnThrustX(nil,angle, dist) + me.momx,
			me.y + P_ReturnThrustY(nil,angle, dist) + me.momy,
			me.z + (me.height/2)
		)
		me.whiff_fx.angle = angle
		
		local aiming = AngleFixed(p.aiming + ANGLE_90)
		--clamp so it doesnt distort so much
		aiming = max(50*FU,min(130*FU,$))
		aiming = FixedAngle($) - ANGLE_90
		
		local whiff = me.whiff_fx
		local slope = whiff.floorspriteslope
		slope.o = {
			x = whiff.x, y = whiff.y, z = whiff.z
		}
		slope.zangle = aiming
		slope.xydirection = angle
		
		--wumbo steve
		whiff.spritexscale = whiff.scale
		whiff.spriteyscale = FixedMul(cos(slope.zangle), whiff.scale + (slope.zangle == ANGLE_90 - 1 and 1024 or 0))
	end
end)

return weapon