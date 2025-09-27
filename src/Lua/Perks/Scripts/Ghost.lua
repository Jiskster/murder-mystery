local perk_name = "Ghost"
local perk_price = 525 --1500

local ghost_min_alpha = FU/2
freeslot("sfx_cloak1")
sfxinfo[sfx_cloak1] = {
	flags = SF_X2AWAYSOUND,
	caption = "\x86".."Murderer cloaks\x80"
}
freeslot("sfx_cloak2")
sfxinfo[sfx_cloak2] = {
	flags = SF_X2AWAYSOUND,
	caption = "\x86".."Murderer uncloaks\x80"
}

local TR = TICRATE

local hud_tween_start = -55*FU
local hud_tween = hud_tween_start
local icon_name = "MM_PI_GHOST"
local icon_scale = FU/2

local perk_maxtime = 8*TR
local perk_cooldown = 20*TR
local perk_volume = (255)/4
local perk_translation = "Grayscale"
local perk_translucent = tofixed("0.6")

MM_PERKS[MMPERK_GHOST] = {
	primary = function(p)
		p.mm.perk_ghost_time = $ or 0
		p.mm.perk_ghost_cooldown = $ or 0
		
		local me = p.mo
		
		local last_ghosting = p.mm.perk_ghost_time
		
		if (p.cmd.buttons & BT_TOSSFLAG)
		and not (p.lastbuttons & BT_TOSSFLAG)
			if (p.mm.perk_ghost_cooldown == 0)
				p.mm.perk_ghost_time = perk_maxtime
				p.mm.perk_ghost_cooldown = perk_cooldown + perk_maxtime
				
				S_StartSoundAtVolume(me, sfx_cloak1, perk_volume)
			elseif p.mm.perk_ghost_time
				p.mm.perk_ghost_time = 0
				p.mm.perk_ghost_cooldown = perk_cooldown
			end
		end
		
		if MM_N.gameover
			p.mm.perk_ghost_time = 0
		end
		
		if ((p.mm.perk_ghost_time >= perk_maxtime - TR)
		or (p.mm.perk_ghost_time == 0
		and p.mm.perk_ghost_cooldown >= perk_cooldown - (2*TR)))
		and (leveltime % 3 == 0)
			local rad = FixedDiv(p.mo.radius,p.mo.scale)/FU
			local hei = FixedDiv(p.mo.height,p.mo.scale)/FU
			local dust = P_SpawnMobjFromMobj(p.mo,
				P_RandomRange(-rad,rad)*FU,
				P_RandomRange(-rad,rad)*FU,
				P_RandomRange(0,hei)*FU,
				MT_TNTDUST
			)
			dust.scale = ($/4) + P_RandomRange(0,FU/2)
			dust.fuse = $/10
			dust.angle = R_PointToAngle2(dust.x,dust.y, p.mo.x,p.mo.y)
			P_Thrust(dust,dust.angle, -P_RandomRange(0,2)*dust.scale)
			P_SetObjectMomZ(dust,P_RandomRange(-2,2)*FU)
			dust.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
			dust.alpha = FRACUNIT/2
		end
		
		if p.mm.perk_ghost_cooldown
			p.mm.perk_ghost_cooldown = max($-1,0)
		end
		
		if p.mm.perk_ghost_time
			me.alpha = FixedFloor(ease.linear(FU/2, $, 0) * 100)/100
			p.mm.perk_ghost_time = max($-1,0)
			
			if not (me.mm_overlay and me.mm_overlay.valid)
				local over = P_SpawnMobjFromMobj(me,
					0,0,0,
					MT_OVERLAY
				)
				over.sprite = me.sprite
				over.state = S_PLAY_WAIT
				over.skin = me.skin
				over.tics,over.fuse = -1,-1
				over.target = me
				--over.drawonlyforplayer = p
				over.dontdrawforviewmobj = me
				over.shadowscale = me.shadowscale
				me.mm_overlay = over
			end
			me.mm_overlay.sprite = me.sprite
			me.mm_overlay.sprite2 = me.sprite2
			me.mm_overlay.anim_duration = me.anim_duration
			me.mm_overlay.frame = me.frame
			me.mm_overlay.color = me.color
			me.mm_overlay.alpha = max(me.alpha, ghost_min_alpha)
		else
			me.alpha = FixedCeil(ease.linear(FU/3, $, FU) * 100)/100
			
			if (me.mm_overlay and me.mm_overlay.valid)
				me.mm_overlay.sprite = me.sprite
				me.mm_overlay.sprite2 = me.sprite2
				me.mm_overlay.frame = me.frame
				me.mm_overlay.color = me.color
				me.mm_overlay.anim_duration = me.anim_duration
				me.mm_overlay.alpha = max($, me.alpha)
				
				if me.alpha >= FU
					P_RemoveMobj(me.mm_overlay)
					me.mm_overlay = nil
				end
			end
		end
		
		if (me.mm_overlay and me.mm_overlay.valid)
		and (displayplayer and displayplayer.valid)
			if displayplayer.mm.role ~= MMROLE_MURDERER
				me.mm_overlay.flags2 = $|MF2_DONTDRAW	
			else
				me.mm_overlay.flags2 = $ &~MF2_DONTDRAW
			end
		end
		
		if last_ghosting > 0
		and p.mm.perk_ghost_time == 0
			S_StartSoundAtVolume(me, sfx_cloak2, perk_volume)
		end
	end,
	
	secondary = function(p)
		local me = p.mo
		local item = p.mm.inventory.items[p.mm.inventory.cur_sel]
		if not (item and item.id == "knife")
			me.alpha = FixedCeil(ease.linear(FU/2, $, FU) * 100)/100
			if me.lasttranslation
				me.translation = me.lasttranslation.t
				me.lasttranslation = nil
			end
			return
		end
		
		if (p.mm.inventory.hidden)
			me.alpha = FixedCeil(ease.linear(FU/2, $, FU) * 100)/100
			if me.lasttranslation
				me.translation = me.lasttranslation.t
				me.lasttranslation = nil
			end
		else
			me.alpha = FixedFloor(ease.linear(FU/2, $, perk_translucent) * 100)/100
			if not me.lasttranslation
				me.lasttranslation = {
					t = me.translation
				}
			end
			me.translation = perk_translation
		end
	end,

	drawer = function(v,p,c, order)
		local x = 5*FU
		local y = 100*FU
		local scale = FU/2
		local flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
		local timer = 0
		if order == "sec" then y = $ + 18*FU end
		
		if p.mm.perk_ghost_time == nil and order == "pri" then return end

		if (order == "pri")
			local x = 5*FU
			local y = 162*FU
			
			if (p.mm.perk_ghost_cooldown == 0
			or p.mm.perk_ghost_time > 0)
				local action = ""
				if (p.mm.perk_ghost_time == 0)
					action = "Cloak"
				elseif p.mm.perk_ghost_time >= 0
					action = "Uncloak"
				end
				v.slideDrawString(x,y,
					"[TOSSFLAG] - "..action,
					V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_ALLOWLOWERCASE,
					"thin-fixed"
				)
			end
		end
		
		if (p.mm.perk_ghost_time == 0
		and p.mm.perk_ghost_cooldown == 0
		and order == "pri")
		and FixedFloor(hud_tween) == hud_tween_start
			return
		end
		
		if order == "pri"
			if (p.mm.perk_ghost_time > 0)
				hud_tween = ease.inquad(FU/2, $, 0)
				timer = p.mm.perk_ghost_time/TR
			else
				if p.mm.perk_ghost_cooldown == 0
					hud_tween = ease.inquad(FU/4, $, hud_tween_start)
				else
					hud_tween = ease.inquad(FU/2, $, 0)
				end
				timer = p.mm.perk_ghost_cooldown/TR
				flags = $|V_50TRANS
			end
		else
			timer = ""
			if FixedFloor(p.realmo.alpha) ~= FU
				hud_tween = ease.inquad(FU/2, $, 0)
			else
				hud_tween = ease.inquad(FU/4, $, hud_tween_start)
			end
		end
		x = $ + hud_tween
		
		v.drawScaled(x,
			y,
			FixedMul(scale, icon_scale),
			v.cachePatch(icon_name),
			flags
		)
		v.drawString(x,
			y + (31*scale) - 8*FU,
			timer,
			flags &~V_ALPHAMASK,
			"thin-fixed"
		)
	end,
	
	icon = icon_name,
	icon_scale = icon_scale,
	name = perk_name,
	
	description = {
		"\x82Primary:\x80 Become fully invisible to",
		"non-murderers for 8 seconds! Cooldowns for",
		"30 seconds. \x82([TOSSFLAG] to activate)",
		
		"",
		
		"\x82Secondary:\x80 Become "..string.format("%.1f",(perk_translucent*100)).."% transparent",
		"when holding your knife!",
	},
	cost = perk_price,
}

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_GHOST