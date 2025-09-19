local weapon = {}

local MAX_COOLDOWN = TICRATE
local MAX_ANIM = MAX_COOLDOWN
local MAX_HIT = MAX_COOLDOWN/3

weapon.id = "hotpotato"
weapon.category = "Weapon"
weapon.display_name = "Hot Potato"
weapon.display_icon = "MM_HOTPOTATO"
weapon.state = dofile "Items/Weapons/HotPotato/freeslot"
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE
weapon.range = FU*5
weapon.zrange = FU*2
weapon.position = {
	x = FU,
	y = 0,
	z = 0
}
weapon.animation_position = {
	x = 0,
	y = (FU/10)*8,
	z = FU/3
}
weapon.stick = true
weapon.animation = true
weapon.damage = false
weapon.weaponize = true
weapon.droppable = false
weapon.allowdropmobj = false
weapon.shootable = false
weapon.nostrafe = false
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_None
weapon.attacksfx = sfx_None
weapon.potato_start_time = 20*TICRATE
weapon.onlyhitone = true
weapon.cantouch = true

local function boom(p)
	MM.Tripmine_SpawnExplosions(p.mo, false, 10)
	P_StartQuake(60*FU, TICRATE * 3/4, {p.realmo.x, p.realmo.y, p.realmo.z}, 512*FU)
	
	local sfx = P_SpawnGhostMobj(p.mo)
	sfx.fuse = 3 * TICRATE
	sfx.tics = sfx.fuse
	sfx.flags2 = $|MF2_DONTDRAW
	S_StartSound(sfx, sfx_mmdie0)
	S_StartSound(sfx, sfx_mmdie0)
	
	local a = p.mo.angle + ANGLE_45
	local spr_scale = FU
	local tntstate = S_TNTBARREL_EXPL3
	local rflags = RF_PAPERSPRITE|RF_FULLBRIGHT|RF_NOCOLORMAPS
	local wavestate = S_FACESTABBERSPEAR
	local wavetime = TICRATE
	for i = 0,1
		local bam = P_SpawnMobjFromMobj(p.mo,0,0,0,MT_THOK)
		P_SetMobjStateNF(bam, tntstate)
		bam.spritexscale = FixedMul($, spr_scale)
		bam.spriteyscale = bam.spritexscale
		bam.renderflags = $|rflags
		bam.angle = a + ANGLE_90 * i
		
		bam.color = p.skincolor
		bam.colorized = true
		bam.blendmode = AST_SUBTRACT
		
		local wave = P_SpawnMobjFromMobj(p.mo,0,0,0,MT_THOK)
		P_SetMobjStateNF(wave, wavestate)
		wave.spritexscale = FixedMul($, spr_scale)
		wave.spriteyscale = wave.spritexscale
		wave.renderflags = $|rflags
		wave.angle = a + ANGLE_90 * i
		wave.tics = wavetime
		wave.fuse = wavetime
		wave.destscale = wave.scale * 6
		wave.scalespeed = FixedDiv(wave.destscale - wave.scale, wavetime*FU)
		
		wave.color = p.skincolor
		wave.colorized = true
		wave.blendmode = AST_ADD
	end
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

