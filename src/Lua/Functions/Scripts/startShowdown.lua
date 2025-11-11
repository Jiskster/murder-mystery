return function()
	MM_N.showdown = true
	MM_N.showdown_song = "SHWDW"..tostring(P_RandomRange(1,3))

	local gt = MM.returnGametype()

	if not gt.disable_proximity_chat then
		chatprint("\x82*Proximity chat has been turned OFF!")
	end

	for p in players.iterate do
		if not (p and p.mo and p.mo.health and p.mm and not p.mm.spectator) then continue end
		
		if p.mm.role ~= MMROLE_MURDERER then
			table.insert(MM_N.showdown_right, {
				skin = p.mo.skin,
				color = p.mo.color
			})
			continue
		end
		
		table.insert(MM_N.showdown_left, {
			skin = p.mo.skin,
			color = p.mo.color
		})
	end

	S_StartSound(nil,sfx_kc4b)
end