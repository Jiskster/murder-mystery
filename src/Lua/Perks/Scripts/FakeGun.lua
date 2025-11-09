local TR = TICRATE

local perk_name = "Fake Gun"
local perk_price = 325 --750

local icon_name = "MM_PI_FAKEGUN"
local icon_scale = FU/2

local perk_maxtime = 15*TR
local perk_cooldown = 18*TR

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
	
	patchbehavior = function(v,p,c, order, props)
		if p.mm.perk_fake_time == nil then return end
		if (p.mm.perk_fake_time > 0)
			-- perk is active
		else
			return V_50TRANS
		end
	end,
	drawer = function(v,p,c, order, props)
		local x = props.x
		local y = props.y
		local flags = props.flags
		if p.mm.perk_fake_time == nil then return end
		local timer
		
		if (order == "pri")
			if (p.mm.perk_fake_cooldown == 0)
				local action = ""
				if (p.mm.perk_fake_time == 0)
					action = "Fake Gun"
				elseif p.mm.perk_fake_time >= 0
					action = "Un-Fake"
				end
				v.slideDrawString(5*FU,162*FU,
					"[TOSSFLAG] - "..action,
					V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_ALLOWLOWERCASE,
					"thin-fixed"
				)
			end
		end
		
		if (p.mm.perk_fake_time > 0)
			timer = "\x82" .. tostring((p.mm.perk_fake_time/TR)+1)
		elseif p.mm.perk_fake_cooldown
			timer = (p.mm.perk_fake_cooldown/TR)+1
		end
		if timer
			v.slideDrawString(x,y + 9*FU,
				timer .. "s", flags|V_ALLOWLOWERCASE,
				"thin-fixed"
			)
		end
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
		
		"Lasts 15 seconds with a 18 second cooldown."
	},
	cost = perk_price
}

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_FAKEGUN