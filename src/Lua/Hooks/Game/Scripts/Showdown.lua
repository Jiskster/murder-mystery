return function()
    local result = MM:countPlayers()
	local gt = MM.returnGametype()

	-- start showdown when the number of innocnts
    -- is less than or equal to the number of murderers
	if result.regulars <= result.murderers
    -- never start showdown in duels besides on time over
	and not MM_N.showdown and not MM_N.dueling 
	and not gt.disable_showdown then
		MM:startShowdown()
	end

	if MM_N.showdown then
		if mapmusname ~= MM_N.showdown_song then
			mapmusname = MM_N.showdown_song
			S_ChangeMusic(MM_N.showdown_song, true)
		end
		MM_N.showdown_ticker = $+1
	end
end