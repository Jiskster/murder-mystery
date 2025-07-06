return function(self)
	if MM_N.gameover then 
		return false
	end
	
	local innocent = false
	local murderer = false

	if splitscreen then
		local player1 = players[0]
		local player2 = players[1]
		
		local function isValid(player)
			return player1 and player1.valid and player1.mo and player1.mo.valid
		end
		
		local function checkPlayerEnd(player)
			if isValid(player) then
				if not player.mo.health then
					if player.mm.role == MMROLE_MURDERER then
						MM:endGame(1) -- if player died and is murderer. innocents win
						return true
					else
						MM:endGame(2) -- if player died and is not murderer. murderers win
						return true
					end
					
					if (MM_N.end_camera and MM_N.end_camera.valid) then
						MM:startEndCamera()
					end
				else
					return false
				end
			end
		end
		
		local check1 = checkPlayerEnd(player1)
		local check2 = checkPlayerEnd(player2)
		
		if check1 ~= false or check2 ~= false then
			return true
		end
	end

	if MM_N.waiting_for_players then
		return false
	end
	
	if not MM_N.ignore_missing_roles then
		for p in players.iterate do
			if not (p and p.mo and p.mm and not p.mm.spectator) then continue end

			if p.mm.role == MMROLE_MURDERER then
				murderer = true
			else
				innocent = true
			end

			if (innocent and murderer) then break end
		end

		if not innocent then
			return true, 2
		end
		if not murderer then
			return true, 1
		end
	end

	-- redundant?
	if MM_N.allow_respawn then
		return false
	end
	
	return false
end