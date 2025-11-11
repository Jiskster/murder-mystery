local ML = MenuLib
local function noPopUpInteract()
	local nointer = false
	if (#ML.client.popups > 0)
		nointer = true
	end
	
	if (#ML.client.popups == 1)
	and (ML.menus[ML.client.popups[1].id].ps_flags & PS_IRRELEVANT)
		nointer = false
	end
	return nointer
end

return function(v, props)
	if ML.client.menuTime < 3 then return false; end
	if (ML.client.currentMenu.id == -1) then return false; end
	if (ML.client.menuLayer ~= ML.HUD.stage_id) then return false; end
	if (ML.client.textbuffer ~= nil) then return false; end
	
	--shitty ik
	if ML.HUD.stage_item.name == "drawMenus"
	and noPopUpInteract()
		return false
	end
	
	return ML.mouseInZone(props.x,props.y, props.width,props.height, false)
end