local ZCollide = MM.require "Libs/zcollide"
local dist_values = {}

dist_values["CLOSE"] = 3000/15
dist_values["NEAR"] = 3000/5
dist_values["FAR"] = 3000/2

local function skinColorToChatColor(color)
	local chatcolor = skincolors[color].chatcolor;

	-- this elseif table is by srb2, not me
	if (chatcolor == V_MAGENTAMAP)
		return "\x81"
	elseif (chatcolor == V_YELLOWMAP)
		return "\x82";
	elseif (chatcolor == V_GREENMAP)
		return "\x83";
	elseif (chatcolor == V_BLUEMAP)
		return "\x84";
	elseif (chatcolor == V_REDMAP)
		return "\x85";
	elseif (chatcolor == V_GRAYMAP)
		return "\x86";
	elseif (chatcolor == V_ORANGEMAP)
		return "\x87";
	elseif (chatcolor == V_SKYMAP)
		return "\x88";
	elseif (chatcolor == V_PURPLEMAP)
		return "\x89";
	elseif (chatcolor == V_AQUAMAP)
		return "\x8a";
	elseif (chatcolor == V_PERIDOTMAP)
		return "\x8b";
	elseif (chatcolor == V_AZUREMAP)
		return "\x8c";
	elseif (chatcolor == V_BROWNMAP)
		return "\x8d";
	elseif (chatcolor == V_ROSYMAP)
		return "\x8e";
	elseif (chatcolor == V_INVERTMAP)
		return "\x8f"
	end

	return "\x80"
end

--ugh
local function SphereToCartesian(alpha,beta)
	return {
	   	x = FixedMul(cos(alpha), cos(beta)),
	    y = FixedMul(sin(alpha), cos(beta)),
	    z = sin(beta)
	}
end

local namechecktype = MT_LETTER
local function checkRayCast(from, to, props)
	local blocked = 0
	local debug = CV_MM.debug.value
	
	local angle = props.angle
	local aiming = props.aiming
	local namecheck = P_SpawnMobjFromMobj(from.mo,
		0, --P_ReturnThrustX(nil,angle, 2*FU),
		0, --P_ReturnThrustY(nil,angle, 2*FU),
		0, --41*FixedDiv(from.mo.height, from.mo.scale)/48,
		namechecktype
	)
	namecheck.angle = angle
	namecheck.aiming = aiming
	namecheck.flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOSECTOR
	namecheck.radius = FixedMul(mobjinfo[MT_NAMECHECK].radius, from.mo.scale)
	namecheck.height = FixedMul(mobjinfo[MT_NAMECHECK].height, from.mo.scale)
	namecheck.namecheck = true
	
	local speed = namecheck.radius * 2
	local vec = SphereToCartesian(angle,aiming)
	namecheck.momx = FixedMul(speed, vec.x)
	namecheck.momy = FixedMul(speed, vec.y)
	namecheck.momz = FixedMul(speed, vec.z)
	
	P_SetOrigin(namecheck, 
		from.x + P_ReturnThrustX(nil,angle, 4*FU),
		from.y + P_ReturnThrustY(nil,angle, 4*FU),
		(from.z + (41*from.mo.height/48)) - 8*FU
	)
	
	local blockrad = namecheck.radius + to.mo.radius
	local startclipping = 7
	for i = 0, 255
		if not (namecheck and namecheck.valid)
			return false
		end
		
		if debug
			P_SpawnMobjFromMobj(namecheck,0,0,0,MT_SPARK)
		end
		
		if (i == startclipping)
			namecheck.flags = $ &~MF_NOCLIP
		end
		
		P_XYMovement(namecheck)
		if not (namecheck and namecheck.valid)
			return false
		end
		
		P_ZMovement(namecheck)
		if not (namecheck and namecheck.valid)
			return false
		end
		
		if (i < startclipping)
		and R_PointInSubsectorOrNil(namecheck.x,namecheck.y) == nil
			if (namecheck and namecheck.valid)
				P_RemoveMobj(namecheck)
			end
			return false
		end
		
		if (namecheck.momx == 0 and namecheck.momy == 0)
			if blocked == 8
				if (namecheck and namecheck.valid)
					P_RemoveMobj(namecheck)
				end
				return false
			end
			blocked = $ + 1
		end
		
		if (not (abs(namecheck.x - to.x) > blockrad
		or abs(namecheck.y - to.y) > blockrad))
		and ZCollide(namecheck, to.mo)
			if (namecheck and namecheck.valid)
				P_RemoveMobj(namecheck)
			end
			return true
		end
	end
	
	if (namecheck and namecheck.valid)
		P_RemoveMobj(namecheck)
		return false
	end
end

local function AntiAdmin(src, msg)
	local admincolor = "\x82"
	local normcolor = "\x80 "
	local color = skinColorToChatColor((src.mo and src.mo.valid) and src.mo.color or src.skincolor)
	if (gamestate == GS_LEVEL)
	and (src.spectator)
		color = "\x86"
		normcolor = "\x86 "
	end
	
	local plrname = src.name
	local name = color.."<"..plrname..">" -- default
	local perm_level = MM:getpermlevel(src)
	
	if perm_level == 1 then -- is Admin
		name = color.."<"..admincolor.."@"..color..plrname..">"
	elseif perm_level == 2 then -- is Server
		name = color.."<"..admincolor.."~"..color..plrname..">"
	end
	
	chatprint(name..normcolor..msg, true)
	return true
