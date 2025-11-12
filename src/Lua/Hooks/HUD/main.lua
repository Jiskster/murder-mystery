customhud.SetupFont("STCFN")

-- Should match hud_disable_options in lua_hudlib.c
-- taken from customhud
local defaultitems = {
	{"stagetitle", "titlecard"},
	{"textspectator", "game"},
	{"crosshair", "game"},

	{"score", "game"},
	{"time", "game"},
	{"rings", "game"},
	{"lives", "game"},

	{"weaponrings", "game"},
	{"powerstones", "game"},
	{"teamscores", "gameandscores"},

	{"nightslink", "game"},
	{"nightsdrill", "game"},
	{"nightsrings", "game"},
	{"nightsscore", "game"},
	{"nightstime", "game"},
	{"nightsrecords", "game"},

	{"rankings", "scores"},
	{"coopemeralds", "scores"},
	{"tokens", "scores"},
	{"tabemblems", "scores"},

	{"intermissiontally", "intermission"},
	{"intermissiontitletext", "intermission"},
	{"intermissionmessages", "intermission"},
	{"intermissionemeralds", "intermission"},
}

local function is_hud_modded(name)
	for k,v in ipairs(defaultitems) do
		if name == v[1] then
			return false
		end
	end

	return true
end

local TR = TICRATE
local HUD_BEGINNINGXOFF = 380*FU
--leveltime at which V_HUDTRANS starts fading in
local HUD_STARTFADEIN = (50 / 2) + 10

local slidein_time = 25
local slidein_frac = FixedDiv(FU, slidein_time*FU)

/*
local game_slidein_time = 20
local game_slidein_frac = FixedDiv(FU, game_slidein_time*FU)
*/

--dont draw if MMHUD.hudtrans == V_100TRANS
rawset(_G, "V_100TRANS", 10 << V_ALPHASHIFT)
local htranstable = {
	[0] = 10,
	[1] = 9,
	[2] = 9,
	[3] = 8,
	[4] = 8,
	[5] = 7,
	[6] = 7,
	[7] = 6,
	[8] = 6,
	[9] = 5,
	[10] = 5,
}
local hudplusalpha = {
	[0] = 10,
	[1] = 8,
	[2] = 6,
	[3] = 4,
	[4] = 2,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
	[9] = 0,
	[10] = 0,
}
local fixedalignlut = {
	["left"] = "fixed",
	["right"] = "fixed-right",
	["center"] = "fixed-center",
	
	["small"] = "small-fixed",
	["small-center"] = "small-fixed-center",
	["small-right"] = "small-fixed-right",

	["small-thin"] = "small-thin-fixed",
	["small-thin-center"] = "small-thin-fixed-center",
	["small-thin-right"] = "small-thin-fixed-right",

	["thin"] = "thin-fixed",
	["thin-center"] = "thin-fixed-center",
	["thin-right"] = "thin-fixed-right",
}

--DO NOT SYNCH!!!!!!!!
rawset(_G, "MMHUD", {
	ticker = 0,
	slidefrac = FU,
	wslidefrac = FU,
	
	xoffset = HUD_BEGINNINGXOFF,
	weaponslidein = HUD_BEGINNINGXOFF,
	dontslidein = false,

	hudtrans = 10,
	hudtranshalf = 10,

	huds = {
		{"rings", "None", "game"};
		{"score", "None", "game"};
		{"time", "None", "game"};
		{"lives", "None", "game"}
	},
})
MMHUD.addHud = function(name, fromfile, path, a_func,a_hudtype,a_layer)
	if (fromfile == nil)
		fromfile = true
	end
	path = $ or "Hooks/HUD/Drawers/"

	local func,hudtype,layer
	if fromfile
		func,hudtype,layer = dofile(path..name)
	else
		func,hudtype,layer = a_func,a_hudtype,a_layer
	end

	table.insert(MMHUD.huds, {name, func or "None", hudtype or "game", layer})
end
local addHud = MMHUD.addHud

local hudwasmm = false
local modname = "SAXAMM"
MMHUD.modname = modname

MMHUD.interpolate = function(v,set)
	if v.interpolate ~= nil then v.interpolate(set) end
end


