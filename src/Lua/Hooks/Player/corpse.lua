local wrapadd = MM.require("Libs/wrappedadd")

freeslot("SPR2_OOF_")
states[freeslot "S_PLAY_BODY"] = {
	sprite = SPR_PLAY,
	frame = SPR2_OOF_|A,
	tics = -1
}
spr2defaults[SPR2_OOF_] = SPR2_DEAD

sfxinfo[freeslot("sfx_dedbdy")] = {
	flags = SF_TOTALLYSINGLE,
	caption = "Body found"
}

local roles = MM.require "Variables/Data/Roles"

local function nodamage(me, i,s)
	local p = me.player
	
	P_DoPlayerPain(p,s,i)
    P_PlayRinglossSound(me,p)
end

addHook("ShouldDamage", function(me, inf, sor, d, dmgt)
	if not MM:isMM() then return end
	if MM:pregame() then return false; end
	if (dmgt & DMG_DEATHMASK) then return end
	
	local p = me.player
	if (p.powers[pw_flashing]) then return end
	
	--sector damage?
	if not (sor and sor.valid)
	and not (inf and inf.valid)
		nodamage(me,sor,inf)
		return false
	end
	
	--damaging mobj?
	if not (sor and sor.valid and sor.player and sor.player.valid)
	and not (inf and inf.valid and inf.player and inf.player.valid)
		nodamage(me,sor,inf)
		return false
	end
end,MT_PLAYER)

