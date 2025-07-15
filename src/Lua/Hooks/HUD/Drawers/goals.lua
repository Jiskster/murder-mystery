--there could be a better way to do this
local function HUD_GoalDrawer(v,p)
	if splitscreen then return end
	
	local x = 2*FU
	local y = 19*FU
	local flags = V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE|V_PERPLAYER
	
	local goals = {}
	
	if not MM_N.dueling
		if p.mm.clues.startamount ~= nil then
			if p.mm.clues.startamount ~= 0
			and p.mm.role ~= MMROLE_SHERIFF
				local complete = #p.mm.clues.list == 0 and V_GREENMAP or 0
				table.insert(goals,{
					string = (#p.mm.clues.list).."/"..p.mm.clues.startamount.." Clues left",
					flags = flags|complete
				})
			end
		end
		
		if p.mm.role == MMROLE_MURDERER
		and MM_N.minimum_killed > 0
			local complete = MM_N.peoplekilled >= MM_N.minimum_killed and V_GREENMAP or 0
			local needed = MM_N.numbertokill
			table.insert(goals,{
				string = MM_N.peoplekilled.."/"..needed.." People killed",
				flags = flags|complete
			})
		end
	end
	
	do
		local longest_str = max(55, MMHUD.info_xpos or 0)
		local goal_len = 0
		for k,val in ipairs(goals)
			longest_str = max(
				v.stringWidth(val.string,0,"thin"),
				$
			)
			goal_len = $ + 1
		end
		local height = (goal_len * 8)
		
		height = $ + 12
		y = 4*FU
		
		local x = x - MMHUD.xoffset
		
		v.drawFill((x/FU), (y/FU) - 3,
			longest_str + 2, 1,
			31|V_50TRANS|(flags &~V_ALLOWLOWERCASE)
		)
		v.drawFill((x/FU) - 1, (y/FU) - 2,
			longest_str + 4, height + 4,
			31|V_50TRANS|(flags &~V_ALLOWLOWERCASE)
		)
		v.drawFill((x/FU), (y/FU) + height + 2,
			longest_str + 2, 1,
			31|V_50TRANS|(flags &~V_ALLOWLOWERCASE)
		)
		
		y = 19*FU
	end
	
	for k,val in ipairs(goals)
		v.slideDrawString(x,y, val.string, val.flags, "thin-fixed")
		y = $ + 8*FU
	end
end
return HUD_GoalDrawer