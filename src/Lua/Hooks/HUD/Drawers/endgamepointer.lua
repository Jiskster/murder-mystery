local sglib = MM.require "Libs/sglib"
local roles = MM.require "Variables/Data/Roles"

local snipe_count = 0
local snipe_ticker = 0
local snipe_frac = 0

local function HUD_EndGameDrawer(v,p,c)
	if not (MM_N.gameover and not MM_N.voting)
		snipe_count = 0
		snipe_ticker = 0
		snipe_frac = 0
		return
	end

	if MM_N.sniped_end then
		local patch = v.cachePatch("MM_SNIPER_APPROVED")
		local tic = MM_N.end_ticker - (TICRATE*3 + MM.sniper_theme_offset) + 6
		if tic > 0 then
			local slide = ease.inquad(min(FU-1, tic*FU/6), FU, 0)
			v.drawScaled(
				140*FU,
				140*FU,
				FU/2 + slide*2,
				patch,
				V_SNAPTOBOTTOM|V_SNAPTORIGHT
			)
		end
		
		if snipe_ticker <= 3*TICRATE
			snipe_count = ease.outexpo(
				snipe_ticker * (FU / (TICRATE*3)),
				0, MM_N.sniped_dist
			)
			snipe_frac = $ + ease.outsine(
				snipe_ticker * (FU / (TICRATE*3)),
				2 * FU, 0
			)
		end
		
		snipe_ticker = $ + 1
		while (snipe_frac > FU)
			S_StartSound(nil, sfx_ptally)
			snipe_frac = $ - FU
		end
		
		v.drawString(160,150,
			string.format("%.2f meter snipe!", snipe_count),
			V_ALLOWLOWERCASE|V_SNAPTOBOTTOM,
			"thin-center"
		)
	end
	
	if MM_N.end_killed and MM_N.end_killed.valid
	and (MM_N.end_killed.player and MM_N.end_killed.player.valid)
		local w2s = sglib.ObjectTracking(v,p,c,MM_N.end_killed,false,true)

		if w2s.onScreen
			local isme = ''
			if MM_N.end_killed == consoleplayer.realmo
				isme = "\x80 (you!)"
			end
			
			v.drawString(w2s.x,
				w2s.y - 32*w2s.scale,
				roles[MM_N.end_killed.player.mm.role].name..isme,
				roles[MM_N.end_killed.player.mm.role].color,
				"thin-fixed-center"
			)
		end
		
	end

	if MM_N.end_killer and MM_N.end_killer.valid and MM_N.end_killer.health and MM_N.end_killer.player
		local w2s = sglib.ObjectTracking(v,p,c,MM_N.end_killer,false,true)

		if w2s.onScreen
			local isme = ''
			if MM_N.end_killer == consoleplayer.realmo
				isme = "\x80 (you!)"
			end
			
			if MM_N.end_killed
			and MM_N.end_killed.valid
			and MM_N.end_killed.player.mm.role == MMROLE_MURDERER
				local name = MM_N.end_killer.player.mm.role == MMROLE_SHERIFF and roles[MMROLE_SHERIFF].name or "HERO"
				local map = MM_N.end_killer.player.mm.role == MMROLE_SHERIFF and roles[MMROLE_SHERIFF].color or V_YELLOWMAP
				
				--amazing!
				if MM_N.end_killer.player.mm.role == MMROLE_MURDERER
					name = roles[MMROLE_MURDERER].name
					map = roles[MMROLE_MURDERER].color
				end
				
				v.drawString(w2s.x,
					w2s.y - 64*w2s.scale,
					name..isme,
					map,
					"thin-fixed-center"
				)
				v.drawString(w2s.x,
					w2s.y - 64*w2s.scale - 8*FU,
					MM_N.end_killer.player.name,
					map|V_ALLOWLOWERCASE,
					"thin-fixed-center"
				)
			--Innocents kill each other
			else
				v.drawString(w2s.x,
					w2s.y - 64*w2s.scale,
					roles[MM_N.end_killer.player.mm.role].name..isme,
					roles[MM_N.end_killer.player.mm.role].color,
					"thin-fixed-center"
				)
			end
		end
		
	end
	
end

return function(v,p,c)
    MMHUD.interpolate(v,true)
    HUD_EndGameDrawer(v,p,c)
    MMHUD.interpolate(v,false)
end