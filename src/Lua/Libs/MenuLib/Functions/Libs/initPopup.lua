local ML = MenuLib

--this functions just the same as initMenu(), this just allows
--another menu to draw as if it was a popup
return function(id,instant)
	if (isdedicatedserver) then return end
	
	--close this popup
	if (id == -1)
		local popupitem_t = ML.client.popups[#ML.client.popups]
		local this_menu = ML.menus[popupitem_t.id]
		
		if this_menu.exit ~= nil
			this_menu.exit(CR_POPUPCLOSED, instant)
		end
		
		if this_menu.ps_flags & PS_NOSLIDEIN
		or instant
			table.remove(ML.client.popups)
		else
			popupitem_t.goingdown = true
			popupitem_t.lifespan = min($, 7)
		end
		return
	end
	
	input.ignoregameinputs = true
	
	table.insert(ML.client.popups, {
		id = id,
		order = #ML.client.popups,
		lifespan = 0,
		
		--animation
		goingdown = false,
		y_off = 700,
	})
	local this_menu = ML.menus[id]
	if this_menu.init ~= nil
		this_menu.init(IR_INITPOPUP)
	end
	
end