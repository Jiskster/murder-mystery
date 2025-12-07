--player tip: you needa kill yourself
local Roles = MM.require("Variables/Data/Roles")
local rolebutt = {
	w = 70,
	h = 16,
}
local RoleExtraData = {
	icons = {
		[MMROLE_INNOCENT] = "MM_RADIO",
		[MMROLE_SHERIFF] = "MM_REVOLVER",
		[MMROLE_MURDERER] = "MM_KNIFE"
	},
	palette = {
		-- {light, dark}
		[MMROLE_INNOCENT] = {102, 111},
		[MMROLE_SHERIFF] = {150, 159},
		[MMROLE_MURDERER] = {38, 47},
	}
}

local function drawRoleButton(v,x,y, role)
	local role_t = Roles[role]
	
	MenuLib.addButton(v, {
		x = x, y = y,
		width = rolebutt.w, height = rolebutt.h,
		name = "",
		color = 13,
		outline = RoleExtraData.palette[role][2],
		
		pressFunc = function()
			local newpage = MenuLib.findMenu("GuidePage_"..(role_t.name))
			if newpage ~= -1
				MenuLib.initMenu(newpage)
			end
		end
	})
	v.drawScaled(
		(x + (rolebutt.w - 16))*FU,
		y*FU, FU/2,
		v.cachePatch(RoleExtraData.icons[role]),
		0
	)
	v.drawString(x + 2, y + (rolebutt.h / 2) - 3,
		role_t.name, V_ALLOWLOWERCASE|(role_t.color),
		"thin"
	)
end

local function drawGenericButton(v,x,y, name, pagename, openpopup, h)
	MenuLib.addButton(v, {
		x = x, y = y,
		width = rolebutt.w, height = rolebutt.h + (h or 0),
		name = name,
		color = 13,
		outline = 19,
		
		pressFunc = function()
			local newpage = MenuLib.findMenu("GuidePage_"..tostring(pagename))
			if newpage ~= -1
				local func = (openpopup) and MenuLib.initPopup or MenuLib.initMenu
				func(newpage)
			end
		end
	})
end

MenuLib.addMenu({
	stringId = "GuidePage_HUDPU",
	title = "Controls",
	
	x = -2, y = -2,
	width = BASEVIDWIDTH + 4,
	height = BASEVIDHEIGHT + 17,
	color = 27,
	
	ps_flags = PS_DRAWTITLE|PS_NOSLIDEIN,
	
	drawer = function(v, ML, menu, props)
		--dont fill the whole screen
		v.draw(1, props.corner_y + 13, v.cachePatch("MMGUD_HUDUI"), 0)
		
		--draw whatever text we need on top of the graphic
		v.drawString(98, 144 + 13,
			"Cycle with WEAPON NEXT/PREV",
			V_ALLOWLOWERCASE, "thin"
		)
	end
})

local clue_text = {
	"There are 3 tiers of \x82Items\x80 you can get from Clues. There's only a limited amount of ",
	"\x82Tier 1 and 2\x80 items, so hurry if you want them. After those are gone, all you'll get ",
	"is junk."
}
local function drawWeaponText(v, x,y, item_id, desc)
	local itemdef_t = MM.Items[item_id]
	local item_patch = v.cachePatch(itemdef_t.display_icon)
	local p_width = item_patch.width * 2/3
	local p_height = item_patch.height * 2/3
	
	local wid = p_width + 2 + v.stringWidth(itemdef_t.display_name,0,"thin")
	local hei = p_height
	for k, str in ipairs(desc)
		wid = max($,
			p_width + 2 + v.stringWidth(str,0,"thin")/2
		)
		if (5 * k > p_height)
			hei = $ + 5
		end
	end
	v.drawFill(x - 1,y - 1,
		wid + 3,hei + 2, 30
	)
	
	v.drawScaled(x*FU,y*FU, FU*2/3, item_patch, 0)
	v.drawString(x + p_width + 2, y, itemdef_t.display_name, V_ALLOWLOWERCASE|V_YELLOWMAP, "thin")
	x = $ + p_width + 2
	y = $ + 8
	
	for k, str in ipairs(desc)
		v.drawString(x,y,str, V_ALLOWLOWERCASE, "small-thin")
		
		y = $ + 5
	end
	return wid+2
end

