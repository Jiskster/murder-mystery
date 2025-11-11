local ML = MenuLib
ML.menus = {}

ML.templates.menu = {
	title = "Menu",
	width = 300,
	height = 170,
	
	color = 27,
	outline = -1,

	--"hooks"
	/*
		function(drawer v,
			MenuLib ML,
			menu_t menu,
			table position {
				corner_x, corner_y
			}
		)
		drawer = func,
		
		--function(initreason IR_*)
		init = func,
		--function(closereason CR_*, boolean instant? [popup only])
		exit = func,
	*/
	--gotta make your own!
	--stringId = string
	
	--popup only
	x = BASEVIDWIDTH/2,
	y = BASEVIDHEIGHT/2,
	ps_flags = 0,
	ms_flags = 0,
}

return function(props)
	assert(props ~= nil and type(props) == "table", "MenuLib.addMenu() <- requires input of type \"table\"")
	assert(props.stringId ~= nil, "MenuLib.addMenu(table) <- table must have \"stringId\" field")
	assert(ML.findMenu(props.stringId) == -1, "MenuLib.addMenu(table) <- \"stringId\" field must be unique (dupe of \""..props.stringId.."\")")
	
	if props.template ~= nil
		for k,v in pairs(props.template)
			props[k] = v
		end
	end
	setmetatable(props, {__index = ML.templates.menu})
	table.insert(ML.menus, props)
	return #ML.menus, props
end