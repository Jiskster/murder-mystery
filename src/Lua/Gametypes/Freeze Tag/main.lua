MM.RegisterGametype("Freeze Tag", {
	max_time = 4*60*TICRATE;
	disable_overtime = true;
	disable_sheriff = true;
	disable_item_mapthing = true; -- includes interactions that drop items.
})