MenuLib.addMenu({
	stringId = "GuidePage_Clues",
	title = "\x89".."Clues",
	
	x = BASEVIDWIDTH/2 - 300/2,
	y = BASEVIDHEIGHT/2 - 150/2,
	width = 300,
	height = 150,
	ps_flags = PS_DRAWTITLE,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		x = $ + 2
		y = $ + 15
		
		for k,str in ipairs(clue_text)
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			y = $ + 5
		end
		y = $ + 5
		
		v.drawString(x,y, "Tier 1 (1 out of 8 chance to get)", V_ALLOWLOWERCASE|V_YELLOWMAP, "left")
		v.drawFill(props.corner_x, y + 10, 300, 1, 73)
		x = $ + 2; y = $ + 12
		x = $ + drawWeaponText(v, x,y, "shotgun", {
			"Fires spread out projectiles.",
			"\x82".."Fire rate\x80: 3 seconds per shot",
			"",
		})
		x = $ + drawWeaponText(v, x,y, "revolver", {
			"Fires 1 fast bullet, with drop off.",
			"\x82".."Fire rate\x80: 2 seconds per shot",
			"",
		})
		x = $ + drawWeaponText(v, x,y, "sword", {
			"A melee weapon that attacks in a",
			"sweeping motion. Lunges mid-air.",
			"\x82".."Fire rate\x80: 2 seconds per shot",
		})
		y = $ + 25
		
		x = props.corner_x + 2
		v.drawString(x,y, "Tier 2", V_ALLOWLOWERCASE|V_YELLOWMAP, "left")
		v.drawFill(props.corner_x, y + 10, 300, 1, 73)
		x = $ + 2; y = $ + 12
		x = $ + drawWeaponText(v, x,y, "loudspeaker", {
			"When equipped, sending a message will broadcast it to everyone.",
			"Single use.",
		})
		v.drawFill(x,y - 1, 70,23, 30)
		drawWeaponText(v, props.corner_x + menu.width - 117,y, "snowball", {
			"8 snowballs that can push people around.",
			"Great for non-violent self defense.",
		})
		y = $ + 25
		
		x = props.corner_x + 2
		v.drawString(x,y, "Tier 3", V_ALLOWLOWERCASE|V_AZUREMAP, "left")
		v.drawFill(props.corner_x, y + 10, 300, 1, 145)
		x = $ + 2; y = $ + 12
		x = $ + drawWeaponText(v, x,y, "bloxycola", {
			"Refreshing junk.                           ",
			"Useless."
		})
		x = $ + drawWeaponText(v, x,y, "burger", {
			"Yummy junk.                               ",
			"Useless."
		})
		x = $ + drawWeaponText(v, x,y, "radio", {
			"Cool junk. Press \x82[CUSTOM 2]\x80 to drop it ",
			"and play some tunes.",
			'Change its song in the "\x82User Settings\x80" menu.'
		})
		
	end
})

local sher_cc = Roles[MMROLE_SHERIFF].colorcode
local inno_text = {
	"* Collect clues scattered around the map as an \x83Innocent\x80!", "",

	"* Getting all your clues before other people can earn you",
	"a useful item! If you're slow, you'll get a junk item instead.", "",

	"* Stay alive as long as you can for a \x82".."Coin Payout\x80!", "",
	
	"* Find bodies to earn cash! \x82Remember\x80: get close to",
	"bodies to find them. \x85Murderers cannot find bodies\x80!", "",
	
	"patchdraw", "",
	"* Collect guns dropped by "..(sher_cc).."Sheriffs\x80 to fend for yourself!", "",
	"* \x85Murderer\x80 camping the gun? Jump over and get the",
	"gun from above!"
}
MenuLib.addMenu({
	stringId = "GuidePage_Innocent",
	title = "\x83Innocents",

	width = 250,
	height = 150,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		x = $ + 2
		y = $ + 15
		
		for k,str in ipairs(inno_text)
			if str == "patchdraw"
				local scale = FU / 2
				local patch = v.cachePatch("MMGUD_DEADT")
				x = $ + 4
				v.drawScaled(x*FU,y*FU, scale, patch, 0)
				
				v.drawScaled( (x + 25)*FU + patch.width*scale,
					(y - 5)*FU + (patch.height * scale), scale,
					v.getSprite2Patch("sonic", SPR2_STND, false, A, 2, 0),
					0, v.getColormap("sonic", SKINCOLOR_BLUE)
				)
				v.drawString((x + 65)*FU,
					(y + 10)*FU, "+25 coins",
					V_GREENMAP|V_ALLOWLOWERCASE, "thin-fixed"
				)
				
				drawGenericButton(v,
					x + 140,
					y + 10,
					"\x82".."More About Clues",
					"Clues",true
				)
				
				y = $ + FixedInt(patch.height * scale) + 3
				x = $ - 4
				continue
			end
			
			local addspace = str:sub(1,2) ~= "* "
			if addspace then x = $ + 6 end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
			if addspace then x = $ - 6 end
			
		end
	end
})

