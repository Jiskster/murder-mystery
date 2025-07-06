-- Simple lua to run hooks for the mod.
-- Adds easy modding support and more!

/*
	HOOK LIST:

	--[Game]--
		* "PostMapLoad", function()
			Executes once MM has given out clues, set the number of murderers, and after the map has loaded.
			
		* "Init", function()
			Executes once MM has set the number of murderers, but before the map has loaded and before
			clues have been given out.
			
	--[Player]--
		* "PlayerInit", function(player_t, boolean midgame?)
			Executes when a player spawns in and all MM variables are initialized.
			If "midgame?" true, then the player joined midgame as a spectator 
			
		* "PlayerThink", function(player_t player)
			Executes when an alive player thinks during a round
			
		* "DeadPlayerThink", function(player_t player)
			Executes when a dead player/spectator thinks during a round
			
		* "CorpseSpawn", function(mobj_t target, mobj_t corpse)
			Executes when a player mobj "target" dies and spawns mobj "corpse"
			
		* "CorpseThink", function(mobj_t corpse)
			Executes when a corpse thinks. "Even dead enemies think"
			
		* "CorpseFound", function(mobj_t corpse, mobj_t finder)
			Executes when player mobj "finder" finds "corpse"
			
		* "GiveStartWeapon", function(player_t)
			Executes when MM decides to give the player their role's item.
			Runs even when the player is an Innocent, and in duels too.
			- Return value(s):
				Boolean (don't give item?)
				or
				Strings (item name, variable arguments)
	
	--[Movement]--
		* "PreMovementTick", function(player_t)
			Executes after player variable nerfs, but not before movement logic.
		
		* "PostMovementTick", function(player_t)
			Executes after movement logic and player variable nerfs.

		* "SkidStart", function(player_t)
			Once the player starts to skid, this hook runs.
		
		* "SkidFinish", function(player_t)
			Once the player finishes skidding, this hook runs.
		
		* "MovementSpeedCap", function(player_t, fixed_t speedcap)
			Executes upon setting the speed cap that the player should walk at.
			- Return value: fixed_t (override speed cap?)
	
	--[Items]--
		* "InventorySwitch", function(player_t player, int cur_slot, int new_slot, item_t cur_item, item_t new_item)
			Executes when a player decides to switch inventory slots, but before
			the switching executes.
			- Return value: Boolean (override default behavior?)
			
		* "ItemDrop", function(player_t player, itemdef_t def, item_t item)
			Executes when a player drops an item by choice. This will not trigger
			during pregame or when forcibly dropped, like when a murderer picks up the
			revolver, for example.
			- Return value: Boolean (override default behavior?)
			
		* "ItemUse", function(player_t player, itemdef_t def, item_t item)
			Executes when a player uses a weapon that fires bullets.
			- Return value: Boolean (override default behavior?)
			
		* "DropItemThinker", function(itemdef_t, mobj_t item)
			Executes after dropped item thinker.

		* "AttackPlayer", function(player_t inflictor, player_t target)
			Executes when player "inflictor" uses a melee weapon and hits player "target."
			- Return value: Boolean (don't hit target?, nil = use default behavior)
			
		* "CreateAlias", function(player_t player, table alias)
			Executes when the Body Swap Potion creates an alias of "player" when swapped with someone.
			
		* "ApplyAlias", function(player_t player, table alias)
			Executes when the Body Swap Potion applies an alias for "player" when swapping with someone.
*/

local handler_snaptrue = {
	func = function(current, ...)
		local arg = {...}
		return (#arg and true or false) or current
	end,
	initial = false
}

local handler_snapany = {
	func = function(current, ...)
		local arg = {...}
		if #arg then
			return unpack(arg)
		else
			return current ~= nil and unpack(current) or nil
		end
	end,
	initial = nil
}
local handler_default = handler_snaptrue

local events = {}
events["PostMapLoad"] = {}
events["Init"] = {}
events["PlayerInit"] = {}
events["PlayerThink"] = {}
events["DeadPlayerThink"] = {}
events["SkidStart"] = {}
events["SkidFinish"] = {}
events["PreMovementTick"] = {}
events["PostMovementTick"] = {}
events["MovementSpeedCap"] = {}
events["CorpseSpawn"] = {}
events["CorpseThink"] = {}
events["CorpseFound"] = {}
events["GiveStartWeapon"] = {handler = handler_snapany}
events["InventorySwitch"] = {}
events["DropItemThinker"] = {}
events["ItemDrop"] = {}
events["ItemUse"] = {}
events["AttackPlayer"] = {}
events["CreateAlias"] = {}
events["ApplyAlias"] = {}
events["OnRawChat"] = {}
events["KilledPlayer"] = {}

MM.addHook = function(hooktype, func)
	if events[hooktype] then
		table.insert(events[hooktype], {
			func = func,
			errored = false
		})
	else
		error("\x83MM: \x82WARNING:\x80 Hook type \""..hooktype.."\" does not exist.", 2)
	end
end

MM.tryRunHook = function(hooktype, v, ...)
	local handler = events[hooktype].handler or handler_default
	local override = handler.initial

	local results = {pcall(v.func, ...)}
	local status = results[1]
	table.remove(results,1)
	
	if status then
		override = {handler.func(
			override,
			unpack(results)
		)}
	elseif not v.errored then
		v.errored = true
		S_StartSound(nil,sfx_lose)
		print("\x83MM: \x82WARNING:\x80 Hook " .. hooktype .. " handler #" .. i .. " error:")
		print(result)
	end
	
	if override == nil then return nil; end
	return unpack(override)
end

MM.events = events
MM.runHook = function()
	error("MM.runHook is deprecated, please use MM.tryRunHook instead.")
	return false
end

MM.hooksPassed = function(eventname, ...)
	local args = {...}
	local hook_event = MM.events[eventname]
	for i,v in ipairs(hook_event)
		if MM.tryRunHook(eventname, v,
			unpack(args) -- i dont know lua syntax enough to know if passing '...' is valid
		) then
			return false
		end
	end
	return true
end