local function countdown(p, item)
	local mo = p.mo
	
	if not (mo and mo.valid) then
		return end;
	
	if mo.hotpotato_timer and mo.hotpotato_lastframe ~= leveltime then
		local owner
		if item.owner then
			owner = item.owner
		end
		local owner_mo
		if owner and owner.mo and owner.mo.valid then
			owner_mo = owner.mo
		end
		
		mo.hotpotato_timer = max(0, $ - 1)
		item.timeleft = mo.hotpotato_timer + 1 -- add one so it doesn't delete before it explodes
		if item.timeleft <= 0 then
			item.timeleft = nil
		end
		
		if (mo.hotpotato_timer <= 0) then
			boom(p)
			
			local radius = 340*mo.scale
			for p in players.iterate
				if (p.spectator) then continue end
				if not (p.mo and p.mo.valid) then continue end
				local me = p.mo
				if not (me.health) then continue end
				
				/*
				if abs(mo.x - me.x) > radius
				or abs(mo.y - me.y) > radius
				or abs(mo.z - me.z) > radius
					continue
				end
				*/
				if (FixedHypot(FixedHypot(me.x - mo.x, me.y - mo.y), me.z - mo.z) > radius)
					continue
				end
				
				P_KillMobj(me, owner_mo, owner_mo, DMG_INSTAKILL)
			end
			
			local redghost = mo.hotpotato_redghost
			
			if redghost and redghost.valid then
				P_RemoveMobj(redghost)
			end
	
			return
		end
		
		if (mo.hotpotato_timer > 5*TICRATE + TICRATE/2) then
			if (mo.hotpotato_timer % TICRATE) == 0 then
				mo.hotpotato_redghost = P_SpawnGhostMobj(mo)
				local redghost = mo.hotpotato_redghost
				
				if redghost and redghost.valid then
					redghost.fuse = 10
					redghost.colorized = true
					redghost.color = SKINCOLOR_RED
				end
				
				S_StartSound(mo, sfx_gbeep)			
			end
		else
			if (mo.hotpotato_timer % 12) == 0 then
				mo.hotpotato_redghost = P_SpawnGhostMobj(mo)
				local redghost = mo.hotpotato_redghost
				
				if redghost and redghost.valid then
					redghost.fuse = 5
					redghost.colorized = true
					redghost.color = SKINCOLOR_RED
				end
				
				S_StartSound(mo, sfx_gbeep)			
			end
		end
		
		local redghost = mo.hotpotato_redghost
		
		if redghost and redghost.valid then
			P_MoveOrigin(redghost, mo.x + mo.momx, mo.y + mo.momy, mo.z + mo.momz)
			redghost.state = mo.state
			redghost.frame = mo.frame
		end
	end
	
	mo.hotpotato_lastframe = leveltime -- so it doesn't repeat function in same frame.
end

weapon.thinker = function(item, p)
	for p2 in players.iterate do
		if not (p2 ~= p
		and p2
		and p2.mo
		and p2.mo.health
		and p2.mm
		and not p2.mm.spectator) then continue end
		
		local dist = R_PointToDist2(p.mo.x, p.mo.y, p2.mo.x, p2.mo.y)
		local maxdist = FixedMul(p.mo.radius+p2.mo.radius, item.range)
		
		if not distchecks(item,p,p2.mo) then continue end
		
		P_SpawnLockOn(p, p2.mo, S_LOCKON1)
		break
	end
	
	countdown(p, item)
end

weapon.hiddenthinker = function(item, p)
	countdown(p, item)
end

function weapon:onhit(player, player2)
	local mo1 = player.mo
	local mo2 = player2.mo

	if (player.mm and player2.mm) and
	(mo1 and mo1.valid) and
	(mo2 and mo2.valid) then
		mo2.hotpotato_timer = mo1.hotpotato_timer or weapon.potato_start_time
		mo1.hotpotato_timer = 0
		
		local senditem = MM:GiveItem(player2, "hotpotato")
		
		if not senditem then
			return end;	
		
		senditem.timeleft = mo2.hotpotato_timer + 1
		senditem.owner = self.owner
		
		MM:ClearInventorySlot(player)
		
		local redghost = mo1.hotpotato_redghost
		
		if redghost and redghost.valid then
			P_RemoveMobj(redghost)
		end
		
		if mo2.hotpotato_timer <= 0 then
			boom(player2)
		end
	end
end

function weapon.equip(item, p)
	local mo = p.mo
	
	if not (mo and mo.valid) then
		return end;
	
	if mo.hotpotato_timer == nil then
		mo.hotpotato_timer = weapon.potato_start_time
		item.owner = p
	end
end

MM.addHook("KeepingItem", function(p, def, item)
	if item.id == "hotpotato" then
		countdown(p, item)
	end
end)

return weapon