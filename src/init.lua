-- SAXAS MURDER MYSTERY

rawset(_G, "MM_N", {})
rawset(_G, "MM", {})
freeslot("TOL_SAXAMM")

G_AddGametype({
    name = "Murder Mystery",
    identifier = "SAXAMM",
    typeoflevel = TOL_SAXAMM,
    rules = GTR_FRIENDLYFIRE|GTR_SPAWNINVUL|GTR_DEATHMATCHSTARTS|GTR_SPAWNENEMIES,
    intermissiontype = int_match,
    headercolor = 164,
	description = "Who murdered this guy? It's a mystery!"
})

for i = 0,1
	freeslot("sfx_mmste"..i)
	sfxinfo[sfx_mmste0 + i].caption = "\x89".."Entered storm!\x80"
end
for i = 0,2
	freeslot("sfx_mmstl"..i)
	sfxinfo[sfx_mmstl0 + i].caption = "\x89".."Exited storm\x80"
end
sfxinfo[freeslot("sfx_mmsmig")].caption = "\x89".."Storm migrating\x80"
sfxinfo[freeslot("sfx_mmstm1")].caption = "/" --"\x89".."Raining\x80"
sfxinfo[freeslot("sfx_mmstm2")].caption = "/" --"\x89".."Wind blowing\x80"

--Zombie Escape 2 by Jisk, used with permission
sfxinfo[freeslot("sfx_oldrad")].caption = "/"

sfxinfo[freeslot("sfx_mmdie0")] = {
	caption = "Dying",
	flags = SF_X4AWAYSOUND
}

freeslot("SPR_BGLS")
freeslot("S_MM_TEAMMATE1")
states[S_MM_TEAMMATE1] = {
	sprite = SPR_BGLS,
	frame = E|FF_FULLBRIGHT,
	tics = 2
}
freeslot("S_MM_TEAMMATE2")
states[S_MM_TEAMMATE2] = {
	sprite = SPR_BGLS,
	frame = F|FF_FULLBRIGHT,
	tics = 2
}
freeslot("S_MM_SWAPIND")
states[S_MM_SWAPIND] = {
	sprite = SPR_BGLS,
	frame = O|FF_FULLBRIGHT,
	tics = 2
}

MM.require = dofile "Libs/require"
dofile "Libs/CustomHud.lua"
dofile "Libs/MenuLib/init.lua"

dofile "events"

dofile "Variables/main"
dofile "Functions/main"
dofile "Console/main"
dofile "Shop/main"
dofile "Perks/main"
dofile "Interactions/main"
dofile "Hooks/main"
dofile "Gametypes/main"
dofile "Cameras/run"
dofile "Clues/main"
dofile "Items/main"
dofile "ItemMapthings/main"
dofile "Maps/exec"
dofile "Objects/NeoRings/define"
dofile "Objects/Vanilla Mobj Tweaks/Monitors"
dofile "Menus/exec"

-- fool-proofing
-- basically if you reference a variable thats not in the local table
-- it corrects itself to get the variable in the network table
-- ofc, its faster to reference the correct tables
-- so dont use this too much
setmetatable(MM, {
	--guess im the fool for trying to optimize this one huh..
	__index = function(self, key)
		if rawget(self, key) ~= nil then
			return rawget(self, key)
		end
		
		if MM_N[key] ~= nil then
			return MM_N[key]
		end
	end,
	__newindex = function(self, key, value)
		if MM_N[key] ~= nil then
			MM_N[key] = value
			return
		end
		
		rawset(self, key, value)
	end
})

--generate random string for security purposes
rawset(_G, "MM_luaSignature", "iAmLua"..P_RandomFixed())
addHook("NetVars",function(n) MM_luaSignature = n($); end)

MM.savefile_path = "client/EpicMurderMystery/savefile.dat"