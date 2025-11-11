local weapon = {}

local MAX_COOLDOWN = TICRATE
local MAX_ANIM = MAX_COOLDOWN
local MAX_HIT = MAX_COOLDOWN/3

weapon.id = "loudspeaker"
weapon.category = "Utility"
weapon.display_name = "LoudSpeaker"
weapon.display_icon = "MM_LOUDSPEAKER"
weapon.state = dofile "Items/Weapons/LoudSpeaker/freeslot"
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE
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
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_None
weapon.attacksfx = sfx_None

MM.addHook("OnRawChat", function(p, chat_type, target, msg)
	if not (p and p.valid) then return end
	
	local item = p.mm.inventory.items[p.mm.inventory.cur_sel]
	if not (item and item.id == "loudspeaker") then return end
	if p.mm.inventory.hidden then return end
	
	local loudspeaker_text = "\x80<\x87LoudSpeaker\x80> "..msg
	
	MM:ClearInventorySlot(p)
	
	if isdedicatedserver then
		loudspeaker_text = "["..p.name.."] "..$
	end
	
	chatprint(loudspeaker_text)
	S_StartSound(nil, sfx_nxitem)
	return true
end)

weapon.attack = function(item,p)
	chatprintf(p, "\x82*Announce a message to the whole server with this item!",true)
end


return weapon