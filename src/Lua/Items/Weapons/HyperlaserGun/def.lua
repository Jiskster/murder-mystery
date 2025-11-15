local weapon = {}

local roles = MM.require "Variables/Data/Roles"

local MAX_COOLDOWN = 3*TICRATE
local MAX_ANIM = TICRATE

weapon.id = "hyperlaser"
weapon.category = "Weapon"
weapon.display_name = "\x88".."Hyperlaser Gun"
weapon.display_icon = "MM_REVOLVER"
weapon.state = dofile("Items/Weapons/HyperlaserGun/freeslot")
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE/4
weapon.cooldown_time = TICRATE
weapon.range = FU*2
weapon.position = {
	x = FU,
	y = 0,
	z = 0
}
weapon.animation_position = {
	x = FU,
	y = -FU/2,
	z = 0
}
weapon.stick = true
weapon.animation = true
weapon.damage = false
weapon.weaponize = true
weapon.droppable = true
weapon.shootable = true
weapon.shootmobj = dofile("Items/Weapons/HyperlaserGun/bullet")
weapon.pickupsfx = sfx_gnpick
weapon.equipsfx = sfx_gequip
weapon.attacksfx = sfx_hlgn_f
weapon.finalkillsfx = sfx_revcrt
weapon.dropsfx = sfx_gndrop
weapon.allowdropmobj = true
weapon.aimtrail = true

MM.addHook("CorpseSpawn", function(me, mo)
	local inf = mo.inflictor
	if not (inf and inf.valid) then return end
	if not (inf.type == weapon.shootmobj) then return end
	
	mo.evaporate = true
	mo.fade = 0
end)

MM.addHook("KilledPlayer", function(_, p)
	local me = p.mo
	local inf = me.inflictor
	if not (inf and inf.valid) then return end
	if not (inf.type == weapon.shootmobj) then return end

	me.color = SKINCOLOR_CORNFLOWER
	me.colorized = true
	me.hyperlasered = true
	me.fade = 0
end)

MM.addHook("DeadPlayerThink", function(p)
	if not MM_N.gameover then return end
	if (p.spectator) then return end
	local me = p.mo
	if not (me and me.valid) then return end
	if me.health then return end
	if not me.hyperlasered then return end

	me.color = SKINCOLOR_CORNFLOWER
	me.colorized = true

	if (me.flags & MF_NOTHINK) then return end

	if not (me.extravalue1)
		me.extravalue1 = 1
		S_StartSound(me, sfx_hlgn_h)
	end

	me.flags = $|MF_NOGRAVITY
	me.momx,me.momy = 0,0
	me.momz = me.scale

	me.translation = nil
	me.renderflags = $|RF_FULLBRIGHT
	me.state = S_PLAY_DEAD

	me.fade = $ + 1
	if (me.fade >= TICRATE)
		me.alpha = max($ - (FU/15), 0)
		if me.alpha <= 0
			p.deadtimer = 1
			p.charflags = $ &~SF_MACHINE
			return
		end
	end

	local off = FixedDiv(me.radius, me.scale)/FU
	local effect = P_SpawnMobjFromMobj(me,
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

end)

MM.addHook("CorpseThink", function(mo)
	if not mo.evaporate then return end

	mo.flags = $|MF_NOGRAVITY
	mo.momx,mo.momy = 0,0
	mo.momz = mo.scale/2

	mo.color = SKINCOLOR_CORNFLOWER
	mo.colorized = true
	mo.translation = nil
	mo.renderflags = $|RF_FULLBRIGHT
	mo.state = S_PLAY_DEAD

	local off = FixedDiv(mo.radius, mo.scale)/FU
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

	mo.fade = $ + 1
	if (mo.fade >= TICRATE)
		mo.alpha = $ - (FU/15)
		if mo.fade >= TICRATE + 15
			MM_N.knownDeadPlayers[mo.playerid] = true
			P_RemoveMobj(mo)
		end
	end
end)

function weapon:postpickup(p)
	local gt = MM.returnGametype()
	if (gt.disable_gun_countdown) then return end
	
	if (MM_N.dueling) then return end
	
	if roles[p.mm.role].team == true then
		self.restrict[p.mm.role] = true
		self.timeleft = 10*TICRATE
	end
end

MM.addHook("ItemUse", function(p)
	local inv = p.mm.inventory
	local item = inv.items[inv.cur_sel]
	
	if item.id ~= "hyperlaser" then return end
	S_StartSound(p.mo, sfx_hlgn_r)

	local gt = MM.returnGametype()
	if (gt.disable_gun_countdown) then return end
	
	if p.mm.role ~= MMROLE_MURDERER then return end
	if (MM_N.dueling) then return end
	
	if (item.shots == nil) then item.shots = 0; end
	
	item.shots = $ + 1
end)

weapon.thinker = function(item, p)
	local gt = MM.returnGametype()
	if (gt.disable_gun_countdown) then return end
	
	if (p.mm.role ~= MMROLE_MURDERER) then return end
	if (MM_N.dueling) then return end
	if (item.shots == nil) then item.shots = 0; end
	
	if item.shots >= 3
		MM:DropItem(p)
	end
end

weapon.drawer = function(v, p,item, x,y,scale,flags, selected, active)
	local gt = MM.returnGametype()
	if (gt.disable_gun_countdown) then return end
	
	if (p.mm.role ~= MMROLE_MURDERER) then return end
	if (MM_N.dueling) then return end
	if not selected then return end
	
	v.slideDrawString(160*FU, y - 20*FU,
		"Ammo: "..(3 - (item.shots or 0)).." / 3",
		(flags &~V_ALPHAMASK)|V_ALLOWLOWERCASE,
		"thin-fixed-center", true
	)
end

weapon.hitplayer = function(bullet, me)
	local sfx = P_SpawnGhostMobj(me)
	sfx.flags2 = $|MF2_DONTDRAW
	sfx.tics = 2*TICRATE

	S_StartSound(sfx, sfx_hlgn_h)
end

return weapon