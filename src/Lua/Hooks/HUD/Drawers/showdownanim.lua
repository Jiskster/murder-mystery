-- DEPRECATED
MM.showdownSprites = {
	["sonic"] = "MMSD_SONIC";
	["tails"] = "MMSD_TAILS";
	["knuckles"] = "MMSD_KNUCKLES";
	["amy"] = "MMSD_AMY";
	["fang"] = "MMSD_FANG";
	["metalsonic"] = "MMSD_METAL";
	-- you may be asking why im doing this instead of directly getting the XTRAB0 spr2
	-- i wanna plan to add custom sprites for this sometime soon
}

--this is super extra and blocks a lot of vision
local SW_STR = "SHOWDOWN!!"
local SW_SUBSTR = "IT'S A SHOWDOWN! "

local str_y = -200*FU
local substr_y = -200*FU
local letters = {}
local letter_cooldown = 0

local function init_vars()
	str_y = -200*FU
	substr_y = -200*FU
	letters = {}
	letter_cooldown = 0
end

local FONT = "STCFN"
local function manage_letters(v)
	if #letters >= #SW_STR then return end

	local stri = #letters+1
	local str = string.sub(SW_STR, stri, stri)

	local byte = str:byte()

	letters[stri] = v.cachePatch(string.format("STCFN%03d", byte))
	S_StopSoundByID(nil, sfx_wepchg)
	S_StartSoundAtVolume(nil, sfx_wepchg, 225)
end

local ANIM = 12
return function(v, p, cam)
	if (not MM_N.showdown or MM_N.gameover) then
		init_vars()
		return
	end
	if not (MM_N.showdown) then return end

	local state = (MM_N.showdown_ticker >= 3*TICRATE) and 2 or 1

	local screen_height = (v.height()/v.dupy())*FU

	if state == 1 then
		local frac = min((FU/ANIM) * MM_N.showdown_ticker, FU)
		
		str_y = ease.linear(frac, -100*FU, 30*FU)
		substr_y = ease.linear(frac, -100*FU, 120*FU)
	elseif state == 2 then
		local frac = min((FU/ANIM) * (MM_N.showdown_ticker - 3*TICRATE), FU)
		
		str_y = ease.linear(frac, 30*FU, -100*FU)
		substr_y = ease.linear(frac, 120*FU, -100*FU)
	end

	manage_letters(v)
	
	local str_scale = FU*3/2
	local width = 8*(#letters*str_scale)
	local str_x = (160*FU)-(width/2)

	local str = "The murderer can see you, \x85RUN!"
	local max_width = v.stringWidth(str, 0, "thin")
	max_width = (max($, 8*#letters)*FU)+(4*FU)
	
	local max_height = (8*str_scale)+(8*FU)+(4*FU)
	
	v.drawStretched(160*FU - (max_width/2),
		str_y - 2*FU,
		max_width,
		max_height,
		v.cachePatch("1PIXEL"),
		V_SNAPTOTOP|V_50TRANS
	)
	
	for k,patch in ipairs(letters) do
		v.drawScaled(
			str_x+v.RandomRange(-FU, FU),
			str_y+v.RandomRange(-FU, FU),
			str_scale,
			patch,
			V_SNAPTOTOP,
			v.getStringColormap(V_REDMAP)
		)
		str_x = $+(8*str_scale)
	end
	if (p and p.mm and p.mm.role == MMROLE_MURDERER) then
		str = "\x85KILL THEM ALL!"
	elseif p.spectator -- murderer cant see you. dork.
		str = ""
	end
	
	v.drawString(160*FU, str_y+(8*str_scale), str, V_SNAPTOTOP, "thin-fixed-center")
end