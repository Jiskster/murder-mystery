freeslot("MT_FROZENTEXTANIM", "S_FROZENTEXTANIM", "SPR_FROZENTEXTANIM")

mobjinfo[MT_FROZENTEXTANIM] = {
	spawnstate = S_FROZENTEXTANIM;	
	height = 12*FRACUNIT;
	radius = 16*FRACUNIT;
	flags = MF_NOCLIP|MF_NOCLIPTHING|MF_NOBLOCKMAP
}

states[S_FROZENTEXTANIM] = {
	sprite = SPR_FROZENTEXTANIM,
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 4,
	var2 = 2,
	tics = -1,
	nextstate = SPR_FROZENTEXTANIM
}

local freezetag_mode = MM.RegisterGametype("Freeze Tag", {
	max_time = 4*60*TICRATE;
	disable_overtime = true;
	disable_sheriff = true;
	disable_item_mapthing = true; -- includes interactions that drop items.
	freezetag_core = true;
	tamer_tripmine = true; -- uses damage function instead of kill
})

local function frozenTextThink(player)
	if not (player.mo.frozeobjtext and player.mo.frozeobjtext.valid) then
		player.mo.frozeobjtext = P_SpawnMobj(player.mo.x, player.mo.y, player.mo.z + (3*player.mo.height)/2, MT_FROZENTEXTANIM)
		player.mo.frozeobjtext.spritexscale = FU/2
		player.mo.frozeobjtext.spriteyscale = FU/2
	else
		local textobj = player.mo.frozeobjtext
		P_MoveOrigin(textobj, player.mo.x, player.mo.y, player.mo.z + (3*player.mo.height)/2)
		textobj.momx = player.mo.momx
		textobj.momy = player.mo.momy
		textobj.momz = player.mo.momz
	end
end

local function frozenGhostThink(player)
	if not (player.mo.frozeobjghost and player.mo.frozeobjghost.valid) then
		player.mo.frozeobjghost = P_SpawnGhostMobj(player.mo)
		player.mo.frozeobjghost.fuse = -1
		player.mo.frozeobjghost.color = SKINCOLOR_SKY
		player.mo.frozeobjghost.colorized = true
	else
		local ghostobj = player.mo.frozeobjghost
		P_MoveOrigin(ghostobj, player.mo.x, player.mo.y, player.mo.z)
		ghostobj.momx = player.mo.momx
		ghostobj.momy = player.mo.momy
		ghostobj.momz = player.mo.momz
		player.mo.alpha = 0
	end
end

local function removeFreezeMobjs(player)
	-- Remove Remaining Freeze Objects
	local ghostobj = player.mo.frozeobjghost
	local textobj = player.mo.frozeobjtext
	
	if ghostobj and ghostobj.valid then
		player.mo.frozeobjghost = nil
		P_RemoveMobj(ghostobj)
	end
	
	if textobj and textobj.valid then
		player.mo.frozeobjtext = nil
		P_RemoveMobj(textobj)
	end
end

local function unfreezePlayer(player)
	player.freezetagged = false
	removeFreezeMobjs(player)
end

MM:addPlayerScript(function(player)
	if player.mo and player.mo.valid then
		if player.freezetagged then
			frozenTextThink(player)
			frozenGhostThink(player)
		else
			removeFreezeMobjs(player)
		end
	else
		removeFreezeMobjs(player)
	end
end)

-- So many damn hooks OMFG

-- Tell me a better way to make both of these hooks
local deathfunc = function(target, inflictor, source, damage)
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end
	
	if target and target.valid and target.player and target.player.valid then
		local tplayer = target.player
		local attacker
		
		if source and source.valid and source.player and source.player.valid then
			attacker = source
		elseif inflictor and inflictor.valid and inflictor.player and inflictor.player.valid then
			attacker = inflictor
		end
		
		if attacker and attacker.player and (attacker.player.mm and tplayer.mm) 
		and attacker.player.mm.role == MMROLE_MURDERER and attacker.player.mm.role ~= tplayer.mm.role then
			if not tplayer.freezetagged then
				S_StartSound(target, sfx_iceb)
				tplayer.freezetagged = true
			end
			
			return true
		end
	end
end

local damagefunc = function(target, inflictor, source, damage)
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end
	
	if target and target.valid and target.player and target.player.valid then
		local tplayer = target.player
		local attacker
		
		if source and source.valid and source.player and source.player.valid then
			attacker = source
		elseif inflictor and inflictor.valid and inflictor.player and inflictor.player.valid then
			attacker = inflictor
		end
		
		if attacker and attacker.player and (attacker.player.mm and tplayer.mm) 
		and attacker.player.mm.role == MMROLE_MURDERER and attacker.player.mm.role ~= tplayer.mm.role then
			if not tplayer.freezetagged then
				S_StartSound(target, sfx_iceb)
				tplayer.freezetagged = true
			end
			
			return false
		end
	end
end

addHook("MobjDeath", deathfunc, MT_PLAYER);
MM.addHook("ShouldDamage", damagefunc);

MM.addHook("AttackPlayer", function(p, p2, item, isDamage)
	if not isDamage then return end
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end

	if (p2.mo and p2.mo.valid) and p.mm.role == MMROLE_MURDERER and p2.mm.role ~= p.mm.role then
		if not p2.freezetagged then
			S_StartSound(p2.mo, sfx_iceb)
			p2.freezetagged = true
		end
		
		return true
	end	
end)

MM.addHook("KilledPlayer", function(attacker, target)
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end
	
	if attacker.mm.role == MMROLE_MURDERER then
		if not target.freezetagged then
			S_StartSound(target.mo, sfx_iceb)
			target.freezetagged = true
		end
		
		return true
	end	
end)

MM.addHook("PostMapLoad", function()
	for player in players.iterate do
		unfreezePlayer(player)
	end
end)