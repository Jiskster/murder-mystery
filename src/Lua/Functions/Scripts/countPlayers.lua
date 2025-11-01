--shitty ass libary already exist, but i already wrote this so you bet your ass im using it
-- boolean countdead: count dead roles
return function(countdead)
    local result = {
        innocents = 0,
        sheriffs = 0,
        murderers = 0,
		
		-- sheriffs + innocents
        regulars = 0,
        total = 0,
		
		-- spectators/dead
        inactive = 0,
    }

	for p in players.iterate do
        result.total = $+1
		if not (p.mm)
            result.inactive = $+1
            continue
        end
        if (p.specator or p.mm.spectator or (not (p.mo and p.mo.valid and p.mo.health) and not countdead)
        or p.mm.joinedmidgame)
            result.inactive = $+1
            continue
        end

        if p.mm.role == MMROLE_INNOCENT
            result.innocents = $+1
            result.regulars = $+1
        elseif p.mm.role == MMROLE_SHERIFF
            result.sheriffs = $+1
            result.regulars = $+1
        elseif p.mm.role == MMROLE_MURDERER
            result.murderers = $+1
        end

	end

    return result
end