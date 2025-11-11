local weapon = {}

local roles = MM.require "Variables/Data/Roles"

local MAX_COOLDOWN = 3*TICRATE
local MAX_ANIM = TICRATE

weapon.id = "luger"
weapon.category = "Weapon"
weapon.display_name = "Luger"
weapon.display_icon = "MM_LUGER"
weapon.state = dofile("Items/Weapons/Luger/freeslot")
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE/3
weapon.cooldown_time = 2*TICRATE + TICRATE/2
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
weapon.droppable = false
weapon.shootable = true
weapon.shootmobj = MT_MM_REVOLV_BULLET
weapon.pickupsfx = sfx_gnpick
weapon.equipsfx = sfx_gequip
weapon.attacksfx = sfx_lugrsh
weapon.finalkillsfx = sfx_revcrt
weapon.allowdropmobj = false
weapon.max_ammo = 4
weapon.noammoinduels = true
weapon.aimtrail = true
function weapon:postpickup(p)
	if (MM_N.dueling) then return end
	if roles[p.mm.role].team == true then
		self.restrict[p.mm.role] = true
		self.timeleft = 5*TICRATE
	end
end

weapon.bulletthinker = function(mo, i)
	if (i >= 192)
		mo.momz = $ - (mo.scale/2)*P_MobjFlip(mo)
	end
end

return weapon