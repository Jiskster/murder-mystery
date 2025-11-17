MM.DroppedMobjs = {}
local shallowCopy = MM.require "Libs/shallowCopy"

local Pickup_Interaction = MM.addInteraction(function(p,mobj)
	local def = MM.Items[mobj.pickupid]
	
	if mobj.restrict[p.mm.role] then
		chatprintf(p, "\x82*This weapon is prohibited from your role.")
		return
	end
	
	if def.pickup
	and def.pickup(mobj, p) then
		return
	end

	local item = MM:GiveItem(p, mobj.pickupid)

	if item then
		if mobj.pickupsfx then
			S_StartSound(p.mo, mobj.pickupsfx)
		end
		if def.postpickup then
			def.postpickup(item, p)
		end
		
		P_RemoveMobj(mobj)
		return true
	end
end,"Pickup_Interaction")

function MM:SpawnItemDrop(item_id, x, y, z, angle, flip, extra)
	local item;
	if not self.Items[item_id] then
		error("invalid item = "..(item_id or "NO INPUT"))
		return
	else
		item = self.Items[item_id]
	end
	
	if flip then
		flip = -1
	end
	
	local mobj = P_SpawnMobj(x,y,z, MT_THOK)
	mobj.state = item.state
	mobj.tics = -1
	mobj.fuse = -1
	
	if angle == nil then
		mobj.angle = FixedAngle(P_RandomRange(0, 360)*FU)
	else
		mobj.angle = angle
	end
	
	mobj.momz = (3*FU)*flip

	mobj.pickupid = item.id
	mobj.pickupsfx = item.pickupsfx
	mobj.restrict = shallowCopy(item.restrict)
	
	mobj.pickupwait = TICRATE
	mobj.sourcep = p
	
	mobj.magtime = 0
	
	if extra then
		if extra.price then
			mobj.pickupprice = extra.price
		end
		
		if extra.pickuptime then
			mobj.pickuptime = extra.pickuptime
		end
		
		if extra.restrict then
			mobj.restrict = extra.restrict
		end
		
		if not extra.disablespawnslide then
			P_InstaThrust(mobj, mobj.angle, 5*FU)
		end
	end
	
	mobj.flags = 0
	mobj.dropid = #MM.DroppedMobjs + 1
	
	table.insert(MM.DroppedMobjs, mobj)
	
	return mobj
end

function MM:DropItem(p, slot, randomize, dont_notify, forced)
	if not (p and p.mm)
		return
	end
	
	slot = $ or p.mm.inventory.cur_sel
	if (p.mm.inventory.items[slot] == nil) then
		if not dont_notify then
			chatprintf(p, "\x82*There's nothing to drop.")
		end
		return
	end

	local item = p.mm.inventory.items[slot]

	if not (item) then
		if not dont_notify then
			chatprintf(p, "\x82*There's nothing to drop.")
		end
		return
	end

	if not (item.droppable) then
		if not dont_notify then
			chatprintf(p, "\x82*You can't drop this.")
		end
		
		if not forced then 
			return
		end
	end

	local def = self.Items[item.id]
	
	local mobj
	if item.allowdropmobj
		mobj = P_SpawnMobjFromMobj(p.mo, 0,0,FixedMul(p.mo.height/2, p.mo.scale), MT_THOK)
		mobj.state = item.state
		mobj.tics = -1
		mobj.fuse = -1
		mobj.angle = p.mo.angle
		
		if randomize then
			mobj.angle = FixedAngle(P_RandomRange(0, 360)*FU)
		end
		
		P_InstaThrust(mobj, mobj.angle, 5*FU)
		mobj.momz = (3*FU)*P_MobjFlip(p.mo)
		
		mobj.pickupid = item.id
		mobj.pickupsfx = item.pickupsfx
		mobj.restrict = shallowCopy(item.restrict)
		mobj.noitemsparkles = item.noitemsparkles
		
		mobj.pickupwait = TICRATE
		mobj.sourcep = p
		
		mobj.magtime = 0
		
		mobj.flags = 0
		mobj.dropid = #MM.DroppedMobjs + 1
		
		table.insert(MM.DroppedMobjs, mobj)
	end
	if def.drop then
		def.drop(item, p, mobj /*the dropped pickup*/)
	end
	if item.dropsfx ~= nil then
		S_StartSound(p.mo, item.dropsfx)
	end
	
	if (item and item.mobj) then
		P_RemoveMobj(item.mobj)
	end
	p.mm.inventory.items[slot] = nil
	
	return mobj
