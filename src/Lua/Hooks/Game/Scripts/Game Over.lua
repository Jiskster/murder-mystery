sfxinfo[freeslot "sfx_mmsnp1"].caption = "Spot on!"
sfxinfo[freeslot "sfx_mmsnp2"].caption = "Good shot, mate!"
sfxinfo[freeslot "sfx_mmsnp3"].caption = "Fine shot, mate!"

local function calcRollX(time)
	if time <= 0 then
		return 0
	end
	local x = 0
	local xv = 0
	for _=1,time do
		x = $ + xv
		xv = $ + (FU/MM_N.mapVote.rollvel)
	end
	return x
end

return function()
	MM_N.end_ticker = $+1

	if MM_N.voting then
		MM_N.mapVote.ticker = $ - 1
		if MM_N.mapVote.state == "voting" and MM_N.mapVote.ticker <= 0 then
			local pool = {}
			local mapc = 0
			for _,map in ipairs(MM_N.mapVote.maps) do
				if map.votes then
					mapc = $ + 1
					for _=1,map.votes do
						table.insert(pool, map)
					end
				end
			end
			if mapc == 1 then
				MM_N.mapVote.state = "done"
				MM_N.mapVote.selected_map = pool[1].map
				MM_N.mapVote.selected_pool = pool[1]
				MM_N.mapVote.ticker = 5*TICRATE
				MM_N.mapVote.unanimous = true
				S_StartSound(nil, sfx_s3kb3)
			else
				if not #pool then
					for _,map in ipairs(MM_N.mapVote.maps) do
						table.insert(pool, map)
					end
				end
				-- Fisher-Yates shuffle algorithm
				for i = #pool, 2, -1 do
					local j = P_RandomRange(1, i)
					pool[i], pool[j] = pool[j], pool[i]
				end
				MM_N.mapVote.pool = pool
				MM_N.mapVote.selected_map = pool[1].map
				MM_N.mapVote.selected_pool = pool[1]
				MM_N.mapVote.state = "rolling"
				MM_N.mapVote.ticker = P_RandomRange(4*TICRATE, 7*TICRATE)
				MM_N.mapVote.rollvel = P_RandomRange(320, 480)
				MM_N.mapVote.rollx = calcRollX(MM_N.mapVote.ticker)
				
			end
		elseif MM_N.mapVote.state == "rolling" then
			local newx = calcRollX(MM_N.mapVote.ticker)
			if FixedFloor(MM_N.mapVote.rollx+FU/2) != FixedFloor(newx+FU/2) then
				S_StartSound(nil, sfx_tink)
			end
			MM_N.mapVote.rollx = newx

			if MM_N.mapVote.ticker <= 0 then
				MM_N.mapVote.state = "done"
				MM_N.mapVote.ticker = 5*TICRATE
				S_StartSound(nil, sfx_s3kb3)
			end
		elseif MM_N.mapVote.state == "done" and MM_N.mapVote.ticker <= 0 then
			MM_N.next_gametype = MM_N.mapVote.selected_pool.gametype
			print("MM Gametype: "..MM.Gametypes[MM_N.next_gametype].name) 
			G_SetCustomExitVars(MM_N.mapVote.selected_map, 2)
			G_ExitLevel()
		end
		
		
		local changemusic = 1 -- Tic to change music
		
		/* UNUSED
		--this song is very long
		if mapmusname == "CHPASS" --"MMWIN"
			changemusic = 5*TICRATE + TICRATE/2
		elseif mapmusname == "_CLEAR"
		or mapmusname == "CHFAIL"
			changemusic = 2*TICRATE + TICRATE/2
		end
		*/

		if MM_N.end_ticker == changemusic
		and (MM_N.killing_end) then
			local theme = MM.themes[MM_N.theme or "srb2"]
			mapmusname = theme.music or "CHRSEL"
			S_ChangeMusic(mapmusname, true, nil, 0,0)
		end
		return
	end

	if (MM_N.end_camera and MM_N.end_camera.valid) then
		MM:startEndCamera()
	end

	local releaseTic = 3*TICRATE
	if MM_N.sniped_end then
		-- for music timing
		releaseTic = 3*TICRATE + MM.sniper_theme_offset
	end
	if MM_N.end_ticker == releaseTic
		for mo in mobjs.iterate()
			if not (mo and mo.valid) then continue end
			
			if mo.notthinking
				continue
			end
			
			mo.flags = $ &~MF_NOTHINK
			mo.fake_drawangle = nil
		end
	end
	if MM_N.sniped_end and MM_N.end_ticker == releaseTic+8 then
		S_StartSound(nil, sfx_mmsnp1 + P_RandomRange(0, 2))
	end
	
	/* UNUSED
	if not MM_N.sniped_end
	and MM_N.end_ticker == releaseTic + 8
	and (MM_N.killing_end)
		if (consoleplayer and consoleplayer.valid)
			local p = consoleplayer
			
			if p.mm
			and (p.mo and p.mo.valid)
				--this makes me sad
				local sheriff = 
					((MM_N.end_killed and MM_N.end_killed.valid and MM_N.end_killed.player and MM_N.end_killed.player.mm.role == MMROLE_MURDERER)
						and not (MM_N.end_killer and MM_N.end_killer.valid and MM_N.end_killer.health)
					)
					and MM_N.end_killed
					or MM_N.end_killer
				
				--we made the winning kill
				if (p.mo == sheriff)
				and p.mo.health
					mapmusname = "CHPASS" --"MMWIN"
				--innocents won
				elseif ((MM.endType.results == "innocents")
				and (p.mm.role ~= MMROLE_MURDERER))
				--murderers won
				or ((MM.endType.results == "murderers")
				and (p.mm.role == MMROLE_MURDERER))
					mapmusname = "_CLEAR" --"MMOKAY"
				else
					mapmusname = "CHFAIL" --"MMLOSE"
				end
				
				S_ChangeMusic(mapmusname, false)
			else
				mapmusname = "_CLEAR" --"MMOKAY"
				S_ChangeMusic(mapmusname, false)
			end
		end
	end
	*/
	
	/*if MM_N.end_ticker >= 5*TICRATE then
		local song = "MMWINR"
		local p = consoleplayer

		if (p and p.mm and p.mm.spectator and not p.mm.joinedmidgame) then
			song = "MMLOSR"
		end

		if MM_N.results_ticker == 0 then
			S_ChangeMusic(song, false)
		end

		MM_N.results_ticker = $+1
	end*/

	-- an extra half second for the new killcam sequence
	if MM_N.end_ticker >= 5*TICRATE + (TICRATE) then
		-- freeze all player's angles
		for player in players.iterate do
			if player and player.valid 
			and player.mo and player.mo.valid 
			and player.mo.health and not player.spectator 
			and player.mm then
				player.mm.freeze_angle = player.mo.angle 
			end
		end
		
		MM_N.end_ticker = 1
		MM:startTransition()
	end
end, "gameover"