local match_time = 180*TICRATE
local duel_time = 60*TICRATE
local pregame_time = 10*TICRATE

return {
	time = match_time + pregame_time,
	maxtime = match_time,
	pregame_time = pregame_time,
	duel_time = duel_time,
	dueling = false,
	rounds = 0,
	
	gametype = "classic",

	special_count = 0,

	murderers = {},
	innocents = {},

	theme = "srb2",

	transition = false,
	transition_time = 0,

	clues_amount = 0,
	clues_in_map = false,
	clues_weaponsleft = 0,
	clues_singlemode = false,
	clues_positions = {},
	clues = {},
	
	speed_cap = 23*FU,

	waiting_for_players = false,
	found_player = false,
	waiting_start_time = 7*TICRATE,

	showdown = false,
	showdown_song = "_PINCH",
	showdown_ticker = 0,
	showdown_left = {},
	showdown_right = {},
	showdown_ticker = 0,

	overtime = false,
	overtime_ticker = 0,

	storm_point = nil,
	storm_ticker = 0,
	storm_startingdist = 6000*FU,
	storm_usedpoints = false,
	
	gameover = false,
	voting = false,
	mapVote = {},
	results_ticker = 0,
	end_ticker = 0,
	lastmap = -1,

	pings_done = 0,
	ping_time = 0,
	ping_approx = FU,
	max_ping_time = 30*TICRATE,
	ping_positions = {},

	corpses = {},
	knownDeadPlayers = {},
	minimum_killed = 0,
	numbertokill = 0,
	peoplekilled = 0,
	
	/*
		--Dont take into account aliases when checking for dupe colors
		[player_t*] = {
			color = SKINCOLOR_*,
			skin = "string",
		}
	*/
	player_colors = {},

	-- General gamtype attributes.
	allow_respawn = false,
	ignore_missing_roles = false,

	--round ended because all innocents/murderers left the game
	disconnect_end = false,
	killing_end = false,
	sniped_end = false,
	
	--list of sectors safe to spawn coins in
	safe_sectors = {},
	--"UserData"
	safe_sectors_ud = {},
}