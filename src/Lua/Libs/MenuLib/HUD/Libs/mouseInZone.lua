local ML = MenuLib
return function(x,y, w,h, fixed)
	if ML.client.menuTime < 3 then return false; end
	if (ML.client.currentMenu.id == -1) then return false; end
	if (ML.client.menuLayer ~= ML.HUD.stage_id) then return false; end
	if (ML.client.textbuffer ~= nil) then return false; end
	
	local m_x = ML.client.mouse_x
	local m_y = ML.client.mouse_y
	if not fixed
		m_x = $ / FU
		m_y = $ / FU
	end
	
	if ((m_x >= x) and (m_x <= x + w))
	and ((m_y >= y) and (m_y <= y + h))
		return true
	end
	return false
end