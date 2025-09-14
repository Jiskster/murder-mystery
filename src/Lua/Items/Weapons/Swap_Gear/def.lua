local roles = MM.require "Variables/Data/Roles"

local weapon = {}

local MAX_COOLDOWN = TICRATE
local MAX_ANIM = MAX_COOLDOWN
local MAX_HIT = MAX_COOLDOWN/3

weapon.id = "swap_gear"
weapon.category = "perkitem"
weapon.display_name = "Body Swap Potion"
weapon.display_icon = "MM_SWAP_GEAR"
weapon.state = dofile "Items/Weapons/Swap_Gear/freeslot"
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE*3
weapon.range = FU*5
weapon.zrange = FU*3
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
weapon.shootable = false
weapon.nostrafe = true
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_None
weapon.attacksfx = sfx_None
weapon.allowdropmobj = false
weapon.onlyhitone = true

weapon.hiddenforothers = true
weapon.cantouch = true

local function get_alias(player)
	local mo = player.mo
	local alias
	local ext = {}

	local oa = player.mm.alias

	if not oa then
		alias = {}
		alias.name = player.name
		alias.skin = mo.skin
		alias.color = mo.color
		alias.skincolor = player.skincolor
		alias.perm_level = MM:getpermlevel(player)
		alias.posingas = player

		local alias_addon = {}
		local hook_event = MM.events["CreateAlias"]
		for i,v in ipairs(hook_event)
			local result = MM.tryRunHook("CreateAlias", v,
				player, alias
			)
			if type(result) ~= "table" then continue end

			for k,v in pairs(result)
				alias_addon[k] = v
			end
		end

		if #alias_addon then
			for k,v in pairs(alias_addon) do
				alias[k] = v
			end
		end
	else
		alias = oa
	end

	ext.x = mo.x
	ext.y = mo.y
	ext.z = mo.z
	ext.angle = mo.angle
	ext.drawangle = player.drawangle
	ext.momx = mo.momx
	ext.momy = mo.momy
	ext.momz = mo.momz
	ext.state = mo.state
	ext.sprite = mo.sprite
	ext.frame = mo.frame & FF_FRAMEMASK
	ext.perm_level = 0

	alias.ext = ext

	return alias
end

local function apply_alias_to_player(player, alias)
	if not (alias.ext) then 
		return
	end

	local mo = player.mo
	local ext = alias.ext

	player.mm.alias = alias
	if not player.mm.alias_save then
		player.mm.alias_save = {
			skin = player.skin,
			skincolor = player.skincolor
		}
	end

	P_SetOrigin(mo, ext.x, ext.y, ext.z)
	mo.angle = ext.angle
	mo.momx = ext.momx
	mo.momy = ext.momy
	mo.momz = ext.momz
	mo.state = ext.state
	mo.frame = $|ext.frame
	player.drawangle = ext.drawangle
	
	mo.color = alias.color
	player.skincolor = alias.skincolor
	R_SetPlayerSkin(player, alias.skin)

	local hook_event = MM.events["ApplyAlias"]
	for i,v in ipairs(hook_event)
		MM.tryRunHook("ApplyAlias", v,
			player, alias
		)
	end

	player.mm.alias = alias
	alias.ext = nil

	-- This is for if you swap back to your original body.
	-- You shouldn't have an alias set if you're going back to your own body
	if player.mm.alias.posingas ~= nil then
		if player.mm.alias.posingas.valid and player.mm.alias.posingas == player then
			player.mm.alias = nil
		end
	end

	return true
end

function weapon:onhit(player, player2)
	local mo1 = player.mo
	local mo2 = player2.mo

	if (player.mm and player2.mm) and
	(mo1 and mo1.valid) and
	(mo2 and mo2.valid) then
		self.hit = 0
		
		local alias = get_alias(player)
		local alias2 = get_alias(player2)
		
		apply_alias_to_player(player, alias2)
		apply_alias_to_player(player2, alias)
		
		--do effects after
		S_StartSound(nil, sfx_bdyswp, player)
		S_StartSound(nil, sfx_bdyswp, player2)
		
		/*
		P_SpawnGhostMobj(player.mo).fuse = 5
		P_SpawnGhostMobj(player2.mo).fuse = 5
		*/
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

weapon.thinker = function(item, p)
	if not (p and p.valid) then return end
	if p.mm.inventory.items[p.mm.inventory.cur_sel].cooldown
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
		
		if roles[p.mm.role].team == roles[p2.mm.role].team
		and not roles[p.mm.role].friendlyfire then
			continue
		end
		
		if not distchecks(item,p,p2.mo) then continue end
		
		P_SpawnLockOn(p, p2.mo, S_MM_SWAPIND)
		break
	end

end

return weapon