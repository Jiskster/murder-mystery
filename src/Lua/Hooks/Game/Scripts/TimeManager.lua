--handles everything related to round times

local possibleItems = {
	"shotgun",
	"revolver",
	"luger",
	"knife",
	"sword"
}
local previousRoundTic = 0

return function()
	if not (MM_N) then return end
	--Bruh stop bro
	--STOP BEING SHITTYY
	if MM_N.pregame_time == nil then return end
	
	--starting countdown
	if (leveltime >= (MM_N.pregame_time - 4*TICRATE - 1) and leveltime <= MM_N.pregame_time - TICRATE)
	and (leveltime % TICRATE == 0)
		S_StartSound(nil,leveltime == MM_N.pregame_time - TICRATE and sfx_s3kad or sfx_s3ka7)
	end
	
	do
		local numplay = 0
		local innocents = 0
		for p in players.iterate do
			if not (p.mm) then continue end
			if (p.spectator or p.mm.specator) then continue end
			
			if (p.mm.role ~= MMROLE_MURDERER)
				innocents = $+1
			end
			numplay = $+1
			
			-- Don't allow players to change colors midgame
			if leveltime == MM_N.pregame_time
				p.mm.savedcolor = p.skincolor
				
				table.insert(MM_N.player_colors,{
					player = p,
					color = p.skincolor,
					skin = skins[p.skin].name
				})
			end
		end
		
		if MM:pregame()
			MM_N.dueling = numplay == 2 or (CV_MM.force_duel.value ~= 0)
			MM_N.duel_item = possibleItems[P_RandomRange(1,#possibleItems)]
		end
		
		--people might've joined or left, so recalc minimum kills
		if leveltime == MM_N.pregame_time
			if isserver
			and not CV_MM.debug.value then
				CV_Set(CV_FindVar("restrictskinchange"),1)
			end
			
			chatprint("\x82*Proximity chat has been turned ON!")
			MM_N.minimum_killed = max(1,innocents/3)
			MM_N.numbertokill = innocents
			
			--we're for SURE dueling
			if MM_N.dueling
				MM_N.time = MM_N.duel_time
				MM_N.maxtime = MM_N.duel_time
			end
		end
	end
	
	---- time management ----
	
	--we dont need to tic this down during showdown
	previousRoundTic = MM_N.time
	if not (MM_N.overtime or MM_N.showdown)
		MM_N.time = max(0, $-1)
	end
	
	if not (MM_N.time)
	and not (MM_N.overtime or MM_N.showdown) then
		if not MM_N.dueling
			if (MM_N.peoplekilled >= MM_N.minimum_killed
				or MM_N.showdown
				or (CV_MM.debug.value)
			) and not MM.Gametypes[MM_N.gametype].disable_overtime
				MM:startOvertime()
			else
				MM:endGame(1)
				MM_N.disconnect_end = true
				MM_N.end_ticker = 3*TICRATE - 1
				S_StartSound(nil,sfx_s253)
			end
		elseif not MM_N.showdown
			MM:startShowdown()
		end
	end

	if MM_N.overtime
	and not MM_N.showdown then 
		if not MM_N.ping_time then
			MM_N.pings_done = $+1
			
			if MM_N.pings_done >= 2 then
				MM_N.pings_done = 0
				MM_N.max_ping_time = max(6, $/2)
			end
			
			MM_N.ping_time = MM_N.max_ping_time
			MM_N.ping_approx = FixedDiv(MM_N.ping_time, 30*TICRATE)
			
			MM:pingMurderers(min(MM_N.max_ping_time, 5*TICRATE), MM_N.ping_approx)
		end
		MM_N.ping_time = max(0, $-1)
		
		for k,pos in pairs(MM_N.ping_positions) do
			pos.time = max($-1, 0)
			if not (pos.time) then
				table.remove(MM_N.ping_positions, k)
			end
		end
	end

	if (MM_N.overtime or MM_N.time <= 30*TICRATE) then
		local songname = (not MM_N.overtime) and "_PINCH" or "_OVRTM"
		if not MM_N.showdown
		and mapmusname ~= songname then
			mapmusname = songname
			S_ChangeMusic(mapmusname, true)
		end
		
		--end countdown
		if (MM_N.time <= 3*TICRATE
		and (MM_N.time % TICRATE == 0))
		--or (MM_N.time == 10*TICRATE)
		and (MM_N.time
		and (MM_N.time ~= lastRoundTic))
			S_StartSound(nil,
				sfx_s3ka7
			)
		end
		
		if (MM_N.time <= 30*TICRATE)
		and (MM_N.time > 0)
		and not (MM_N.showdown)
		--start emitting AURA if overtime will start
		and (MM_N.peoplekilled >= MM_N.minimum_killed)
			local point = MM_N.storm_point
			local dist = 120*FU
			local scale = FU / 2
			local spokes = 12
			
			if (leveltime % 9 == 0)
				local ticker_offset = FixedAngle( ((MM_N.overtime_ticker + 6)*FU) / 2 )
				for i = 0, spokes - 1
					local angle = FixedAngle(FixedDiv(360*FU, spokes*FU) * i) + ticker_offset
					local dust = P_SpawnMobjFromMobj(point,
						P_ReturnThrustX(nil, angle, dist),
						P_ReturnThrustY(nil, angle, dist),
						0,
						MT_ARIDDUST
					)
					
					dust.state = dust.info.spawnstate + P_RandomRange(0, 2)
					P_SetScale(dust, 3 * scale, true)
					P_SetOrigin(dust, dust.x, dust.y, dust.z)
					
					dust.angle = angle + ticker_offset
					P_Thrust(dust,dust.angle, 5 * scale)
					
					dust.color = SKINCOLOR_GALAXY
					dust.colorized = true
					dust.destscale = 1
					dust.scalespeed = FixedDiv(dust.scale, dust.tics * FU)
					dust.renderflags = $|RF_SEMIBRIGHT|RF_NOCOLORMAPS
					
					dust.momz = (P_RandomRange(1,5)*scale)
				end
			end
		end
		
		MM_N.overtime_ticker = $+1
	end

	--Overtime storm
	if MM_N.showdown 
	or MM_N.overtime
	--there used to be a separate block that ran the storm handler
	--with debug on too, meaning the storm would be handled _twice_
	--in a tic... YIKES
	or CV_MM.debug.value then
		MM:handleStorm()
	end
	
	--debug thinker
	if CV_MM.debug.value
    and not CV_MM.force_duel.value
		MM_N.dueling = false
	end
end