local function sphereToCartesian(alpha,beta)
    local t = {}

    t.x = FixedMul(cos(alpha), cos(beta))
    t.y = FixedMul(sin(alpha), cos(beta))
    t.z = sin(beta)
    --t.z = FixedMul(sin(alpha), sin(beta)) -- for elliptical orbit

    return t
end
local function P_3DThrust(mo, h_ang, v_ang, speed)
	local t = sphereToCartesian(h_ang,v_ang)
	mo.momx = $ + FixedMul(speed, t.x)
	mo.momy = $ + FixedMul(speed, t.y)
	mo.momz = $ + FixedMul(speed, t.z)
end

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
			
			mo.colorized = false
			mo.color = p.mm.savedcolor or p.skincolor
			mo.hotpotato_colored = nil
			mo.renderflags = $ &~RF_FULLBRIGHT
			mo.hotpotato_timer = nil
			return
		end
		
		if mo.hotpotato_timer then
			local timer = mo.hotpotato_timer
			local flashtime = 6 << (timer/TICRATE)
			flashtime = min($, 2 * TICRATE)
			if (timer % (flashtime/2) ~= 0) then
				if mo.hotpotato_colored
					mo.hotpotato_colored = $ - 1
				elseif mo.hotpotato_colored == 0
					mo.colorized = false
					mo.color = p.mm.savedcolor or p.skincolor
					mo.hotpotato_colored = nil
					mo.renderflags = $ &~RF_FULLBRIGHT
				end
			elseif timer % flashtime == 0 then
				mo.colorized = true
				mo.renderflags = $|RF_FULLBRIGHT
				mo.color = SKINCOLOR_BLACK
				mo.hotpotato_colored = max(flashtime/4, 1)
				S_StartSound(mo, sfx_gbeep)
			else
				mo.colorized = true
				mo.renderflags = $|RF_FULLBRIGHT
				mo.color = SKINCOLOR_RED
				mo.hotpotato_colored = max(flashtime/4, 1)
				S_StartSound(mo, sfx_gbeep)
			end
		end
		
		-- steam effects
		local radius = 20
		local height = 40
		local steam = P_SpawnMobjFromMobj(mo,
			P_RandomRange(-radius, radius)*FU,
			P_RandomRange(-radius, radius)*FU,
			P_RandomRange(0,height)*FU,
			MT_SPINDUST
		)
		steam.alpha = FU/2
		local ha,va = R_PointToAngle2(steam.x,steam.y,mo.x,mo.y), R_PointToAngle2(
			0,steam.z,
			R_PointToDist2(steam.x,steam.y,mo.x,mo.y), mo.z
		)
		P_3DThrust(steam, ha,va, -(P_RandomRange(4,10)*steam.scale))
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
		
		mo2.momx = $/2
		mo2.momy = $/2
		
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

weapon.drawer = function(v, p,item, x,y,scale,flags, selected, active)
	if not p.realmo.hotpotato_timer then return end
	
	local bob = sin(FixedAngle(leveltime*FU*20))
	v.slideDrawString(x + 16*scale, y - 20*FU + bob,
		"Toss me!",
		(flags &~V_ALPHAMASK)|V_ALLOWLOWERCASE|V_YELLOWMAP,
		"thin-fixed-center", true
	)
	if not selected
		v.slideDrawString(x + 16*scale, y - 10*FU + bob,
			"\x1B",
			(flags &~V_ALPHAMASK)|V_ALLOWLOWERCASE|V_YELLOWMAP,
			"thin-fixed-center", true
		)
	end
end

MM.addHook("KeepingItem", function(p, def, item)
	if item.id == "hotpotato" then
		countdown(p, item)
	end
end)

return weapon