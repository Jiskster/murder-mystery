dofile "Clues/freeslot"

local GetMobjSpawnHeight, GetMapThingSpawnHeight = MM.require "Libs/MapThingLib"
local choosething = MM.require "Libs/choosething"
local shallowCopy = MM.require "Libs/shallowCopy"
local ZCollide = MM.require "Libs/zcollide"
local CLUE_MAXBOUNCE = 2*FU

local clueitemtiers = {
	[1] = {
		"shotgun",
		"revolver",
		"sword",
	},
	[2] = {
		"loudspeaker",
		"snowball",
		"toyknife",
	},
	[3] = {
		"bloxycola",
		"burger",
		"radio",
	}
}

local CLUE_FLOOROFF = 20*FU
function MM:spawnClueMobj(p, pos)
	local mobj = P_SpawnMobj(pos.x, pos.y, pos.z, MT_MM_CLUESPAWN)

	mobj.state = S_MM_CLUE_DEFAULT
	mobj.frame = $|FF_FULLBRIGHT
	mobj.tics = -1
	mobj.fuse = -1
	mobj.drawonlyforplayer = p
	mobj.color = p.skincolor
	mobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
	mobj.target = p.mo
	
	local mul = FU*2
	mobj.spritexscale = mul
	mobj.spriteyscale = mul
	
	mobj.clue_bounce = 0
	mobj.clue_momz = CLUE_MAXBOUNCE

	if pos.flip then
		mobj.eflags = $|MFE_VERTICALFLIP
		mobj.flags2 = $|MF2_OBJECTFLIP
	end
	
	--try to not have them on the ground
	if (mobj.z <= mobj.floorz)
	or (mobj.z+mobj.height >= mobj.ceilingz)
		local sign = (mobj.z+mobj.height >= mobj.ceilingz) and -1 or 1
		mobj.z = $ + FixedMul(CLUE_FLOOROFF, mobj.scale) * sign
	end
	
	if MM.clues_singlemode
		mobj.flags2 = $|MF2_DONTDRAW
	end

	return mobj
end

local fallbackNums = {
	[303] = true,
	[330] = true,
	[331] = true,
	[332] = true,
	[333] = true,
	[334] = true,
	[335] = true
}

