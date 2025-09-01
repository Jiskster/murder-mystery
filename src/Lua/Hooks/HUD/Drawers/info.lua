local TR = TICRATE

-- https://stackoverflow.com/questions/10989788/format-integer-in-lua
local function format_int(number)

  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")

  -- reverse the int-string back remove an optional comma and put the 
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

MMHUD.info_xpos = 0

-- "gameandscores" hud now returns the player for game hud so we can tell
-- if this item is being drawn on the game or scores hud
local function HUD_InfoDrawer(v, stplyr)
	local p = displayplayer
	
	--Timer
	do
		local x = 5*FU
		local y = 10*FU
		local flags = V_SNAPTOLEFT|V_SNAPTOTOP
		
		local flash = false
		local timetic = MM_N.time
		
		if (MM_N.overtime and not MM_N.showdown)
			timetic = 0
		else
			timetic = $ + TICRATE
		end
		
		local minutes = G_TicsToMinutes(timetic, true)
		local seconds = G_TicsToSeconds(timetic)
		local centi = G_TicsToCentiseconds(timetic)
		
		if minutes < 10 then minutes = "0"..$ end
		if seconds < 10 then seconds = "0"..$ end
		if centi < 10 then centi = "0"..$ end
		
		flash = timetic <= 31*TICRATE or MM_N.showdown
		flash = (flash and ((leveltime%(2*TICRATE)) < 30*TICRATE) and (leveltime/5 & 1))
		
		local finalstring = minutes..":"..seconds .. (CV_MM.debug.value and ("."..centi) or "")
		if (MM_N.showdown)
			finalstring = "SHOWDOWN !!" -- ("..$..")"
		end
		
		if splitscreen and (stplyr and stplyr.valid)
			x = 160*FU - ((v.stringWidth(finalstring,0,"normal") + 15)/2)*FU
			y = 100*FU
			flags = 0
		end
		
		v.slideDrawScaled(x + FU, y + FU,
			FU,
			v.cachePatch("MM_CLOCK2"),
			flags,
			v.getColormap(nil,nil,"MM_HudShadow")
		)
		v.slideDrawScaled(x,y,
			FU,
			v.cachePatch("MM_CLOCK2"),
			flags
		)
		
		v.slideDrawString(x + 15*FU, y,
			finalstring,
			flags|(flash and V_REDMAP or 0),
			"fixed", true
		)
		
		MMHUD.info_xpos = (x/FU) + 15 + v.stringWidth(finalstring,0,"normal")
	end
	
	--rings
	do
		local x = 5*FU
		local y = (splitscreen and 5 or 23)*FU
		if (splitscreen and stplyr == secondarydisplayplayer)
			y = $ + (v.height()/v.dupy() << (FRACBITS-1))
		end
		local yoff = 0
		local rings = MM:GetPlayerRings(p)
		local slidein = 0
		local func = v.slideDrawScaled
		local Sfunc = v.slideDrawString
		
		if splitscreen then
			if secondarydisplayplayer == stplyr then
				rings = MM:GetPlayerRings(secondarydisplayplayer)
			end
		end
		
		if (MMHUD.info_slideout)
			func = v.drawScaled
			Sfunc = v.drawString
			local ticker = MMHUD.info_ticker
			ticker = min($, 7*TR)
			
			yoff = -12*FU
			if ticker <= 16
				yoff = ease.outback((FU/16)*ticker, 0, $)
			end
			
			if ticker >= 5*TR
				slidein = ease.inquad((FU/TR)*(ticker - 5*TR), $, 60*FU)
			end
			
			rings = ($ - p.mm.ringspaid) + MMHUD.info_count
			
			Sfunc(
				x + 15*FU + (v.stringWidth(format_int(tostring(rings)),0,"normal")*FU) - slidein,
				y + 11*FU + yoff,
				"+"..(p.mm.ringspaid - MMHUD.info_count),
				V_SNAPTOLEFT|V_SNAPTOTOP|V_GREENMAP,
				"fixed-right", true
			)	
		end
		
		local origin_size = FixedDiv(16*FU, v.cachePatch("MMRING").width*FU) -- Scale to 16 pixels
		local origin_scale = FU*3/4
		
		func(x - slidein + FU,
			y + yoff + FU,
			FixedMul(origin_size, origin_scale),
			v.cachePatch("MMRING"),
			V_SNAPTOLEFT|V_SNAPTOTOP,
			v.getColormap(nil,nil,"MM_HudShadow")
		)
		func(x - slidein,
			y + yoff,
			FixedMul(origin_size, origin_scale),
			v.cachePatch("MMRING"),
			V_SNAPTOLEFT|V_SNAPTOTOP
		)
		
		local ring_string = format_int(tostring(rings))
		Sfunc(x + 15*FU - slidein,
			y + FU + yoff,
			ring_string,
			V_SNAPTOLEFT|V_SNAPTOTOP,
			"fixed", true
		)
		MMHUD.info_xpos = max($,
			(x/FU) + 15 + v.stringWidth(ring_string,0,"normal")
		)
	end
end

return HUD_InfoDrawer,"gameandscores"
