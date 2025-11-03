local ML = MenuLib

local function drawIt(v, ML)
	local irrelevant_popups = 0
	for key, popupitem_t in ipairs(ML.client.popups)
		local menu = ML.menus[popupitem_t.id]
		if (menu.ps_flags & PS_IRRELEVANT)
		or (popupitem_t.goingdown)
			irrelevant_popups = $ + 1
			continue
		end
		continue
	end
	
	ML.client.menuLayer = $ + #ML.client.popups - irrelevant_popups
	
	for key, popupitem_t in ipairs(ML.client.popups)
		ML.interpolate(v, key)
		local menu = ML.menus[popupitem_t.id]
		
		--set the stage_id to the topmost pop-up
		if key == #ML.client.popups
			ML.HUD.stage_id = $ + #ML.client.popups - irrelevant_popups
		end
		
		local target = (popupitem_t.goingdown) and 700*FU or 0 
		popupitem_t.y_off = (ease.linear(FU/2, $*FU, target)) / FU
		
		local y_off = popupitem_t.y_off
		if (menu.ps_flags & PS_NOSLIDEIN)
			y_off = 0
		end
		
		if (popupitem_t.y_off >= (target/FU) - 10)
		and (popupitem_t.goingdown)
			table.remove(ML.client.popups, key)
			continue
		end
		
		--interpolate the background and stuff
		if not (popupitem_t.goingdown)
			popupitem_t.lifespan = $ + 1
		else
			popupitem_t.lifespan = $ - 1
		end
		if not (menu.ps_flags & PS_NOFADE)
			v.drawFill(0,0,
				(v.width()/v.dupx())+1,
				(v.height()/v.dupy())+1,
				31|(max(3, 10 - popupitem_t.lifespan)<<V_ALPHASHIFT)|V_SNAPTOLEFT|V_SNAPTOTOP
			)
		end
		
		local corner_x = menu.x
		local corner_y = menu.y + y_off
		
		if (menu.outline ~= nil)
			v.drawFill(
				corner_x - 1, corner_y - 1,
				menu.width + 2, menu.height + 2,
				menu.outline
			)
		end
		if (menu.color ~= -1)
			v.drawFill(
				corner_x, corner_y,
				menu.width, menu.height,
				menu.color
			)
		end
		
		if (menu.ps_flags & PS_DRAWTITLE)
			v.drawString(corner_x + 2,
				corner_y + 2,
				menu.title,
				V_ALLOWLOWERCASE,
				"left"
			)
			
			v.drawFill(corner_x, corner_y + 13,
				menu.width, 1,
				0
			)
			
		end
		
		if not (menu.ps_flags & PS_NOXBUTTON)
			ML.addButton(v, {
				x = corner_x + (menu.width) - 10,
				y = corner_y,
				width = 10,
				height = 13,
				
				name = "x",
				color = menu.color,
				
				pressFunc = function()
					ML.initPopup(-1)
				end
			})
		end
		
		if (menu.drawer ~= nil)
			menu.drawer(v, ML, menu, {
				corner_x = corner_x,
				corner_y = corner_y,
			})
		end
	end
	ML.interpolate(v, false)
end

return function(v, ML)
	drawIt(v, ML)	
end, nil, false