local function_list = {}
rawset(_G,"INTER_RANGE",64*FU)

local function onPoint(point1,point2)
	local x1,y1 = FixedFloor(point1.x),FixedFloor(point1.y)
	local x2,y2 = FixedFloor(point2.x),FixedFloor(point2.y)
	return (x1 == x2) and (y1 == y2)
end

--adds a function to the LUT and returns its ID
--use this funcion as an include, at the top and in whitespace (dont use during runtime)
--@identifier is a string to be used as a name/identifier
MM.addInteraction = function(func,identifier)
	if func == nil
		error("MM.addInteraction(): argument 1 must be a function",2)
		return
	end
	if identifier == nil
		error("MM.addInteraction(): argument 2 must be a string identifier",2)
		return
	end
	
	--does this func already exist?
	for k,thisfunc in ipairs(function_list)
		if thisfunc.func == func then
			return k
		end
	end
	
	table.insert(function_list,#function_list+1,{
		func = func,
		iden = identifier
	})
	return #function_list
end

--returns a function based on its identifier
MM.getInteraction = function(identifier)
	for k,thisfunc in ipairs(function_list)
		if thisfunc.iden == identifier then
			return thisfunc.func
		end
	end
	return nil
end

MM.interactFunction = function(p,mo,funcid)
	if funcid == 0 then return end
	if function_list[funcid] == nil then return end
	
	return function_list[funcid].func(p,mo)
end

--Only interact with the closest point of interest
MM.sortInteracts = function(p,a,b)
	if (a == nil) then return true end
	if (b == nil) then return false end
	
	if not (a.mo and a.mo.valid)
		return true
	end
	if not (b.mo and b.mo.valid)
		return false
	end
	
	--Bruh
	/*
	if (a.mo.dropip ~= nil and b.mo.dropid ~= nil)
	and (onPoint(a.mo, b.mo)
	or (#p.mm.interact.points == 2))
		return a.mo.dropid < b.mo.dropid
	end
	*/
	
	local aDist = R_PointToDist2(p.mo.x,p.mo.y, a.mo.x,a.mo.y)
	local bDist = R_PointToDist2(p.mo.x,p.mo.y, b.mo.x,b.mo.y)
	
	if bDist <= aDist then
		return false
	end
	return true
end

MM.canInteract = function(p,mobj) --Point of interest
	if p.mm.interact == nil then return false end
	if (p.spectator or p.mm.spectator) then return false end
	if (p.pflags & PF_STASIS or p.powers[pw_nocontrol]) then return false end
	
	local me = p.realmo
	
	if not (me.health) then return false end
	if not (me and me.valid) then return false end
	if not (mobj and mobj.valid) then return false end
	if (mobj.cooldown) then return false end
	
	if R_PointToDist2(me.x,me.y, mobj.x,mobj.y) > FixedMul(INTER_RANGE,max(me.scale,mobj.scale))+mobj.radius then return false end
	if not P_CheckSight(me,mobj) then return false end
	
	return true
end

/*@properties: a table that accepts multiple arguments, where the keys are the arguments
	name:			the name of the interaction (ex. "Button")
	intertext:		the description of the interaction (ex. "Press")
	
	itemdrop:		the item ID this interaction drops (ex. "knife")
	
	button:			the BT_* needed to activate (ex. BT_CUSTOM3)
	time:			the amount of time needed to interact (ex. TICRATE/2)
	funcid:			the ID of the interaction function
	price:			the ammount of rings needed to interact with this
	
	restrict:		a table or bitfield of which roles cannot interact with this
*/
MM.interactPoint = function(p,mobj,properties)
	if not MM.canInteract(p,mobj) then return end
	if (p.mm.interact.interacted) then return end
	if properties == nil then return end
	
	for k,inter in ipairs(p.mm.interact.points)
		--Dont add the same mobj multiple times
		if inter.mo == mobj
			return
		end
	end
	
	table.insert(p.mm.interact.points,{
		mo = mobj,
		name = properties.name or "Thing",
		
		interacttext = properties.intertext or "Interact",
		interacttime = properties.time or TICRATE/4,
		interacting = 0,
		timesinteracted = 0,
		
		restrict = properties.restrict or 0,
		
		button = properties.button or 0,
		timespan = 0,
		price = properties.price or 0,
		
		--the best way i can think of doing this without archiving a func
		--would be to have a lookup id to a LUT of funcs that another function
		--can add functions to
		func_id = properties.funcid or 0,
		
		itemdrop_id = properties.itemdrop,
		
		--idk what this is for
		hud = {
			xscale = 0,
			goingaway = false,
		}
	})
	if #p.mm.interact > 1
		table.sort(p.mm.interact.points,function(a,b)
			return MM.sortInteracts(p,a,b)
		end)
	end
