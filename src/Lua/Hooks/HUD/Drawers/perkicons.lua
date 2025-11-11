local function getpatch(perk)
	if perk == 0
	or perk == nil
	or (MM_PERKS[perk] == nil)
		return "MM_NOITEM"
	end
	
	return MM_PERKS[perk].icon or "MISSING"
end

local function getscale(perk)
	if perk == 0
	or perk == nil
	or (MM_PERKS[perk] == nil)
		return FU
	end
	
	return MM_PERKS[perk].icon_scale or FU
end

local function getname(perk)
	if perk == 0
	or perk == nil
	or (MM_PERKS[perk] == nil)
		return "\x86No perk"
	end
	
	return MM_PERKS[perk].name or "Perk"
end


return function(v)
	local p = consoleplayer
	
	local x = 5
	local y = 162
	local flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
	local scale = FU/2
	
	if (p.spectator)
	and (displayplayer ~= p)
	and (displayplayer.mm.role == MMROLE_MURDERER)
		p = displayplayer
	end
	
	local gt = MM.returnGametype()
	if (gt.disable_perks) then return end
	
	v.drawFill(x - 2,
		y - 2,
		100,
		38,
		31|flags|V_50TRANS
	)
	
	if p == consoleplayer
		v.drawFill(x - 2,
			y - 11,
			43,
			9,
			31|flags|V_20TRANS
		)
		v.drawString(x*FU,
			(y - 11)*FU,
			"Perks",
			flags|V_ALLOWLOWERCASE|V_YELLOWMAP,
			"fixed"
		)
	end
	
	v.drawScaled(x*FU,y*FU,
		FixedMul(scale,getscale(p.mm_save.pri_perk)),
		v.cachePatch(getpatch(p.mm_save.pri_perk)),
		flags
	)
	v.drawString(x*FU + (36*scale),
		(y - 3)*FU + (16*scale),
		getname(p.mm_save.pri_perk),
		flags|V_ALLOWLOWERCASE,
		"thin-fixed"
	)

	v.drawScaled(x*FU,(y+2)*FU + (32*scale),
		FixedMul(scale,getscale(p.mm_save.sec_perk)),
		v.cachePatch(getpatch(p.mm_save.sec_perk)),
		flags
	)
	v.drawString(x*FU + (36*scale),
		(y - 3 + 2)*FU + (16*scale) + (32*scale),
		getname(p.mm_save.sec_perk),
		flags|V_ALLOWLOWERCASE,
		"thin-fixed"
	)
	
	
end, "scores", 101