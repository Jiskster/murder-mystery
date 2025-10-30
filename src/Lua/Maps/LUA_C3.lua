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
		flags = MF_RUNSPAWNFUNC|MF_ENEMY|MF_FLOAT|MF_NOGRAVITY|MF_PAIN
}

--Script by: SpectrumUK
addHook("MobjThinker", function(mo)
	if not mo.tracer then return end
    if not S_SoundPlaying(mo, sfx_tdsee)
        S_StartSound(mo, sfx_tdsee)
    end
end, MT_TAILSDOLL)