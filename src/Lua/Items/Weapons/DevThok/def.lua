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