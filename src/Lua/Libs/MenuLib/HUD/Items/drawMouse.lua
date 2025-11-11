return function(v, ML)
	local dup = v.dupx()
	local graphic = ML.client.canPressSomething and "ML_RBLX_POINT" or "ML_RBLX_CURS"
	if ML.client.mouse_graphic ~= nil
		graphic = ML.client.mouse_graphic
	end
	v.drawScaled(
		ML.client.mouse_x,
		ML.client.mouse_y,
		FU / dup,
		v.cachePatch(graphic),
		0
	)
end, nil, true