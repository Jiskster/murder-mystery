local weapon = {}

local MAX_COOLDOWN = 3*TICRATE
local MAX_ANIM = TICRATE*2
local MAX_HIT = MAX_COOLDOWN/3

weapon.id = "bloxycola"
weapon.category = "Food"
weapon.display_name = "Bloxy Cola"
weapon.display_icon = "MM_BLOXYCOLA"
weapon.state = dofile "Items/Weapons/BloxyCola/freeslot"
weapon.timeleft = -1
weapon.hit_time = MAX_HIT
weapon.animation_time = MAX_ANIM
weapon.cooldown_time = MAX_COOLDOWN
weapon.range = FU
weapon.zrange = FU
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
weapon.weaponize = false
weapon.droppable = true
weapon.shootable = false
weapon.nostrafe = true
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_bcola1
weapon.attacksfx = sfx_bcola2

return weapon