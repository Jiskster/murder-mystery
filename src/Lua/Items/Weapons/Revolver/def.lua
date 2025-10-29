local weapon = {}

local roles = MM.require "Variables/Data/Roles"

local MAX_COOLDOWN = 3*TICRATE
local MAX_ANIM = TICRATE

weapon.id = "revolver"
weapon.category = "Weapon"
weapon.display_name = "Revolver"
weapon.display_icon = "MM_REVOLVER"
weapon.state = dofile "Items/Weapons/Revolver/freeslot"
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE/2
weapon.cooldown_time = TICRATE*2
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
weapon.shootmobj = dofile("Items/Weapons/Revolver/bullet")
weapon.pickupsfx = sfx_gnpick
weapon.equipsfx = sfx_gequip
weapon.attacksfx = sfx_revlsh
weapon.dropsfx = sfx_gndrop
weapon.allowdropmobj = true
weapon.aimtrail = true

weapon.bulletthinker = function(mo, i)
	if (i >= 192)
		mo.momz = $ - (mo.scale/3)*P_MobjFlip(mo)
	elseif (i >= 64)
		mo.momz = $ - (mo.scale/2)*P_MobjFlip(mo)
	end
end

function weapon:postpickup(p)
	if (MM_N.dueling) then return end
	if roles[p.mm.role].team == true then
		self.restrict[p.mm.role] = true
		self.timeleft = 10*TICRATE
	end
end

MM.addHook("ItemUse", function(p)
	local inv = p.mm.inventory
	local item = inv.items[inv.cur_sel]
	
	if p.mm.role ~= MMROLE_MURDERER then return end
	if (MM_N.dueling) then return end
	if item.id ~= "revolver" then return end
	
	if (item.shots == nil) then item.shots = 0; end
	
	item.shots = $ + 1
end)

weapon.thinker = function(item, p)
	if (p.mm.role ~= MMROLE_MURDERER) then return end
	if (MM_N.dueling) then return end
	if (item.shots == nil) then item.shots = 0; end
	
	if item.shots >= 3
		MM:DropItem(p)
	end
end

weapon.drawer = function(v, p,item, x,y,scale,flags, selected, active)
	if (p.mm.role ~= MMROLE_MURDERER) then return end
	if (MM_N.dueling) then return end
	if not selected then return end
	
	v.slideDrawString(160*FU, y - 20*FU,
		"Ammo: "..(3 - (item.shots or 0)).." / 3",
		(flags &~V_ALPHAMASK)|V_ALLOWLOWERCASE,
		"thin-fixed-center", true
	)
end

return weapon