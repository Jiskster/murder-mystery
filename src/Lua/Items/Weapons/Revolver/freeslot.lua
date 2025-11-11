states[freeslot("S_MM_REVOLV")] = {
	sprite = freeslot("SPR_RVOL"),
	frame = A,
	tics = -1
}

sfxinfo[freeslot "sfx_gequip"].caption = "Gun equip"
sfxinfo[freeslot "sfx_gnfire"] = {
	caption = "Gun fire",
	flags = SF_X2AWAYSOUND
}
sfxinfo[freeslot "sfx_revlsh"] = {
	caption = "Revolver fire",
	flags = SF_X2AWAYSOUND
}
sfxinfo[freeslot "sfx_revcrt"] = {
	caption = "/",
	flags = SF_X2AWAYSOUND
}
sfxinfo[freeslot "sfx_gnpick"].caption = "Item pick up"
sfxinfo[freeslot "sfx_gndrop"].caption = "Item drop"

return S_MM_REVOLV