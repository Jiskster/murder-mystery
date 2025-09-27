local perk_name = "Haste"
local perk_price = 325 --750

MM:RegisterEffect("perk.primary.haste", {
	modifiers = {
		normalspeed_multi = tofixed("1.10") -- no luigi, i hate srb2 division
	},
})

MM:RegisterEffect("perk.secondary.haste", {
	modifiers = {
		normalspeed_multi = tofixed("1.07")
	},
})

local hud_tween_start = -55*FU
local hud_tween = hud_tween_start
local icon_name = "MM_PI_HASTE"
local icon_scale = FU/2

local function windeffect(p)
	if p.speed < 20*p.mo.scale then return end
	if (leveltime & 1) then return end
	
	local me = p.mo
	local rad = FixedDiv(me.radius,me.scale)/FU
	local hei = FixedDiv(me.height,me.scale)/FU
	
	local wind = P_SpawnMobjFromMobj(me,
		P_RandomRange(-rad,rad)*FU,
		P_RandomRange(-rad,rad)*FU,
		P_RandomRange(0,hei)*FU,
		MT_THOK
	)
	wind.sprite = SPR_RAIN
	wind.fuse = TICRATE/2
	wind.tics = wind.fuse
	wind.frame = $|FF_PAPERSPRITE|FF_SEMIBRIGHT|FF_ADD
	
	local momz = me.momz
	if (me.lastz ~= nil)
		momz = me.z - me.lastz 
	end
	
	wind.angle = R_PointToAngle2(0,0, me.momx, me.momy)
	wind.rollangle = R_PointToAngle2(0, 0, R_PointToDist2(0,0,me.momx,me.momy), momz) + ANGLE_90
	
	wind.momx = me.momx/3
	wind.momy = me.momy/3
	wind.momz = momz/3
	
	wind.spriteyoffset = -16*FU
	
	wind.height = wind.scale
	wind.radius = 5*wind.scale
	wind.dontdrawforviewmobj = me
end

local thinkers = {
	[1] = function(p)
		local item = p.mm.inventory.items[p.mm.inventory.cur_sel]
		if not (item and item.id == "knife") then return end
		if p.mm.inventory.hidden then return end
		if not P_IsObjectOnGround(p.mo) then return end
		if p.speed < 17*p.mo.scale then return end
		
		MM:ApplyPlayerEffect(p, "perk.primary.haste")
		p.runspeed = FixedMul(MM_N.speed_cap, tofixed("1.20")) - 7*FU
		windeffect(p)
	end,
	[2] = function(p)
		local item = p.mm.inventory.items[p.mm.inventory.cur_sel]
		if not (item and item.id == "knife") then return end
		if p.mm.inventory.hidden then return end
		if not P_IsObjectOnGround(p.mo) then return end
		if p.speed < 17*p.mo.scale then return end
		
		MM:ApplyPlayerEffect(p, "perk.secondary.haste")
		p.runspeed = FixedMul(MM_N.speed_cap, tofixed("1.10")) - 7*FU
		windeffect(p)
	end,
}

--i know this is bad, kill me later
MM_PERKS[MMPERK_HASTE] = {
	primary = function(p)
		thinkers[1](p)
		
		if p.mo and p.mo.valid
			p.mo.lastz = p.mo.z
		end
	end,
	secondary = function(p)
		thinkers[2](p)
		
		if p.mo and p.mo.valid
			p.mo.lastz = p.mo.z
		end
	end,
	
	drawer = function(v,p,c, order)
		local x = 5*FU
		local y = 100*FU
		local scale = FU/2
		local flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
		if order == "sec" then y = $ + 18*FU end
		
		local knifeequiped = true
		local item = p.mm.inventory.items[p.mm.inventory.cur_sel]
		if not (item and item.id == "knife") then knifeequiped = false; end
		if p.mm.inventory.hidden then knifeequiped = false; end
		
		if knifeequiped
			hud_tween = ease.inquad(FU/2, $, 0)
		else
			hud_tween = ease.inquad(FU/4, $, hud_tween_start)
		end
		x = $ + hud_tween

		v.drawScaled(x,
			y,
			FixedMul(scale, icon_scale),
			v.cachePatch(icon_name),
			flags
		)
	end,
	
	--this icon is so fucking goofy
	--its placeholder for a reason bruh
	icon = icon_name,
	icon_scale = icon_scale,
	name = perk_name,

	description = {
		"\x82Primary:\x80 Speed up 11% when holding",
		"your knife out!",
		
		"",
		
		"\x82Secondary:\x80 Speed up 8% when holding",
		"your knife out!",
	},
	cost = perk_price,
}

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_HASTE