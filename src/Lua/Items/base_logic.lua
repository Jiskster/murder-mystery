local roles = MM.require "Variables/Data/Roles"
local ZCollide = MM.require("Libs/zcollide")

--wraps a value around the inventory's max count
local function shittyfunction(newvalue, maximum)
	if newvalue < 1 then newvalue = maximum end
	if newvalue > maximum then newvalue = 1 end
	return newvalue
end

local hooksPassed = MM.hooksPassed 

--ugh
local function SphereToCartesian(alpha,beta)
	return {
	   	x = FixedMul(cos(alpha), cos(beta)),
	    y = FixedMul(sin(alpha), cos(beta)),
	    z = sin(beta)
	}
end

local namechecktype = MT_LETTER
local function checkRayCast(from, to, props)
	local blocked = 0
	local debug = CV_MM.debug.value
	
	local angle = props.angle
	local aiming = props.aiming
	local namecheck = P_SpawnMobjFromMobj(from.mo,
		0, --P_ReturnThrustX(nil,angle, 2*FU),
		0, --P_ReturnThrustY(nil,angle, 2*FU),
		0, --41*FixedDiv(from.mo.height, from.mo.scale)/48,
		namechecktype
	)
	namecheck.sprite = SPR_NULL
	namecheck.angle = angle
	namecheck.aiming = aiming
	namecheck.flags = MF_NOGRAVITY
	namecheck.radius = FixedMul(3*FU, from.mo.scale)
	namecheck.height = FixedMul(3*FU, from.mo.scale)
	namecheck.namecheck = true
	
	local speed = namecheck.radius * 2
	local vec = SphereToCartesian(angle,aiming)
	namecheck.momx = FixedMul(speed, vec.x)
	namecheck.momy = FixedMul(speed, vec.y)
	namecheck.momz = FixedMul(speed, vec.z)
	
	P_SetOrigin(namecheck, 
		from.x + P_ReturnThrustX(nil,angle, 4*FU),
		from.y + P_ReturnThrustY(nil,angle, 4*FU),
		(from.z + (41*from.mo.height/48)) - 8*FU
	)
	
	local blockrad = namecheck.radius + to.mo.radius
	for i = 0, 255
		if not (namecheck and namecheck.valid)
			return false
		end
		
		if debug
			P_SpawnMobjFromMobj(namecheck,0,0,0,MT_SPARK)
		end
		
		P_XYMovement(namecheck)
		if not (namecheck and namecheck.valid)
			return false
		end
		
		P_ZMovement(namecheck)
		if not (namecheck and namecheck.valid)
			return false
		end
		
		if R_PointInSubsectorOrNil(namecheck.x,namecheck.y) == nil
			if (namecheck and namecheck.valid)
				P_RemoveMobj(namecheck)
			end
			return false
		end
		
		if (namecheck.momx == 0 and namecheck.momy == 0)
			if blocked == 8
				if (namecheck and namecheck.valid)
					P_RemoveMobj(namecheck)
				end
				return false
			end
			blocked = $ + 1
		end
		
		if (not (abs(namecheck.x - to.x) > blockrad
		or abs(namecheck.y - to.y) > blockrad))
		and ZCollide(namecheck, to.mo)
			if debug
				P_SpawnMobjFromMobj(namecheck,0,0,0,MT_UNKNOWN).fuse = TICRATE
			end
			if (namecheck and namecheck.valid)
				P_RemoveMobj(namecheck)
			end
			return true
		end
	end
	
	if (namecheck and namecheck.valid)
		P_RemoveMobj(namecheck)
		return false
	end
end