addHook("MapLoad",do
	MMHUD.ticker = 0
	MMHUD.xoffset = HUD_BEGINNINGXOFF
	MMHUD.weaponslidein = HUD_BEGINNINGXOFF
	
	MMHUD.slidefrac = FU
	MMHUD.wslidefrac = FU
	
	MMHUD.hudtrans = V_100TRANS
end)

local function Playing()
	return not MM:pregame() and not MM_N.waiting_for_players and not MM_N.gameover
end

--itd be nice to have hacked in drawfuncs that handled this
local function DoRegularSlide(v, out)
	local offset = HUD_BEGINNINGXOFF
	MMHUD.xoffset = FixedMul(offset, MMHUD.slidefrac)
	
	local my_frac = slidein_frac
	if not out
		MMHUD.slidefrac = min($, my_frac * 5)
		MMHUD.slidefrac = max($ - my_frac, 0)
	else
		MMHUD.slidefrac = min($ + my_frac, FU)
	end
end

--ugh
local function DoWeaponSlide(v, out)
	local offset = HUD_BEGINNINGXOFF
	MMHUD.weaponslidein = FixedMul(offset, MMHUD.wslidefrac)
	
	local my_frac = slidein_frac
	if not out
		MMHUD.wslidefrac = min($, my_frac * 5)
		MMHUD.wslidefrac = $ - my_frac
		MMHUD.wslidefrac = max($, 0)
	else
		MMHUD.wslidefrac = $ + my_frac
		MMHUD.wslidefrac = min($, FU)
	end
end

local function TickSliders()
	MMHUD.ticker = $+1
	if abs(leveltime - MMHUD.ticker) >= 4
		MMHUD.ticker = leveltime
	end
	
	if not MMHUD.dontslidein
		if not MM.gameover
			
			--"Round starts in..."
			if MMHUD.ticker >= HUD_STARTFADEIN
			and not Playing()
				DoWeaponSlide(v)
				
				if MM_N.waiting_for_players
					DoRegularSlide(v)
				end
			end
			
			--slide in regular hud
			if Playing()
				DoRegularSlide(v)
				DoWeaponSlide(v,true)
			end
			
			--fade in stuff if we've tweened for at least 2 tics
			if MMHUD.xoffset <= FixedMul(HUD_BEGINNINGXOFF, FixedSqrt(FU*7/10))
				if MMHUD.hudtrans ~= 0
					MMHUD.hudtrans = $ - 1
				end
			end
			
		--everything slides out
		else
			DoRegularSlide(v,true)
			DoWeaponSlide(v,true)
			
			if MMHUD.hudtrans ~= 10
				MMHUD.hudtrans = $ + 1
			end
		end
	else
		if MMHUD.hudtrans ~= 10
			MMHUD.hudtrans = $ + 1
		end
		
		MMHUD.dontslidein = false
	end
	MMHUD.hudtranshalf = htranstable[10 - (MMHUD.hudtrans >> V_ALPHASHIFT)] << V_ALPHASHIFT	
end
MMHUD.DoRegularSlide = DoRegularSlide
MMHUD.DoWeaponSlide = DoWeaponSlide
MMHUD.TickSliders = TickSliders

local function SlideTemplate(x,y,flags,weapons)
	local alpha = (flags & V_ALPHAMASK) >> V_ALPHASHIFT
	local slide = MMHUD.xoffset
	if weapons
		slide = MMHUD.weaponslidein
	end
	if (flags & V_SNAPTOLEFT)
		x = $ - slide
	elseif (flags & V_SNAPTORIGHT)
		x = $ + slide
	elseif (flags & V_SNAPTOTOP)
		y = $ - slide
	elseif (flags & V_SNAPTOBOTTOM)
		y = $ + slide
	else
		if flags & V_HUDTRANSHALF
			alpha = htranstable[MMHUD.hudtrans]
		elseif flags & V_HUDTRANSDOUBLE
			alpha = hudplusalpha[MMHUD.hudtrans]
		else
			alpha = (MMHUD.hudtrans)
		end
	end
	return x,y,alpha
end

