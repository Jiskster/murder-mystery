// WEAPON SYSTEM BY @j1sk ON DISCORD
// ORIGINALLY FOR ZE2

// MM ITEM SYSTEM V2

local ITEM_DEF = {
	id = "knife",

	display_name = "Knife",
	display_icon = "MM_KNIFE",

	category = "Weapon",

	state = S_THOK,

	timeleft = -1,

	hit_time = 35,
	animation_time = 35,
	cooldown_time = 35,
	max_ammo = 0,
	
	--if TRUE, this weapon wont use ammo in duels
	noammoinduels = false,

	-- this is a multiplication of the targets range and the players range combined
	-- putting this to FU will make the attack only hit if the target is directly in the players hitbox
	-- theres another variable called "zrange" thatll only modify the range of the weapon on the z axis
	-- use this if you got a big range but might be too big for the players height
	range = FU*2,

	-- these actually scale based on the players radius
	-- so, what these values would be if you want the default to be on the upper right of the player is...
	-- {x = FU, y = FU, z = 0}
	position = {x = 0, y = 0, z = 0},
	animation_position = {x = 0, y = 0, z = 0},

	stick = true,				-- disable if you wanna manually handle weapon sticking
									-- useful for cooldowns after throwing a weapon, or if you just want to do a fake-drop or something
	hiddenforothers = false,	-- determines if the stick is hidden for others
									-- stick needs to be true for this to operate correctly
	showinfirstperson = false,
	
	cantouch = false,
	animation = true,			-- enable if you want the weapon to be tweened between it's hit pos and default pos
	damage = true,				-- enable if this can damage people
	weaponize = true,			-- make item classified as a weapon
									-- weapons are usually on the players right hand, while items are on the players left
	latencyadjust = false,		-- melee items will adjust to have a longer
									-- hit window according to latency
	droppable = false,			-- enable to let item be dropped
	allowdropmobj = true,		-- determines whether dropping the item will spawn another to be picked up
	shootable = false,			-- enable to make weapon shoot projectiles instead of stabbing
	shootmobj = MT_THOK,		-- the mobj type it shoots
	nostrafe = false,
	rapidfire = false,			-- allows shooting by holding down
	onlyhitone = false,			-- for melees, this weapon wont hit more than 1 person in succession
	aimtrail = false,			-- for aimables, show a trail where youre aiming in 3rd person?
	restrict = {},				-- restricts pickup from certain roles
	/* example:
	{
		[MMROLE_INNOCENT] = true
	}
	this would restrict innocents from picking the item up, but allow for murderers and sheriffs to pick it up
	*/
	
	-- not required, for scripters
	--TODO: document these
	pickup = func,
	postpickup = func,
	equip = func,
	unequip = func,
	thinker = func,
	hiddenthinker = func,
	attack = func,
	hit = func,
	drop = func,
	dropthinker = func,
	onmiss = func,
	drawer = func, --for hud
}

local ITEM_STRUCT = {
	id = "knife",

	display_name = "Knife",
	display_icon = "MM_KNIFE",

	mobj = MT_THOK,
	state = S_THOK,

	timeleft = -1,

	max_hit = 0,
	max_cooldown = 0,
	max_anim = 0,
	max_ammo = 0,

	hit = 0,
	anim = 0,
	cooldown = 0,
	ammo = 0,

	range = FU*2,

	pos = {x = 0, y = 0, z = 0},
	default_pos = {x = 0, y = 0, z = 0},
	anim_pos = {x = 0, y = 0, z = 0},

	stick = true,
	hiddenforothers = false,
	showinfirstperson = false,
	cantouch = false, -- damage attribute without the damage.
	
	animation = true,
	damage = true,
	weaponize = true,
	latencyadjust = false,
	droppable = false,
	shootable = false,
	shootmobj = MT_THOK,
	nostrafe = false,
	rapidfire = false,
	aimtrail = false,
	onlyhitone = false,

	restrict = {},

	bullets = {} -- save valid bullets here incase modders decide they wanna do cool shit
}

local shallowCopy = MM.require "Libs/shallowCopy"

MM.Items = {}

