local ML = MenuLib
local keyname2sym = {
	["KEY123"] = "{",
	["KEY124"] = "|",
	["KEY125"] = "}",
	["KEY126"] = "`",
	["TILDE"] = "~"
}

return function(key, buffer, callback)
	local keydown = false
	
	if key.name == "space"
		buffer = $ .. " "
		keydown = true
	elseif input.keyNumPrintable(key.num)
		local letter = input.keyNumToName(key.num)
		if ML.client.text_shiftdown or ML.client.text_capslock
			letter = input.keyNumToName( input.shiftKeyNum(key.num) )
		end
		if keyname2sym[letter] ~= nil
			letter = keyname2sym[letter]
		end
		
		buffer = $ .. letter
		if buffer:len() > 32
			buffer = buffer:sub(1,32)
		end
		keydown = true
	elseif key.name == "backspace"
		if buffer:len() ~= 0
			if ML.client.text_ctrldown
				local i = buffer:len()
				
				--find our first spcae
				repeat
					i = $ - 1
				until (buffer:sub(i,i) == " " or i <= 0)
				--search for any extra spaces
				while (i and buffer:sub(i,i) == " ")
					i = $ - 1
				end
				
				if i <= 0
					buffer = ""
				else
					buffer = string.sub(buffer, 1, i)
				end
			else
				buffer = string.sub(buffer, 1, buffer:len() - 1)
			end
			keydown = true
		end
	elseif key.name == "enter"
	and callback ~= nil
		callback(buffer)
		keydown = true
	end
	
	if keydown
		S_StartSound(nil,ML.client.textbuffer_sfx,consoleplayer)
	end
	if buffer:len() > 32
		buffer = buffer:sub(1,32)
	end
	return buffer or "", keydown
	
end