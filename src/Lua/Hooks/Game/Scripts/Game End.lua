return function()
	if CV_MM.debug.value or splitscreen then return end
	if (leveltime == 0 or MM:pregame()) then return end
	
	local canEnd, endType = MM:canGameEnd()

	if canEnd then
		MM:endGame(endType or 1)
		if not MM_N.killing_end then
			MM_N.disconnect_end = true
			MM_N.end_ticker = 3*TICRATE - 1
			S_StartSound(nil,sfx_s253)
		end
		
		--Allow players to change their skin during intermission
		if isserver then
			CV_Set(CV_FindVar("restrictskinchange"),0)
		end
	end
end