local sher_text = {
	"* You and your teammates must protect the \x83Innocents\x80!", "",

	"* Neutralize all \x85Murderers\x80 with your weapon. Don't",
	"shoot \x83Innocents\x80! Your teammates are fair game, though.", "",

	"* Save as much \x83Innocents\x80 as you can for a huge \x82".."Coin Payout\x80!", "",
	
	"* Drop your gun with \x82[CUSTOM2]\x80 to relieve yourself of your duties,",
	"or have someone else do your job for you!", "",
	
	"* You will be alerted when your teammates die.", "",
	"* \x85".."Don't shoot people all willy-nilly! \x80Unless you want a pay cut."
}
MenuLib.addMenu({
	stringId = "GuidePage_Sheriff",
	title = sher_cc.."Sheriffs\x80",

	width = 270,
	height = 110,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		x = $ + 2
		y = $ + 15
		
		--Bruh
		MenuLib.interpolate(v,false)
		v.draw(x + props.fakewidth - 35,
			y + 30,
			v.cachePatch("BGLSF0"), 0
		)
		MenuLib.interpolate(v,true)
		
		for k,str in ipairs(sher_text)
			
			local addspace = str:sub(1,2) ~= "* "
			if addspace then x = $ + 6 end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
			if addspace then x = $ - 6 end
			
		end
	end
})

local murd_text = {
	"* You and your teammates must \x85".."dispatch everyone\x80.", "",

	"* Be sneaky! Try to pick off people in secluded areas, or take a risk",
	"and kill multiple people with a sweeping motion!", "",
	
	"patchdraw", "",

	"* \x85Kill\x80 as many people as you can to get a massive \x82".."Coin Payout\x80!", "",
	
	"* If you don't kill enough people before the timer ends, \x85Overtime\x80",
	"will start and \x89The Storm\x80 will start closing in.",
	"\x82Showdown\x80 will start when the number of \x85Murderers\x80 matches",
	"the number of \x83Innocents\x80, and takes priority over \x85Overtime\x80.", "",
	
	"* Collect your clues to earn a \x85Luger\x80, a silent gun with no bullet drop off!", "",
	
	"* Pick up "..(sher_cc).."Sheriffs'\x80 guns to use as your own.", "",
	"* Purchase \x82Perks\x80 from the Shop to make your job easier!", "",
	"* Hold \x82[FIRE NORMAL]\x80 to throw your knife.", "",
}
MenuLib.addMenu({
	stringId = "GuidePage_Murderer",
	title = "\x85Murderer\x80",

	width = 270,
	height = 180,
	
	drawer = function(v, ML, menu, props)
		local x,y = props.corner_x, props.corner_y
		x = $ + 2
		y = $ + 15
		
		--Bruh
		MenuLib.interpolate(v,false)
		v.draw(x + props.fakewidth - 35,
			y + 70,
			v.cachePatch("BGLSE0"), 0
		)
		MenuLib.interpolate(v,true)
		
		for k,str in ipairs(murd_text)
			if str == "patchdraw"
				local scale = FU / 4
				local patch = v.cachePatch("MMGUD_KILL")
				x = $ + 4
				v.drawScaled(x*FU,y*FU, scale, patch, 0)
				
				y = $ + FixedInt(patch.height * scale) + 3
				v.drawString(x,y,
					"The red arrow indicates people in range.",
					V_ALLOWLOWERCASE|V_YELLOWMAP,
					"small-thin"
				)
				x = $ - 4
				continue
			end
			
			local addspace = str:sub(1,2) ~= "* "
			if addspace then x = $ + 6 end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
			if addspace then x = $ - 6 end
			
		end
	end
})

