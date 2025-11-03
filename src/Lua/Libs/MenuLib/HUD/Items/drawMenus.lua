local ML = MenuLib
ML.HUD.menu_fake_width = 1
ML.HUD.menu_fake_height = 1

return function(v,ML)
	if ML.client.currentMenu.id == -1 then
		ML.HUD.menu_fake_width = 1
		ML.HUD.menu_fake_height = 1
		
		return
	end
	
	local menu = ML.menus[ML.client.currentMenu.id]
	
	if menu.ms_flags & MS_NOANIM
		ML.HUD.menu_fake_width = menu.width
		ML.HUD.menu_fake_height = menu.height
	else
		ML.HUD.menu_fake_width = FixedCeil(ease.linear(FU/2, $*FU, menu.width*FU)) / FU
		ML.HUD.menu_fake_height = FixedCeil(ease.linear(FU/2, $*FU, menu.height*FU)) / FU
	end
	
	local fake_width = ML.HUD.menu_fake_width
	local fake_height = ML.HUD.menu_fake_height
	
	local corner_x = (BASEVIDWIDTH/2) - (fake_width/2)
	local corner_y = (BASEVIDHEIGHT/2) - (fake_height/2)
	
	if (menu.outline ~= nil)
	and (menu.outline ~= -1)
		v.drawFill(
			corner_x - 1, corner_y - 1,
			fake_width + 2, fake_height + 2,
			menu.outline
		)
	end
	
	if menu.color ~= -1
		v.drawFill(
			corner_x, corner_y,
			fake_width, fake_height,
			menu.color
		)
	end
	
	v.drawString(corner_x + 2,
		corner_y + 2,
		menu.title,
		V_ALLOWLOWERCASE,
		"left"
	)
	
	do --if (ML.client.currentMenu.prevId ~= -1)
		ML.interpolate(v, -1)
		ML.addButton(v, {
			x = (BASEVIDWIDTH/2) + (fake_width/2) - 25,
			y = corner_y,
			width = 25,
			height = 13,
			
			name = ML.client.currentMenu.layers[#ML.client.currentMenu.layers - 1] ~= nil and "Back" or "Exit",
			color = 27,
			
			pressFunc = function()
				ML.initMenu(-1)
			end
		})
		ML.interpolate(v, true)
	end
	
	if not (menu.ms_flags & MS_NOLINE)
		v.drawFill(corner_x, corner_y + 13,
			fake_width, 1,
			0
		)
	end
	
	if (menu.drawer ~= nil)
		ML.interpolate(v, false)
		menu.drawer(v, ML, menu, {
			corner_x = corner_x,
			corner_y = corner_y,
			fakewidth = fake_width,
			fakeheight = fake_height
		})
	end
	--re-interp
	ML.interpolate(v, true)
	
	ML.HUD.stage_id = $ + 1
	ML.client.menuLayer = $ + 1
end, nil, true