addHook("MobjDeath", function(target, inflictor, source, dmgt)
	if not MM:isMM() then return end
	if MM:pregame() then return end
	
	--most likely map damage
	/*
	if not (inflictor and inflictor.valid and source and source.valid)
	and dmgt ~= DMG_DEATHPIT
		P_DoPlayerPain(target.player,target,target)
		P_PlayRinglossSound(target,target.player)
		return true
	end
	*/
	
	if not (target and target.valid and target.player and target.player.mm) then return end
	if target.player.mm.spectator or target.player.spectator then return end

	if not (MM_N.waiting_for_players or CV_MM.debug.value or MM_N.allow_respawn) then
		target.player.mm.spectator = true
	end

	for k,v in pairs(target.player.mm.inventory.items) do
		MM:DropItem(target.player, k, false, true, true)
	end
	
	if target.player.mm.role ~= MMROLE_MURDERER
		--people like to shoot each other and fall into pits,
		--so we wouldnt be able to get those kills
		--actually i changed my mind
		if (source and source.valid)
		and (source.player)
		and (source.player.mm.role == MMROLE_MURDERER)
			MM_N.peoplekilled = $+1
		end
	end
	
	--numbers for hacky hud stuff
	target.player.mm.whokilledme = source or 123123
	
	if (source
	and source.player
	and source.player.mm
	and target
	and target.player
	and target.player.mm
	and roles[source.player.mm.role].team == roles[target.player.mm.role].team
	and not roles[source.player.mm.role].cankillmates)
	and (source ~= target) --lol
		chatprintf(source.player, "\x82*That was not the murderer. You were killed for friendly fire! \x85(- $60)", true)
		source.player.mm_save.rings = max($ - 60, 0)
		S_StartSound(nil, sfx_antiri,source.player)
		P_DamageMobj(source, nil, nil, 999, DMG_INSTAKILL)
		
		target.player.mm.whokilledme = "Killed by someone else's stupidity."
	end
	
	--this is not a good place to put this
	if (inflictor and inflictor.valid)
	and (inflictor.type == MT_MM_KNIFE_PROJECT)
	and (
		source
		and source.player
		and source.player.mm
	) and R_PointToDist2(source.x,source.y, target.x,target.y) >= 100*source.scale
		chatprintf(source.player,
			"\x83*Ranged kill! (+ $10)",
			true
		)
		source.player.mm_save.ringstopay = wrapadd($, 10)
	end

	do
		local attacker;
		local attacker_mo;
		local target_player;

		if source and source.valid and source.player and source.player.valid then
			attacker = source.player
			attacker_mo = source
		elseif inflictor and inflictor.valid and inflictor.player and inflictor.player.valid then
			attacker = inflictor.player
			attacker_mo = inflictor
		end
		
		if target and target.valid and target.player and target.player.valid then
			target_player = target.player
		end
		
		-- hmmm what if we made this an item variable, like item.ammokillincrease = 2
		if attacker then
			--there is no reason to use MM.hooksPassed since we never do anything with the result
			--it would also prevent any other hooks from running which is not how these
			--"one shot" hooks work.
			local hook_event = MM.events["KilledPlayer"]
			for i,v in ipairs(hook_event)
				MM.tryRunHook("KilledPlayer", v, attacker, target_player)
			end
		end
	end
	
	if not MM:canGameEnd()
	and MM_N.special_count >= 2 then
		if target.player.mm.role ~= MMROLE_INNOCENT
			if target.player.mm.role == MMROLE_MURDERER
				local text = "\x82*"..target.player.name.." was a murderer!"
				
				/*
				if source
				and source.player then
					text = $.." // Died to "..source.player.name
				elseif source
					--died to an mobj
					text = $.." // Died to an mobj."
				else
					text = $.." // Died to a hazard."
				end
				*/
				
				chatprint(text)
				
				--add immediately so we KNOW.
				MM_N.knownDeadPlayers[#target.player] = true
			end
			
			local color = roles[target.player.mm.role].colorcode
			for p in players.iterate()
				if not (p.mm) then continue end
				if (p.mm.spectator) then continue end
				
				if (p.mm.role == target.player.mm.role)
					if (p == consoleplayer)
						MMHUD:PushToTop(5*TICRATE,
							"TEAMMATE DEAD",
							"Your teammate, "..color..target.player.name.."\x80 died!"
						)
						S_StartSound(nil,sfx_alart, consoleplayer)
					end
					p.mm.attract = {
						x = target.x,
						y = target.y,
						z = target.z,
						tics = 10*TICRATE,
						name = target.player.name
					}
				end
			end
		end
	end

	local angle = (inflictor and inflictor.valid) and R_PointToAngle2(target.x, target.y, inflictor.x, inflictor.y) or target.angle
	target.deathangle = angle
	
	if MM:canGameEnd() and not MM_N.gameover 
	and not (CV_MM.debug.value) then
		-- funny sniper sound
		if target.player.mm.role == MMROLE_MURDERER and source and source.valid then
			local dist = R_PointToDist2(
				R_PointToDist2(target.x, target.y, source.x, source.y), target.z,
				0, source.z
			)
			local required_dist = FU*800
			local required_speed = FU*20
			required_speed = FixedMul($, target.scale)
			
			if dist > required_dist and target.player.speed > required_speed then
				MM_N.sniped_end = true
				S_ChangeMusic("mmtf2o", false, nil)
			end
		end

		S_StartSound(nil,sfx_buzz3)
		S_StartSound(nil,sfx_s253)
		local facingangle = target.player.drawangle + ANGLE_180
		if (source and source.valid)
			facingangle = R_PointToAngle2(target.x,target.y, source.x,source.y)
		end
		MM:startEndCamera(target,
			facingangle,
			200*FU,
			6*TICRATE,
			FU/16
		)
		target.state = (target.player.mm.end_deathstate and S_PLAY_DEAD or S_PLAY_PAIN)
		target.flags2 = $ &~MF2_DONTDRAW
		target.angle = angle
		MM_N.killing_end = true
		
		if source and source.valid
			source.momx,source.momy = 0,0
		end
		
		--Sheriff Kills Murderer
		if target.player.mm.role == MMROLE_MURDERER
			MM_N.end_killed = target
			MM_N.end_killer = source
		--Someone kills non-murderer
		else
			MM_N.end_killed = source
			MM_N.end_killer = target
		end
		MM:discordMessage("***The round has ended!***\n")
		
		do
			local sherrifs = {}
			local murderers = {}
			for p in players.iterate
				if not (p.mm) then continue end
				
				local status = (p.mm.spectator) and " (Dead)" or ''
				if (p.mm.role == MMROLE_SHERIFF)
					table.insert(sherrifs,p.name..status)
				elseif (p.mm.role == MMROLE_MURDERER)
					table.insert(murderers,p.name..status)
				end
			end
			
			if #murderers > 0
				local str = ''
				for k,name in ipairs(murderers)
					str = $ .. "*"..name.."*, "
				end
				MM:discordMessage("***Murderers:*** "..str.."\n")
			end
			if #sherrifs > 0
				local str = ''
				for k,name in ipairs(sherrifs)
					str = $ .. "*"..name.."*, "
				end
				MM:discordMessage("***Sheriffs:*** "..str.."\n")
			end
			
		end
		
		return
	end

	if not MM_N.allow_respawn then
		local corpse = P_SpawnMobjFromMobj(target, 0,0,0, MT_THOK)
		
		target.flags2 = $|MF2_DONTDRAW
		
		corpse.skin = target.skin
		corpse.color = target.color
		corpse.state = S_PLAY_BODY
		corpse.colorized = target.colorized
		
		corpse.angle = angle
		corpse.flags = 0
		corpse.flags2 = 0
		corpse.tics = -1
		corpse.fuse = -1
		corpse.shadowscale = target.shadowscale
		corpse.radius = target.radius
		if not MM_N.knownDeadPlayers[#target.player]
			corpse.translation = "Grayscale"
		end
		--corpses dont have colormaps?
		corpse.renderflags = $|RF_SEMIBRIGHT
		
		P_InstaThrust(corpse, angle, -8*FU)
		P_SetObjectMomZ(corpse,6*FU)
		
		MM_N.corpses[#MM_N.corpses+1] = corpse
		corpse.playerid = #target.player
		corpse.playername = target.player.name
		if (target.player.mm.alias and target.player.mm.alias.name)
			corpse.playername = target.player.mm.alias.name
		end
		
		local hook_event = MM.events["CorpseSpawn"]
		for i,v in ipairs(hook_event)
			MM.tryRunHook("CorpseSpawn", v,
				target, corpse
			)
		end
		
		S_StopSound(target)
		S_StartSound(nil, sfx_altdi1, target.player)
	end
end, MT_PLAYER)

addHook("ThinkFrame", function()
	if not MM then return end
	if not MM_N then return end
	if not MM:isMM() then return end

	if MM_N.gameover
	and not MM_N.voting
		--this makes me sad
		/*
		local sheriff = 
			((MM_N.end_killed and MM_N.end_killed.valid and MM_N.end_killed.player and MM_N.end_killed.player.mm.role == MMROLE_MURDERER)
				and not (MM_N.end_killer and MM_N.end_killer.valid and MM_N.end_killer.health)
			)
			and MM_N.end_killed
			or MM_N.end_killer
		*/
		
		local releaseTic = 3*TICRATE
		if MM_N.sniped_end then
			-- for music timing
			releaseTic = 3*TICRATE + MM.sniper_theme_offset
		end
		for p in players.iterate() do
			if not (p.mo and not (p.mo.health)) then continue end
			--if (p.mo == sheriff) then continue end
			
			if p.mo.stormkilledme
				p.mo.color = SKINCOLOR_GALAXY
				p.mo.colorized = true
			end
			
			--Endcam cutscene
			if MM_N.end_ticker < releaseTic
				p.deadtimer = min($,1)
				p.mo.momx,p.mo.momy,p.mo.momz = 0,0,0
				p.mo.flags2 = $ &~MF2_DONTDRAW
				p.mo.flags = $ | MF_NOGRAVITY
				p.mo.state = (p.mm.end_deathstate and S_PLAY_DEAD or S_PLAY_PAIN)
				continue
			end
			if not (MM_N.end_ticker == releaseTic) then continue end
			
			p.mo.flags2 = $ &~MF2_DONTDRAW
			p.mo.flags = $ &~MF_NOGRAVITY
			p.mo.state = S_PLAY_DEAD
			
			P_InstaThrust(p.mo, p.mo.deathangle, -6*FU)
			P_SetObjectMomZ(p.mo, 20*FU)
			S_StartSound(p.mo, sfx_altdi1)
			
			local machine = false
			if (p.charflags & SF_MACHINE)
			or (skins[p.skin].flags & SF_MACHINE)
				machine = true
			end
			
			if not machine then continue end
			
			p.charflags = $|SF_MACHINE
			MM.Tripmine_SpawnExplosions(p.mo, false, 10)
			P_StartQuake(60*FU, TICRATE * 3/4, {p.mo.x, p.mo.y, p.mo.z}, 512*FU)
			
			local sfx = P_SpawnGhostMobj(p.mo)
			sfx.fuse = 3 * TICRATE
			sfx.tics = sfx.fuse
			sfx.flags2 = $|MF2_DONTDRAW
			S_StartSound(sfx, sfx_mmdie0)
			S_StartSound(sfx, sfx_mmdie0)
			
			local a = p.mo.angle + ANGLE_45
			local spr_scale = FU
			local tntstate = S_TNTBARREL_EXPL3
			local rflags = RF_PAPERSPRITE|RF_FULLBRIGHT|RF_NOCOLORMAPS
			local wavestate = S_FACESTABBERSPEAR
			local wavetime = TICRATE
			for i = 0,1
				local bam = P_SpawnMobjFromMobj(p.mo,0,0,0,MT_THOK)
				P_SetMobjStateNF(bam, tntstate)
				bam.spritexscale = FixedMul($, spr_scale)
				bam.spriteyscale = bam.spritexscale
				bam.renderflags = $|rflags
				bam.angle = a + ANGLE_90 * i
				
				bam.color = p.skincolor
				bam.colorized = true
				bam.blendmode = AST_SUBTRACT
				
				local wave = P_SpawnMobjFromMobj(p.mo,0,0,0,MT_THOK)
				P_SetMobjStateNF(wave, wavestate)
				wave.spritexscale = FixedMul($, spr_scale)
				wave.spriteyscale = wave.spritexscale
				wave.renderflags = $|rflags
				wave.angle = a + ANGLE_90 * i
				wave.tics = wavetime
				wave.fuse = wavetime
				wave.destscale = wave.scale * 6
				wave.scalespeed = FixedDiv(wave.destscale - wave.scale, wavetime*FU)
				
				wave.color = p.skincolor
				wave.colorized = true
				wave.blendmode = AST_ADD
			end
			continue
		end
		return
	end
	
	--JUST in case...
	if not MM_N then return end
	if not (MM_N.corpses) then return end --BRUH
	
	local body_found = false
	
	for _,corpse in ipairs(MM_N.corpses) do
		if not (corpse and corpse.valid) then
			table.remove(MM_N.corpses, _)
			continue
		end
		
		if (corpse.playerid ~= nil)
		and (players[corpse.playerid] and players[corpse.playerid].valid)
		and (players[corpse.playerid].mo and players[corpse.playerid].mo.valid)
			if not players[corpse.playerid].mo.health
			and not (players[corpse.playerid].mo.flags2 & MF2_DONTDRAW) then
				players[corpse.playerid].mo.flags2 = $|MF2_DONTDRAW
			end
		end
        if MM_N.knownDeadPlayers[corpse.playerid]
        and (corpse.translation)
            corpse.translation = nil
        end
        
		local hook_event = MM.events["CorpseThink"]
		for i,v in ipairs(hook_event)
			MM.tryRunHook("CorpseThink", v,
				corpse
			)
		end
		
        if MM_N.gameover then break end
		
        for p in players.iterate do
			if not (p and p.mo and p.mo.health) then continue end
            if not p.mm then continue end
			if p.mm.role == MMROLE_MURDERER then continue end
            if (p.spectator) then continue end
			
			if P_CheckSight(corpse, p.mo)
			and R_PointToDist2(corpse.x, corpse.y, p.mo.x, p.mo.y) < 512*FU
			and not (MM_N.knownDeadPlayers[corpse.playerid]) then
				chatprint("\x82*The corpse of "..corpse.playername.." has been found!")
				MM_N.knownDeadPlayers[corpse.playerid] = true
				body_found = true
				
				local marker = P_SpawnMobjFromMobj(corpse, 0,0,
					FixedDiv(corpse.height, corpse.scale),
					MT_THOK
				)
				marker.sprite = SPR_BGLS
				marker.frame = H|FF_FULLBRIGHT
				marker.tics = 10 * TICRATE
				marker.fuse = marker.tics
				
				corpse.translation = nil
				
				local bonus = 25
				chatprintf(p, "\x83*Found a body! (+ $"..bonus..")\x80")
				CONS_Printf(p, "\x83You got "..bonus.." coins for finding a body!\x80")
				p.mm_save.ringstopay = wrapadd($, bonus)
				
				local hook_event = MM.events["CorpseFound"]
				for i,v in ipairs(hook_event)
					MM.tryRunHook("CorpseFound", v,
						corpse, p.mo
					)
				end
                continue
			end
		end
	end
	
	--only play ONCE
	if body_found
		S_StartSound(nil,sfx_dedbdy)
	end
end)