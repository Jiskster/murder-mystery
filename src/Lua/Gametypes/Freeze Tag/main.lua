-- NOTE: I don't intend showdown to be in this mode - Jisk

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
	small_name = "FT"; -- unused: was for the rolling animation in the vote.
	max_time = 4*60*TICRATE;
	disable_overtime = true;
	disable_sheriff = true;
	disable_item_mapthing = true; -- includes interactions that drop items.
	freezetag_core = true;
	tamer_tripmine = true; -- uses damage function instead of kill
	unlock_spectating = true;
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

local function freezePlayer(player, attacker)
	if not player.freezetagged and not player.powers[pw_invulnerability] then
		S_StartSound(player.mo, sfx_iceb)
		player.freezetagged = true
		
		local alivecount = 0
		for p in players.iterate
			if not (p.mm) then continue end
			if not (p.mm_save) then continue end
			if (p.mm.lastafkmode and p.spectator) then continue end
			if (p.mm.role ~= MMROLE_INNOCENT) then continue end
			if (p.freezetagged) then continue end
			
			alivecount = $ + 1
		end
		
		if not alivecount then
			S_StartSound(nil,sfx_buzz3)
			S_StartSound(nil,sfx_s253)
			local facingangle = player.drawangle + ANGLE_180
			if (attacker.mo and attacker.mo.valid)
				facingangle = R_PointToAngle2(player.mo.x,player.mo.y, attacker.mo.x,attacker.mo.y)
			end
			MM:endGame(2)
			
			MM:startEndCamera(player.mo,
				facingangle,
				200*FU,
				6*TICRATE,
				FU/16
			)
			
			MM_N.killing_end = true
			MM_N.end_killed = player.mo
			MM_N.end_killer = attacker.mo
			
			MM:discordMessage("***The round has ended!***\n")
		end
	end
end

local function unfreezePlayer(player)
	if player.freezetagged then
		player.powers[pw_nocontrol] = 0
	end
	
	player.freezetagged = false
	removeFreezeMobjs(player)
end

MM:addPlayerScript(function(player)
	if player.unfreezecooldown then
		player.unfreezecooldown = max(0, $ - 1)
	end
	
	if player.mo and player.mo.valid then
		if player.freezetagged then
			frozenTextThink(player)
			frozenGhostThink(player)
			player.powers[pw_nocontrol] = 2
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
			freezePlayer(tplayer, attacker.player)
			
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
			freezePlayer(tplayer, attacker.player)
			
			return false
		end
	end
end

local function zCollide(mo1, mo2)
	if mo1.z > mo2.z+mo2.height then return false end
	if mo2.z > mo1.z+mo1.height then return false end
	return true
end

addHook("MobjDeath", deathfunc, MT_PLAYER);
MM.addHook("ShouldDamage", damagefunc);

MM.addHook("AttackPlayer", function(p, p2, item, isDamage)
	if not isDamage then return end
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end

	if (p2.mo and p2.mo.valid) and p.mm.role == MMROLE_MURDERER and p2.mm.role ~= p.mm.role then
		freezePlayer(p2, p)
		
		return true
	end	
end)

MM.addHook("KilledPlayer", function(attacker, target)
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end
	
	if attacker.mm.role == MMROLE_MURDERER then
		freezePlayer(target, attacker)
		
		return true
	end	
end)

MM.addHook("PostMapLoad", function()
	for player in players.iterate do
		unfreezePlayer(player)
	end
end)

addHook("MobjMoveCollide", function(tmthing, thing)
	if not MM.Gametypes[MM_N.gametype].freezetag_core then return end
	
	if zCollide(tmthing, thing) then
		local tm_player = tmthing.player
		local player = thing.player
		
		if tm_player and tm_player.valid and player and player.valid 
		and tm_player.mm and player.mm 
		and tm_player.mm.role == MMROLE_INNOCENT and player.mm.role == MMROLE_INNOCENT 
		and not tm_player.powers[pw_invulnerability] and player.freezetagged 
		and not tm_player.freezetagged and not tm_player.unfreezecooldown then
			unfreezePlayer(player)
			tm_player.unfreezecooldown = 5*TICRATE
			thing.alpha = FRACUNIT -- come backk!!
			player.powers[pw_invulnerability] = 85
			S_StartSound(thing, sfx_ncitem)
		end
	end
end, MT_PLAYER)