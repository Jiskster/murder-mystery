local getCount = MM.require "Libs/getCount"
local randomPlayer = MM.require "Libs/getRandomPlayer"
local roles = MM.require "Variables/Data/Roles"
local lostgun = roles[MMROLE_SHERIFF].weapon or "revolver"

local guns = {
	[lostgun] = true,
	["shotgun"] = true,
	--lol
	["sword"] = true,
}

local function _eligibleGunPlayer(p)
	local hasfreeslot = false
	local hasgun = false
	local inv = p.mm.inventory
	for i = 1, inv.count
		if inv.items[i] == nil
			hasfreeslot = true
			continue
		end
		if guns[inv.items[i].id] == true
			hasgun = true
		end
	end
	
	return (p
	and p.mo
	and p.mo.valid
	and p.mo.health
	and p.mm
	and not (p.mm.spectator or p.spectator)
	and p.mm.role ~= MMROLE_MURDERER
	and hasfreeslot
	and not hasgun)
end

--refill any empty murd/sheriff slots left by players who left
--this is a bad place to put this function
local function refillSlots()
	if MM_N.dueling then return end
	if not MM:pregame() then return end
	
	local count = MM.countPlayers(true)
	local maxrole = MM_N.special_count

	if count.total - count.inactive <= 1
		MM_N.waiting_for_players = true
		return
	end
	
	if count.murderers < maxrole
	or count.sheriffs < maxrole
		local neededrole = min(count.murderers, count.sheriffs)
		MM:assignRoles(maxrole - neededrole,
			true,
			count.murderers < count.sheriffs
		)
		if CV_MM.debug.value
			print("\x83MM:\x80 Special roles too low! Reassigning roles... (required: ".. MM_N.special_count ..", needed: "..neededrole..")")
			print("\x83MM:\x80 extra "..(count.murderers < count.sheriffs and "Murderers" or "Sheriffs").. "needed")
		end
	end
end

return function()
	if (MM.Gametypes[MM_N.gametype].disable_sheriff) then return end
	if (MM_N.dueling) then return end
	refillSlots()
	if (CV_MM.debug.value) then return end
	
	local _,innocents = getCount()

	-- gun management
	if not ((not MM:pregame())
	and (not MM:playerWithGun())
	and innocents >= 1) then
		MM_N.gavegun = nil
		return
	end
	
	--shitty
	if (MM_N.gavegun)
		MM_N.gavegun = nil
		return
	end

	local wpns = MM:GetCertainDroppedItems(lostgun)
	if #wpns then
		for _,wpn in ipairs(wpns) do
			if wpn.timealive == nil then
				wpn.timealive = 0
			end
			
			wpn.timealive = $+1
			
			if wpn.timealive >= 20*TICRATE then
				-- give player gun
				local p = randomPlayer(_eligibleGunPlayer)
				if p then
					MM:GiveItem(p, lostgun)
					MM_N.gavegun = true
					
					for play in players.iterate do
						if play == p then
							chatprintf(play,"\x82*You have been given the gun!",true)
						else
							chatprintf(play,"\x82*A random player has received the gun due to inactivity!")
						end
					end
					
					MM:discordMessage("***A random player has received the gun due to inactivity!***\n")
					P_RemoveMobj(wpn)
				end
			end
		end
		
	else
		local p = randomPlayer(_eligibleGunPlayer)
		if p and not MM:canGameEnd() then
			MM:GiveItem(p, lostgun)
			for play in players.iterate
				if play == p
					chatprintf(play,"\x82*You have been given the gun!",true)
				else
					chatprintf(play,"\x82*A random player has received the gun due to the gun despawning!")
				end
			end
			MM:discordMessage("***A random player has received the gun due to the gun despawning!***\n")
		end
	end
end