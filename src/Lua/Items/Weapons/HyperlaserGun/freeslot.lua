freeslot("SPR_HYPERLASERGUN")
states[freeslot("S_MM_HYPERLASER")] = {
	sprite = SPR_HYPERLASERGUN,
	frame = A|FF_SEMIBRIGHT,
	tics = -1
}

sfxinfo[freeslot("sfx_hlgn_f")] = {
	caption = "Hyperlaser gun fires",
	flags = SF_X4AWAYSOUND
}
sfxinfo[freeslot("sfx_hlgn_r")] = {
	caption = "/",
}
sfxinfo[freeslot("sfx_hlgn_h")] = {
	caption = "/",
	flags = SF_X2AWAYSOUND
}

return S_MM_HYPERLASER