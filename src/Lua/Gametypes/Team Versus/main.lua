local teamversus_mode = MM.RegisterGametype("Team Versus", {
	max_time = 2*60*TICRATE;
	required_players = 8;
	fill_teams = true;
	disable_item_mapthing = true; -- includes interactions that drop items.
	disable_perks = true;
	disable_proximity_chat = true;
	disable_clues = true;
	disable_showdown = true;
	disable_gun_countdown = true;
	force_overtime = true;
	reveal_roles = true;
	items = {"revolver", "shotgun", "sword", "knife"};
})