local storm_text = {
	"\x89The Storm\x80 forms during Overtime or Showdown. It closes",
	"into the \x89Storm Gargoyle\x80. If you can't find it, there is",
	"a pointer to it on your screen. \x89The Storm\x80 closes in",
	"faster during Overtime, so you'd better pick up the pace.",
	"There is around a 15 second grace window of being in \x89The",
	"\x89Storm\x80, after that time window, you can stay in \x89The Storm",
	"for up to 5 seconds before dying.",
	
	"patchdraw",
}
MenuLib.addMenu({
	stringId = "GuidePage_TheStorm",
	title = "The Storm",
	
	width = 217,
	height = 130,
	
	drawer = function(v, ML, menu, props)
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
	
		for k,str in ipairs(storm_text)
			if str == "patchdraw"
				x = (props.corner_x + props.fakewidth/2) * FU
				y = ($ + 20)*FU
				
				v.drawScaled(x,y, FU/2,
					v.cachePatch("MMGUD_GARG"), 0
				)
				
				continue
			end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
		end
	end
})

local inter_text = {
	"Dropped items can be picked up through \x82Interactions.\x80",
	"Other map gimmicks can be interacted too, just look for the prompt.",
	"You may need to hold the button on the prompt in order to",
	"completely interact with it. Interaction progress is",
	"signified through the \"loading bar.\"",
	
	"patchdraw",
}
MenuLib.addMenu({
	stringId = "GuidePage_Interactions",
	title = "Interactions",
	
	width = 250,
	height = 130,
	
	drawer = function(v, ML, menu, props)
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
	
		for k,str in ipairs(inter_text)
			if str == "patchdraw"
				x = (props.corner_x + props.fakewidth/2) * FU
				y = ($ + 20)*FU
				
				local icon = v.cachePatch("MM_INTERBOX")
				x = $ - icon.width * FU/2
				
				v.drawScaled(x - 10*FU, y + (icon.height + 5)*FU, FU,
					v.cachePatch("RVOLA2A8"), 0
				)
				v.drawScaled(x,y, FU,
					icon, V_50TRANS
				)

				v.drawString(x + 30*FU,
					y + 3*FU,
					"Revolver",
					V_ALLOWLOWERCASE,
					"thin-fixed"
				)
				v.drawString(x + 30*FU,
					y + 13*FU,
					"Pick up",
					V_ALLOWLOWERCASE|V_GRAYMAP,
					"thin-fixed"
				)
				
				v.drawScaled(x + 15*FU,
					y + 16*FU,
					FU,
					v.cachePatch("MM_INTERBALLBG"),
					V_30TRANS,
					v.getColormap(nil,SKINCOLOR_CARBON)
				)
				v.drawScaled(x + 15*FU,
					y + 16*FU,
					FU/2,
					v.cachePatch("MM_INTERBUT"),
					0
				)
				v.drawString(x + 15*FU,
					y + 12*FU,
					"C3",
					V_ALLOWLOWERCASE,
					"thin-fixed-center"
				)
				
				local resolution = 55
				local timetic = FU * 2/3
				local radi = 12
				if timetic ~= 0
					for i = 0,resolution
						local angle = FixedAngle(
							FixedMul(
								FixedDiv(
									FixedMul(360*FU,timetic),
									resolution*FU
								),
								i*FU
							)-90*FU
						)
						v.drawScaled(x + 15*FU + radi*cos(angle),
							y + 16*FU + radi*sin(angle),
							FU/6,
							v.cachePatch("MM_INTERBALL"),
							trans,
							v.getColormap(nil,SKINCOLOR_CLOUDY)
						)
					end
				end
				
				continue
			end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
			
		end
		
	end
})

local perks_text = {
	"\x82Perks\x80 are abilities you can buy from the Shop. They",
	"make your role as \x85Murderer\x80 a little bit easier.",
	"You can get coins in many ways, so play a couple rounds",
	"and buy yourself some perks, it's a worthwhile investment!",
	/*
	"There is around a 15 second grace window of being in \x89The",
	"\x89Storm\x80, after that time window, you can stay in \x89The Storm",
	"for up to 5 seconds before dying.",
	*/
	
	"patchdraw",
}
MenuLib.addMenu({
	stringId = "GuidePage_Perks",
	title = "Perks",
	
	width = 217,
	height = 110,
	
	drawer = function(v, ML, menu, props)
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
	
		for k,str in ipairs(perks_text)
			if str == "patchdraw"
				x = (props.corner_x + props.fakewidth/2)
				y = $ + 10
				
				MMHUD.menus.drawPerkItem(v,
					(x - 32) - 4, y, MMPERK_HASTE, true
				)
				
				MenuLib.addButton(v, {
					x = x + 4, y = y,
					width = rolebutt.w, height = rolebutt.h,
					name = "Shop",
					color = 13,
					outline = 19,
					
					pressFunc = function()
						MenuLib.initMenu(MenuLib.findMenu("ShopPage"))
						--quick exits
						MenuLib.client.currentMenu.layers = {}
					end
				})
				continue
			end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
		end
	end
})

