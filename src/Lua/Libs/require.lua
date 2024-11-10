local libs = {}

local function require(value)
	value = $:gsub(".lua", "")
	if not libs[value] then
		libs[value] = {dofile(value)}
	end

	return unpack(libs[value])
end

return require