addHook("HUD", function(v,p,c)
	--wrapper
	v.slideDrawScaled2 = function(x,y,scale,patch,flags,cmap, weapons)
		local x2,y2,alpha = SlideTemplate(x,y,flags,weapons)
		x,y = x2,y2
		if alpha >= 10 then return end
		flags = ($ &~V_ALPHAMASK)|(alpha << V_ALPHASHIFT)
		
		v.drawScaled(x,y,scale,patch,flags,cmap,translation)
	end
	v.slideDrawScaled = function(x,y,scale,patch,flags,cmap)
		v.slideDrawScaled2(x,y,scale,patch,flags,cmap,false)
	end
	v.WslideDrawScaled = function(x,y,scale,patch,flags,cmap)
		v.slideDrawScaled2(x,y,scale,patch,flags,cmap,true)
	end
	
	--wrapper
	v.slideDrawString2 = function(x,y,str,flags,align,fixed, weapons)
		if fixed == nil then fixed = true end
		str = $ or ""
		-- align = $ or (fixed and "fixed" or "left")
		if not fixed
			x = $*FU
			y = $*FU
		end
		
		local x2,y2,alpha = SlideTemplate(x,y,flags,weapons)
		x,y = x2,y2
		if alpha >= 10 then return end
		flags = ($ &~V_ALPHAMASK)|(alpha << V_ALPHASHIFT)
		
		if not fixed
			align = fixedalignlut[$]
		end
		v.drawString(x,y,str,flags,align)
	end
	v.slideDrawString = function(x,y,str,flags,align,fixed)
		v.slideDrawString2(x,y,str,flags,align,fixed,false)
	end
	v.WslideDrawString = function(x,y,str,flags,align,fixed)
		v.slideDrawString2(x,y,str,flags,align,fixed,true)
	end
	
	--wrapper
	v.slideDrawStretched2 = function(x,y,hs,vs,patch,flags,cmap, weapons)
		local x2,y2,alpha = SlideTemplate(x,y,flags,weapons)
		x,y = x2,y2
		if alpha >= 10 then return end
		flags = ($ &~V_ALPHAMASK)|(alpha << V_ALPHASHIFT)
		
		v.drawStretched(x,y,hs,vs,patch,flags,cmap)
	end
	v.slideDrawStretched = function(x,y,hs,vs,patch,flags,cmap)
		v.slideDrawStretched2(x,y,hs,vs,patch,flags,cmap,false)
	end
	v.WslideDrawStretched2 = function(x,y,hs,vs,patch,flags,cmap)
		v.slideDrawStretched2(x,y,hs,vs,patch,flags,cmap,true)
	end
	
	if MM:isMM() then
		if not hudwasmm then
			for i, data in ipairs(MMHUD.huds) do
				local drawFunc = data[2]
				
				if drawFunc == "None" then drawFunc = nil end
				
				if (is_hud_modded(data[1])
				and not customhud.ItemExists(data[1]))
				or not is_hud_modded(data[1]) then
					customhud.SetupItem(data[1], modname, drawFunc, data[3], data[4] or i)
					continue
				end
				
				customhud.enable(data[1])
			end
		end
		
		TickSliders()
		hudwasmm = true
		return
	end

	MMHUD.ticker = 0
	MMHUD.xoffset = HUD_BEGINNINGXOFF
	
	if hudwasmm
		for i,data in ipairs(MMHUD.huds) do
			if not is_hud_modded(data[1]) then
				customhud.SetupItem(data[1], "vanilla")
				continue
			end
			
			customhud.disable(data[1])
		end
	end
	
	hudwasmm = false
end)

--Cool
addHook("HUD",function(v)
	if hudwasmm
		TickSliders()
	end
end,"scores")
addHud "deathflash"
addHud "outofbounds"
addHud "afktimeout"
addHud "interacthud"
addHud "endgamepointer"
addHud "murdererping"
addHud "stormgohere"
addHud "attraction"
addHud "showdownicon"
addHud "role"
--good coding practices
addHud "gamerole"
addHud "goals"
addHud "availableitems"
addHud "weapontime"
addHud "pregamehud"
addHud "payment"
addHud "info"
addHud "toptext"
addHud "seenplayer"
addHud "results"
addHud "intermissiontally"
addHud "rankings"
addHud "real_rankings"
addHud "intermissionhud"
addHud "interhud_scores"
addHud "showdownanim"
addHud "foundplayer"
addHud "debug"
addHud "textspectator"
addHud "spectatormode"
addHud "menulib"
