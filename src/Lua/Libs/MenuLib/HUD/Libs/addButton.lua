local ML = MenuLib

local function getSelectedAttrib(over, prop, attrib, index)
	local new_attrib
	
	if (over)
		new_attrib = prop.selected and prop.selected[attrib] or prop[attrib]
	else
		new_attrib = prop[attrib]
	end
	/*
	if new_attrib == nil
	and prop.template ~= nil
		new_attrib = prop.template[attrib]
	end
	*/
	
	if type(new_attrib) == "table"
		return new_attrib[index]
	end
	return new_attrib
end

/*
from menulib v2 prototype:
function MenuLib:addMenu(props)
  assert(props ~= nil and type(props) == "table", "MenuLib:addMenu() <- requires input of type \"table\"")
  assert(props.name ~= nil, "MenuLib:addMenu(table) <- table must have \"name\" field")
  assert(self:findMenu(props.name) == nil, "MenuLib:addMenu(table) <- \"name\" field must be unique (dupe of \""..props.name.."\")")
  
  setmetatable(props, {__index = self.protos.menu})
  self.menus[self.menu_incre] = props
  self.menu_incre = self.menu_incre + 1
  return props
end

maybe `selected` could use a metatable instead?
the one reason why butons dont use metatables right now is that since these are all added
in the menu's drawer, theyre constantly executed every tic, setting a metatable could
possibly add even more overhead than necessary
*/

return function(v, props)
	--highlight
	local over = false
	
	if props.interptag ~= nil
		ML.interpolate(v, props.interptag)
	end
	setmetatable(props, {__index = props.template})
	if props.seletected ~= nil
		setmetatable(props.seletected, {__index = props})
	end
	
	if ML.buttonHovering(v,props)
	and (props.pressFunc ~= nil)
		local this = {
			x = getSelectedAttrib(true, props, "x"),
			y = getSelectedAttrib(true, props, "y"),
			width = getSelectedAttrib(true, props, "width"),
			height = getSelectedAttrib(true, props, "height"),
			outline = getSelectedAttrib(true, props, "outline")
		}
		if (this.outline)
			this.x = $ - 1
			this.y = $ - 1
			this.width = $ + 2
			this.height = $ + 2
		end
		
		v.drawFill(this.x - 2, this.y - 2,
			this.width + 4, this.height + 4,
			0
		)
		v.drawFill(this.x - 1, this.y - 1,
			this.width + 3, this.height + 3,
			31
		)
		v.drawFill(this.x, this.y,
			this.width + 1, this.height + 1,
			0
		)
		over = true
		
		if (props.id ~= nil)
			ML.client.hovering = props.id
		end
		
		if (props.pressFunc ~= nil)
			ML.client.canPressSomething = true
			
			--pressed
			if (ML.client.doMousePress)
				props.pressFunc()
				S_StartSound(nil, sfx_menu1)
			end
		end
	end
	
	if (getSelectedAttrib(over, props, "outline") ~= nil)
	and (getSelectedAttrib(over, props, "outline") ~= -1)
		v.drawFill(props.x - 1, props.y - 1,
			props.width + 2, props.height + 2,
			getSelectedAttrib(over, props, "outline")
		)
	end
	
	if getSelectedAttrib(over, props, "color") ~= -1
		v.drawFill(props.x, props.y,
			props.width, props.height,
			getSelectedAttrib(over, props, "color")
		)
	end
	
	if (props.name ~= nil)
		if type(props.name) == "string"
			v.drawString(
				props.x + (props.width/2),
				props.y + (props.height/2) - 4,
				props.name,
				getSelectedAttrib(over, props, "nameStyles", "flags") or V_ALLOWLOWERCASE,
				getSelectedAttrib(over, props, "nameStyles", "align") or "thin-center"
			)
		elseif type(props.name) == "function"
			props.name(v,
				props, props.x, props.y
			)
			ML.interpolate(v,false)
		--elseif type(props.name) == "table"
		end
	end
	props.highlighted = over
	
	return props
end