local overt_text = {
	"\x85Overtime\x80 only starts when time runs out AND the \x85Murderer",
	"has killed at least a fifth of the total players. The \x85Murderer",
	"will slowly be revealed during \x85Overtime\x80. \x82Showdown\x80 starts when",
	"the number of \x85Murderers\x80 matches the number of \x83Innocents\x80.",
	"\x85Murderers\x80 can see \x83Innocents\x80, so be on the look out!",
	/*
	"There is around a 15 second grace window of being in \x89The",
	"\x89Storm\x80, after that time window, you can stay in \x89The Storm",
	"for up to 5 seconds before dying.",
	*/
	
	"patchdraw",
}
MenuLib.addMenu({
	stringId = "GuidePage_Overtime",
	title = "Overtime & Showdown",
	
	width = 230,
	height = 110,
	
	drawer = function(v, ML, menu, props)
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
	
		for k,str in ipairs(overt_text)
			if str == "patchdraw"
				x = (props.corner_x + props.fakewidth/2)*FU
				y = ($ + 10)*FU
				
				local sonis = v.cachePatch("MMSD_SONIC")
				local knux = v.cachePatch("MMSD_KNUCKLES")
				local vs = v.cachePatch("MM_VERSUS")
				
				v.drawScaled(x - 50*FU,
					y, FU/4,
					sonis, 0,
					v.getColormap(nil,SKINCOLOR_BLUE)
				)
				
				v.drawScaled(x - FixedMul(vs.width*FU,FU/4)/2,
					y + FixedMul(vs.height*FU,FU/4)/2,
					FU/4, vs, 0
				)
				
				v.drawScaled(x + 50*FU,
					y, FU/4,
					knux, V_FLIP,
					v.getColormap(nil,SKINCOLOR_RED)
				)
				continue
			end
			
			v.drawString(x,y,str, V_ALLOWLOWERCASE, "small")
			
			if str == ""
				y = $ + 7
			else
				y = $ + 5
			end
		end
	end
})

MenuLib.addMenu({
	stringId = "Protips",
	title = "Guide",
	
	width = 180,
	height = 140,
	
	drawer = function(v, ML, menu, props)
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
		
		do
			v.drawString(x,y,"Roles",V_YELLOWMAP|V_ALLOWLOWERCASE,"left")
			y = $ + 12
			
			drawRoleButton(v,x,y, MMROLE_INNOCENT)
			y = $ + rolebutt.h + 4
			
			drawRoleButton(v,x,y, MMROLE_SHERIFF)
			y = $ + rolebutt.h + 4
			
			drawRoleButton(v,x,y, MMROLE_MURDERER)
			y = $ + rolebutt.h + 4
			
			y = $ + 8
			drawGenericButton(v,x,y, "\x82".."HUD", "HUDPU", true)
		end
		
		x = props.corner_x + 100
		y = props.corner_y + 32
		
		drawGenericButton(v,x,y, "\x89".."The Storm", "TheStorm")
		y = $ + rolebutt.h + 4
		
		drawGenericButton(v,x,y, "\x82Interactions", "Interactions")
		y = $ + rolebutt.h + 4
		
		drawGenericButton(v,x,y, "\x82Perks", "Perks")
		y = $ + rolebutt.h + 4
		
		drawGenericButton(v,x,y, "", "Overtime", false, 8)
		do
			local center = y + (rolebutt.h + 8) / 2
			v.drawString(x + rolebutt.w/2, center - 9,
				"\x85Overtime\n\x82Showdown",
				V_ALLOWLOWERCASE,
				"thin-center"
			)
		end
		y = $ + rolebutt.h + 32
		
		if menu.fromkeydown
			v.drawString(
				160,
				props.corner_y + props.fakeheight - 10,
				"Press \x82[WEAPON 5]\x80 to open this menu again!",
				V_ALLOWLOWERCASE,
				"thin-center"
			)
		end
	end,
	
	exit = function(flags)
		MenuLib.menus[MenuLib.findMenu("Protips")].fromkeydown = nil
	end
})