local weapon = {}

local roles = MM.require "Variables/Data/Roles"

local MAX_COOLDOWN = 3*TICRATE
local MAX_ANIM = TICRATE

dofile("Items/Weapons/Shotgun/bullet")

weapon.id = "shotgun"
weapon.category = "Weapon"
weapon.display_name = "Shotgun"
weapon.display_icon = "MM_SHOTGUN"
weapon.state = dofile "Items/Weapons/Shotgun/freeslot"
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE
weapon.cooldown_time = 3*TICRATE
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
weapon.shootmobj = MT_RAY
weapon.pickupsfx = sfx_gnpick
weapon.equipsfx = sfx_gequip
weapon.attacksfx = sfx_gnfire
weapon.dropsfx = sfx_gndrop
weapon.allowdropmobj = true

function weapon:postpickup(p)
	if (MM_N.dueling) then return end
	if roles[p.mm.role].team == true then
		self.restrict[p.mm.role] = true
		self.timeleft = 5*TICRATE
	end
end

--shotgun spread
function weapon:attack(p)
	self.shootmobj = MT_MM_BULLET
	for i = -2,2
		--if i == 0 then continue end
		
		MM.FireBullet(p, MM.Items[self.id], self,
			p.mo.angle + FixedAngle(P_RandomFixed()*i)*2,
			p.aiming + FixedAngle(P_RandomFixed()*(P_RandomChance(FU/2) and 1 or -1))*7,
			false
		)
		
	end
	self.shootmobj = MT_RAY
end

weapon.bulletthinker = function(mo, i)
	if (i >= 170)
		mo.momz = $ - (mo.scale/3)*P_MobjFlip(mo)
	end
	if (i >= 230)
		mo.momz = $ - (mo.scale/2)*P_MobjFlip(mo)
	end
end

--(v, props.p, item, x,y, scale, flags, selected, not inv.hidden)
/*
weapon.drawer = function(v, p,item, x,y,scale,flags, selected, active)
	if selected and active
		v.drawString(160,100,"Test",0)
	end
end
*/

return weapon