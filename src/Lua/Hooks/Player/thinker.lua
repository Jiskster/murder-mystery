local scripts = {}
local global_scripts = {}

function MM:addPlayerScript(file, global)
	local func = file

	if global then
		global_scripts[#global_scripts+1] = func
		return
	end
	scripts[#scripts+1] = func
end

addHook("PlayerThink", function(p)
	if not MM:isMM() then return end

	if not p.mm then
		MM:playerInit(p)
	end

	for _,script in ipairs(global_scripts) do
		script(p)
	end

	--Force a respawn
	--why was the " and p.mo.health" part removed?
	if not (p.mo and p.mo.valid and p.mo.health) then
		if p.deadtimer >= 3*TICRATE
		and p.playerstate == PST_DEAD
			G_DoReborn(#p)
			p.deadtimer = 0
		end
		
		p.mm.oob_ticker = 0
		
		local hook_event = MM.events["DeadPlayerThink"]
		for i,v in ipairs(hook_event)
			MM.tryRunHook("DeadPlayerThink", v,
				p
			)
		end
		
		return
	end

	p.spectator = p.mm.spectator
	if p.mm.spectator then
		local hook_event = MM.events["DeadPlayerThink"]
		for i,v in ipairs(hook_event)
			MM.tryRunHook("DeadPlayerThink", v,
				p
			)
		end
		return
	end
	
	for _,script in ipairs(scripts) do
		script(p)
	end

	local hook_event = MM.events["PlayerThink"]
	for i,v in ipairs(hook_event)
		MM.tryRunHook("PlayerThink", v,
			p
		)
	end
	
	if not (MM_N.gameover
	or MM:pregame())
		p.mm.timesurvived = $+1
	end
	
	-- Check if valid again, hooks could kill the player.
	if not (p.mo and p.mo.valid) then
		return
	end

    if (p.mo.fake_drawangle ~= nil) then
        p.drawangle = p.mo.fake_drawangle
        p.mo.angle = p.drawangle
    end
	
	if p.mm.outofbounds and not MM_N.gameover
		if (not p.mm.oob_lenient)
		--or (leveltime % 2 == 0)
			p.mm.oob_ticker = min($+1,MM_PLAYER_STORMMAX)
		else
			p.mm.oob_ticker = -1
		end
		
		local sec = (p.mo.subsector.sector)
		
		if displayplayer and displayplayer.mo and displayplayer.mo.valid
		and (displayplayer == p)
			if not S_SoundPlaying(displayplayer.mo,sfx_mmstm1)
				S_StartSound(displayplayer.mo,sfx_mmstm1)
			end
			if not S_SoundPlaying(displayplayer.mo,sfx_mmstm2)
				S_StartSound(displayplayer.mo,sfx_mmstm2)
			end
		end
		
		if sec and sec.valid
			if sec.ceilingpic ~= "F_SKY1"
			and (leveltime & 1)
				local thunderchance = (P_RandomKey(8192))
				local strike = thunderchance < 90
				
				if strike
					S_StartSoundAtVolume(p.mo, sfx_litng1 + P_RandomKey(4), 255, p)
					MM.NearbyLightning({
						x = p.mo.x,
						y = p.mo.y,
						z = p.mo.z
					})
				elseif (thunderchance < 110)
					S_StartSoundAtVolume(p.mo, sfx_athun1 + P_RandomKey(2), 80, p)
				end
			end
		end
		
		do
			local rad = FixedDiv(p.mo.radius,p.mo.scale)/FU
			local hei = FixedDiv(p.mo.height,p.mo.scale)/FU
			for i = 0,1
				local spark = P_SpawnMobjFromMobj(p.mo,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(0,hei)*FU,
					MT_WATERZAP
				)
				spark.color = SKINCOLOR_GALAXY
				spark.colorized = true
				spark.angle = R_PointToAngle2(spark.x,spark.y, p.mo.x,p.mo.y) + ANGLE_90
				spark.renderflags = $|RF_PAPERSPRITE|RF_NOCOLORMAPS
				spark.frame = $|FF_FULLBRIGHT|FF_ADD
				spark.scale = $ + P_RandomRange(0,FU/2)
			end
			
			if P_RandomChance(FU/2)
			and (leveltime % 3 == 0)
				local dust = P_SpawnMobjFromMobj(p.mo,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(-rad,rad)*FU,
					P_RandomRange(0,hei)*FU,
					MT_TNTDUST
				)
				dust.color = SKINCOLOR_GALAXY
				dust.colorized = true
				dust.scale = ($/2) + P_RandomRange(0,FU/2)
				dust.fuse = $/10
				dust.angle = R_PointToAngle2(dust.x,dust.y, p.mo.x,p.mo.y)
				P_Thrust(dust,dust.angle, -P_RandomRange(0,2)*dust.scale)
				P_SetObjectMomZ(dust,P_RandomRange(-2,2)*FU)
				dust.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
				dust.frame = $|FF_SEMIBRIGHT
			end
		end
		
		if p.mm.oob_ticker == MM_PLAYER_STORMMAX
		and p.mo.health
			p.mo.color = SKINCOLOR_GALAXY
			p.mo.colorized = true
			p.mo.stormkilledme = true
			P_KillMobj(p.mo)
		end
	else
		p.mm.oob_ticker = max($ - 4, 0)
		if (p.mo.health)
		and (displayplayer and displayplayer.mo and displayplayer.mo.valid)
		and (p == displayplayer)
			S_StopSoundByID(displayplayer.mo,sfx_mmstm1)
			S_StopSoundByID(displayplayer.mo,sfx_mmstm2)
		end
	end
end)

--when should we be forced into spectating?
MM.addHook("PlayerInit",function(p)
	if (p.mm_save and p.mm_save.afkmode)
	--force the duel to finish first
	or (MM_N.dueling)
		p.mm.joinedmidgame = true
		p.mm.spectator = true
		p.spectator = true
	end
	
	--Sure! (hacky fix to allow footsteps perk to be uneqiuped)
	if MM_PERKS
		--MM.Shop.buyItem(p, MM_PERKS.perkid_to_itemid[MMPERK_FOOTSTEPS], false)
		p.mm_save.purchased[MM_PERKS.perkid_to_itemid[MMPERK_FOOTSTEPS]] = true
	end
end)

MM:addPlayerScript(dofile("Hooks/Player/Scripts/Role Handler"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/PlayerRework"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/Map Vote"), true)
MM:addPlayerScript(dofile("Hooks/Player/Scripts/AFKHandle"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/SkinCorrector"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/Alias"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/InteractHandler"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/Teammates"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/AntiAbility"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/PerkHandler"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/ItemStrafe"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/CashInChecks"), true)
MM:addPlayerScript(dofile("Hooks/Player/Scripts/ForbidJoin"))
MM:addPlayerScript(dofile("Hooks/Player/Scripts/NoTeeter"))

addHook("KeyDown",function(key)
	if isdedicatedserver then return end
	if (chatactive) then return end
	if (key.repeated) then return end
	if MenuLib.client.currentMenu.id ~= -1 then return end
	
	local wp5_f, wp5_s = input.gameControlToKeyNum(GC_WEPSLOT5)
	
	if (key.num == wp5_f)
	or (key.num == wp5_s)
		MenuLib.initMenu(MenuLib.findMenu("MainMenu"))
	end
	
	--Manual replacement
	if key.name == "f1"
		MM.openMenu()
		return true
	end
end)