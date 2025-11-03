return function(v, set)
	if type(v) ~= "table"
		error("MenuLib.interpolate(drawer v, tag) :: argument 1 must be drawer table")
	end
	if (v.interpolate == nil) then return end
	
	v.interpolate(set)
end