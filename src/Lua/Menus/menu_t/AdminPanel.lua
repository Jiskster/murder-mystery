local buttonwidth = 65
local buttonpad = buttonwidth + 5
local buttonpad_h = 25 + 5

MenuLib.addMenu({
	stringId = "AdminPanel",
	title = "Admin Panel",
	
	width = 180,
	height = 120,
	
	drawer = function(v, ML, menu, props)
		if not ((consoleplayer == server) or (IsPlayerAdmin(consoleplayer)))
			MenuLib.initMenu(-1)
			return
		end
		
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
		
		do
			MenuLib.addButton(v, {
				x = x,
				y = y,
				
				width = buttonwidth,
				height = 25,
				
				name = "",
				color = 155,
				outline = 159,
				
				pressFunc = function()
					MenuLib.client.commandbuffer = "add mm_afkmode 1"
				end,
				
			})
			
			v.drawString(x + (buttonwidth/2),
				y + 2,
				"Anti-AFK",
				V_ALLOWLOWERCASE|V_YELLOWMAP,
				"thin-center"
			)
			v.drawString(x + (buttonwidth/2),
				y + 15,
				CV_MM.afkkickmode.string,
				V_ALLOWLOWERCASE,
				"thin-center"
			)
			
		end
		
		MenuLib.addButton(v, {
			x = (props.corner_x + menu.width) - 5 - buttonwidth,
			y = y,
			
			width = buttonwidth,
			height = 25,
			
			name = "Debug",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				MenuLib.initMenu(MenuLib.findMenu("AdminPanel_Sub1"))
			end,
			
		})
		
		--line 2
		do
			local ypos = y + (menu.height - 5 - 25) - 25
			MenuLib.addButton(v, {
				x = x,
				y = ypos,
				
				width = buttonwidth,
				height = 25,
				
				name = "",
				color = 155,
				outline = 159,
				
				pressFunc = function()
					MenuLib.client.commandbuffer = "MM_AdminBadge"
				end,
				
			})
			
			v.drawString(x + (buttonwidth/2),
				ypos + 2,
				"Admin Badge",
				V_ALLOWLOWERCASE|V_YELLOWMAP,
				"thin-center"
			)
			v.drawString(x + (buttonwidth/2),
				ypos + 15,
				consoleplayer.mm_save.adminbadge and "Visible" or "Hidden",
				V_ALLOWLOWERCASE,
				"thin-center"
			)
			
		end
		
	end
})

local debug_command = ""
local debug_commandid = MenuLib.newBufferID()

MenuLib.addMenu({
	stringId = "AdminPanel_Sub1",
	title = "Admin Panel",
	
	width = (buttonpad*4) + 7,
	height = 120,
	
	drawer = function(v, ML, menu, props)
		MenuLib.interpolate(v, false)
		local x,y = props.corner_x, props.corner_y
		x = $ + 5
		y = $ + 20
		
		do
			MenuLib.addButton(v, {
				x = x,
				y = y,
				
				width = buttonwidth,
				height = 25,
				
				name = "",
				color = 155,
				outline = 159,
				
				pressFunc = function()
					MenuLib.client.commandbuffer = "toggle mm_debug"
				end,
				
			})
			
			v.drawString(x + (buttonwidth/2),
				y + 2,
				"Debug",
				V_ALLOWLOWERCASE|V_YELLOWMAP,
				"thin-center"
			)
			v.drawString(x + (buttonwidth/2),
				y + 15,
				CV_MM.debug.string,
				V_ALLOWLOWERCASE,
				"thin-center"
			)
			
		end
		
		MenuLib.addButton(v, {
			x = x + buttonpad,
			y = y,
			
			width = buttonwidth,
			height = 25,
			
			name = "End Round",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				MenuLib.client.commandbuffer = "mm_endgame"
			end,
			
		})
		
		MenuLib.addButton(v, {
			x = x + buttonpad*2,
			y = y,
			
			width = buttonwidth,
			height = 25,
			
			name = "Showdown",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				MenuLib.client.commandbuffer = "mm_startshowdown"
			end,
			
		})
		
		MenuLib.addButton(v, {
			x = x + buttonpad*3,
			y = y,
			
			width = buttonwidth,
			height = 25,
			
			name = "Overtime",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				MenuLib.client.commandbuffer = "mm_timeto0"
			end,
			
		})
		
		--layer 2
		MenuLib.addButton(v, {
			x = x,
			y = y + buttonpad_h,
			
			width = buttonwidth,
			height = 25,
			
			name = "Storm Radius",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				ML.startTextInput(debug_command,debug_commandid, {
					onenter = function()
						MenuLib.client.commandbuffer = "mm_stormradius "..ML.client.textbuffer
						debug_command = ""
					end,
					tooltip = "\x86mm_stormradius <radius> <time>",
					typesound = sfx_oldrad
                })				
			end,
		})
		
		MenuLib.addButton(v, {
			x = x + buttonpad,
			y = y + buttonpad_h,
			
			width = buttonwidth,
			height = 25,
			
			name = "Set Role",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				ML.startTextInput(debug_command,debug_commandid, {
					onenter = function()
						MenuLib.client.commandbuffer = "MM_MakeMeA "..ML.client.textbuffer
						debug_command = ""
					end,
					tooltip = "\x86mm_makemea <role>",
					typesound = sfx_oldrad
                })				
			end,
		})
		
		MenuLib.addButton(v, {
			x = x + buttonpad*2,
			y = y + buttonpad_h,
			
			width = buttonwidth,
			height = 25,
			
			name = "Give Coins",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				ML.startTextInput(debug_command,debug_commandid, {
					onenter = function()
						MenuLib.client.commandbuffer = "MM_AddRings "..ML.client.textbuffer
						debug_command = ""
					end,
					tooltip = "\x86mm_addrings <rings>",
					typesound = sfx_oldrad
				})				
			end,
		})
		
		MenuLib.addButton(v, {
			x = x + buttonpad*3,
			y = y + buttonpad_h,
			
			width = buttonwidth,
			height = 25,
			
			name = "Set Perks",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				ML.startTextInput(debug_command,debug_commandid, {
					onenter = function()
						MenuLib.client.commandbuffer = "MM_SetPerk "..ML.client.textbuffer
						debug_command = ""
					end,
					tooltip = "\x86mm_setperk <pri/sec> <name>",
					typesound = sfx_oldrad
				})				
			end,
		})

		--layer 3
		MenuLib.addButton(v, {
			x = x,
			y = y + buttonpad_h*2,
			
			width = buttonwidth,
			height = 25,
			
			name = "Give Item",
			color = 13,
			outline = 19,
			
			pressFunc = function()
				ML.startTextInput(debug_command,debug_commandid, {
					onenter = function()
						MenuLib.client.commandbuffer = "mm_giveitem "..ML.client.textbuffer
						debug_command = ""
					end,
					tooltip = "\x86mm_giveitem <name>",
					typesound = sfx_oldrad
				})				
			end,
		})
	end
})