end

function MM:GetCertainDroppedItems(id)
	local wpns = {}

	for i,item in ipairs(MM.DroppedMobjs) do
		if item and item.valid then
			if item.pickupid == id then
				table.insert(wpns, item)
			end
		end
	end

	return wpns
end

local function manage_unpicked_weapon(mobj, releaseTic)
	if (mobj.flags & MF_NOTHINK)
	or ((MM_N.gameover and MM_N.end_ticker < releaseTic) or MM_N.voting)
		mobj.flags = $|MF_NOTHINK
		if not (MM_N.voting)
			mobj.flags2 = $|MF2_DONTDRAW
		end
		return
	end
	
	local angle = FixedAngle(FixedDiv(leveltime % 80, 80)*360)
	local z = (12*FU)+12*cos(angle)

	local def = MM.Items[mobj.pickupid]

	mobj.flags = $ &~(MF_NOCLIP|MF_NOCLIPHEIGHT)
	mobj.flags2 = $ &~MF2_DONTDRAW

	mobj.spriteyoffset = z
	mobj.angle = angle
	mobj.flags = 0
	mobj.shadowscale = FU/2
	
	if (displayplayer and displayplayer.valid)
		local p = displayplayer
		if (p == mobj.sourcep and mobj.pickupwait > 0)
			mobj.frame = $|FF_TRANS50
		else
			mobj.frame = $ &~FF_TRANSMASK
		end
	end
	
	if P_RandomChance(FU/2)
	and not mobj.noitemsparkles
		local wind = P_SpawnMobj(
			mobj.x + P_RandomRange(-18,18)*mobj.scale,
			mobj.y + P_RandomRange(-18,18)*mobj.scale,
			mobj.z + (mobj.height/2) + P_RandomRange(-20,20)*mobj.scale,
			MT_BOXSPARKLE
		)
		wind.renderflags = $|RF_FULLBRIGHT
		P_SetObjectMomZ(wind,P_RandomRange(1,3)*FU)
	end
	
	if def.dropthinker then
		def.dropthinker(mobj)
	end
	local hook_event = MM.events["DropItemThinker"]
	for i,v in ipairs(hook_event)
		MM.tryRunHook("DropItemThinker", v, def, mobj)
	end
	
	// PICK ME UP. PICK ME UP.
	for p in players.iterate do
		if not (p.mo
		and p.mo.health
		and p.mm
		and not p.mm.spectator
		and not p.mm.picking_up) then continue end
		
		--You have to wait to pick this up again
		if (p == mobj.sourcep and mobj.pickupwait > 0) then continue end
		
		/*
		if not (p.cmd.buttons & BT_CUSTOM3
		and not (p.lastbuttons & BT_CUSTOM3)) then
			continue
		end
		
		local radius = p.mo.radius*4

		if abs(p.mo.x - mobj.x) > radius
		or abs(p.mo.y - mobj.y) > radius
		or abs(p.mo.z - mobj.z) > p.mo.height then
			continue
		end
		*/

		MM.interactPoint(p,mobj, {
			name = def.display_name or "Item",
			intertext = "Pick up",
			button = BT_CUSTOM3,
			restrict = mobj.restrict or {},
			time = mobj.pickuptime or TICRATE/7,
			funcid = Pickup_Interaction,
			price = mobj.pickupprice,
		})
	end
	
	mobj.pickupwait = max(0,$-1)
end

addHook("PostThinkFrame", do
	local releaseTic = 3*TICRATE
	if MM_N.sniped_end then
		-- for music timing
		releaseTic = 3*TICRATE + MM.sniper_theme_offset
	end
	
	local lastitem
	for i,mobj in ipairs(MM.DroppedMobjs) do
		if not (mobj and mobj.valid and not manage_unpicked_weapon(mobj, releaseTic)) then
			table.remove(MM.DroppedMobjs, i)
			continue
		end
		
		if (lastitem and lastitem.valid)
			--dogshit formatting
			if R_PointToDist2(
				lastitem.x,lastitem.y,
				mobj.x,mobj.y
			) < FixedMul(INTER_RANGE,max(mobj.scale,lastitem.scale)) + mobj.radius
			and P_IsObjectOnGround(mobj)
				P_Thrust(mobj,
					R_PointToAngle2(mobj.x,mobj.y,
						lastitem.x,lastitem.y
					),
					-mobj.scale/2
				)
			end
		end
		
		lastitem = mobj
	end
end)

addHook("NetVars", function(n)
	MM.DroppedMobjs = n($)
end)