end

addHook("PlayerMsg", function(src, t, trgt, msg)
	if not MM:isMM() then return end
	
	--allow dedicated server chats
	if (src == server and not players[0]) then return end
	if gamestate ~= GS_LEVEL then return AntiAdmin(src,msg); end
	if t == 3 then return end
	
	--only apply AntiAdmin here
	local no_prox_chat = false
	local npc_nospectators = false
	if (MM_N.gameover)
	or (MM_N.showdown)
	or (MM:pregame())
	or (MM_N.waiting_for_players)
	or (paused)
		no_prox_chat = true
		npc_nospectators = MM:pregame()
	end
	if no_prox_chat
		if npc_nospectators
		--theyre dead and im not
		and (not (
			src and src.mo and src.mo.health
			and src.mm and not (src.mm.spectator or src.spectator)
		) and (consoleplayer and consoleplayer.mo and consoleplayer.mo.health
			and consoleplayer.mm and not (consoleplayer.mm.spectator or consoleplayer.spectator)
		)) then
			return true
		end
		return AntiAdmin(src,msg)
	end
	
	local hook_event = MM.events["OnRawChat"]
	for i,v in ipairs(hook_event)
		if MM.tryRunHook("OnRawChat", v,
			src, t, trgt, msg
		) then
			return true
		end
	end
	
	--if we're dead, see everyones chats
	if not (consoleplayer
	and consoleplayer.mo
	and consoleplayer.mo.health
	and consoleplayer.mm
	and not consoleplayer.mm.spectator) then
		return AntiAdmin(src,msg);
	end
	
	--if theyre dead, dont see their chats at all
	if not (src
		and src.mo
		and src.mo.health
		and src.mm
		and not src.mm.spectator) then
			return true
	end
	
	local plrname = src.name
	local alias = src.mm.alias
	
	local perm_level = MM:getpermlevel(src)

	if alias then
		if alias.perm_level ~= nil
		and (alias.posingas and alias.posingas.valid) then
			perm_level = MM:getpermlevel(alias.posingas)
		end
		
		if alias.name then
			plrname = alias.name
		end
	end
	
	--talk from cameras
	if (src.mmcam and src.mmcam.cam and src.mmcam.cam.valid)
		MMCAM.CameraSay(src,src.mmcam.cam,msg)
	--talk to cameras
	elseif #MMCAM.TOTALCAMS ~= nil
		local me = src.mo
		local myyname = plrname
		if perm_level == 1 then -- is Admin
			myyname = "\x82@".. $ .."\x86"
		elseif perm_level == 2 then -- is Server
			myyname = "\x82~".. $ .."\x86"
		end
		
		for k,cam in ipairs(MMCAM.TOTALCAMS)
			
			if not (me and me.valid) then break end
			if not (cam.health) then continue end
			if not P_CheckSight(me,cam) then continue end
			
			local dist = R_PointToDist2(me.x,me.y, cam.x,cam.y)
			if dist > MMCAM.far_dist*cam.scale then continue end
			
			--send our message to the cameramen (skibidi)
			for i = 0,#players - 1
				local p = cam.args.players[i]
				
				if not (p and p.valid) then continue end
				if not (p.mm) then continue end
				if (p.spectator or p.mm.spectator) then continue end
				
				chatprintf(p,"\x86[CAM]<"..myyname..">\x80 "..msg,true)
			end
		end
	end

	local dist = R_PointToDist2(consoleplayer.mo.x, consoleplayer.mo.y,
		src.mo.x,
		src.mo.y
	)
	
	if dist > (1 << 12)*FU then
		return true
	end

	if not P_CheckSight(consoleplayer.mo, src.mo)
	and (dist >= 64*FU) then
		--dont even bother
		if dist >= 255*FU
			return true
		end
		
		if not checkRayCast(
			{mo = consoleplayer.mo,	x = consoleplayer.mo.x,	y = consoleplayer.mo.y,	z = consoleplayer.mo.z},
			{mo = src.mo,			x = src.mo.x,			y = src.mo.y,			z = src.mo.z},
			{
				angle = R_PointToAngle2(consoleplayer.mo.x,consoleplayer.mo.y, src.mo.x,src.mo.y),
				aiming = R_PointToAngle2(0, consoleplayer.mo.z, dist, src.mo.z),
				dist = dist,
			}
		)
			chatprint("\x86You can hear faint talking through the walls...", true)
			return true
		end
	end
	
	local color = skinColorToChatColor(src.mo and src.mo.color or src.skincolor)
	
	if alias
	and alias.skincolor then
		color = skinColorToChatColor(alias.skincolor)
	end
	
	local name = color.."<"..plrname..">".."\x80" -- default

	if perm_level == 1 then -- is Admin
		name = color.."<\x82@"..color..plrname..">".."\x80"
	elseif perm_level == 2 then -- is Server
		name = color.."<\x82~"..color..plrname..">".."\x80"
	end

	local disttext = "[NEAR]"

	if src ~= consoleplayer then
		local distcheck
		for name,_dist in pairs(dist_values) do
			if dist <= _dist*FU
			and (not distcheck or distcheck > _dist*FU) then
				disttext = "["..name.."]"
				distcheck = _dist*FU
				continue
			end
		end
		
		name = "\x86"..disttext.."\x80".." "..$
	end
	
	chatprint(name.."\x80 "..msg, true)
	return true
end)