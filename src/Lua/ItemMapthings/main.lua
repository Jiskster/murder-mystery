freeslot "MT_MM_ITEMSPAWN"

mobjinfo[MT_MM_ITEMSPAWN] = {
	--$Name Item Spawner
	--$Sprite RVOLA2A8
	--$Category EPIC!MM
	--$NotAngled
	--$StringArg0 Item ID
	--$StringArg0ToolTip The item's ID to spawn.
	--$Arg0 Price
	--$Arg0Default 0
	--$Arg0Type 0
	--$Arg0Tooltip How many coins does this item cost to pick up?\nIf the player doesn't have enough coins, the item stays in place. 
	--$Arg1 Interact Duration
	--$Arg1Default 5
	--$Arg1Type 0
	--$Arg1Tooltip How long a player needs to interact (in tics) in order to activate.
	--$Arg2 Restrict
	--$Arg2Default 0
	--$Arg2Type 12
	--$Arg2Enum {1="Innocent"; 2="Sheriff"; 4="Murderer";}
	--$Arg2Tooltip Which roles can't interact with this point?
	flags = MF_NOGRAVITY|MF_NOBLOCKMAP,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	doomednum = 8003,
	spawnstate = S_NULL
}

local rolebits = {
	[MMROLE_INNOCENT] = 1 << 0,
	[MMROLE_SHERIFF] = 1 << 1,
	[MMROLE_MURDERER] = 1 << 2,
}

addHook("MapThingSpawn",function(mo,mt)
	if MM.Gametypes[MM_N.gametype].disable_item_mapthing then return end
	
	local item_id = mt.stringargs[0]
	local item_cost = mt.args[0]
	local item_pickuptime = mt.args[1]
	local item_restrict = mt.args[2]
	
	if MM.Items[item_id] then
		if item_id then
			if mo and mo.valid then
				local restrict = {}
				
				for teamnum,bit in pairs(rolebits) do -- i guess this is how you convert
					if (item_restrict & bit) then
						restrict[teamnum] = true
					end
				end
			
				MM:SpawnItemDrop(item_id, mo.x, mo.y, mo.z, mo.angle, 0, {
					price = item_cost;
					pickuptime = item_pickuptime;
					restrict = restrict;
					disablespawnslide = true; -- makes it so it doesnt slide when it spawns
				})
			end
		end
	end
end, MT_MM_ITEMSPAWN)