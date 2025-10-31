--TD Script and behavior used with permission of DylanSahr from TD Forest

freeslot("SPR_TDOL", "SFX_TDSEE", "SFX_SCRETD", "S_TD_FLOAT1", "S_TD_CHASE1", "S_TD_CHASE2", "MT_TAILSDOLL")
		
states[S_TD_FLOAT1] = {SPR_TDOL, A, 1, A_Look, 0, 0, S_TD_FLOAT1}
states[S_TD_CHASE1] = {SPR_TDOL, FF_FULLBRIGHT|B, 1, A_DetonChase, 0, 0, S_TD_CHASE2}
states[S_TD_CHASE2] = {SPR_TDOL, FF_FULLBRIGHT|C, 1, A_DetonChase, 0, 0, S_TD_CHASE1}

mobjinfo[MT_TAILSDOLL] = {
		//$Name Tails Doll
		//$Sprite TDOLA1
		//$Category Enemies
        doomednum = -1,
        spawnstate = S_TD_FLOAT1,
        spawnhealth = 1,
        seestate = S_TD_CHASE1,
        seesound = sfx_TDSEE,
		painchance = 2000,
        reactiontime = 1,
		speed = 30*FRACUNIT,
        radius = 10*FRACUNIT,
        height = 40*FRACUNIT,
		damage = 1,
		flags = MF_RUNSPAWNFUNC|MF_ENEMY|MF_FLOAT|MF_NOGRAVITY|MF_SPECIAL
}

--Script by: SpectrumUK
addHook("MobjThinker", function(mo)
	if not mo.tracer then return end
    if not S_SoundPlaying(mo, sfx_tdsee)
        S_StartSound(mo, sfx_tdsee)
    end
end, MT_TAILSDOLL)

local td_kill = function(mo, mo2)
	P_KillMobj(mo2, mo, mo)
	P_KillMobj(mo)
	return true
end
addHook("TouchSpecial", td_kill, MT_TAILSDOLL)

--Other Interactions

freeslot("sfx_loff")

--Lord X painting
freeslot("sfx_haha")

local hauntedmansion_screen = function(v,p)
	if not p.statictimer then return end
	if p.statictimer then
		local frame = (leveltime % 4)
		local patch = v.cachePatch("STATIC"..frame)
		local wid = (v.width() / v.dupx()) + 1
		local hei = (v.height() / v.dupy()) + 1
		local p_w = patch.width
		local p_h = patch.height
		v.drawStretched(0,0,
			FixedDiv(wid * FU, p_w * FU),
			FixedDiv(hei * FU, p_h * FU),
			patch,
			V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS
		)
	end
end

local trigger_lordxstatic = function(line, mo)
	if mo.player
		if not mo.player.statictimer then mo.player.statictimer = 2*TICRATE end
	end
end
local staticperplayer = function(p)
	if not p.statictimer then return end
	p.statictimer = $-1
end
addHook("PlayerThink", staticperplayer)
addHook("LinedefExecute", trigger_lordxstatic, "LORDX")

customhud.SetupItem("hauntedmansion_events", "HauntedMansion", hauntedmansion_screen, "game", -1)