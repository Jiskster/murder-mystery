local TR = TICRATE

local perk_name = "Fake Gun"
local perk_price = 325 --750

local hud_tween_start = -55*FU
local hud_tween = hud_tween_start
local icon_name = "MM_PI_FAKEGUN"
local icon_scale = FU/2

local perk_maxtime = 10*TR
local perk_cooldown = 30*TR

local clueItems = {
	"shotgun",
	"revolver",
	"sword",
	
	"loudspeaker",
	"snowball",
	
	"bloxycola",
	"burger",
	"radio",
}

local function perk_thinker(p)
	p.mm.perk_fake_time = $ or 0
	p.mm.perk_fake_cooldown = $ or 0
	
	if (p.cmd.buttons & BT_TOSSFLAG)
	and not (p.lastbuttons & BT_TOSSFLAG)
		if not p.mm.perk_fake_time
		and not p.mm.perk_fake_cooldown
			p.mm.perk_fake_time = perk_maxtime
			p.mm.perk_fake_cooldown = perk_cooldown + perk_maxtime
			p.mm.perk_fake_item = clueItems[P_RandomRange(1,#clueItems)]
		elseif p.mm.perk_fake_time
			p.mm.perk_fake_time = 0
			p.mm.perk_fake_cooldown = perk_cooldown
		end
	end
	
	if MM_N.gameover
		p.mm.perk_fake_time = 0
	end
	
	if p.mm.perk_fake_cooldown
		p.mm.perk_fake_cooldown = max($-1,0)
	end
	
	--id put this in whitespace but perks are executed too early
	local knife_def = MM.Items["knife"]
	
	if p.mm.perk_fake_time
		p.mm.perk_fake_time = max($-1, 0)
		
		local fake_def = MM.Items[p.mm.perk_fake_item]
		for i = 1, p.mm.inventory.count
			local item = p.mm.inventory.items[i]
			
			if (item and item.mobj and item.mobj.valid and item.id == "knife")
				if not (item.perkfake_setit)
					item.equipsfx = fake_def.equipsfx
					item.mobj.state = fake_def.state
					item.display_icon = fake_def.display_icon
					item.perkfake_setit = true
				end
				
				if p.mm.perk_fake_time == 0
					item.equipsfx = knife_def.equipsfx
					item.mobj.state = knife_def.state
					item.display_icon = knife_def.display_icon
					item.perkfake_setit = false
				end
			end
		end
	elseif p.mm.perk_fake_cooldown >= (perk_cooldown - perk_maxtime - TR)
		for i = 1, p.mm.inventory.count
			local item = p.mm.inventory.items[i]
			
			if (item and item.mobj and item.mobj.valid and item.id == "knife")
				if (item.perkfake_setit)
					item.equipsfx = knife_def.equipsfx
					item.mobj.state = knife_def.state
					item.display_icon = knife_def.display_icon
					item.perkfake_setit = false
				end
			end
		end
	end
end
--yeah this is SUPER good code


MM_PERKS[MMPERK_FAKEGUN] = {
	primary = perk_thinker,
	secondary = perk_thinker,
	
	drawer = function(v,p,c, order)
		local x = 5*FU
		local y = 100*FU
		local scale = FU/2
		local flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
		local timer = 0
		if order == "sec" then y = $ + 18*FU end
		
		if p.mm.perk_fake_time == nilthen return end

		if (order == "pri")
			local x = 5*FU
			local y = 162*FU
			
			if (p.mm.perk_fake_cooldown == 0)
				local action = "Fake gun"
				v.slideDrawString(x,y,
					"[TOSSFLAG] - "..action,
					V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_ALLOWLOWERCASE,
					"thin-fixed"
				)
			end
		end
		
		if (p.mm.perk_fake_time == 0
		and p.mm.perk_fake_cooldown == 0)
		and FixedFloor(hud_tween) == hud_tween_start
			return
		end
		
		if (p.mm.perk_fake_time > 0)
			hud_tween = ease.inquad(FU/2, $, 0)
			timer = p.mm.perk_fake_time/TR
		else
			if p.mm.perk_fake_cooldown == 0
				hud_tween = ease.inquad(FU/4, $, hud_tween_start)
			end
			timer = p.mm.perk_fake_cooldown/TR
			flags = $|V_50TRANS
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
		"\x82When equipped:\x80 Pressing [TOSSFLAG] will",
		"change your knife's appearance to a random gun,",
		"fooling Innocents. You can still",
		"kill with it!",
		"Press [TOSSFLAG] again to deactivate it.",
		
		"",
		
		"Lasts 10 seconds with a 30 second cooldown."
	},
	cost = perk_price
}

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_FAKEGUN