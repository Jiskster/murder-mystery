local roles = MM.require "Variables/Data/Roles"

local weapon = {}

local MAX_COOLDOWN = TICRATE
local MAX_ANIM = MAX_COOLDOWN
local MAX_HIT = MAX_COOLDOWN/5

weapon.id = "toyknife"
weapon.category = "Weapon"
weapon.display_name = "Toy Knife"
weapon.display_icon = "MM_TOYKNIFE"
--TODO: Maybe make a separate sprite for this? Right now, the knife uses
--		translations to recolor it, but models cant support translations soo...
weapon.state = S_MM_KNIFE
weapon.timeleft = -1
weapon.hit_time = 2
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE*3
weapon.range = FU*7
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
weapon.damage = false
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
weapon.cantouch = true

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

weapon.attack = function(item,p)
	MM.MeleeWhiffFX(p)
	if item.misssfx then
		S_StartSound(p.mo,item.misssfx)
	end
end

function weapon:onhit(player, player2)
	local mo1 = player.mo
	local mo2 = player2.mo

	if (player.mm and player2.mm) and
	(mo1 and mo1.valid) and
	(mo2 and mo2.valid) then
		local power = 100*FU
		self.hit = 0
		
		S_StartSound(mo2, sfx_s3k7b)
		P_InstaThrust(mo2, mo1.angle, power)
		P_MovePlayer(mo2.player)
		
		if weapon.misssfx then
			S_StopSoundByID(mo1, weapon.misssfx)
		end
	end
end

weapon.thinker = function(item, p)
	if not (p and p.valid) then return end
	
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
	item.mobj.translation = "MM_ToyKnife"
end

return weapon