end

local MT_Interaction = MM.addInteraction(function(p,mo)
	if mo.calling_tag ~= 0
		P_LinedefExecute(mo.calling_tag,p.mo)
	end
	mo.cooldown = mo.set_cooldown
end,"MapthingInteraction")

freeslot("MT_MM_INTERACT_POINT")
mobjinfo[MT_MM_INTERACT_POINT] = {
	--$Name Interaction Point
	--$Sprite BGLSD0
	--$Category EPIC!MM
	--$NotAngled
	
	--$StringArg0 Name
	--$StringArg0ToolTip The top text on the\ninteraction prompt. (Ex. Button)
	
	--$StringArg1 Action
	--$StringArg1ToolTip The bottom text on the\ninteraction prompt. (Ex. Press)
	
	--$Arg0 Interact Duration
	--$Arg0Default 0
	--$Arg0Type 0
	--$Arg0Tooltip How long a player needs to interact (in tics) in order to activate.
	
	--$Arg1 Button
	--$Arg1Type 11
	--$Arg1Enum {128="Spin"; 1024="Toss flag"; 4096="Fire Normal"; 32768="Custom 3";}
	--$Arg1Tooltip The button the player needs to hold.
	
	--$Arg2 Trigger Tag
	--$Arg2Default 0
	--$Arg2Type 0
	--$Arg2Tooltip This tag will be called when interacted with.
	
	--$Arg3 Cooldown
	--$Arg3Default 0
	--$Arg3Type 0
	--$Arg3Tooltip How long the point will need to wait (in tics) in order for players to interact with it again.\n Set to -1 for one-time use.
	
	--$Arg4 Restrict
	--$Arg4Default 0
	--$Arg4Type 12
	--$Arg4Enum {1="Innocent"; 2="Sheriff"; 4="Murderer";}
	--$Arg4Tooltip Which roles can't interact with this point?
	
	--$Arg5 Price
	--$Arg5Default 0
	--$Arg5Type 0
	--$Arg5Tooltip How many coins does this interaction cost?\nIf the player doesn't have enough coins, the interaction will fail. 
	
	flags = MF_NOGRAVITY|MF_NOSECTOR|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	doomednum = 8000,
	spawnstate = S_INVISIBLE
}

addHook("MapThingSpawn",function(mo,mt)
	mo.name = mt.stringargs[0]
	mo.desc = mt.stringargs[1]
	
	-- Item drop, only looks at the end of the description.
	if mo.desc ~= nil then
		local a1 = select(1, string.find(mo.desc, "item>>"))
		local a2 = select(2, string.find(mo.desc, "item>>"))
		
		if a1 ~= nil and a2 ~= nil then
			local item = string.sub(mo.desc, a2+1)
			mo.itemdrop = item
			
			mo.desc = $:sub(1, a1-1) -- Cut off item command.
		end
	end
	
	mo.duration = mt.args[0]
	mo.button = mt.args[1]
	mo.calling_tag = mt.args[2]
	mo.set_cooldown = mt.args[3]
	mo.cooldown = 0
	mo.restrict = mt.args[4]
	mo.price = mt.args[5]
end,MT_MM_INTERACT_POINT)

local rolebits = {
	[MMROLE_INNOCENT] = 1 << 0,
	[MMROLE_SHERIFF] = 1 << 1,
	[MMROLE_MURDERER] = 1 << 2,
}

addHook("MobjThinker",function(point)
	if point.cooldown ~= 0
		if point.cooldown ~= -1
			point.cooldown = $-1
		else
			--we dont need this anymore
			P_RemoveMobj(point)
		end
		return
	end
	
	for p in players.iterate
		if not p.mm then continue end
		if point.restrict & (rolebits[p.mm.role] or 0) then continue end
		
		if MM.Gametypes[MM_N.gametype].disable_item_mapthing and point.itemdrop then 
			continue 
		end
		
		MM.interactPoint(p, point, {
			name = point.name,
			intertext = point.desc,
			itemdrop = point.itemdrop,
			button = point.button,
			time = point.duration,
			price = point.price,
			restrict = point.restrict,
			funcid = MT_Interaction
		})
	end
end,MT_MM_INTERACT_POINT)