function MM:CreateItem(input_table)
	if not input_table then
		error("ItemDef not found.")
	end
	if type(input_table) ~= "table" then
		error("ItemDef (Argument #1) is not a table.")
	end

	for k,v in pairs(ITEM_DEF) do
		if input_table[k] == nil
		or type(input_table[k]) ~= type(ITEM_DEF[k]) then
			--these are debugging messages, so only print if so
			if (CV_MM.debug.value or devparm)
				if input_table[k] == nil then
					print(tostring(k).." is nil. It has been corrected to the default property from ITEM_DEF.")
					print("Ignore this notification unless you are the dev and know that something is wrong.")
				else
					print(tostring(k).." is not the same type as the default. It has been corrected to the default property from ITEM_DEF.")
				end
				print("View pk3/Lua/Items/main.lua for more information.")
			end
			
			input_table[k] = ITEM_DEF[k]
		end
	end

	MM.Items[input_table.id] = input_table

	print("\x84MM:".."\x82 Item ".."\""..input_table.id.."\" included ["..(#self.Items).."]")
	return true
end



function MM:FetchInventory(p)
	if not (p and p.valid and p.mm) then return end

	return p.mm.inventory and p.mm.inventory.items
end

function MM:FetchInventoryLimit(p)
	if not (p and p.valid and p.mm) then return 1 end
	return p.mm.inventory.count
end

function MM:FetchInventorySlot(p, slot)
	if not (p and p.valid and p.mm) then return end

	local inv = self:FetchInventory(p)
	slot = $ or p.mm.inventory.cur_sel

	return inv and inv[slot]
end

function MM:ClearInventorySlot(p, slot)
	if not (p and p.valid and p.mm) then return end

	slot = $ or p.mm.inventory.cur_sel

	local inv = self:FetchInventory(p)
	if inv and inv[slot] then
		if (inv[slot].mobj and inv[slot].mobj.valid) then
			P_RemoveMobj(inv[slot].mobj)
		end
		
		inv[slot] = nil
		
		return true
	end

	return false
end

-- returns number
function MM:FetchEmptySlot(p)
	if not (p and p.valid and p.mm) then return end

	for i=1,self:FetchInventoryLimit(p) do
		if not (self:FetchInventorySlot(p, i)) then
			return i
		end	
	end
	
	return false
end

function MM:GetInventoryItemFromId(p, id)
	if not (p and p.valid and p.mm) then return end

	local found
	local found_slot
	
	for i=1,self:FetchInventoryLimit(p) do
		if self:FetchInventorySlot(p, i)
		and self:FetchInventorySlot(p, i).id
		and self:FetchInventorySlot(p, i).id == id then
			found = self:FetchInventorySlot(p, i)
			found_slot = i
			
			return found, found_slot
		end
	end
		
	return false
end

function MM:IsInventoryFull(p)
	if not (p and p.valid and p.mm) then return end
	local inv = self:FetchInventory(p)

	if inv
	and #self:FetchInventory(p) >= self:FetchInventoryLimit(p) then
		return true
	elseif inv then
		return false
	end

	return true
end

function MM:GetItemInfoIndex(iteminfo, index, skin, real)
	if not iteminfo then return end

	if not (iteminfo.skin_overwrite
	and iteminfo.skin_overwrite[skin])
	or not skin
	and index then -- no overwrite or no skin, has index
		return iteminfo[index]
	elseif index then
		if skin and iteminfo.skin_overwrite[skin][index] and not real then
			return iteminfo.skin_overwrite[skin][index]
		elseif iteminfo[index] then
			return iteminfo[index]
		end
	end
end

function MM:SetItemInfoIndex(iteminfo, index, value, skin, real)
	if not iteminfo then return end
	if value == nil then return end

	if not (iteminfo.skin_overwrite and iteminfo.skin_overwrite[skin]) or not skin and index then -- no overwrite or no skin, has index
		if iteminfo[index] then
			iteminfo[index] = value
		end
	elseif index then
		if skin and iteminfo.skin_overwrite[skin][index] and not real then
			iteminfo.skin_overwrite[skin][index] = value
		elseif iteminfo[index] then
			iteminfo[index] = value
		end
	end
end

function MM:CopyItemFromID(item_id)
	local item = shallowCopy(self.Items[item_id]) or error("Invalid item_id.")

	item.ontrigger = nil
	item.onspawn = nil
	item.onhit = nil
	item.thinker = nil
	item.hiddenthinker = nil

	return item
end

function MM:MakeWeaponMobj(p, item)
	local def = self.Items[item.id]
	local mobj = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)

	mobj.tics = -1
	mobj.fuse = -1
	mobj.state = def.state
	mobj.flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOTHINK|MF_NOCLIP|MF_NOCLIPHEIGHT
	mobj.flags2 = MF2_DONTDRAW

	return mobj
end

function MM:GiveItem(p, item_input, slot, overrides)
	if not (p and p.valid and p.mm) then return end

	local datatype = type(item_input)
	local isName = datatype == "string"
	
	if not item_input
	or (isName and item_input and not self.Items[item_input]) then
		return false
	elseif self:FetchInventory(p) then
		local item = shallowCopy(ITEM_STRUCT)
		local def = self.Items[item_input]
		
		item.id = def.id
		
		item.display_name = def.display_name
		item.display_icon = def.display_icon
		
		item.mobj = self:MakeWeaponMobj(p, item)
		
		item.state = def.state
		
		item.timeleft = def.timeleft
		
		item.max_hit = def.hit_time
		item.max_anim = def.animation_time
		item.max_cooldown = def.cooldown_time
		item.max_ammo = def.max_ammo
		item.ammo = item.max_ammo
		item.noammoinduels = item.noammoinduels
		
		item.range = def.range
		item.zrange = def.zrange
		
		item.pos = shallowCopy(def.position)
		item.default_pos = shallowCopy(def.position)
		item.anim_pos = shallowCopy(def.animation_position)

		item.stick = def.stick
		item.animation = def.animation
		item.damage = def.damage
		item.weaponize = def.weaponize
		item.latencyadjust = def.latencyadjust
		item.droppable = def.droppable
		item.droppable_clue = def.droppable_clue
		item.allowdropmobj = def.allowdropmobj
		item.shootable = def.shootable
		item.shootmobj = def.shootmobj
		item.nostrafe = def.nostrafe
		item.rapidfire = def.rapidfire
		item.onlyhitone = def.onlyhitone
		item.restrict = shallowCopy(def.restrict)
		item.noitemsparkles = def.noitemsparkles
		item.aimtrail = def.aimtrail
		
		item.pickupsfx = def.pickupsfx
		item.equipsfx = def.equipsfx
		item.attacksfx = def.attacksfx
		item.hitsfx = def.hitsfx
		item.finalkillsfx = def.finalkillsfx
		item.misssfx = def.misssfx
		item.dropsfx = def.dropsfx
		
		item.silencedkill = def.silencedkill
		
		item.hiddenforothers = def.hiddenforothers
		item.showinfirstperson = def.showinfirstperson
		item.cantouch = def.cantouch
		
		if overrides
		and type(overrides) == "table" then
			for k,v in pairs(overrides) do
				if item[k] ~= nil
				and type(v) == type(item[k]) then
					item[k] = v
				end
			end
		end
		
		if slot then
			self:FetchInventory(p)[slot] = item
			if def.spawn then
				def.spawn(item, p)
			end
			if not p.mm.inventory.hidden
			and p.mm.inventory.cur_sel == slot
			and item.equipsfx then
				S_StartSound(p.mo, item.equipsfx)
				
				item.cooldown = 17
			end
			return item
		end
		
		if self:FetchEmptySlot(p) then
			local emptyslot = self:FetchEmptySlot(p) 
			
			if emptyslot then
				self:FetchInventory(p)[emptyslot] = item
				if def.spawn then
					def.spawn(item, p)
				end
				if not p.mm.inventory.hidden
				and p.mm.inventory.cur_sel == emptyslot
				and item.equipsfx then
					S_StartSound(p.mo, item.equipsfx)
					
					item.cooldown = 17
				end
				
				return item
				--print("Went to empty slot")
			end
		else
			CONS_Printf(p, "\x85\Inventory full!")
			return false
		end
	elseif not self:FetchInventory(p) then
		CONS_Printf(p, "\x85\Invalid inventory!")
		return false
	end
	
	return false
end

dofile "Items/base_logic"
dofile "Items/dropped"

// FETCH VALID ITEMS

dofile "Items/Weapons/main"