--also kickstarts the melee function
MM.FireBullet = function(p,def,item, angle, aiming, callhooks)
	item.hit = item.max_hit
	if item.latencyadjust
		item.hit = $ + max(p.cmd.latency - item.max_hit + 1, 0)
	end
	
	item.anim = item.max_anim
	item.cooldown = item.max_cooldown

	if item.shootable then
		--THIS IS GLORPSHIT
		/*
		local offset = FixedDiv(p.mo.height, p.mo.scale) - mobjinfo[MT_PLAYER].height
		local start = p.mo.height/2 --FixedDiv(p.mo.height,p.mo.scale)/2
		local flipped = P_MobjFlip(p.mo) == -1
		offset = max($,0)
		if flipped
			start = 10*FU
			offset = 0
		end
		offset = FixedMul($,p.mo.scale)
		*/
		
		local bullet = P_SpawnMobjFromMobj(p.mo,
			--dont spawn in the wall
			P_ReturnThrustX(nil,angle, 2*FU),
			P_ReturnThrustY(nil,angle, 2*FU),
			41*FixedDiv(p.mo.height,p.mo.scale)/48,
			item.shootmobj
		)
		bullet.angle = angle
		bullet.aiming = aiming
		bullet.color = p.mo.color
		bullet.target = p.mo
		bullet.origin = item
		bullet.eflags = $|(p.mo.eflags & MFE_VERTICALFLIP)
		
		P_InstaThrust(bullet, bullet.angle, 32*cos(aiming))
		bullet.momz = 32*sin(aiming)
		
		P_SetOrigin(bullet, 
			p.mo.x + P_ReturnThrustX(nil,p.mo.angle, 4*FU),
			p.mo.y + P_ReturnThrustY(nil,p.mo.angle, 4*FU),
			(p.mo.z + (41*p.mo.height/48))-8*FU
		)
		table.insert(item.bullets, bullet)
	end
	if callhooks
		if def.attack then
			def.attack(item, p)
		end
		if item.attacksfx then
			S_StartSound(p.mo, item.attacksfx)
		end
		
		--This weapon doesnt use ammo
		if item.max_ammo ~= 0
			if not item.noammoinduels
			and not MM_N.dueling
				item.ammo = $ - 1
			end
			
			--remove it
			if item.ammo <= 0
				item.allowdropmobj = false
				local dropped = MM:DropItem(p,nil,false,true,true)
			end
		end
	end
	return bullet
end

local function manage_position(p, item, set)
	if not item.stick then return end

	if not (item.mobj and item.mobj.valid)
	and (p.mo.health)
		item.mobj = MM:MakeWeaponMobj(p, item)
	end

	local tpfunc = set and P_SetOrigin or P_MoveOrigin

	if item.animation then
		local t = FixedDiv(item.anim, item.max_anim)

		item.pos = {
			x = ease.incubic(t, item.default_pos.x, item.anim_pos.x),
			y = ease.incubic(t, item.default_pos.y, item.anim_pos.y),
			z = ease.incubic(t, item.default_pos.z, item.anim_pos.z),
		}
	else
		item.pos = {
			x = item.default_pos.x,
			y = item.default_pos.y,
			z = item.default_pos.z
		}
	end

	local radius = p.mo.radius

	local ox = FixedMul(radius*3/2, item.pos.y)
	local oy = FixedMul(radius*3/2, -item.pos.x)

	local xx = FixedMul(ox, cos(p.mo.angle))
	local xy = FixedMul(ox, sin(p.mo.angle))
	local yx = FixedMul(oy, sin(p.mo.angle))
	local yy = FixedMul(oy, cos(p.mo.angle))

	local x = xx-yx
	local y = yy+xy
	local h = p.mo.height/2
	local z = FixedMul(h, item.pos.z)

	item.mobj.angle = p.mo.angle
	item.mobj.scale = p.mo.scale
	item.mobj.fuse = 1
	tpfunc(item.mobj,
		p.mo.x + x,
		p.mo.y + y,
		p.mo.z+h+z
	)
	
	if (P_MobjFlip(p.mo) == -1)
		item.mobj.z = $ - item.mobj.height
		item.mobj.eflags = $|MFE_VERTICALFLIP
	else
		item.mobj.eflags = $ &~MFE_VERTICALFLIP
	end
	
	do
		local slope = InvAngle(p.aiming)
		item.mobj.roll = FixedMul(slope, sin(p.mo.angle))
		item.mobj.pitch = FixedMul(slope, cos(p.mo.angle))
	end
	
	--Hide in 1st person
	if item.showinfirstperson
		item.mobj.dontdrawforviewmobj = nil
	else
		item.mobj.dontdrawforviewmobj = p.mo 
	end