function MM:giveOutClues(amount)
	--Bruh
	if (MM_N.dueling) then return end
	
	MM_N.clues_positions = {}
	local fallbackThings = {}
	--local useNewClues = false
	
	MM.clues_singlemode = false
	if (mapheaderinfo[gamemap]
	and mapheaderinfo[gamemap].mm_singleclues ~= nil)
		MM.clues_singlemode = true
	end

	for thing in mapthings.iterate do
		if thing.type ~= mobjinfo[MT_MM_CLUESPAWN].doomednum then
			if fallbackNums[thing.type] then
				table.insert(fallbackThings, thing)
			end
			continue
		end
		
		local newPos = {}
		
		newPos.x = thing.x*FU
		newPos.y = thing.y*FU
		
		local z = GetMapThingSpawnHeight(MT_MM_CLUESPAWN, thing, newPos.x, newPos.y)
		newPos.z = z
		
		newPos.flip = (thing.options & MTF_OBJECTFLIP)
		
		table.insert(MM_N.clues_positions, newPos)
	end
	
	if not #MM_N.clues_positions
	and #fallbackThings then
		for _, thing in ipairs(fallbackThings) do
			-- i love copying code!!
			local newPos = {}
			
			newPos.x = thing.x*FU
			newPos.y = thing.y*FU
			
			local z = GetMapThingSpawnHeight(MT_MM_CLUESPAWN, thing, newPos.x, newPos.y)
			newPos.z = z
			
			newPos.flip = (thing.options & MTF_OBJECTFLIP)
			
			table.insert(MM_N.clues_positions, newPos)
		end
	end
	
	if not (#MM_N.clues_positions) then return end
	
	--weird issue where it would default to 5 even if theres more clue amounts?
	amount = min(#MM_N.clues_positions, amount)
	MM_N.clues_amount = amount
	
	for p in players.iterate do
		MM:InitPlayerClues(p)
	end
end


MM:addPlayerScript(function(p)
	local removalList = {}

	if (leveltime <= 1) then return end
	if (p.mm.clues == nil) then return end
	
	--we shouldnt have to do this
	p.mm.clues.list = $ or {}
	for i,clue in ipairs(p.mm.clues.list) do
		if not (clue.mobj and clue.mobj.valid) then
			clue.mobj = MM:spawnClueMobj(p, clue.ref)
		end
		
		local pos = clue.ref
		local mo = clue.mobj
		
		mo.color = p.skincolor
		if (p.realmo and p.realmo.valid)
			mo.scale = p.realmo.scale
		end
		
		if p.mm.clues.current ~= nil
		and clue ~= p.mm.clues.current
			mo.flags2 = $|MF2_DONTDRAW
			continue
		end
		mo.flags2 = $ &~MF2_DONTDRAW
		
		--dont "spy" on clues on mapstart
		if (leveltime == 0)
		and MM.clues_singlemode
			mo.flags2 = $|MF2_DONTDRAW
		end
		
		do
			mo.clue_momz = $ - FU/4
			
			mo.clue_bounce = $ + mo.clue_momz
			if mo.clue_bounce <= 0
				mo.clue_bounce = 0
				mo.clue_momz = CLUE_MAXBOUNCE
			end
		end
		mo.spriteyoffset = mo.clue_bounce
		
		mo.shadowscale = (FU / 6) + (FU - (FixedDiv(mo.spriteyoffset, 7*FU)) / 10)
		
		if P_RandomChance(FU/2)
			local wind = P_SpawnMobj(
				mo.x + P_RandomRange(-18,18)*p.mo.scale,
				mo.y + P_RandomRange(-18,18)*p.mo.scale,
				mo.z + (p.mo.height/2) + P_RandomRange(-20,20)*p.mo.scale,
				MT_BOXSPARKLE
			)
			wind.frame = $|FF_FULLBRIGHT
			wind.drawonlyforplayer = p
			wind.renderflags = $|RF_FULLBRIGHT
			P_SetObjectMomZ(wind,P_RandomRange(1,3)*FU)
		end
		
		-- Ugh (FNF)
		if ((mo.ceilingz - mo.floorz) > mo.height + FixedMul(CLUE_FLOOROFF*2, mo.scale))
			if (mo.z + mo.height > mo.ceilingz - FixedMul(CLUE_FLOOROFF, mo.scale))
				mo.z = mo.ceilingz - mo.height - FixedMul(CLUE_FLOOROFF, mo.scale)
			elseif (mo.z < mo.floorz + FixedMul(CLUE_FLOOROFF, mo.scale))
				mo.z = mo.floorz + FixedMul(CLUE_FLOOROFF, mo.scale)
			end
		-- "There isn't enough room up here..."
		else
			--Set it to the middle of the sector once
			if not mo.threshold
				local sec_height = mo.ceilingz - mo.floorz
				mo.z = mo.floorz + sec_height/2 - (mo.height/2)
				mo.threshold = 1
			end
		end
		
		--debugging + actual purpose
		mo.radius = p.mo.radius*3/2
		mo.height = p.mo.height*3/2
		if abs(p.mo.x-pos.x) > mo.radius + p.mo.radius
		or abs(p.mo.y-pos.y) > mo.radius + p.mo.radius
		or not ZCollide(p.mo, mo) then
			continue
		end
		
		table.insert(removalList, clue)
	end

	for _,remove in pairs(removalList) do
		for i,clue in pairs(p.mm.clues.list) do
			if clue == remove then
				local text = "CLUE FOUND!"
				
				S_StartSound(p.mo, sfx_cluecl,p)
				if clue.mobj.valid then
					P_RemoveMobj(clue.mobj)
				end
				
				table.remove(p.mm.clues.list, i)
				if p.mm.clues.current ~= nil
					p.mm.clues.current = choosething(unpack(p.mm.clues.list))
				end
				
				local subtext = tostring(#p.mm.clues.list).."/"..tostring(p.mm.clues.amount).." remaining..."
				
				if not (#p.mm.clues.list) then
					text = "YOU FOUND THEM ALL!"
					subtext = "Your clues gave you a weapon!"
					local sub2 = nil
					
					local reward = ''
					if p.mm.role == MMROLE_MURDERER
						reward = "luger"
					else
						if MM_N.clues_weaponsleft
							if P_RandomChance(FU/8) then
								reward = clueitemtiers[1][P_RandomRange(1, #clueitemtiers[1])]
							else
								reward = clueitemtiers[2][P_RandomRange(1, #clueitemtiers[2])]
								subtext = "Your clues gave you a useful item!"
							end
							
							MM_N.clues_weaponsleft = $-1
						else
							reward = clueitemtiers[3][P_RandomRange(1, #clueitemtiers[3])]
							subtext = "Your clues gave you an item!"
							sub2 = "Try being faster next time!"
						end
					end
					
					if isdedicatedserver then
						print(string.format('%s [%s] got item "%s" from a clue!', p.name, #p, reward))
					end
					
					local item = MM:GiveItem(p, reward)
					if p.mm.role ~= MMROLE_MURDERER -- Don't let other people pick up your hard work!
						if not item.droppable_clue then
							item.droppable = false
							item.allowdropmobj = false
						end
					end
				end
				
				if p == displayplayer then
					MMHUD:PushToTop(3*TICRATE, text, subtext, sub2)
				end
				
				if CV_MM.wip_dynamic_time.value then
					MM_N.time = max(30*TICRATE, $ - 30*TICRATE)
					MM_N.uncap_timer = true
				end
				
				break
			end
		end
	end
end)

--garbage collection
addHook("MobjThinker",function(clue)
	if not (clue and clue.valid) then return end
	
	local me = clue.target
	if not (me and me.valid)
		P_RemoveMobj(clue)
		return
	end
	
	local p = me.player
	if (p.spectator)
		P_RemoveMobj(clue)
		return
	end	
end,MT_MM_CLUESPAWN)