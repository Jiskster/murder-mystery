local ML = MenuLib

local function canExitMenu(layers)
	local canLeave = false
	
	if layers[#layers - 1] == nil
	or layers[#layers - 1] == -1
		canLeave = true
	end
	
	if #layers == 2
		canLeave = false
	end
	
	return canLeave
end

return function(id)
	if (isdedicatedserver) then return end
	
	--just opened
	if ML.client.currentMenu.id == -1
		ML.client.doMousePress = false
		ML.client.mouseTime = -1
		
		ML.client.menuLayer = 1
	end
	
	input.ignoregameinputs = true
	local layers = ML.client.currentMenu.layers
	
	--immediately close ALL menus
	if id == -2
		for i = #layers, 1, -1
			local this_menu = ML.menus[layers[i]]
			if this_menu ~= nil
			and (this_menu.exit ~= nil)
				this_menu.exit(CR_MENUEXITED|CR_FORCEDCLOSEALL)
			end
		end
		
		input.ignoregameinputs = false
		
		ML.client.mouse_x = (BASEVIDWIDTH*FU) / 2
		ML.client.mouse_y = (BASEVIDHEIGHT*FU) / 2
		ML.client.currentMenu.layers = {}
		ML.client.currentMenu.id = -1
		ML.client.menuLayer = 0
		
		--close all popups too
		for k,_ in ipairs(ML.client.popups)
			ML.initPopup(-1, true)
			continue
		end
		
		return
	end
	
	if id ~= -1
		--dont open the same menu more than once
		if ML.client.currentMenu.id == id then return end
		
		table.insert(ML.client.currentMenu.layers, ML.client.currentMenu.id)
		local this_menu = ML.menus[id]
		if (this_menu.init ~= nil)
			this_menu.init(IR_INITMENU)
		end
	--go backwards
	else
		--there is NOT an available submenu before this one, so exit
		if canExitMenu(layers)
			local this_menu = ML.menus[ML.client.currentMenu.id]
			if (this_menu.exit ~= nil)
				this_menu.exit(CR_MENUEXITED)
			end
			
			input.ignoregameinputs = false
			
			ML.client.mouse_x = (BASEVIDWIDTH*FU) / 2
			ML.client.mouse_y = (BASEVIDHEIGHT*FU) / 2
			ML.client.currentMenu.layers = {}
			ML.client.menuLayer = 0
			
			for k,_ in ipairs(ML.client.popups)
				ML.initPopup(-1, true)
				continue
			end
			
		else
			id = layers[#layers]
			layers[#layers] = nil
		end
		
	end
	
	ML.client.currentMenu.id = id
end