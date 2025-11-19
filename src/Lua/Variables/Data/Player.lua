local player_variables = 
{
	role = MMROLE_INNOCENT,
	spectator = false,
	got_weapon = false,

	timesurvived = 0,
	ringspaid = 0,
	--rings collected during the match
	rings = 0,
	
	clues = {},
	clues_collected = 0,

	-- Never show this info in tab menu.
	alias = nil,
	alias_save = nil,
	
	usingsetcolor = false,
	savedcolor = nil,
	joinedmidgame = false,

	selected_map = false,
	cur_map = 1,

	forwardmove = 0,
	sidemove = 0,
	lastforward = 0,
	lastside = 0,
	buttons = 0,
	
	afktimer = 0,
	afkhelpers = {
		timedout = false,
		timeuntilreset = 0,
		lastangle = 0,
		lastaiming = 0,
		keepalive = false,
	},
	afkmodelast = false,
	
	interact = {
		--the actual points of interests
		points = {},
		interacted = false,
	},
	
	outofbounds = false,
	oob_dist = 0,
	oob_ticker = 0,

	inventory = {
		items = {},
		hidden = true,
		cur_sel = 1,
		count = 4
	},
	
	attract = {
		/*
		{
			x = fixed_t,
			y = fixed_t,
			z = fixed_t,
			tics = tic_t,
			str = string,
			patch = string
		}
		*/
	},
	teammates = {},
	refreshteammates = false,
	
	effects = {},
}

setmetatable(player_variables, MM.player_metatable)

return player_variables