local speedCap = MM.require "Libs/speedCap"
local stopfriction = tofixed("0.750")
local jumpfactormulti = tofixed("1.10")

local function ApplyMovementBalance(player)
    local pmo = player.mo

    if pmo and pmo.valid then
        local pta = R_PointToAngle2(0, 0, pmo.momx, pmo.momy)
		
        if pmo.lastpta ~= nil then
            local adiff = AngleFixed(pta)-AngleFixed(pmo.lastpta)
			
            if AngleFixed(adiff) > 180*FU
                adiff = InvAngle($)
            end
            
            if adiff > 10*FU and player.speed > 18*FU 
            and P_IsObjectOnGround(pmo) then
                pmo.skidscore = 3
            	MM.hooksPassed("SkidStart", player)
            end
			
            if pmo.skidscore then
                pmo.friction = stopfriction
				if CV_MM.skid_dust.value then
					P_SpawnSkidDust(player, 4*FU, true)
				end
				
                pmo.skidscore = $ - 1
                if pmo.skidscore == 0 then
                	MM.hooksPassed("SkidFinish", player)
                end
            end
        end
		
		if P_IsObjectOnGround(pmo) then
			pmo.playergroundcap = FixedHypot(pmo.momx, pmo.momy) + 10*FU
		end
		
        pmo.lastpta = pta
    end
end

return function(p)
	if CV_MM.debug.value then return end
	
	local sonic = skins["sonic"]
	local speedcap = MM_N.speed_cap
	local basespeedmulti = FU
	
	p.charflags = $ &~(SF_DASHMODE|SF_RUNONWATER|SF_CANBUSTWALLS|SF_MACHINE|SF_NOJUMPDAMAGE)
	p.charability = CA_NONE
	p.charability2 = CA2_NONE
	p.jumpfactor = FixedMul(sonic.jumpfactor, jumpfactormulti)
	p.runspeed = 9999*FU

	if (p.panim == PA_ABILITY)
	or (p.panim == PA_ABILITY2)
		P_ResetPlayer(p)
		p.mo.state = S_PLAY_WALK
		P_MovePlayer(p)
	end
	
	p.thrustfactor = sonic.thrustfactor
	p.accelstart = (sonic.accelstart*3)/2 -- Buff start acceleration
	p.acceleration = sonic.acceleration
	
	p.rings = 0

	p.powers[pw_shield] = 0
	p.powers[pw_underwater] = 0
	p.powers[pw_spacetime] = 0
	
	speedcap = FixedMul($, basespeedmulti)
	speedcap = MM.hooksPassed("MovementSpeedCap", p, $) or $

	if not P_IsObjectOnGround(p.mo) then
		local me = p.mo
		local airspeedcap = max(speedcap - 3*me.scale, 20 * me.scale)

		if p.speed > airspeedcap then
			local div = 16 * FU
			local newspeed = p.speed - FixedDiv(p.speed - airspeedcap,div)
			
			me.momx = FixedMul(FixedDiv(me.momx, p.speed), newspeed)
			me.momy = FixedMul(FixedDiv(me.momy, p.speed), newspeed)
		end

		speedcap = $ - 3*FU
	end

	-- reverse water effects
	if (p.mo.eflags & (MFE_UNDERWATER|MFE_GOOWATER)) then
		p.accelstart = 3*$/2
		p.acceleration = 3*$/2
		p.normalspeed = $*2
		p.jumpfactor = FixedDiv($, FixedDiv(117*FU, 200*FU))
		
		if not P_IsObjectOnGround(p.mo)
		and (p.mo.state ~= S_PLAY_SPRING) then
		--probably used a spring
			local grav = P_GetMobjGravity(p.mo)
			p.mo.momz = $ + FixedMul(grav, 3*FU) - grav/3
		end
	--probably jumped out of water
	elseif p.mo.last_weflag then
		if (p.pflags & PF_JUMPED) then
			p.mo.momz = FixedMul(
				--get the last (hopefully corrected to normal grav) momz...
				FixedMul(p.mo.last_momz or 0, FixedDiv(117*FU, 200*FU)),
				--and reapply the extra thrust you get
				FixedDiv(780*FU, 457*FU)
			)
		end
	end

	MM.hooksPassed("PreMovementTick", p)

	local effects = p.mm.effects
	for i,v in pairs(effects) do
		if v.fuse then
			v.fuse = $ - 1
			
			if MM.player_effects[i] then
				if MM.player_effects[i].thinker then
					MM.player_effects[i].thinker(p)
				end
			end
			
			if v.modifiers then
				local modifiers = v.modifiers
				
				if modifiers.normalspeed_multi then
					basespeedmulti = FixedMul($, modifiers.normalspeed_multi)
				end
			end
			
			if v.fuse <= 0 then
				if MM.player_effects[i].on_end then
					MM.player_effects[i].on_end(p)
				end
				
				effects[i] = nil
			end
		end
	end

	if p.powers[pw_carry] ~= CR_ZOOMTUBE
		if p.mo.playergroundcap ~= nil then
			if not P_IsObjectOnGround(p.mo) then
				speedcap = min(p.mo.playergroundcap, $) or $
			end
		end
		
		speedCap(p.mo, FixedMul(speedcap,p.mo.scale))
	end
	
	ApplyMovementBalance(p)

	p.normalspeed = speedcap
	p.mo.last_weflag = p.mo.eflags & (MFE_UNDERWATER|MFE_GOOWATER)
	p.mo.last_momz = p.mo.momz

	MM.hooksPassed("PostMovementTick", p)
end