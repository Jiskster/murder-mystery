local activebuttons = BT_JUMP|BT_WEAPONNEXT|BT_WEAPONPREV|BT_ATTACK|BT_CUSTOM1|BT_CUSTOM2|BT_CUSTOM3
--lol
rawset(_G,"AFK_TIMEOUT", 45*TICRATE)

--minimum difference to be detected as "player input"
local ANGLE_FUDGE = 7*FU

local function handleTimeout(p)
	if CV_MM.afkkickmode.value == 0 then return end
	
	if (p == server
	or IsPlayerAdmin(p))
	or (CV_MM.afkkickmode.value == 2) -- "kill" mode
		P_KillMobj(p.mo,nil,nil,DMG_SPECTATOR)
		chatprintf(p,"\x82*You have been made a spectator for being AFK.")
		MM_N.knownDeadPlayers[#p] = true
		
		p.mm.afkhelpers.timedout = false
		p.mm.whokilledme = "Killed by an AFK heart attack."
		p.mm.afkhelpers.timeuntilreset = 0
		p.mm.afktimer = 0
		
		p.mm_save.timesafk = $ + 1
		if p.mm_save.timesafk >= 3
			p.mm_save.afkmode = true
		end
	else
		COM_BufAddText(server,"kick "..#p.." AFK")
	end
end

local function angleDiff(ang1, ang2)
	local adiff = FixedAngle(
		AngleFixed(ang1) - AngleFixed(ang2)
	)
	if AngleFixed(adiff) > 180*FU
		adiff = InvAngle($)
	end
	return AngleFixed(adiff)
end

return function(p)
	local cmd = p.cmd
	local afk = p.mm.afkhelpers
	
	if (MM_N.waiting_for_players)
	or (MM_N.gameover)
	or (p.mm.spectator)
	or (splitscreen)
		return
	end
	
	/*
	print("afk",
		afk.timeuntilreset,
		p.mm.afktimer,
		afk.timedout,
		CV_MM.afkkickmode.value
	)
	*/
	
	if afk.timedout
	or not CV_MM.afkkickmode.value
	or afk.keepalive
		p.mm.afktimer = 0
		afk.keepalive = false
		return
	end
	
	if not ((cmd.forwardmove or cmd.sidemove
	or cmd.buttons & activebuttons)
	or (angleDiff(afk.lastangle, cmd.angleturn << 16) >= ANGLE_FUDGE)
	or (angleDiff(afk.lastaiming, cmd.aiming) >= ANGLE_FUDGE))
		if afk.timeuntilreset < 10*TICRATE
			afk.timeuntilreset = $+1
		else
			p.mm.afktimer = $ + 1
			
			if p.mm.afktimer == AFK_TIMEOUT
				p.mm.afktimer = 0
				afk.timedout = true
				
				handleTimeout(p)
			end
		end
	else
		if afk.timeuntilreset
			afk.timeuntilreset = max($-6,0)
		else
			p.mm.afktimer = $*3/4
		end
	end
	
	afk.lastangle = cmd.angleturn << 16
	afk.lastaiming = cmd.aiming	
end
