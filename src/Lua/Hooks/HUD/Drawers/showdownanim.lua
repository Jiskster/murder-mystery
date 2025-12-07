-- DEPRECATED
MM.showdownSprites = {
	["sonic"] = "MMSD_SONIC";
	["tails"] = "MMSD_TAILS";
	["knuckles"] = "MMSD_KNUCKLES";
	["amy"] = "MMSD_AMY";
	["fang"] = "MMSD_FANG";
	["metalsonic"] = "MMSD_METAL";
}

--this WAS super extra, now it shouldnt block so much vision
local SW_STR = "SHOWDOWN!!"
local SW_SUBSTR = "IT'S A SHOWDOWN! "

local str_y = -200*FU
local substr_y = -200*FU
local letters = {}
local letter_cooldown = 0
local murdererskins = {}

local function init_vars()
	str_y = -200*FU
	substr_y = -200*FU
	letters = {}
	letter_cooldown = 0
	murdererskins = {}
end

local function manage_letters(v)
	if #letters >= #SW_STR then return end

	local stri = #letters+1
	local str = string.sub(SW_STR, stri, stri)

	local byte = str:byte()

	letters[stri] = v.cachePatch(string.format("STCFN%03d", byte))
	S_StopSoundByID(nil, sfx_menu1)
	S_StartSound(nil, sfx_menu1)
end

local ANIM = 16
local STATE_IN = 1
local STATE_OUT = 2
local LENGTH = 6*TR

return function(v, p, cam)
	if (not MM_N.showdown or MM_N.gameover) then
		init_vars()
		return
	end
	if not (MM_N.showdown) then return end
	if (MM_N.showdown_ticker > LENGTH) then return end
	
	if MM_N.showdown_ticker == 1
		murdererskins = {}
		for play in players.iterate
			if (not play.mm) or (play.spectator)
			or (play.mm.spectator)
				continue
			end
			-- Show innocents
			if (p.mm.role == MMROLE_MURDERER)
				if play.mm.role == MMROLE_MURDERER
					continue
				end
			-- Show murderers
			else
				if play.mm.role ~= MMROLE_MURDERER
					continue
				end
			end
			
			table.insert(murdererskins, {
				skin = skins[play.skin].name,
				color = play.skincolor
			})
		end
	end
	local state = (MM_N.showdown_ticker >= LENGTH - ANIM) and STATE_OUT or STATE_IN

	if state == STATE_IN then
		local frac = min((FU/ANIM) * MM_N.showdown_ticker, FU)
		
		str_y = ease.outquad(frac, -100*FU, 30*FU)
		substr_y = ease.outquad(frac, -100*FU, 120*FU)
	elseif state == STATE_OUT then
		local frac = min((FU/ANIM) * (MM_N.showdown_ticker - (LENGTH - ANIM)), FU)
		local back = FU*2
		str_y = ease.inback(frac, 30*FU, -100*FU, back)
		substr_y = ease.inback(frac, 120*FU, -100*FU, back)
	end

	manage_letters(v)
	
	local str_scale = FU*3/2
	local width = 8*(#letters*str_scale)
	local str_x = (160*FU)-(width/2)

	local str = "The murderer can see you, \x85RUN!"
	local max_width = v.stringWidth(str, 0, "thin")
	max_width = (max($, 8*#letters)*FU)+(4*FU)
	
	local max_height = (8*str_scale)+(8*FU)+(4*FU)+(11*FU)
	
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
		str = "\x85Kill them all!"
	elseif p.spectator -- murderer cant see you. dork.
		str = ""
	end
	
	v.drawString(160*FU, str_y+(8*str_scale), str, V_SNAPTOTOP|V_ALLOWLOWERCASE, "thin-fixed-center")
	
	local x = 160*FU - ((8*FU * #murdererskins) + (2*FU * (#murdererskins - 1)))/2
	for k, va in ipairs(murdererskins)
		v.drawScaled(x, str_y + (8*str_scale) + (16*FU), skins[va.skin].highresscale/2,
			v.getSprite2Patch(va.skin, SPR2_LIFE, false,A,0,0),
			V_SNAPTOTOP, v.getColormap(va.skin, va.color)
		)
		x = $ + 10*FU
	end
end