end

addHook("PostThinkFrame", do
	if not MM:isMM() then return end

	for p in players.iterate do
		if not (p and p.mo and p.mm) then continue end
		
		local inv = p.mm.inventory
		
		for i,item in pairs(inv.items) do
			if not (item.mobj and item.mobj.valid) then
				item.mobj = MM:MakeWeaponMobj(p, item)
			end
			
			if i ~= inv.cur_sel
			or inv.hidden then
				item.mobj.flags2 = $|MF2_DONTDRAW
				continue
			end
			item.mobj.flags2 = $ & ~MF2_DONTDRAW
			
			manage_position(p, item)
			
			if (item.hiddenforothers) and (displayplayer and displayplayer.valid) then
				local hide = false
				if (displayplayer.mm)
					if (displayplayer.spectator or displayplayer.mm.spectator)
						hide = false
					elseif (displayplayer.mm.role ~= p.mm.role)
						hide = true
					end
				else
					hide = true
				end

				item.mobj.flags2 = ($ &~MF2_DONTDRAW)|(hide and MF2_DONTDRAW or 0)
			end
		end
	end
end)

MM:addPlayerScript(function(p)
	local inv = p.mm.inventory
	local sel = 0
	
	if not (p.mo and p.mo.valid) then return end
	if (p.mo.flags & MF_NOTHINK) then return end
	
	if p.cmd.buttons & BT_CUSTOM1
	and not (p.lastbuttons & BT_CUSTOM1)
	and not (MM:pregame()) then
		inv.hidden = not inv.hidden
		
		local item = inv.items[inv.cur_sel]
		
		if item then
			local def = MM.Items[item.id]
			if inv.hidden then
				if def.unequip then
					def.unequip(item, p)
				end
			else
				if def.equip then
					def.equip(item, p)
				end
				
				if item.equipsfx then
					S_StartSound(p.mo, item.equipsfx)
				end
				
				item.anim = 0
				item.hit = 0
				item.cooldown = max(item.cooldown, 20)
				manage_position(p, item, true)
			end
		end
	end

	for i,item in pairs(p.mm.inventory.items) do
		local def = MM.Items[item.id]
		
		if def then
			hooksPassed("KeepingItem", p, def, item)
		end
		
		if item.timeleft >= 0 then
			item.timeleft = max(0, $-1)
		end
		if item.timeleft == 0 then
			if item.droppable then
				MM:DropItem(p, i, nil, true, true)
			else
				MM:ClearInventorySlot(p, i)
			end
		end 
	end

	if p.cmd.buttons & BT_WEAPONNEXT
	and not (p.lastbuttons & BT_WEAPONNEXT) then
		sel = $+1
	end

	if p.cmd.buttons & BT_WEAPONPREV
	and not (p.lastbuttons & BT_WEAPONPREV) then
		sel = $-1
	end

	if (sel ~= 0)
	and hooksPassed("InventorySwitch",
		p, inv.cur_sel, 
		shittyfunction(inv.cur_sel+sel, inv.count),
		--curitem
		inv.items[inv.cur_sel],
		--newitem
		MM.Items[
			inv.items[shittyfunction(inv.cur_sel+sel, inv.count)]
			and
			inv.items[shittyfunction(inv.cur_sel+sel, inv.count)].id
			or ""
		]
	) then
		S_StartSound(nil,sfx_menu1,p)
		
		local olditem = inv.items[inv.cur_sel]
		local olddef = (olditem) and MM.Items[olditem.id] or nil
		
		local old_sel = inv.cur_sel
		inv.cur_sel = $+sel
		
		if inv.cur_sel < 1 then
			inv.cur_sel = inv.count
		end
		if inv.cur_sel > inv.count then
			inv.cur_sel = 1
		end
		
		if not inv.hidden then
			local newitem = inv.items[inv.cur_sel]
			local newdef = MM.Items[newitem and newitem.id or ""]
			
			--saxa might be stupid because none of these were defined before
			--or whoever added this i shouldnt be blaming everything on saxas
			--good code lol
			if olditem
			and olddef
			and olddef.unequip then
				olddef.unequip(olditem, p)
			end
			
			if newitem
			and newdef
			and newdef.equip then
				newdef.equip(newitem, p)
			end
			
			if newitem
			and newitem.equipsfx then
				S_StartSound(p.mo, newitem.equipsfx)
			end
			
			if newitem then
				newitem.anim = 0
				newitem.hit = 0
				newitem.cooldown = max(newitem.cooldown, 12)
				manage_position(p, newitem, true)
			end
		end
	end
	
	if sel == 0
	and ((p.cmd.buttons & BT_WEAPONMASK ~= p.lastbuttons & BT_WEAPONMASK)
	and (p.cmd.buttons & BT_WEAPONMASK))
	--not if we reselect our current slot
	and (min(p.cmd.buttons & BT_WEAPONMASK, inv.count) ~= inv.cur_sel)
	and (p.cmd.buttons & BT_WEAPONMASK <= inv.count)
	and hooksPassed("InventorySwitch",
		p, inv.cur_sel, 
		min(p.cmd.buttons & BT_WEAPONMASK, inv.count),
		--curitem
		inv.items[inv.cur_sel],
		--newitem
		MM.Items[
			inv.items[min(p.cmd.buttons & BT_WEAPONMASK, inv.count)]
			and
			inv.items[min(p.cmd.buttons & BT_WEAPONMASK, inv.count)].id
			or ""
		]
	) then
		S_StartSound(nil,sfx_menu1,p)
		
		local olditem = inv.items[inv.cur_sel]
		local olddef = (olditem) and MM.Items[olditem.id] or nil
		
		inv.cur_sel = min(p.cmd.buttons & BT_WEAPONMASK, inv.count)
		
		if not inv.hidden then
			local newitem = inv.items[inv.cur_sel]
			local newdef = MM.Items[newitem and newitem.id or ""]
			
			--saxa might be stupid because none of these were defined before
			--or whoever added this i shouldnt be blaming everything on saxas
			--good code lol
			if olditem
			and olddef
			and olddef.unequip then
				olddef.unequip(olditem, p)
			end
			
			if newitem
			and newdef
			and newdef.equip then
				newdef.equip(newitem, p)
			end
			
			if newitem
			and newitem.equipsfx then
				S_StartSound(p.mo, newitem.equipsfx)
			end
			
			if newitem then
				newitem.anim = 0
				newitem.hit = 0
				newitem.cooldown = max(newitem.cooldown, 12)
				manage_position(p, newitem, true)
			end
		end	
	end

	local item = inv.items[inv.cur_sel]

	if not item then return end

	local def = MM.Items[item.id]

	-- timers
	if not inv.hidden then
		item.hit = max(0, $-1)
		item.anim = max(0, $-1)
		item.cooldown = max(0, $-1)
		if def.thinker
			def.thinker(item, p)
		end
	else
		if def.hiddenthinker
			def.hiddenthinker(item,p)
		end
	end
	
	-- thinkers mightve removed our item
	if not item then return end

	-- drop le weapon
	if p.cmd.buttons & BT_CUSTOM2
	and not (p.lastbuttons & BT_CUSTOM2)
	--wtf are you doing???
	and not MM:pregame()
	and hooksPassed("ItemDrop", p, def,item) then
		MM:DropItem(p)
		return
	end

	-- attacking/use
	local canfire = false
	if p.cmd.buttons & BT_ATTACK
		canfire = true
		if not item.rapidfire
		and (p.lastbuttons & BT_ATTACK)
			canfire = false
		end
	end	
	
	if canfire
	and not (item.cooldown) 
	and not inv.hidden
	and hooksPassed("ItemUse", p, def,item) then
		MM.FireBullet(p,def,item, p.mo.angle, p.aiming, true)
	end
	
	if (displayplayer and displayplayer.valid)
	and (p == displayplayer or p == secondarydisplayplayer)
	and not (MM_N.gameover)
		if item.aimtrail
		and (p == displayplayer and camera or camera2).chase
		and not inv.hidden
			local me = p.mo
			local ang = me.angle
			local max_iter = 8
			local max_dist = 128 * me.scale
			local step = max_dist / max_iter
			--close enough
			--TODO: align these properly
			local vstep = FixedMul(step, SphereToCartesian(ang, p.aiming).z)
			
			for i = -3, max_iter do
				local move = step * i
				local vmove = vstep * i
				local trail = P_SpawnMobjFromMobj(me,0,0,0,MT_THOK)
				P_SetOrigin(trail,
					me.x + P_ReturnThrustX(nil, ang, move) + me.momx,
					me.y + P_ReturnThrustY(nil, ang, move) + me.momy,
					(p.mo.z + (41*p.mo.height/48))-8*FU + vmove + me.momz
				)
				trail.tics = 2
				trail.fuse = -1
				trail.spritexscale = FU/10
				trail.spriteyscale = trail.spritexscale
				trail.translation = "AllWhite"
				trail.blendmode = AST_SUBTRACT
				trail.dispoffset = 110
				trail.radius = 2 * me.scale
				trail.height = 4 * me.scale
				trail.dontdrawforviewmobj = me
			end
		end
	end

	-- hit detection
	if (item.damage or item.cantouch)
	and item.hit
	and not inv.hidden then
		local hitsomething = false
		local myheight = P_GetPlayerHeight(p)
		
		for p2 in players.iterate do
			if not (p2 ~= p
			and p2
			and p2.mo
			and p2.mo.health
			and p2.mm
			and not p2.mm.spectator) then continue end
			
			local dist = R_PointToDist2(p.mo.x, p.mo.y, p2.mo.x, p2.mo.y)
			local maxdist = FixedMul(p.mo.radius+p2.mo.radius, item.range)
			local theirheight = P_GetPlayerHeight(p2)
			
			if dist > maxdist
			or abs((p.mo.z + myheight/2) - (p2.mo.z + theirheight/2)) > FixedMul(max(myheight, theirheight), item.zrange or item.range)
			or not P_CheckSight(p.mo, p2.mo) then
				continue
			end
			
			if p.mm.role == p2.mm.role
			and p.mm.role ~= MMROLE_INNOCENT then
				continue
			end
			
			--sight check passed, but did it physically pass?
			if not checkRayCast(
				{mo = p.mo,		x = p.mo.x,		y = p.mo.y,		z = p.mo.z},
				{mo = p2.mo,	x = p2.mo.x,	y = p2.mo.y,	z = p2.mo.z},
				{
					angle = R_PointToAngle2(p.mo.x,p.mo.y, p2.mo.x,p2.mo.y),
					aiming = R_PointToAngle2(0, p.mo.z, dist, p2.mo.z),
					dist = dist,
				}
			) then
				continue
			end
			
			--no need to check for angles if we're touchin the guy
			if dist > p.mo.radius + p2.mo.radius
				local adiff = FixedAngle(
					AngleFixed(R_PointToAngle2(p.mo.x, p.mo.y, p2.mo.x, p2.mo.y)) - AngleFixed(p.cmd.angleturn << 16)
				)
				if AngleFixed(adiff) > 180*FU
					adiff = InvAngle($)
				end
				if (AngleFixed(adiff) > 115*FU)
					continue
				end
			end
			
			local ignore = false
			local hook_event = MM.events["AttackPlayer"]
			for i,v in ipairs(hook_event)
				if MM.tryRunHook("AttackPlayer", v,
					p, p2, item, (item.damage or false)
				) then
					ignore = true
					continue
				end
			end
			
			if ignore then
				continue
			end
			
			if item.damage then
				P_KillMobj(p2.mo, item.mobj, p.mo, 999)
				
				if item.silencedkill then
					S_StopSound(p2.mo)
				end
			end
			
			if def.onhit then
				def.onhit(item,p,p2)
			end
			
			item.anim = min(item.max_anim/3, $)
			if item.hitsfx and (item.hit >= item.max_hit - 1) then
				S_StartSound(p.mo, item.hitsfx)
			end
			hitsomething = true
			
			if item.onlyhitone
				item.hit = 0
				break
			end
			continue
		end
		
		if not hitsomething
		and def.onmiss
			def.onmiss(item,p)
		end
	end
end)