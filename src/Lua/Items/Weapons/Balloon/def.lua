local weapon = {}

weapon.id = "balloon"
weapon.category = "Utility"
weapon.display_name = "Balloon"
weapon.display_icon = "MM_BALLOON"
weapon.state = dofile "Items/Weapons/Balloon/freeslot"
weapon.timeleft = -1
weapon.hit_time = TICRATE/3
weapon.animation_time = TICRATE
weapon.cooldown_time = TICRATE
weapon.range = FU
weapon.zrange = FU
weapon.position = {
	x = FU,
	y = 0,
	z = 2*FU
}

weapon.animation_position = weapon.position

weapon.stick = true
weapon.animation = true
weapon.damage = false
weapon.weaponize = false
weapon.droppable = true
weapon.shootable = false
weapon.shootmobj = MT_THOK
weapon.equipsfx = sfx_None
weapon.attacksfx = sfx_None

weapon.thinker = function(item, player)
	if not (player.mo and player.mo.valid) then
		return end;
		
	if not P_IsObjectOnGround(player.mo) then
		P_SetObjectMomZ(player.mo, (-P_GetMobjGravity(player.mo)/2)*P_MobjFlip(player.mo), true)
		
		if player.mo.momz > 0 then
			if player.mo.state ~= S_PLAY_SPRING then
				player.mo.state = S_PLAY_SPRING
			end
		else
			if player.mo.state ~= S_PLAY_FALL then
				player.mo.state = S_PLAY_FALL
			end
		end
	end
end


return weapon